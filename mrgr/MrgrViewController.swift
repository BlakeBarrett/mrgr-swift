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
        self.tempVideoPath = getPathForTempFileNamed("temp.mov")
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

    var tempVideoPath:NSURL?
    var videoPrepared:Bool = false
    func prepareVideo() -> Bool {
        if self.videoPrepared {
            return true
        }
        
        guard let _ = self.video1Path else { return false }
        guard let _ = self.video2Path else { return false }
        
        let first = AVURLAsset(URL: self.video1Path!)
        let second = AVURLAsset(URL: self.video2Path!)
        
        self.videoPrepared = self.prepend(video: first, before: second, andExportTo: tempVideoPath!)
        
        return self.videoPrepared
    }
    
    @IBAction func onPlayClicked(sender: UIBarButtonItem) {
        
        if !self.prepareVideo() { return }
        
        let videoPreviewer = VideoPreviewerViewController(nibName: "VideoPreviewView", bundle: NSBundle.mainBundle())
        
        NSNotificationCenter.defaultCenter().addObserverForName("videoExportDone", object: nil, queue: NSOperationQueue.mainQueue()) {message in
            if let url = message.object as? NSURL {
                videoPreviewer.url = url
                self.presentViewController(videoPreviewer, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func onActionSelected(sender: UIBarButtonItem) {
        
        if !self.prepareVideo() { return }
        
        guard let videoPath = self.tempVideoPath else { return }
        let activity = UIActivityViewController(activityItems: [videoPath], applicationActivities: nil)
        
        if (UIDevice.currentDevice().userInterfaceIdiom == .Pad) {
            let nav = UINavigationController(rootViewController: activity)
            nav.modalPresentationStyle = .Popover
            
            let popover = nav.popoverPresentationController as UIPopoverPresentationController!
            popover.barButtonItem = sender
            
            self.presentViewController(nav, animated: true, completion: nil)
        } else {
            self.presentViewController(activity, animated: true, completion: nil)
        }
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
    
    // MARK: UIImagePicker Delegate methods
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        self.videoPrepared = false
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
        
        self.videoPrepared = false
        
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
    
    // MARK: AVFoundation Video Manipulation Code
    
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
    
    func prepend(video secondAsset: AVURLAsset, before firstAsset: AVURLAsset, andExportTo outputUrl: NSURL) -> Bool {
        let mixComposition = AVMutableComposition()
        
        let videoTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        let firstAssetTimeRange = CMTimeRangeMake(kCMTimeZero, firstAsset.duration)
        let secondAssetTimeRange = CMTimeRangeMake(kCMTimeZero, secondAsset.duration)
        
        guard let firstMediaTrack = firstAsset.tracksWithMediaType(AVMediaTypeVideo).first else { return false }
        guard let secondMediaTrack = secondAsset.tracksWithMediaType(AVMediaTypeVideo).first else { return false }
        
        do {
            try videoTrack.insertTimeRange(firstAssetTimeRange , ofTrack: firstMediaTrack, atTime: kCMTimeZero)
            try videoTrack.insertTimeRange(secondAssetTimeRange, ofTrack: secondMediaTrack, atTime: kCMTimeZero)
        } catch (let error) {
            print(error)
            return false
        }
        
        self.exportCompositedVideo(mixComposition, toURL: outputUrl, withVideoComposition: nil)
        return true
    }
    
    func exportCompositedVideo(compiledVideo: AVMutableComposition, toURL outputUrl: NSURL, withVideoComposition videoComposition: AVMutableVideoComposition?) {
        guard let exporter = AVAssetExportSession(asset: compiledVideo, presetName: AVAssetExportPresetHighestQuality) else { return }
        exporter.outputURL = outputUrl
        if let videoComposition = videoComposition {
            exporter.videoComposition = videoComposition
        }
        exporter.outputFileType = AVFileTypeQuickTimeMovie
        exporter.shouldOptimizeForNetworkUse = true
        exporter.exportAsynchronouslyWithCompletionHandler({
            switch exporter.status {
            case .Completed:
                // we can be confident that there is a URL because
                // we got this far. Otherwise it would've failed.
                let url = exporter.outputURL!
                print("MrgrViewController.exportVideo SUCCESS!")
                if exporter.error != nil {
                    print("MrgrViewController.exportVideo Error: \(exporter.error)")
                    print("MrgrViewController.exportVideo Description: \(exporter.description)")
                    NSNotificationCenter.defaultCenter().postNotificationName("videoExportDone", object: exporter.error)
                } else {
                    NSNotificationCenter.defaultCenter().postNotificationName("videoExportDone", object: url)
                }
                
                break
                
            case .Exporting:
                let progress = exporter.progress
                print("MrgrViewController.exportVideo \(progress)")
                
                NSNotificationCenter.defaultCenter().postNotificationName("videoExportProgress", object: progress)
                break
                
            case .Failed:
                print("MrgrViewController.exportVideo Error: \(exporter.error)")
                print("MrgrViewController.exportVideo Description: \(exporter.description)")
                
                NSNotificationCenter.defaultCenter().postNotificationName("videoExportDone", object: exporter)
                break
                
            default: break
            }
        })
    }
    
    func getPathForTempFileNamed(filename: String) -> NSURL {
        let outputPath = NSTemporaryDirectory() + filename
        let outputUrl = NSURL(fileURLWithPath: outputPath)
        removeTempFileAtPath(outputPath)
        return outputUrl
    }
    
    func removeTempFileAtPath(path: String) {
        let fileManager = NSFileManager.defaultManager()
        if (fileManager.fileExistsAtPath(path)) {
            do {
                try fileManager.removeItemAtPath(path)
            } catch _ {
            }
        }
    }
    
}

