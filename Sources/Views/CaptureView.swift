//
//  CaptureView.swift
//  TheCall
//
//  Created by Dmitry Obukhov on 14/03/16.
//  Copyright © 2016 Dmitry Obukhov. All rights reserved.
//

import Cocoa
import AVFoundation

class CaptureView: LayerBackedView {

    var session: AVCaptureSession? {
        get {
            return previewLayer.session
        }
        
        set {
            previewLayer.session = newValue
            previewLayer.connection.automaticallyAdjustsVideoMirroring = false
            previewLayer.connection.videoMirrored = true
        }
    }
    
    private var previewLayer = AVCaptureVideoPreviewLayer()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        setupPlayerLayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setupPlayerLayer()
    }
    
    private func setupPlayerLayer() {
        layer?.addSublayer(previewLayer)
    }
    
    override func layoutSublayersOfLayer(layer: CALayer) {
        if layer == self.layer {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            previewLayer.frame = bounds
            CATransaction.commit()
        }
    }
    
}
