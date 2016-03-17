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
    func captureController(controller: CaptureController, didCaptureFrame image: CIImage)
    
}

class CaptureController: NSObject {
    
    weak var delegate: CaptureControllerDelegate?
    
    var effect: VideoEffect?
    
    var recording: Bool {
        return movieFileWriter?.writing ?? false
    }
    
    private let session = AVCaptureSession()
    
    private var inputVideoDimensions: NSSize
    
    private var movieFileWriter: CaptureMovieFileWriter?
    
    private let sampleBufferCallbackQueue = dispatch_queue_create("com.dmitry-obukhov.TheCall.SampleBufferCallback", nil)
    
    override init() {
        let videoDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        let audioDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
        
        let dimensions = CMVideoFormatDescriptionGetDimensions(videoDevice.activeFormat.formatDescription)
        
        inputVideoDimensions = NSSize(width: Int(dimensions.width), height: Int(dimensions.height))
        
        super.init()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "captureInputPortFormatDescriptionDidChange:", name: AVCaptureInputPortFormatDescriptionDidChangeNotification, object: nil)
        
        session.beginConfiguration()
        
        session.sessionPreset = AVCaptureSessionPresetHigh
        
        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            assert(session.canAddInput(videoDeviceInput))
            session.addInput(videoDeviceInput)
            
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
            
            assert(session.canAddInput(audioDeviceInput))
            session.addInput(audioDeviceInput)
        } catch let error as NSError {
            BlueScreenOfDeath.show(reason: "Some default input devices are missing: \(error.localizedDescription)")
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: sampleBufferCallbackQueue)
        
        assert(session.canAddOutput(videoOutput))
        session.addOutput(videoOutput)
        
        let audioOutput = AVCaptureAudioDataOutput()
        audioOutput.setSampleBufferDelegate(self, queue: sampleBufferCallbackQueue)

        assert(session.canAddOutput(audioOutput))
        session.addOutput(audioOutput)
        
        session.commitConfiguration()
        
        session.startRunning()
    }
    
    deinit {
        stopRecording()
        session.stopRunning()
        cleanup()
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func captureInputPortFormatDescriptionDidChange(notification: NSNotification) {
        if let inputPort = notification.object as? AVCaptureInputPort {
            if inputPort.mediaType == AVMediaTypeVideo {
                let dimensions = CMVideoFormatDescriptionGetDimensions(inputPort.formatDescription)
                
                inputVideoDimensions = NSSize(width: Int(dimensions.width), height: Int(dimensions.height))
            }
        }
    }
    
    func startRecording() {
        if recording {
            return
        }
        
        cleanup()
        
        do {
            let videoSettings: [String: AnyObject] = [
                AVVideoCodecKey: AVVideoCodecH264,
                AVVideoWidthKey: inputVideoDimensions.width,
                AVVideoHeightKey: inputVideoDimensions.height
            ]
            
            let audioSettings: [String: AnyObject] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVNumberOfChannelsKey: 1,
                AVSampleRateKey: 44100,
                AVEncoderBitRateKey: 64000
            ]
            
            movieFileWriter = try CaptureMovieFileWriter(url: NSFileManager.defaultManager().applicationTemporaryUniqueFileURL(), fileType: AVFileTypeMPEG4, videoDimensions: inputVideoDimensions, videoSettings: videoSettings, audioSettings: audioSettings)
        } catch let error as NSError {
            BlueScreenOfDeath.show(reason: "Can't create asset writer: \(error.localizedDescription)")
        }
        
        movieFileWriter?.startWriting()
    }
    
    func stopRecording() {
        movieFileWriter?.finishWriting() { error in
            dispatch_async(dispatch_get_main_queue()) {
                self.delegate?.captureController(self, didFinishRecordingWithError: error)
            }
        }
    }
    
    func exportRecording(destinationURL: NSURL) throws {
        guard let sourceUrl = movieFileWriter?.outputURL else {
            return
        }
        
        if destinationURL.checkResourceIsReachableAndReturnError(nil) {
            try NSFileManager.defaultManager().removeItemAtURL(destinationURL)
        }
        
        try NSFileManager.defaultManager().copyItemAtURL(sourceUrl, toURL: destinationURL)
    }
    
    func cleanup() {
        precondition(!recording)
        
        if let url = movieFileWriter?.outputURL {
            do {
                try NSFileManager.defaultManager().removeItemAtURL(url)
            } catch {
                // TODO: Ooops
            }
        }
        
        movieFileWriter = nil
    }

}

extension CaptureController: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {

    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        let formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer)!
        let mediaType = CMFormatDescriptionGetMediaType(formatDesc)
        
        switch mediaType {
        case kCMMediaType_Video:
            captureSampleBufferForVideoOutput(sampleBuffer)
        case kCMMediaType_Audio:
            captureSampleBufferForAudioOutput(sampleBuffer)
        default:
            assert(false)
        }
    }
    
    private func captureSampleBufferForVideoOutput(sampleBuffer: CMSampleBuffer) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        var resultImage = (CIImage(CVPixelBuffer: imageBuffer))
        
        if let effect = effect {
            resultImage = effect.apply(resultImage)
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            self.delegate?.captureController(self, didCaptureFrame: resultImage)
        }
        
        if let writer = movieFileWriter where writer.writing {
            writer.appendFrame(resultImage, withPresentationTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
        }
    }
    
    private func captureSampleBufferForAudioOutput(sampleBuffer: CMSampleBuffer) {
        movieFileWriter?.appendAudioSampleBuffer(sampleBuffer)
    }

}
