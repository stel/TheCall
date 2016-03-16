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
    
}

class CaptureController: NSObject {
    
    weak var delegate: CaptureControllerDelegate?
    
    let session = AVCaptureSession()
    
    var recording: Bool {
        return videoOutput.recording
    }
    
    private let videoOutput = AVCaptureMovieFileOutput()
    private let audioOutput = AVCaptureAudioPreviewOutput()
    
    private var temporaryOutputFileURL: NSURL?
    
    override init() {
        super.init()
        
        videoOutput.delegate = self
        
        session.beginConfiguration()
        
        do {
            session.addInput(try AVCaptureDeviceInput(device: AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)))
            session.addInput(try AVCaptureDeviceInput(device: AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)))
        } catch {
            BlueScreenOfDeath.show(reason: "Some default input devices are missing")
        }
        
        session.addOutput(videoOutput)
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
        
        temporaryOutputFileURL = NSFileManager.defaultManager().applicationTemporaryUniqueFileURL()
        
        videoOutput.startRecordingToOutputFileURL(temporaryOutputFileURL, recordingDelegate: self)
    }
    
    func stopRecording() {
        videoOutput.stopRecording()
    }
    
    func exportRecording(destinationURL: NSURL) throws {
        guard let sourceUrl = temporaryOutputFileURL else {
            return
        }
        
        if destinationURL.checkResourceIsReachableAndReturnError(nil) {
            try NSFileManager.defaultManager().removeItemAtURL(destinationURL)
        }
        
        try NSFileManager.defaultManager().copyItemAtURL(sourceUrl, toURL: destinationURL)
    }
    
    func cleanup() {
        if let url = temporaryOutputFileURL {
            do {
                try NSFileManager.defaultManager().removeItemAtURL(url)
            } catch {
                // TODO: Ooops
            }
        }
        
        temporaryOutputFileURL = nil
    }

}

extension CaptureController: AVCaptureFileOutputDelegate {
    
    func captureOutputShouldProvideSampleAccurateRecordingStart(captureOutput: AVCaptureOutput!) -> Bool {
        return false
    }
    
}

extension CaptureController: AVCaptureFileOutputRecordingDelegate {
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        delegate?.captureController(self, didFinishRecordingWithError: error)
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
