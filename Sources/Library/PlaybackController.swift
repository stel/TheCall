//
//  PlaybackController.swift
//  TheCall
//
//  Created by Dmitry Obukhov on 14/03/16.
//  Copyright © 2016 Dmitry Obukhov. All rights reserved.
//

import Cocoa
import AVFoundation

class PlaybackController {
    
    private(set) var player: AVPlayer
    
    init(url: NSURL) {
        let asset = AVAsset(URL: url)
        
        if !asset.playable {
            BlueScreenOfDeath.show(reason: "Can't load the default incomming call video")
        }
        
        let playerItem = AVPlayerItem(asset: asset)
        
        player = AVPlayer(playerItem: playerItem)
        
        player.actionAtItemEnd = AVPlayerActionAtItemEnd.None
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerItemDidReachEnd:", name: AVPlayerItemDidPlayToEndTimeNotification, object: player.currentItem)
    }
    
    deinit {
        stop()
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func play() {
        player.play()
    }
    
    func stop() {
        player.pause()
        player.currentItem?.seekToTime(kCMTimeZero)
    }
    
    dynamic private func playerItemDidReachEnd(notification: NSNotification) {
        if let playerItem = notification.object as? AVPlayerItem {
            playerItem.seekToTime(kCMTimeZero)
        }
    }
    
}
