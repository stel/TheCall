//
//  CaptureController.swift
//  TheCall
//
//  Created by Dmitry Obukhov on 14/03/16.
//  Copyright © 2016 Dmitry Obukhov. All rights reserved.
//

import Cocoa
import AVFoundation

protocol CaptureControllerDelegate: class {
    
    func captureController(controller: CaptureController, didFinishRecordingWithError error: NSError?)
    func captureController(controller: CaptureController, didOutputSampleBuffer buffer: CMSampleBuffer)
    
}

class CaptureController: NSObject {
    
    weak var delegate: CaptureControllerDelegate?
    
    private(set) var recording = false
    
    private let session = AVCaptureSession()
    
    private var assetWriter: AVAssetWriter?
    
    private let outputVideoSettings: [String: AnyObject] = [
        AVVideoCodecKey: AVVideoCodecH264,
        AVVideoWidthKey: 640,
        AVVideoHeightKey: 360
    ]
    
    override init() {
        super.init()
        
        session.beginConfiguration()
        
        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo))
            
            assert(session.canAddInput(videoDeviceInput))
            session.addInput(videoDeviceInput)
            
            let audioDeviceInput = try AVCaptureDeviceInput(device: AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio))
            
            assert(session.canAddInput(audioDeviceInput))
            session.addInput(audioDeviceInput)
        } catch let error as NSError {
            BlueScreenOfDeath.show(reason: "Some default input devices are missing: \(error.localizedDescription)")
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: dispatch_get_main_queue())
        
        assert(session.canAddOutput(videoOutput))
        session.addOutput(videoOutput)
        
        let audioOutput = AVCaptureAudioPreviewOutput()

        assert(session.canAddOutput(audioOutput))
        session.addOutput(audioOutput)
        
        session.commitConfiguration()
        
        session.startRunning()
    }
    
    deinit {
        stopRecording()
        session.stopRunning()
        cleanup()
    }
    
    func startRecording() {
        if recording {
            return
        }
        
        cleanup()
        
        do {
            let writer = try AVAssetWriter(URL: NSFileManager.defaultManager().applicationTemporaryUniqueFileURL(), fileType: AVFileTypeMPEG4)
            
            let videoInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: outputVideoSettings)
            videoInput.expectsMediaDataInRealTime = true
            
            assert(writer.canAddInput(videoInput))
            writer.addInput(videoInput)
            
            assetWriter = writer
        } catch let error as NSError {
            BlueScreenOfDeath.show(reason: "Can't create asset writer: \(error.localizedDescription)")
        }
        
        recording = true
    }
    
    func stopRecording() {
        recording = false
        
        guard let writer = assetWriter else {
            return
        }
        
        for input in writer.inputs {
            input.markAsFinished()
        }
        
        writer.finishWritingWithCompletionHandler {
            dispatch_async(dispatch_get_main_queue()) {
                self.delegate?.captureController(self, didFinishRecordingWithError: self.assetWriter?.error)
            }
        }
    }
    
    func exportRecording(destinationURL: NSURL) throws {
        guard let sourceUrl = assetWriter?.outputURL else {
            return
        }
        
        if destinationURL.checkResourceIsReachableAndReturnError(nil) {
            try NSFileManager.defaultManager().removeItemAtURL(destinationURL)
        }
        
        try NSFileManager.defaultManager().copyItemAtURL(sourceUrl, toURL: destinationURL)
    }
    
    func cleanup() {
        precondition(!recording)
        
        if let url = assetWriter?.outputURL {
            do {
                try NSFileManager.defaultManager().removeItemAtURL(url)
            } catch {
                // TODO: Ooops
            }
        }
        
        assetWriter = nil
    }

}

extension CaptureController: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        delegate?.captureController(self, didOutputSampleBuffer: sampleBuffer)
        
        if let writer = assetWriter where recording {
            if writer.status != .Writing {
                writer.startWriting()
                writer.startSessionAtSourceTime(CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
            }
            
            for input in writer.inputs where input.mediaType == AVMediaTypeVideo {
                input.appendSampleBuffer(sampleBuffer)
            }
        }
    }

}

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
