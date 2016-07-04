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
        self.durationLabelView.text = "\(round(item.duration.seconds))"
    }
    
}