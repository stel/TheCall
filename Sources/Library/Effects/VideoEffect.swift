//
//  VideoEffect.swift
//  TheCall
//
//  Created by Dmitry Obukhov on 16/03/16.
//  Copyright © 2016 Dmitry Obukhov. All rights reserved.
//

import Cocoa
import AVFoundation

protocol VideoEffect {
    
    func apply(sourceImage: CIImage) -> CIImage
    
}

protocol SimpleCIFilterVideoEffect: VideoEffect {
    
    var filter: CIFilter { get }
    
}

extension SimpleCIFilterVideoEffect {
    
    func apply(sourceImage: CIImage) -> CIImage {
        filter.setValue(sourceImage, forKey: kCIInputImageKey)
        
        return filter.outputImage!
    }
    
}
