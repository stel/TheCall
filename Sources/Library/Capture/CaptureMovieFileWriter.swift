//
//  CaptureMovieFileWriter.swift
//  TheCall
//
//  Created by Dmitry Obukhov on 16/03/16.
//  Copyright © 2016 Dmitry Obukhov. All rights reserved.
//

import Cocoa
import AVFoundation

class CaptureMovieFileWriter {
    
    private let assetWriter: AVAssetWriter!
    private let assetWriterInputPixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor
    
    var outputURL: NSURL {
        return assetWriter.outputURL
    }
    
    var writing: Bool {
        return assetWriter.status == .Writing
    }
    
    private var writingSessionStarted = false
    
    private let ciContext: CIContext = {
        let attributes: [NSOpenGLPixelFormatAttribute] = [
            UInt32(NSOpenGLPFAAccelerated),
            UInt32(NSOpenGLPFANoRecovery),
            UInt32(NSOpenGLPFAColorSize),
            UInt32(32),
            UInt32(0)
        ]
        
        let pixelFormat = NSOpenGLPixelFormat(attributes: attributes)!
        
        return CIContext(CGLContext: CGLGetCurrentContext(), pixelFormat: pixelFormat.CGLPixelFormatObj, colorSpace: nil, options: nil)
    }()

    init(url: NSURL, fileType: String, videoDimensions: NSSize, videoCodec: String) throws {
        let outputVideoSettings: [String: AnyObject] = [
            AVVideoCodecKey: videoCodec,
            AVVideoWidthKey: videoDimensions.width,
            AVVideoHeightKey: videoDimensions.height
        ]
        
        let videoInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: outputVideoSettings)
        videoInput.expectsMediaDataInRealTime = true
        
        let pixelBufferAttributes = [
            String(kCVPixelBufferPixelFormatTypeKey): Int(kCVPixelFormatType_32BGRA),
            String(kCVPixelBufferWidthKey): Int(videoDimensions.width),
            String(kCVPixelBufferHeightKey): Int(videoDimensions.height),
            String(kCVPixelFormatOpenGLCompatibility): kCFBooleanTrue
        ]
        
        assetWriterInputPixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput,
            sourcePixelBufferAttributes: pixelBufferAttributes)
        
        do {
            assetWriter = try AVAssetWriter(URL: url, fileType: fileType)
        } catch {
            assetWriter = nil
            
            throw error
        }
        
        assert(assetWriter.canAddInput(videoInput))
        assetWriter.addInput(videoInput)
    }
    
    func startWriting() -> Bool {
        return assetWriter.startWriting()
    }
    
    func finishWriting(completionHandler: (error: NSError?) -> Void) {
        for input in assetWriter.inputs {
            input.markAsFinished()
        }
        
        assetWriter.finishWritingWithCompletionHandler {
            completionHandler(error: self.assetWriter?.error)
        }
    }
    
    func createVideoPixelBuffer() -> CVPixelBuffer? {
        assert(writingSessionStarted)
        
        var buffer: CVPixelBuffer? = nil
        
        if let pool = assetWriterInputPixelBufferAdaptor.pixelBufferPool {
            CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer)
        }
        
        return buffer
    }
    
    func startWritingSessionIfNeeded(timestamp: CMTime) {
        if writing && !writingSessionStarted {
            assetWriter.startSessionAtSourceTime(timestamp)
            writingSessionStarted = true
        }
    }

}

extension CaptureMovieFileWriter {
    
    func appendVideoSampleBuffer(sampleBuffer: CMSampleBuffer) -> Bool {
        // TODO: call appendBuffer on videoInput instead
        return appendVideoPixelBuffer(CMSampleBufferGetImageBuffer(sampleBuffer)!, withPresentationTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
    }
    
    func appendFrame(image: CIImage, withPresentationTime presentationTime: CMTime) -> Bool {
        startWritingSessionIfNeeded(presentationTime)
        
        guard let pixelBuffer = createVideoPixelBuffer() else {
            return false
        }
        
        ciContext.render(image, toCVPixelBuffer: pixelBuffer)
        
        return appendVideoPixelBuffer(pixelBuffer, withPresentationTime: presentationTime)
    }
    
    func appendVideoPixelBuffer(pixelBuffer: CVPixelBuffer, withPresentationTime presentationTime: CMTime) -> Bool {
        startWritingSessionIfNeeded(presentationTime)
        
        return assetWriterInputPixelBufferAdaptor.appendPixelBuffer(pixelBuffer, withPresentationTime: presentationTime)
    }
    
}

extension CaptureMovieFileWriter {
    
    func appendAudioSampleBuffer(sampleBuffer: CMSampleBuffer) -> Bool {
        return false
    }
    
}
