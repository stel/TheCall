//
//  Blur.swift
//  TheCall
//
//  Created by Dmitry Obukhov on 16/03/16.
//  Copyright © 2016 Dmitry Obukhov. All rights reserved.
//

import Cocoa

class Blur: SimpleCIFilterVideoEffect {
    
    let filter = CIFilter(name: "CIGaussianBlur", withInputParameters: ["inputRadius": 10])!
    
    convenience init(radius: CGFloat) {
        self.init()
        filter.setValue(radius, forKey: "inputRadius")
    }
    
}
