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
    
    var url: URL? {
        didSet {
            guard let _ = self.url else { return }
            self.player = AVPlayer(url: self.url!)
            self.player?.isMuted = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        player?.play()
    }
}
