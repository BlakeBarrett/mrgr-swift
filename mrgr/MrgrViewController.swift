//
//  ViewController.swift
//  mrgr
//
//  Created by Blake Barrett on 6/14/16.
//  Copyright © 2016 Blake Barrett. All rights reserved.
//

import UIKit
import MobileCoreServices
import AVFoundation

class MrgrViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var trashBarButtonView: UIBarButtonItem!
    @IBOutlet weak var playBarButtonView: UIBarButtonItem!
    @IBOutlet weak var actionBarButtonView: UIBarButtonItem!
    
    @IBOutlet weak var video1ImageView: UIImageView!
    @IBOutlet weak var video2ImageView: UIImageView!
    
    var video1Path: NSURL?
    var video2Path: NSURL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func shouldAutorotate() -> Bool {
        return UIDevice.currentDevice().orientation == UIDeviceOrientation.Portrait
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }

    // MARK: Bar Button Item Action Outlets
    
    @IBAction func onTrashClicked(sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let destroyAction = UIAlertAction(title: "Reset", style: .Destructive) { (action) in
            self.startOver()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
            // no-op
        }
        
        alertController.addAction(destroyAction)
        alertController.addAction(cancelAction)
        
        alertController.popoverPresentationController?.barButtonItem = sender
        
        self.presentViewController(alertController, animated: true) {
            // ...
        }
    }

    @IBAction func onPlayClicked(sender: UIBarButtonItem) {
        
    }
    
    @IBAction func onActionSelected(sender: UIBarButtonItem) {
        
    }
    
    // MARK: Video Thumbnail Image Tap Gesutre Recognizer Action Outlets
    
    var videoImageThumbnailTagBeingPickedFor: Int = 0
    
    @IBAction func onSelectVideo1TapGestureRecognizer(sender: UITapGestureRecognizer) {
        self.videoImageThumbnailTagBeingPickedFor = self.video1ImageView.tag
        self.browseForVideo()
    }
    
    @IBAction func onSelectVideo2TapGestureRecognizer(sender: UITapGestureRecognizer) {
        self.videoImageThumbnailTagBeingPickedFor = self.video2ImageView.tag
        self.browseForVideo()
    }
    
    // MARK: 
    func browseForVideo() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .PhotoLibrary
        picker.mediaTypes = [kUTTypeMovie as String]
        picker.allowsEditing = true
        self.presentViewController(picker, animated: true) { () -> Void in
            // no-op
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        var path: NSURL?
        let mediaType = info[UIImagePickerControllerMediaType] as! CFString
        if (mediaType == kUTTypeMovie) {
            // trimmed/edited videos
            if let trimmedUrl = info[UIImagePickerControllerMediaURL] as? NSURL {
                path = trimmedUrl
            } else if let referenceUrl = info[UIImagePickerControllerReferenceURL] as? NSURL {
                path = referenceUrl
            }
        }
        
        picker.dismissViewControllerAnimated(true) { () -> Void in
            if let path = path {
                self.onVideoSelected(path)
            }
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true) { () -> Void in
            
        }
    }
    
    // MARK:
    // MARK: Program Functions
    
    func startOver() {
        guard let selectAVideoImage = UIImage(named: "Select a Video") else { return }
        
        self.video1ImageView.image = selectAVideoImage
        self.video2ImageView.image = selectAVideoImage
        
        self.disableButtons()
    }
    
    func disableButtons() {
        self.trashBarButtonView.enabled = false
        self.playBarButtonView.enabled = false
        self.actionBarButtonView.enabled = false
    }
    
    func enableButtons() {
        self.trashBarButtonView.enabled = true
        self.playBarButtonView.enabled = true
        self.actionBarButtonView.enabled = true
    }
    
    func onVideoSelected(path: NSURL) {
        let image = thumbnailImageForVideo(path)
        switch (self.videoImageThumbnailTagBeingPickedFor) {
        case self.video1ImageView.tag:
            self.video1ImageView.image = image
            self.video1Path = path
            break
        case self.video2ImageView.tag:
            self.video2ImageView.image = image
            self.video2Path = path
            break
        default: break
        }
        
        if (self.video1Path != nil &&
            self.video2Path != nil) {
            self.enableButtons()
        }
    }
    
    func thumbnailImageForVideo(url:NSURL) -> UIImage? {
        let asset = AVAsset(URL: url)
        
        var time = asset.duration
        time.value = min(time.value, 2)
        
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        do {
            let imageRef = try imageGenerator.copyCGImageAtTime(time, actualTime: nil)
            return UIImage(CGImage: imageRef)
        } catch let error as NSError
        {
            print("MrgrViewController.getFrameFrom:: Error: \(error)")
            return nil
        }
    }
    
}

