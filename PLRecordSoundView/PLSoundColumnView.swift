//
//  PLSoundColumnView.swift
//  PLSoundWaveView
//
//  Created by Jayz Zz on 2018/11/28.
//  Copyright © 2018 Pithy'L. All rights reserved.
//

import UIKit

class PLSoundColumnView: UIView {

    private let levelWidth = 3.0
    private let levelMargin = 2.0
    public var idleAmplitude: CGFloat = 0.05
    private var _amplitude: CGFloat = 0.05

    private weak var linker: CADisplayLink?

    private var currentLevels: [CGFloat] = [0.05, 0.05, 0.05, 0.05, 0.05]

    private var allLevels: [CGFloat] = [0.05, 0.05, 0.05, 0.05, 0.05]

    private var levelPath = UIBezierPath()

    public var level: CGFloat = 0.0 {
        didSet {
            _amplitude = max(level, idleAmplitude)
        }
    }

    public var amplitude: CGFloat {
        get {
            return _amplitude
        }
    }
    
    private lazy var levelLayer: CAShapeLayer = {
        let shaperLayer = CAShapeLayer()
        let width = CGFloat(6 * levelWidth + 5 * levelMargin)
        shaperLayer.frame = CGRect(x: 0, y: 0, width: width, height: 20.0)
        shaperLayer.strokeColor = UIColor.white.cgColor
//        shaperLayer.shadowColor = UIColor.cyan.cgColor
        shaperLayer.lineWidth = CGFloat(levelWidth)
        return shaperLayer

    }()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.layer.addSublayer(levelLayer)
    }

    deinit {
        stop()
    }

    public func stop() {
        if linker != nil {
            linker?.invalidate()
            linker = nil
        }
    }

    public func reset() {
        if self.linker == nil {
            let linker = CADisplayLink(target: self, selector: #selector(PLSoundColumnView.updateLevels))
            linker.add(to: .current, forMode: RunLoop.Mode.common)
            self.linker = linker
        }
    }

    public func start() {
        if self.linker == nil {
            let linker = CADisplayLink(target: self, selector: #selector(PLSoundColumnView.updateLevels))
            linker.add(to: .current, forMode: RunLoop.Mode.common)
            self.linker = linker
        }
    }

    @objc private func updateLevels() {
        let level = amplitude
        currentLevels.removeLast()
        currentLevels.insert(level, at: 0)
        allLevels.append(level)
        updateMeters()
    }

    private func updateMeters() {
        let level = CGFloat(allLevels.first ?? 0.05)
        currentLevels.removeLast()
        currentLevels.insert(level, at: 0)
        allLevels.remove(at: 0)
        levelPath = UIBezierPath()
        let height = levelLayer.frame.height
        var i = 0
        for level in currentLevels {
            let widtn = (levelWidth + levelMargin) + levelWidth / 2.0
            let x = CGFloat(i) * CGFloat(widtn)
            let pathH = level * height
            let startY = height / 2.0 - pathH / 2.0
            let endY = height / 2.0 + pathH / 2.0
            levelPath.move(to: CGPoint(x: x, y: startY))
            levelPath.addLine(to: CGPoint(x: x, y: endY))
            i += 1
        }
        self.levelLayer.path = levelPath.cgPath

    }
}
