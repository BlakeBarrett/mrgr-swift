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
    
    func setVideo(item:Video) {
        self.item = item
        self.thumbnailImageView.image = item.thumbnail
        
        let durationString = TableViewCell.parseDuration(Int(round(item.duration.seconds)))
        self.durationLabelView.text = durationString
    }
    
    class func parseDuration(value: Int) -> String {
        let hours = (value / 3600)
        let minutes = ((value % 3600) / 60)
        let seconds = (value % 60)
        
        var durationString = "\(seconds)"
        if minutes > 0 {
            durationString = "\(minutes):" + durationString
        }
        if hours > 0 {
            durationString = "\(hours):" + durationString
        }
        return durationString
    }
}