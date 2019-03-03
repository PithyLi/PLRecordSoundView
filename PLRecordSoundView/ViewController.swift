//
//  ViewController.swift
//  PLRecordSoundView
//
//  Created by Jayz Zz on 2018/11/29.
//  Copyright © 2018 Pithy'L. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet private weak var soundWaveView: PLSoundWaveView!

    @IBOutlet private weak var soundColumnView: PLSoundColumnView!

    override func viewDidLoad() {
        super.viewDidLoad()
        PLAudioRecord.shared.delegate = self
        soundColumnView.backgroundColor = UIColor(red: 30.0 / 255, green: 147.0 / 255, blue: 250.0 / 255, alpha: 1.0)
//        soundWaveView.reset()
        soundColumnView.reset()
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func startAction(_ sender: Any) {
//        soundWaveView.start()
        soundColumnView.start()
        PLAudioRecord.shared.record()
    }

    @IBAction func stopAction(_ sender: Any) {
//        soundWaveView.reset()
        PLAudioRecord.shared.stop()
    }
}

extension ViewController: PLAudioRecordPortocol {
    func record(_ record: PLAudioRecord, volume: Float) {
//        soundWaveView.level = CGFloat(volume / 2.0) + 0.1
        soundColumnView.level = CGFloat(volume)
        print("volue: \(volume)")
    }
}

