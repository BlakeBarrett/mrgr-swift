//
//  EmptyTableViewCell.swift
//  mrgr
//
//  Created by Blake Barrett on 7/4/16.
//  Copyright © 2016 Blake Barrett. All rights reserved.
//

import UIKit

class EmptyTableViewCell: UITableViewCell {
    
    @IBOutlet weak var addButtonView: UIButton!
    @IBAction func onAddButtonClicked(sender: UIButton) {
        NSNotificationCenter.defaultCenter().postNotificationName("addVideoClicked", object: nil)
    }
}
