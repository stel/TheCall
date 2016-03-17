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
    
    private let assetWriterVideoInput: AVAssetWriterInput
    private let assetWriterVideoInputAdaptor: AVAssetWriterInputPixelBufferAdaptor
    
    private let assetWriterAudioInput: AVAssetWriterInput
    
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

    init(url: NSURL, fileType: String, videoDimensions: NSSize, videoSettings: [String: AnyObject]?, audioSettings: [String: AnyObject]?) throws {

        assetWriterVideoInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoSettings)
        assetWriterVideoInput.expectsMediaDataInRealTime = true
        
        let pixelBufferAttributes = [
            String(kCVPixelBufferPixelFormatTypeKey): Int(kCVPixelFormatType_32BGRA),
            String(kCVPixelBufferWidthKey): Int(videoDimensions.width),
            String(kCVPixelBufferHeightKey): Int(videoDimensions.height),
            String(kCVPixelFormatOpenGLCompatibility): kCFBooleanTrue
        ]
        
        assetWriterVideoInputAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterVideoInput,
            sourcePixelBufferAttributes: pixelBufferAttributes)
        
        assetWriterAudioInput = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: audioSettings)
        assetWriterAudioInput.expectsMediaDataInRealTime = true
        
        do {
            assetWriter = try AVAssetWriter(URL: url, fileType: fileType)
        } catch {
            assetWriter = nil
            
            throw error
        }
        
        assert(assetWriter.canAddInput(assetWriterVideoInput))
        assetWriter.addInput(assetWriterVideoInput)
        
        assert(assetWriter.canAddInput(assetWriterAudioInput))
        assetWriter.addInput(assetWriterAudioInput)
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
        
        if let pool = assetWriterVideoInputAdaptor.pixelBufferPool {
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
    
    func appendFrame(image: CIImage, withPresentationTime presentationTime: CMTime) -> Bool {
        startWritingSessionIfNeeded(presentationTime)
        
        guard let pixelBuffer = createVideoPixelBuffer() else {
            return false
        }
        
        ciContext.render(image, toCVPixelBuffer: pixelBuffer)
        
        return appendVideoPixelBuffer(pixelBuffer, withPresentationTime: presentationTime)
    }
    
    func appendVideoPixelBuffer(pixelBuffer: CVPixelBuffer, withPresentationTime presentationTime: CMTime) -> Bool {
        guard assetWriterVideoInput.readyForMoreMediaData else {
            return false
        }
        
        startWritingSessionIfNeeded(presentationTime)
        
        return assetWriterVideoInputAdaptor.appendPixelBuffer(pixelBuffer, withPresentationTime: presentationTime)
    }
    
    func appendVideoSampleBuffer(sampleBuffer: CMSampleBuffer) -> Bool {
        guard assetWriterVideoInput.readyForMoreMediaData else {
            return false
        }
        
        return assetWriterVideoInput.appendSampleBuffer(sampleBuffer)
    }
    
}

extension CaptureMovieFileWriter {
    
    func appendAudioSampleBuffer(sampleBuffer: CMSampleBuffer) -> Bool {
        // TODO: find a way to sync audio/video capture, currently session will be started by the video input
        guard assetWriterAudioInput.readyForMoreMediaData && writingSessionStarted else {
            return false
        }
        
        return assetWriterAudioInput.appendSampleBuffer(sampleBuffer)
    }
    
}
