//
//  Monochrome.swift
//  TheCall
//
//  Created by Dmitry Obukhov on 16/03/16.
//  Copyright © 2016 Dmitry Obukhov. All rights reserved.
//

import Cocoa

class Monochrome: SimpleCIFilterVideoEffect {
    
    let filter = CIFilter(name: "CIColorMonochrome")!
    
    convenience init(color: NSColor) {
        self.init()
        
        filter.setValue(CIColor(color: color), forKey: "inputColor")
    }
    
}
