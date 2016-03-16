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

    var image: CIImage? {
        didSet {
            needsDisplay = true
        }
    }
    
    override func drawRect(dirtyRect: NSRect) {
        if let image = image {
            NSGraphicsContext.currentContext()?.CIContext?.drawImage(image, inRect: bounds, fromRect: image.extent)
        }
    }
    
}
