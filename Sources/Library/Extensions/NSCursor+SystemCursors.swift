//
//  NSCursor+SystemCursors.swift
//  TheCall
//
//  Created by Dmitry Obukhov on 14/03/16.
//  Copyright © 2016 Dmitry Obukhov. All rights reserved.
//

import Cocoa

extension NSCursor {
    
    static func resizeNorthSouthCursor() -> NSCursor {
        return NSCursor(named: "resizenorthsouth")!
    }
    
    static func resizeEastWestCursor() -> NSCursor {
        return NSCursor(named: "resizeeastwest")!
    }
    
    static func resizeNorthEastSouthWestCursor() -> NSCursor {
        return NSCursor(named: "resizenortheastsouthwest")!
    }
    
    static func resizeNorthWestSouthEastCursor() -> NSCursor {
        return NSCursor(named: "resizenorthwestsoutheast")!
    }
    
    convenience init?(named name: String) {
        guard let image = NSImage(named: name) else {
            return nil
        }
        
        var hotSpot = NSPoint(x: 0.0, y: 0.0)
        
        if let url = NSBundle.mainBundle().URLForResource(name, withExtension: "plist") {
            let info = NSDictionary(contentsOfURL: url)
            
            hotSpot = NSPoint(x: (info?["hotx"] as? CGFloat) ?? 0.0, y: (info?["hoty"] as? CGFloat) ?? 0.0)
        }
        
        self.init(image: image.retinaReadyCursorImage(), hotSpot: hotSpot)
    }

}

extension NSImage {
    
    private func retinaReadyCursorImage() -> NSImage {
        let resultImage = NSImage(size: size)
        
        for scale in 1..<4 {
            let transform = NSAffineTransform()
            
            transform.scaleBy(CGFloat(scale))
            
            if let rasterCGImage = self.CGImageForProposedRect(nil, context: nil, hints: [NSImageHintCTM: transform]) {
                let rep = NSBitmapImageRep(CGImage: rasterCGImage)
                rep.size = size
                resultImage.addRepresentation(rep)
            }
        }
        
        return resultImage
    }
    
}
