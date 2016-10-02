//
//  TableViewCell.swift
//  mrgr
//
//  Created by Blake Barrett on 7/4/16.
//  Copyright © 2016 Blake Barrett. All rights reserved.
//

import UIKit

class TableViewCell: UITableViewCell {
    
    var item: Video?
    
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var durationLabelView: UILabel!
    
    @IBOutlet weak var playView: UIVisualEffectView!
    
    @IBAction func onPlayButtonClick(_ sender: UIButton) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "previewClicked"), object: item)
    }
    
    func setVideo(_ item:Video) {
        self.item = item
        self.thumbnailImageView.image = item.thumbnail
        
        let durationString = TableViewCell.parseDuration(Int(round(item.duration.seconds)))
        self.durationLabelView.text = durationString
        
        mask(self.playView)
    }
    
    class func parseDuration(_ value: Int) -> String {
        let hours = (value / 3600)
        let minutes = ((value % 3600) / 60)
        let seconds = (value % 60)
        
        var durationString: String
        if (seconds < 10) {
            durationString = ":0\(seconds)"
        } else {
            durationString = ":\(seconds)"
        }
        if minutes > 0 {
            durationString = "\(minutes)" + durationString
        }
        if hours > 0 {
            durationString = "\(hours):" + durationString
        }
        return durationString
    }
    
    class func createTriangleView(_ size: CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: size, height: size), false, 0)
        let context = UIGraphicsGetCurrentContext()
        
        context?.move(to: CGPoint(x: 0, y: 0))
        context?.addLine(to: CGPoint(x: size, y: size / 2))
        context?.addLine(to: CGPoint(x: 0, y: size))
        context?.addLine(to: CGPoint(x: 0, y: 0))
        context?.fillPath()
        
        context?.setStrokeColor(UIColor.black.cgColor)
        context?.strokePath()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
    
    func mask(_ view: UIView) {
        let size = view.frame.size.width
        
        let image = TableViewCell.createTriangleView(size)
        view.layer.mask = UIImageView(image: image).layer
    }
}
