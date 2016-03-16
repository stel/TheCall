//
//  RoundButton.swift
//  TheCall
//
//  Created by Dmitry Obukhov on 15/03/16.
//  Copyright © 2016 Dmitry Obukhov. All rights reserved.
//

import Cocoa

class RoundPopUpButton: NSPopUpButton {

    override func drawRect(dirtyRect: NSRect) {
        let path = NSBezierPath(ovalInRect: bounds)
        
        if highlighted {
            NSColor(calibratedRed:0.35, green:0.35, blue:0.35, alpha:1).setFill()
        } else {
            NSColor(calibratedRed:0.5, green:0.5, blue:0.5, alpha:1).setFill()
        }
        
        path.fill()
        image?.drawInRect(bounds)
    }
    
}
