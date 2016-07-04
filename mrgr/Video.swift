//
//  Video.swift
//  mrgr
//
//  Created by Blake Barrett on 7/3/16.
//  Copyright © 2016 Blake Barrett. All rights reserved.
//

import UIKit
import AVFoundation

class Video {
    var videoUrl: NSURL
    var asset: AVAsset
    var duration: CMTime {
        get {
            return self.asset.duration
        }
    }
    var thumbnail: UIImage
    
    init(url:NSURL) {
        self.videoUrl = url
        self.asset = AVURLAsset(URL: url)
        
        var time = self.asset.duration
        time.value = min(time.value, 2)
        
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        do {
            let imageRef = try imageGenerator.copyCGImageAtTime(time, actualTime: nil)
            self.thumbnail = UIImage(CGImage: imageRef)
        } catch _ as NSError {
            self.thumbnail = UIImage(named: "Select a Video")!
        }
    }
    
}