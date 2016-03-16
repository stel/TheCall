//
//  NSFileManager+TemporaryURL.swift
//  TheCall
//
//  Created by Dmitry Obukhov on 16/03/16.
//  Copyright © 2016 Dmitry Obukhov. All rights reserved.
//

import Cocoa

extension NSFileManager {
    
    func applicationTemporaryDirectoryURL() -> NSURL {
        let url = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(NSProcessInfo.processInfo().processName, isDirectory: true)
        
        do {
            try NSFileManager.defaultManager().createDirectoryAtURL(url, withIntermediateDirectories: true, attributes: nil)
        } catch {
            BlueScreenOfDeath.show(reason: "Can't create temporary directory")
        }
        
        return url
    }
    
    func applicationTemporaryUniqueFileURL() -> NSURL {
        return applicationTemporaryDirectoryURL().URLByAppendingPathComponent(NSProcessInfo.processInfo().globallyUniqueString)
    }
    
}
