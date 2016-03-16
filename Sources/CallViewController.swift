//
//  CallViewController.swift
//  TheCall
//
//  Created by Dmitry Obukhov on 14/03/16.
//  Copyright © 2016 Dmitry Obukhov. All rights reserved.
//

import Cocoa
import AVFoundation

class CallViewController: NSViewController {
    
    @IBOutlet weak var pipView: PiPView!
    @IBOutlet weak var captureView: CaptureView!
    @IBOutlet weak var playbackView: PlaybackView!
    @IBOutlet weak var overlayView: OverlayView!
    
    @IBOutlet weak var callButton: NSButton!
    
    let captureController = CaptureController()
    let playbackController = PlaybackController(url: NSBundle.mainBundle().URLForResource("Saw", withExtension: "mp4")!)

    override func viewDidLoad() {
        super.viewDidLoad()

        captureController.delegate = self
        captureController.effect = Blur(radius: 20)
        
        playbackView.player = playbackController.player
        
        // TODO: grab ratio from CaptureController
        pipView.contentAspectRatio = NSSize(width: 16, height: 9)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        // Aspect Ratio layout constrains sucks
        view.window?.contentAspectRatio = pipView.contentAspectRatio
    }
    
}

extension CallViewController: CaptureControllerDelegate {
    
    func captureController(controller: CaptureController, didCaptureFrame image: CIImage) {
        captureView.image = image
    }
    
    func captureController(controller: CaptureController, didFinishRecordingWithError error: NSError?) {
        let alert = NSAlert()
        
        alert.messageText = "Do you want to save video of this call?"
        alert.informativeText = "You can choose to save or delete video immediately. You can't undo this action."
        alert.addButtonWithTitle("Save")
        alert.addButtonWithTitle("Delete")
        
        alert.beginSheetModalForWindow(view.window!) { result in
            if result == NSAlertFirstButtonReturn {
                let savePanel = NSSavePanel()
                
                savePanel.allowedFileTypes = ["mp4"]
                
                savePanel.beginSheetModalForWindow(self.view.window!) { result in
                    if let url = savePanel.URL where result == NSModalResponseOK {
                        do {
                            try controller.exportRecording(url)
                        } catch let error as NSError {
                            BlueScreenOfDeath.show(reason: error.localizedFailureReason)
                        }
                    }
                    
                    controller.cleanup()
                }
            } else {
                controller.cleanup()
            }
        }
    }
    
}

extension CallViewController {
    
    @IBAction func startCall(sender: AnyObject? = nil) {
        pipView.showSecondaryView()
        
        captureController.startRecording()
        playbackController.play()
        
        overlayView.transient = true
        callButton.action = "endCall:"
    }
    
    @IBAction func endCall(sender: AnyObject? = nil) {
        captureController.stopRecording()
        playbackController.stop()
        
        pipView.hideSecondaryView()
        overlayView.transient = false
        callButton.action = "startCall:"
    }
    
}
