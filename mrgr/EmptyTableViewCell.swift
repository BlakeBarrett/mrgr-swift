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
    @IBAction func onAddButtonClicked(_ sender: UIButton) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "addVideoClicked"), object: nil)
    }
}
