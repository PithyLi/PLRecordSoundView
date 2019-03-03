//
//  PLAudioRecord.swift
//  PLSoundWaveView
//
//  Created by Pithy'L on 2018/11/28.
//  Copyright © 2018 Pithy'L. All rights reserved.
//

import AVFoundation
import Accelerate

protocol PLAudioRecordPortocol: NSObjectProtocol {
    func record(_ record: PLAudioRecord, volume: Float)
}

class PLAudioRecord: NSObject {

    public static let shared = PLAudioRecord()

    public weak var delegate: PLAudioRecordPortocol?
    
    private static let bufSize: Int = 4096
    private var engine: AVAudioEngine?
    private var lame: lame_t?
    private var mp3Buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufSize)
    private var data = Data()

    private var averagePowerForChannel0: Float = 0.0
    private var averagePowerForChannel1: Float = 0.0

    private var minLevel: Float = 0.1
    private var maxLevel: Float = 0.1

    deinit {
        mp3Buffer.deallocate()
    }

    public func record() {
        let session = AVAudioSession.sharedInstance()
        let options: AVAudioSession.CategoryOptions = [.mixWithOthers, .allowBluetooth, .defaultToSpeaker]
        do {
            if #available(iOS 11.0, *) {
                try? session.setCategory(.playAndRecord, mode: .default, policy: .default, options: options)
            } else {
                try? session.setCategory(.playAndRecord, mode: .default, options: options)
            }
            try session.setPreferredSampleRate(44100)
            try session.setPreferredIOBufferDuration(0.1)
            try session.setActive(true)
            initLame()
        } catch {
            return
        }

        guard let input = engine?.inputNode else {
            return
        }

        let format = input.inputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize:AVAudioFrameCount(PLAudioRecord.bufSize) , format: format) { [weak self] (buffer, when) in

            guard let this = self else {
                return
            }

            if let buf = buffer.floatChannelData?[0]
            {
                let frameLength = Int32(buffer.frameLength) / 2
                let bytes = lame_encode_buffer_interleaved_ieee_float(this.lame, buf, frameLength, this.mp3Buffer, Int32(PLAudioRecord.bufSize))

                let levelLowpassTrig: Float = 0.5
                var avgValue: Float32 = 0
                vDSP_meamgv(buf, 1, &avgValue, vDSP_Length(frameLength))
                this.averagePowerForChannel0 = (levelLowpassTrig * ((avgValue==0) ? -100.0 : 20.0 * log10f(avgValue))) + ((1-levelLowpassTrig) * this.averagePowerForChannel0)

                let volume = min((this.averagePowerForChannel0 + Float(50))/50.0, 1.0)

                this.minLevel = min(this.minLevel, volume)
                this.maxLevel = max(this.maxLevel, volume)
                DispatchQueue.main.async {
                    this.delegate?.record(this, volume: volume)
                }
                if bytes > 0 {
                    this.data.append(this.mp3Buffer, count: Int(bytes))
                }
            }
        }

        engine?.prepare()
        do {
            try engine?.start()
        } catch {
        }
    }

    private func initLame() {

        engine = AVAudioEngine()

        guard let engine = engine else { return }

        let playNode = AVAudioPlayerNode()
        engine.attach(playNode)

//        let mixer = engine.mainMixerNode
//        engine.connect(playNode, to: mixer, format: mixer.outputFormat(forBus: 0))

        let input = engine.inputNode
        // 耳返
        let output = engine.outputNode
        engine.connect(input, to: output, format: input.inputFormat(forBus: 0))

        let format = input.inputFormat(forBus: 0)
        let sampleRate = Int32(format.sampleRate) / 2

        lame = lame_init()
        lame_set_in_samplerate(lame, sampleRate);
        lame_set_VBR_mean_bitrate_kbps(lame, 96);
        lame_set_VBR(lame, vbr_off);
        lame_init_params(lame);
    }

    public func stop() {
        engine?.inputNode.removeTap(onBus: 0)
        engine = nil
        do {
            var url = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let name = String("PLAudio_" + String(CACurrentMediaTime())).appending(".mp3")
            url.appendPathComponent(name)
            if !data.isEmpty {
                try data.write(to: url)
            }
            else {
                print("error")
            }
        } catch {
            print("fail to write")
        }
        data.removeAll()
    }
}
