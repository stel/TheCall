//
//  LayerBackedView.swift
//  TheCall
//
//  Created by Dmitry Obukhov on 14/03/16.
//  Copyright © 2016 Dmitry Obukhov. All rights reserved.
//

import Cocoa

class LayerBackedView: NSView {
    
    @IBInspectable var backgroundColor: NSColor? {
        get {
            guard let cgColor = layer?.backgroundColor else {
                return nil
            }
            
            return NSColor(CGColor: cgColor)
        }
        
        set {
            layer?.backgroundColor = newValue?.CGColor
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        setupLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setupLayer()
    }
    
    private func setupLayer() {
        wantsLayer = true
    }
    
}
