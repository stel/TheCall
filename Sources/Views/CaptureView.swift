//
//  CaptureView.swift
//  TheCall
//
//  Created by Dmitry Obukhov on 14/03/16.
//  Copyright © 2016 Dmitry Obukhov. All rights reserved.
//

import Cocoa
import AVFoundation
import GLKit
import GLUT

class CaptureView: NSOpenGLView {
    
    var image: CIImage? {
        didSet {
            needsDisplay = true
        }
    }
    
    private var ciContext: CIContext?
    private var lastBounds: NSRect?

    override static func defaultPixelFormat() -> NSOpenGLPixelFormat {
        let attributes: [NSOpenGLPixelFormatAttribute] = [
            UInt32(NSOpenGLPFAAccelerated),
            UInt32(NSOpenGLPFANoRecovery),
            UInt32(NSOpenGLPFAColorSize),
            UInt32(32),
            UInt32(NSOpenGLPFAAllowOfflineRenderers),
            UInt32(0)
        ]
        
        return NSOpenGLPixelFormat(attributes: attributes)!
    }
    
    override var mouseDownCanMoveWindow: Bool {
        return true
    }
    
    func updateCIContextIfNeeded() {
        if ciContext != nil {
            return
        }
        
        let cglContext = openGLContext!.CGLContextObj
        
        if pixelFormat == nil {
            pixelFormat = CaptureView.defaultPixelFormat()
        }
        
        CGLLockContext(cglContext)
        
        ciContext = CIContext(CGLContext: cglContext, pixelFormat: pixelFormat!.CGLPixelFormatObj, colorSpace: nil, options: nil)
        
        CGLUnlockContext(cglContext)
    }
    
    func updateViewportIfNeeded() {
        if bounds == lastBounds {
            return
        }
        
        openGLContext?.update()
        
        glViewport(0, 0, Int32(bounds.size.width), Int32(bounds.size.height))
        
        glMatrixMode(UInt32(GL_PROJECTION))
        glLoadIdentity()
        
        // Flip horizontaly because we want to see us in a mirror
        glOrtho(Double(bounds.size.width), 0, 0, Double(bounds.size.height), -1, 1)
        
        lastBounds = bounds
    }
    
    override func drawRect(dirtyRect: NSRect) {
        openGLContext?.makeCurrentContext()
        
        updateCIContextIfNeeded()
        updateViewportIfNeeded()
        
        if let image = image {
            ciContext?.drawImage(image, inRect: bounds, fromRect: image.extent)
        } else {
            glClear(UInt32(GL_COLOR_BUFFER_BIT))
        }
        
        glFlush()
    }
    
}
