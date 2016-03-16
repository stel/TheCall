//
//  OverlayView.swift
//  TheCall
//
//  Created by Dmitry Obukhov on 14/03/16.
//  Copyright © 2016 Dmitry Obukhov. All rights reserved.
//

import Cocoa

class OverlayView: LayerBackedView {
    
    var transient = false {
        didSet {
            if !transient {
                alphaValue = 1.0
            }
        }
    }
    
    override func updateTrackingAreas() {
        for area in trackingAreas {
            removeTrackingArea(area)
        }
        
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.ActiveAlways, .MouseEnteredAndExited], owner: self, userInfo: nil))
        
        super.updateTrackingAreas()
        
        // In case mouse exited while live resize
        if let event = NSApp.currentEvent {
            if !bounds.contains(convertPoint(event.locationInWindow, fromView: nil)) {
                mouseExited(event)
            }
        }
    }
    
    override func mouseEntered(theEvent: NSEvent) {
        animator().alphaValue = 1.0
    }
    
    override func mouseExited(theEvent: NSEvent) {
        if transient {
            animator().alphaValue = 0.0
        }
    }
    
}
