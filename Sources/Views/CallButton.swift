//
//  CallButton.swift
//  TheCall
//
//  Created by Dmitry Obukhov on 15/03/16.
//  Copyright © 2016 Dmitry Obukhov. All rights reserved.
//

import Cocoa

class CallButton: NSButton {

    override func drawRect(dirtyRect: NSRect) {
        let path = NSBezierPath(ovalInRect: bounds)
        
        if state == NSOnState {
            if highlighted {
                NSColor(calibratedRed:0.96, green:0.26, blue:0.18, alpha:1).setFill()
            } else {
                NSColor(calibratedRed:1, green:0.28, blue:0.24, alpha:1).setFill()
            }
            
            path.fill()
            alternateImage?.drawInRect(bounds)
        } else {
            if highlighted {
                NSColor(calibratedRed:0.16, green:0.79, blue:0.25, alpha:1).setFill()
            } else {
                NSColor(calibratedRed:0.3, green:0.85, blue:0.39, alpha:1).setFill()
            }
            
            path.fill()
            image?.drawInRect(bounds)
        }
    }
    
}
