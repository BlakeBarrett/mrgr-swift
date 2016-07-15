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
    
    @IBAction func onPlayButtonClick(sender: UIButton) {
        NSNotificationCenter.defaultCenter().postNotificationName("previewClicked", object: item)
    }
    
    func setVideo(item:Video) {
        self.item = item
        self.thumbnailImageView.image = item.thumbnail
        
        let durationString = TableViewCell.parseDuration(Int(round(item.duration.seconds)))
        self.durationLabelView.text = durationString
        
        mask(self.playView)
    }
    
    class func parseDuration(value: Int) -> String {
        let hours = (value / 3600)
        let minutes = ((value % 3600) / 60)
        let seconds = (value % 60)
        
        var durationString = "\(seconds)"
        if (seconds < 10) {
            durationString = "0\(seconds)"
        }
        if minutes > 0 {
            durationString = "\(minutes):" + durationString
        }
        if hours > 0 {
            durationString = "\(hours):" + durationString
        }
        return durationString
    }
    
    class func createTriangleView(size: CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: size, height: size), false, 0)
        let context = UIGraphicsGetCurrentContext()
        
        CGContextMoveToPoint(context, 0, 0)
        CGContextAddLineToPoint(context, size, size / 2)
        CGContextAddLineToPoint(context, 0, size)
        CGContextAddLineToPoint(context, 0, 0)
        CGContextFillPath(context)
        
        CGContextSetStrokeColorWithColor(context, UIColor.blackColor().CGColor)
        CGContextStrokePath(context)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    func mask(view: UIView) {
        let size = view.frame.size.width
        
        let image = TableViewCell.createTriangleView(size)
        view.layer.mask = UIImageView(image: image).layer
    }
}