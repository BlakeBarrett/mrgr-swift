//
//  VideoPreviewerViewController.swift
//  mrgr
//
//  Created by Blake Barrett on 6/14/16.
//  Copyright © 2016 Blake Barrett. All rights reserved.
//

import Foundation
import AVFoundation
import AVKit

class VideoPreviewerViewController: AVPlayerViewController {
    
    var url: NSURL? {
        didSet {
            guard let _ = self.url else { return }
            self.player = AVPlayer(URL: self.url!)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        player?.play()
    }
}