//
//  AboutScreenViewController.swift
//  mrgr
//
//  Created by Blake Barrett on 7/13/16.
//  Copyright © 2016 Blake Barrett. All rights reserved.
//

import UIKit

class AboutScreenViewController: UIViewController {
    
    @IBOutlet weak var webView: UIWebView!
    
    @IBAction func onDoneClicked(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        let location = "http://mskr.co/private/147372542885/tumblr_oaa9yaYtLh1ts3t7o"
        let url = NSURL(string:location)!
        let request = NSURLRequest(URL:url)
        self.webView.loadRequest(request)
    }
}
