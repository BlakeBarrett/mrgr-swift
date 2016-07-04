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

class MrgrViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var trashBarButtonView: UIBarButtonItem!
    @IBOutlet weak var playBarButtonView: UIBarButtonItem!
    @IBOutlet weak var actionBarButtonView: UIBarButtonItem!
    
    @IBOutlet weak var tableView: UITableView!
    
    var videos: [Video] = [Video]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tempVideoPath = getPathForTempFileNamed("temp.mov")
        
        NSNotificationCenter.defaultCenter().addObserverForName("videoExportDone", object: nil, queue: NSOperationQueue.mainQueue()) {message in
            self.hideSpinner()
            if let url = message.object as? NSURL {
                if (self.previewing) {
                    let videoPreviewer = VideoPreviewerViewController(nibName: "VideoPreviewView", bundle: NSBundle.mainBundle())
                    videoPreviewer.url = url
                    self.presentViewController(videoPreviewer, animated: true, completion: nil)
                }
                if (self.actioning) {
                    let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                    if (UIDevice.currentDevice().userInterfaceIdiom == .Pad) {
                        let nav = UINavigationController(rootViewController: activity)
                        nav.modalPresentationStyle = .Popover
                        
                        let popover = nav.popoverPresentationController as UIPopoverPresentationController!
                        popover.barButtonItem = self.actionBarButtonView
                        
                        self.presentViewController(nav, animated: true, completion: nil)
                    } else {
                        self.presentViewController(activity, animated: true, completion: nil)
                    }
                }
                self.actioning = false
                self.previewing = false
            }
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName("addVideoClicked", object: nil, queue: NSOperationQueue.mainQueue()) { item in
            self.browseForVideo()
        }
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
            NSNotificationCenter.defaultCenter().postNotificationName("videoExportDone", object: self.tempVideoPath)
            return true
        }
        
        self.showSpinner()
        
        self.videoPrepared = self.append(self.videos, andExportTo: tempVideoPath!)
        
        return self.videoPrepared
    }
    
    var previewing = false
    @IBAction func onPlayClicked(sender: UIBarButtonItem) {
        self.previewing = true
        self.prepareVideo()
    }
    
    var actioning = false
    @IBAction func onActionSelected(sender: UIBarButtonItem) {
        self.actioning = true
        self.prepareVideo()
    }
    
    // MARK: UITableViewDataSource methods
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.videos.count + 1
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (indexPath.row == videos.count) {
            let cell = tableView.dequeueReusableCellWithIdentifier("emptyTableViewCellReuseIdentifier", forIndexPath: indexPath)
            return cell
        } else {
            let item = videos[indexPath.row]
            let cell = tableView.dequeueReusableCellWithIdentifier("mrgrCellReuseIdentifier", forIndexPath: indexPath) as! TableViewCell
            cell.setVideo(item)
            return cell
        }
    }
    
    // MARK: Video Thumbnail Image Tap Gesutre Recognizer Action Outlets
    
    var videoImageThumbnailTagBeingPickedFor: Int = 0
    
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
        self.videos.removeAll()
        self.videoPrepared = false
        self.disableButtons()
        self.tableView.reloadData()
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
        let video = Video(url: path)
        
        self.videos.append(video)
        
        if (self.videos.count > 1) {
            self.enableButtons()
        }
        
        self.tableView.reloadData()
    }
    
    var loadingIndicatorView: ProgressViewController?
    func showSpinner() {
        //LoadingIndicatorView
        self.loadingIndicatorView = ProgressViewController(nibName: "ProgressIndicatorView", bundle: NSBundle.mainBundle())
        loadingIndicatorView!.modalPresentationStyle = .OverCurrentContext
        self.presentViewController(loadingIndicatorView!, animated: true, completion: nil)
    }
    
    func hideSpinner() {
        guard let loadingIndicatorView = self.loadingIndicatorView else { return }
        loadingIndicatorView.dismissViewControllerAnimated(true, completion: {
            
        })
    }
    
    // MARK: AVFoundation Video Manipulation Code
    
    func append(assets: [Video], andExportTo outputUrl: NSURL) -> Bool {
        let mixComposition = AVMutableComposition()
        
        let videoTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
        let audioTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        // run through all the assets selected
        // TODO: This ends up appending them in reverse order.
        assets.forEach {(video) in
            
            let timeRange = CMTimeRangeMake(kCMTimeZero, video.duration)
            
            // add all video tracks in asset
            let videoMediaTracks = video.asset.tracksWithMediaType(AVMediaTypeVideo)
            videoMediaTracks.forEach{ (videoMediaTrack) in
                do {
                    try videoTrack.insertTimeRange(timeRange, ofTrack: videoMediaTrack, atTime: kCMTimeZero)
                } catch _  {
                    return
                }
            }
            
            // add all audio tracks in asset
            let audioMediaTracks = video.asset.tracksWithMediaType(AVMediaTypeAudio)
            audioMediaTracks.forEach {(audioMediaTrack) in
                do {
                    try audioTrack.insertTimeRange(timeRange, ofTrack: audioMediaTrack, atTime: kCMTimeZero)
                } catch _ {
                    return
                }
            }
        }
        
        guard let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality) else { return false }
        exporter.outputURL = outputUrl
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
        return true
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

