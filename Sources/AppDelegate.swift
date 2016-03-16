//
//  AppDelegate.swift
//  TheCall
//
//  Created by Dmitry Obukhov on 14/03/16.
//  Copyright © 2016 Dmitry Obukhov. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }
    
}

