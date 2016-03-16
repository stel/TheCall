//
//  CallWindowController.swift
//  TheCall
//
//  Created by Dmitry Obukhov on 14/03/16.
//  Copyright © 2016 Dmitry Obukhov. All rights reserved.
//

import Cocoa

class CallWindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
    
        window?.titleVisibility = .Hidden
        window?.titlebarAppearsTransparent = true
        window?.movableByWindowBackground = true
    }

}

extension CallWindowController: NSWindowDelegate {
    
    func windowShouldClose(sender: AnyObject) -> Bool {
        guard let callViewController = contentViewController as? CallViewController else {
            return true
        }
        
        callViewController.endCall()
        
        // Should we care about that in test app? Nope.
        return true
    }
    
}
