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

class MrgrViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate, UIVideoEditorControllerDelegate {

    @IBOutlet weak var trashBarButtonView: UIBarButtonItem!
    @IBOutlet weak var playBarButtonView: UIBarButtonItem!
    @IBOutlet weak var actionBarButtonView: UIBarButtonItem!
    
    @IBOutlet weak var tableView: UITableView!
    
    var videos = [Video]()
    
    var previewing = false
    var exporting = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tempVideoPath = getPathForTempFileNamed("temp.mov")
        
        NSNotificationCenter.defaultCenter().addObserverForName("videoExportDone", object: nil, queue: NSOperationQueue.mainQueue()) {message in
            if let url = message.object as? NSURL {
                self.hideSpinner(){
                    if (self.previewing) {
                        self.previewVideoAt(url)
                    }
                    if (self.exporting) {
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
                    self.exporting = false
                    self.previewing = false
                }
            } else {
                self.hideSpinner(){
                    guard let _ = self.tempVideoPath else { return }
                    self.previewVideoAt(self.tempVideoPath!)
                }
            }
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName("addVideoClicked", object: nil, queue: NSOperationQueue.mainQueue()) { item in
            self.browseForVideo()
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName("previewClicked", object: nil, queue: NSOperationQueue.mainQueue()) { item in
            guard let video = item.object as? Video else { return }
            self.previewVideoAt(video.videoUrl)
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

    // MARK:
    // MARK: Bar Button Item Action Outlets
    
    @IBAction func onTrashClicked(sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let destroyAction = UIAlertAction(title: "Reset", style: .Destructive) { (action) in
            self.startOver()
            self.removeTempFileAtPath("temp.mov")
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
    
    @IBAction func onPlayClicked(sender: UIBarButtonItem) {
        self.previewing = true
        self.prepareVideo()
    }
    
    @IBAction func onActionSelected(sender: UIBarButtonItem) {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let shareAction = UIAlertAction(title: "Share", style: .Default) { (action) in
            self.exporting = true
            self.prepareVideo()
        }
        
        let aboutAction = UIAlertAction(title: "About", style: .Default) { (action) in
            self.showAboutPage()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
            alertController.dismissViewControllerAnimated(true, completion: nil)
        }
        
        alertController.addAction(shareAction)
        alertController.addAction(aboutAction)
        alertController.addAction(cancelAction)
        
        alertController.popoverPresentationController?.barButtonItem = sender
        
        self.presentViewController(alertController, animated: true) {
            // ...
        }
        
    }
    
    // MARK:
    // MARK: UITableViewDataSource methods
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.videos.count + 1
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (indexPath.row == self.videos.count) {
            let cell = tableView.dequeueReusableCellWithIdentifier("emptyTableViewCellReuseIdentifier", forIndexPath: indexPath)
            return cell
        } else {
            let item = self.videos[indexPath.row]
            let cell = tableView.dequeueReusableCellWithIdentifier("mrgrCellReuseIdentifier", forIndexPath: indexPath) as! TableViewCell
            cell.setVideo(item)
            return cell
        }
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return indexPath.row < self.videos.count
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return indexPath.row < self.videos.count
    }
    
    func tableView(tableView: UITableView, willBeginEditingRowAtIndexPath indexPath: NSIndexPath) {
        tableView.setEditing(true, animated: true)
        tableView.beginUpdates()
    }
    
    func tableView(tableView: UITableView, didEndEditingRowAtIndexPath indexPath: NSIndexPath) {
        tableView.endUpdates()
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        let row = indexPath.row
        if !(row < self.videos.count) {
            return
        }
        tableView.endUpdates()
        
        let video = self.videos[row]
        switch (editingStyle) {
        case UITableViewCellEditingStyle.Insert:
            self.videos.removeAtIndex(indexPath.row)
            self.videos.insert(video, atIndex: row)
            break
        case UITableViewCellEditingStyle.Delete:
            self.videos.removeAtIndex(row)
            tableView.reloadData()
            break
        default: break
        }
    }
    
    func tableView(tableView: UITableView, shouldShowMenuForRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return indexPath.row < self.videos.count
    }
    
    func thumbnailAt(indexPath: NSIndexPath) -> UIImage? {
        if (indexPath.row < videos.count) {
            return videos[indexPath.row].thumbnail
        } else {
            return UIImage(named: "Select a Video")
        }
    }
    
    // variable row height
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return cellHeightFor(tableView, image: thumbnailAt(indexPath))
    }
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return cellHeightFor(tableView, image: thumbnailAt(indexPath))
    }
    
    func cellHeightFor(tableView: UITableView, image: UIImage?) -> CGFloat {
        let tableWidth: CGFloat = tableView.frame.width
        
        let size = image?.size
        let width = size?.width
        let height = size?.height
        let aspectRatio = (width! / height!)
        
        return min((tableWidth / aspectRatio), (self.view.bounds.height / 2))
    }
    
    // MARK:
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
    
    // MARK: UIVideoEditorController
    
    func openEditorFor(video: Video) {
        
        guard let path = video.videoUrl.path else { return }
        
        let editor = UIVideoEditorController()
        editor.delegate = self
        if UIVideoEditorController.canEditVideoAtPath(path) {
            editor.videoPath = path
            self.presentViewController(editor, animated: true) {
                
            }
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
//        self.actionBarButtonView.enabled = false
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
        dispatch_async(dispatch_get_main_queue(),{
            //LoadingIndicatorView
            self.loadingIndicatorView = ProgressViewController(nibName: "ProgressIndicatorView", bundle: NSBundle.mainBundle())
            self.loadingIndicatorView!.modalPresentationStyle = .OverCurrentContext
            self.presentViewController(self.loadingIndicatorView!, animated: true, completion: nil)
        })
    }
    
    func hideSpinner(completion: (() -> Void)?) {
        let completionAndCleanup: () -> Void = {
            completion?()
            self.loadingIndicatorView = nil
        }
        guard let loadingIndicatorView = self.loadingIndicatorView else {
            completionAndCleanup()
            return
        }
        loadingIndicatorView.dismissViewControllerAnimated(true, completion: completionAndCleanup)
    }
    
    func previewVideoAt(url: NSURL) {
        let videoPreviewer = VideoPreviewerViewController(nibName: "VideoPreviewView", bundle: NSBundle.mainBundle())
        videoPreviewer.url = url
        self.presentViewController(videoPreviewer, animated: true, completion: nil)
    }
    
    // MARK: AVFoundation Video Manipulation Code
    
    func append(assets: [Video], andExportTo outputUrl: NSURL) -> Bool {
        let mixComposition = AVMutableComposition()
        
        let videoTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
        let audioTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
//        var maxWidth: CGFloat = 0;
//        var maxHeight: CGFloat = 0;
//        
        // run through all the assets selected
        assets.reverse().forEach {(video) in
            
            let timeRange = CMTimeRangeMake(kCMTimeZero, video.duration)
            
            // add all video tracks in asset
            let videoMediaTracks = video.asset.tracksWithMediaType(AVMediaTypeVideo)
            videoMediaTracks.forEach{ (videoMediaTrack) in
                
//                maxWidth = max(videoMediaTrack.naturalSize.width, maxWidth)
//                maxHeight = max(videoMediaTrack.naturalSize.height, maxHeight)
                
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
    
    // MARK:
    // MARK: About Page
    func showAboutPage() {
        let location = "http://mskr.co/private/147372542885/tumblr_oaa9yaYtLh1ts3t7o"
        guard let url = NSURL(string:location) else { return }
        UIApplication.sharedApplication().openURL(url)
    }
}

