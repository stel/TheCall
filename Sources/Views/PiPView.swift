//
//  PiPView.swift
//  TheCall
//
//  Created by Dmitry Obukhov on 14/03/16.
//  Copyright © 2016 Dmitry Obukhov. All rights reserved.
//

import Cocoa

class PiPView: LayerBackedView {
    
    @IBOutlet var primaryView: NSView? {
        willSet {
            primaryView?.removeFromSuperview()
        }
        
        didSet {
            if let view = primaryView {
                view.frame = bounds
                view.autoresizingMask = [.ViewWidthSizable, .ViewHeightSizable]
                
                addSubview(view)
            }
        }
    }
    
    @IBOutlet var secondaryView: NSView? {
        didSet {
            if secondaryView == nil {
                hideSecondaryView()
            }
            
            secondaryViewContainer.contentView = secondaryView
        }
    }
    
    var contentAspectRatio = NSSize(width: 1, height: 1)
    
    private let secondaryViewContainer = FloatingContainerView(frame: NSRect(x: 0, y: 0, width: 200, height: 120))
    
    override var intrinsicContentSize: NSSize {
        let conteinerSize = secondaryViewContainer.frame.size
        
        return NSSize(width: conteinerSize.width, height: conteinerSize.width / contentAspectRatio.width * contentAspectRatio.height)
        
//        return secondaryViewContainer.frame.size
    }
    
    func showSecondaryView() {
        if secondaryViewContainer.superview != self {
            secondaryViewContainer.autoresizingMask = [.ViewMaxXMargin, .ViewMaxYMargin, .ViewMinXMargin, .ViewMinYMargin]
            addSubview(secondaryViewContainer)
        }
    }
    
    func hideSecondaryView() {
        secondaryViewContainer.removeFromSuperview()
    }

}

private class FloatingContainerView: LayerBackedView {
    
    enum Transformation {
        case Move
        case ResizeTop
        case ResizeTopRight
        case ResizeRight
        case ResizeBottomRight
        case ResizeBottom
        case ResizeBottomLeft
        case ResizeLeft
        case ResizeTopLeft
        
        static let allValues = [Move, ResizeTop, ResizeTopRight, ResizeRight, ResizeBottomRight, ResizeBottom, ResizeBottomLeft, ResizeLeft, ResizeTopLeft]
    }
    
    private var hotCorner: CGFloat = 8.0
    private var paddings: CGFloat = 20.0
    private var minSize = NSSize(width: 80, height: 60)
    
    override var mouseDownCanMoveWindow: Bool {
        return false
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func acceptsFirstMouse(theEvent: NSEvent?) -> Bool {
        return true
    }
    
    var contentView: NSView? {
        willSet {
            contentView?.removeFromSuperview()
        }
        
        didSet {
            if let view = contentView {
                view.frame = bounds.insetBy(dx: paddings, dy: paddings)
                view.autoresizingMask = [.ViewWidthSizable, .ViewHeightSizable]
                
                addSubview(view)
            }
        }
    }
    
    override func resetCursorRects() {
        super.resetCursorRects()
        
        for transformation in Transformation.allValues {
            addCursorRect(rectForTransformation(transformation), cursor: cursorForTransformation(transformation))
        }
    }
    
    override func mouseDown(theEvent: NSEvent) {
        trackMouseWithEvent(theEvent)
    }
    
    private func trackMouseWithEvent(theEvent: NSEvent) {
        func constrainedPointForEvent(event: NSEvent) -> NSPoint {
            guard let superview = superview else {
                return event.locationInWindow
            }
            
            let superviewPoint = superview.convertPoint(event.locationInWindow, fromView: nil)
            
            return NSPoint(x: max(0, min(superview.bounds.maxX, superviewPoint.x)),
                           y: max(0, min(superview.bounds.maxY, superviewPoint.y)))
        }
        
        guard let transformation = transformationForPoint(pointForEvent(theEvent)) else {
            return
        }
        
        var previousScreenPoint = constrainedPointForEvent(theEvent)

        let mask: NSEventMask = [.LeftMouseDraggedMask, .LeftMouseUpMask]
        
        window?.disableCursorRects()
        
        cursorForTransformation(transformation).set()
        
        while true {
            if let event = window?.nextEventMatchingMask(Int(mask.rawValue)) {
                if event.type == .LeftMouseUp {
                    break
                }
                
                let currentScreenPoint = constrainedPointForEvent(event)
                
                performTransformation(transformation, dx: currentScreenPoint.x - previousScreenPoint.x, dy: currentScreenPoint.y - previousScreenPoint.y)
                
                previousScreenPoint = currentScreenPoint
            }
        }
        
        window?.enableCursorRects()
        window?.invalidateCursorRectsForView(self)
    }
    
    private func performTransformation(transformation: Transformation, dx: CGFloat, dy: CGFloat) {
        switch transformation {
        case .Move:
            moveBy(x: dx, y: dy)
        case .ResizeLeft:
            resizeLeftBy(dx)
        case .ResizeTopLeft:
            resizeTopBy(dy)
            resizeLeftBy(dx)
        case .ResizeTop:
            resizeTopBy(dy)
        case .ResizeTopRight:
            resizeTopBy(dy)
            resizeRightBy(dx)
        case .ResizeRight:
            resizeRightBy(dx)
        case .ResizeBottomRight:
            resizeBottomBy(dy)
            resizeRightBy(dx)
        case .ResizeBottom:
            resizeBottomBy(dy)
        case .ResizeBottomLeft:
            resizeBottomBy(dy)
            resizeLeftBy(dx)
        }
        
        superview?.invalidateIntrinsicContentSize()
    }
    
    private func moveBy(x x: CGFloat, y: CGFloat) {
        var origin = frame.origin
        
        origin.x = max(0, min(origin.x + x, superview!.bounds.width - frame.width))
        origin.y = max(0, min(origin.y + y, superview!.bounds.height - frame.height))
        
        setFrameOrigin(origin)
    }
    
    private func resizeLeftBy(delta: CGFloat) {
        var newFrame = frame
        
        newFrame.origin.x += delta
        newFrame.size.width -= delta
        
        if newFrame.minX < 0 {
            newFrame.size.width += newFrame.minX
            newFrame.origin.x = 0
        }
        
        if newFrame.width < minSize.width {
            newFrame.origin.x += newFrame.width - minSize.width
            newFrame.size.width = minSize.width
        }

        frame = newFrame
    }
    
    private func resizeTopBy(delta: CGFloat) {
        var size = frame.size
        
        size.height = max(minSize.height, min(size.height + delta, superview!.bounds.height - frame.minY))
        
        setFrameSize(size)
    }
    
    private func resizeRightBy(delta: CGFloat) {
        var size = frame.size
        
        size.width = max(minSize.width, min(size.width + delta, superview!.bounds.width - frame.minX))
        
        setFrameSize(size)
    }
    
    private func resizeBottomBy(delta: CGFloat) {
        var newFrame = frame
        
        newFrame.origin.y += delta
        newFrame.size.height -= delta
        
        if newFrame.minY < 0 {
            newFrame.size.height += newFrame.minY
            newFrame.origin.y = 0
        }
        
        if newFrame.height < minSize.height {
            newFrame.origin.y += newFrame.height - minSize.height
            newFrame.size.height = minSize.height
        }
        
        frame = newFrame
    }
    
    private func pointForEvent(event: NSEvent) -> NSPoint {
        return convertPoint(event.locationInWindow, fromView: nil)
    }
    
    private func transformationForPoint(point: NSPoint) -> Transformation? {
        for transformation in Transformation.allValues {
            if rectForTransformation(transformation).contains(point) {
                return transformation
            }
        }
        
        return nil
    }
    
    private func cursorForTransformation(transformation: Transformation) -> NSCursor {
        switch transformation {
        case .Move:
            return NSCursor.arrowCursor()
        case .ResizeTop, .ResizeBottom:
            return NSCursor.resizeNorthSouthCursor()
        case .ResizeRight, .ResizeLeft:
            return NSCursor.resizeEastWestCursor()
        case .ResizeTopRight, .ResizeBottomLeft:
            return NSCursor.resizeNorthEastSouthWestCursor()
        case .ResizeBottomRight, .ResizeTopLeft:
            return NSCursor.resizeNorthWestSouthEastCursor()
        }
    }
    
    private func rectForTransformation(transformation: Transformation) -> NSRect {
        switch transformation {
        case .Move:
            return rectForMoveTransformation
        case .ResizeTop:
            return rectForResizeTopTransformation
        case .ResizeTopRight:
            return rectForResizeTopRightTransformation
        case .ResizeRight:
            return rectForResizeRightTransformation
        case .ResizeBottomRight:
            return rectForResizeBottomRightTransformation
        case .ResizeBottom:
            return rectForResizeBottomTransformation
        case .ResizeBottomLeft:
            return rectForResizeBottomLeftTransformation
        case .ResizeLeft:
            return rectForResizeLeftTransformation
        case .ResizeTopLeft:
            return rectForResizeTopLeftTransformation
        }
    }
    
    private var rectForMoveTransformation: NSRect {
        return hotRect.insetBy(dx: hotCorner, dy: hotCorner)
    }
    
    private var rectForResizeTopTransformation: NSRect {
        return hotRect.insetBy(dx: hotCorner, dy: 0).divide(hotCorner, fromEdge: .MaxYEdge).slice
    }
    
    private var rectForResizeTopRightTransformation: NSRect {
        return NSRect(x: hotRect.maxX - hotCorner, y: hotRect.maxY - hotCorner, width: hotCorner, height: hotCorner)
    }
    
    private var rectForResizeRightTransformation: NSRect {
        return hotRect.insetBy(dx: 0, dy: hotCorner).divide(hotCorner, fromEdge: .MaxXEdge).slice
    }
    
    private var rectForResizeBottomRightTransformation: NSRect {
        return NSRect(x: hotRect.maxX - hotCorner, y: hotRect.minY, width: hotCorner, height: hotCorner)
    }
    
    private var rectForResizeBottomTransformation: NSRect {
        return rectForResizeTopTransformation.offsetBy(dx: 0, dy: -(hotRect.height - hotCorner))
    }
    
    private var rectForResizeBottomLeftTransformation: NSRect {
        return hotRect.insetBy(dx: 0, dy: 0).divide(hotCorner, fromEdge: .MinYEdge).slice
    }
    
    private var rectForResizeLeftTransformation: NSRect {
        return hotRect.insetBy(dx: 0, dy: hotCorner).divide(hotCorner, fromEdge: .MinXEdge).slice
    }
    
    private var rectForResizeTopLeftTransformation: NSRect {
        return NSRect(x: hotRect.minX, y: hotRect.maxY - hotCorner, width: hotCorner, height: hotCorner)
    }
    
    private var hotRect: NSRect {
        return bounds.insetBy(dx: paddings - hotCorner / 2, dy: paddings - hotCorner / 2)
    }
    
}
