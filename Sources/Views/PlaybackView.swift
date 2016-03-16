//
//  PlaybackView.swift
//  TheCall
//
//  Created by Dmitry Obukhov on 14/03/16.
//  Copyright © 2016 Dmitry Obukhov. All rights reserved.
//

import Cocoa
import AVFoundation

class PlaybackView: LayerBackedView {
    
    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        
        set {
            playerLayer.player = newValue
        }
    }

    private var playerLayer = AVPlayerLayer(player: nil)
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        setupPlayerLayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setupPlayerLayer()
    }
    
    private func setupPlayerLayer() {
        layer?.addSublayer(playerLayer)
    }
    
    override func layoutSublayersOfLayer(layer: CALayer) {
        if layer == self.layer {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            playerLayer.frame = bounds
            CATransaction.commit()
        }
    }
    
}
