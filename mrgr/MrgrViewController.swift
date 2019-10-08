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
import MediaPlayer

class MrgrViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate, UIVideoEditorControllerDelegate, MPMediaPickerControllerDelegate {

    @IBOutlet weak var trashBarButtonView: UIBarButtonItem!
    @IBOutlet weak var playBarButtonView: UIBarButtonItem!
    @IBOutlet weak var actionBarButtonView: UIBarButtonItem!
    
    @IBOutlet weak var tableView: UITableView!
    
    var videos = [Video]()
    var audioTrack: MPMediaItem?
    
    var previewing = false
    var exporting = false
    var saving = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initNotificationCenterListeners()
        self.initPicker()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override var shouldAutorotate : Bool {
        return UIDevice.current.orientation == UIDeviceOrientation.portrait
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }

    // MARK:
    // MARK: Bar Button Item Action Outlets
    
    @IBAction func onTrashClicked(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let destroyAction = UIAlertAction(title: "Reset", style: .destructive) { (action) in
            self.startOver()
            self.removeTempFileAtPath("temp.mov")
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            // no-op
        }
        
        alertController.addAction(destroyAction)
        alertController.addAction(cancelAction)
        
        alertController.popoverPresentationController?.barButtonItem = sender
        
        self.present(alertController, animated: true) {
            // ...
        }
    }

    var tempVideoPath:URL?
    var videoPrepared:Bool = false
    func prepareVideo() {
        if self.videoPrepared {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "videoExportDone"), object: self.tempVideoPath)
        }
        self.showSpinner()
        self.videoPrepared = self.append(self.videos, andExportTo: tempVideoPath!, with: self.audioTrack)
    }
    
    @IBAction func onPlayClicked(_ sender: UIBarButtonItem) {
        self.previewing = true
        self.prepareVideo()
    }
    
    @IBAction func onActionSelected(_ sender: UIBarButtonItem) {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let shareAction = UIAlertAction(title: "Share", style: .default) { (action) in
            self.exporting = true
            self.prepareVideo()
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { (action) in
            self.saving = true
            self.prepareVideo()
        }
        
        let aboutAction = UIAlertAction(title: "About", style: .default) { (action) in
            self.showAboutPage()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            alertController.dismiss(animated: true, completion: nil)
        }
        
        if videos.count > 0 {
            alertController.addAction(shareAction)
            alertController.addAction(saveAction)
        }
        alertController.addAction(aboutAction)
        alertController.addAction(cancelAction)
        
        alertController.popoverPresentationController?.barButtonItem = sender
        
        self.present(alertController, animated: true) {
            // ...
        }
        
    }
    
    // MARK:
    // MARK: UITableViewDataSource methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.videos.count + 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if ((indexPath as NSIndexPath).row == self.videos.count) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "emptyTableViewCellReuseIdentifier", for: indexPath)
            return cell
        } else {
            let item = self.videos[(indexPath as NSIndexPath).row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "mrgrCellReuseIdentifier", for: indexPath) as! TableViewCell
            cell.setVideo(item)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return (indexPath as NSIndexPath).row < self.videos.count
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return (indexPath as NSIndexPath).row < self.videos.count
    }
    
    func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        tableView.setEditing(true, animated: true)
        tableView.beginUpdates()
    }
    
    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        tableView.endUpdates()
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        let row = (indexPath as NSIndexPath).row
        if !(row < self.videos.count) {
            return
        }
        tableView.endUpdates()
        
        let video = self.videos[row]
        switch (editingStyle) {
        case UITableViewCell.EditingStyle.insert:
            self.videos.remove(at: (indexPath as NSIndexPath).row)
            self.videos.insert(video, at: row)
            break
        case UITableViewCell.EditingStyle.delete:
            self.videos.remove(at: row)
            tableView.reloadData()
            break
        default: break
        }
    }
    
    func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        return (indexPath as NSIndexPath).row < self.videos.count
    }
    
    func thumbnailAt(_ indexPath: IndexPath) -> UIImage? {
        if ((indexPath as NSIndexPath).row < videos.count) {
            return videos[(indexPath as NSIndexPath).row].thumbnail
        } else {
            return UIImage(named: "Select a Video")
        }
    }
    
    // variable row height
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeightFor(tableView, image: thumbnailAt(indexPath))
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeightFor(tableView, image: thumbnailAt(indexPath))
    }
    
    func cellHeightFor(_ tableView: UITableView, image: UIImage?) -> CGFloat {
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
    var imagePicker = UIImagePickerController()
    func initPicker() {
        self.imagePicker = UIImagePickerController()
        self.imagePicker.delegate = self
        self.imagePicker.sourceType = .photoLibrary
        self.imagePicker.mediaTypes = [kUTTypeMovie as String]
        self.imagePicker.allowsEditing = true
    }
    
    func browseForVideo() {
        self.present(self.imagePicker, animated: true)
    }
    
    func browseForAudio() {
        let pickerController = MPMediaPickerController()
        pickerController.delegate = self
        pickerController.allowsPickingMultipleItems = false
        self.present(pickerController, animated: true)
    }
    
    // MARK: MPMediaPickerControllerDelegate
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection){
        self.audioTrack = mediaItemCollection.items.first
        self.dismiss(mediaPicker)
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        self.dismiss(mediaPicker)
    }
    
    func dismiss(_ mediaPicker: MPMediaPickerController) {
        mediaPicker.dismiss(animated: true, completion: nil)
    }
    
    // MARK: UIVideoEditorController
    
    func openEditorFor(_ video: Video) {
        
        let path = video.videoUrl.path
        
        let editor = UIVideoEditorController()
        editor.delegate = self
        if UIVideoEditorController.canEditVideo(atPath: path) {
            editor.videoPath = path
            self.present(editor, animated: true) {
                
            }
        }
    }
    
    // MARK: UIImagePicker Delegate methods
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Local variable inserted by Swift 4.2 migrator.
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        self.videoPrepared = false
        var path: URL?
        let mediaType = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.mediaType)] as! CFString
        if (mediaType == kUTTypeMovie) {
            // trimmed/edited videos
            if let trimmedUrl = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.mediaURL)] as? URL {
                path = trimmedUrl
            } else if let referenceUrl = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.referenceURL)] as? URL {
                path = referenceUrl
            }
        }
        
        picker.dismiss(animated: true) { () -> Void in
            if let path = path {
                self.onVideoSelected(path)
            }
            self.initPicker()
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) { () -> Void in
            self.initPicker()
        }
    }
    
    // MARK:
    // MARK: Program Functions
    
    func initNotificationCenterListeners() {
        self.tempVideoPath = getPathForTempFileNamed("temp.mov")
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "videoExportDone"), object: nil, queue: OperationQueue.main) {message in
            if let url = message.object as? URL {
                self.hideSpinner(){
                    if (self.previewing) {
                        self.previewVideoAt(url, animated: true)
                    } else if (self.exporting) {
                        let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                        if (UIDevice.current.userInterfaceIdiom == .pad) {
                            let nav = UINavigationController(rootViewController: activity)
                            nav.modalPresentationStyle = .popover
                            
                            if nav.popoverPresentationController != nil {
                                nav.popoverPresentationController?.barButtonItem = self.actionBarButtonView
                            }
                            
                            self.present(nav, animated: true, completion: nil)
                        } else {
                            self.present(activity, animated: true, completion: nil)
                        }
                    } else if (self.saving) {
                        let filename = self.getPathStringForFile(named: "temp.mov")
                        UISaveVideoAtPathToSavedPhotosAlbum(filename, nil, nil, nil);
                    }
                    self.saving = false
                    self.exporting = false
                    self.previewing = false
                }
            } else {
                self.hideSpinner(){
                    guard let _ = self.tempVideoPath else { return }
                    self.previewVideoAt(self.tempVideoPath!, animated: false)
                }
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "addVideoClicked"), object: nil, queue: OperationQueue.main) { item in
            self.browseForVideo()
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "previewClicked"), object: nil, queue: OperationQueue.main) { item in
            guard let video = item.object as? Video else { return }
            self.previewVideoAt(video.videoUrl as URL, animated: true)
        }
    }
    
    func startOver() {
        self.videos.removeAll()
        self.videoPrepared = false
        self.disableButtons()
        self.tableView.reloadData()
    }
    
    func disableButtons() {
        self.trashBarButtonView.isEnabled = false
        self.playBarButtonView.isEnabled = false
//        self.actionBarButtonView.enabled = false
    }
    
    func enableButtons() {
        self.trashBarButtonView.isEnabled = true
        self.playBarButtonView.isEnabled = true
        self.actionBarButtonView.isEnabled = true
    }
    
    func onVideoSelected(_ path: URL) {
        let video = Video(url: path)
        
        self.videos.append(video)
        
        if (self.videos.count > 1) {
            self.enableButtons()
        }
        
        self.tableView.reloadData()
    }
    
    var loadingIndicatorView: ProgressViewController?
    func showSpinner() {
        DispatchQueue.main.async(execute: {
            //LoadingIndicatorView
            self.loadingIndicatorView = ProgressViewController(nibName: "ProgressIndicatorView", bundle: Bundle.main)
            self.loadingIndicatorView!.modalPresentationStyle = .overCurrentContext
            self.present(self.loadingIndicatorView!, animated: true, completion: nil)
        })
    }
    
    func hideSpinner(_ completion: (() -> Void)?) {
        let completionAndCleanup: () -> Void = {
            completion?()
            self.loadingIndicatorView = nil
        }
        guard let loadingIndicatorView = self.loadingIndicatorView else {
            completionAndCleanup()
            return
        }
        loadingIndicatorView.dismiss(animated: false, completion: completionAndCleanup)
    }
    
    func previewVideoAt(_ url: URL, animated: Bool) {
        let videoPreviewer = VideoPreviewerViewController(nibName: "VideoPreviewView", bundle: Bundle.main)
        videoPreviewer.url = url
        self.present(videoPreviewer, animated: animated, completion: nil)
    }
    
    // MARK: AVFoundation Video Manipulation Code
    
    func append(_ assets: [Video], andExportTo outputUrl: URL, with backgroundAudio: MPMediaItem?) -> Bool {
        let mixComposition = AVMutableComposition()
        
        let videoTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let audioTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
//        var maxWidth: CGFloat = 0;
//        var maxHeight: CGFloat = 0;
//        
        // run through all the assets selected
        assets.reversed().forEach {(video) in
            
            let timeRange = CMTimeRangeMake(start: CMTime.zero, duration: video.duration)
            
            // add all video tracks in asset
            let videoMediaTracks = video.asset.tracks(withMediaType: AVMediaType.video)
            videoMediaTracks.forEach{ (videoMediaTrack) in
                
//                maxWidth = max(videoMediaTrack.naturalSize.width, maxWidth)
//                maxHeight = max(videoMediaTrack.naturalSize.height, maxHeight)
                
                do {
                    try videoTrack?.insertTimeRange(timeRange, of: videoMediaTrack, at: CMTime.zero)
                } catch _  {
                    return
                }
            }
            
            if video.muted {
                return
            }
            
            // add all audio tracks in asset
            let audioMediaTracks = video.asset.tracks(withMediaType: AVMediaType.audio)
            audioMediaTracks.forEach {(audioMediaTrack) in
                do {
                    try audioTrack?.insertTimeRange(timeRange, of: audioMediaTrack, at: CMTime.zero)
                } catch _ {
                    return
                }
            }
        }
        
        // TODO: check this shit out for video rotation.
        // http://stackoverflow.com/questions/12136841/avmutablevideocomposition-rotated-video-captured-in-portrait-mode
        // http://stackoverflow.com/questions/27627610/video-not-rotating-using-avmutablevideocompositionlayerinstruction
        // And where would we be w/o Ray Wenderlich?
        // https://www.raywenderlich.com/13418/how-to-play-record-edit-videos-in-ios
        
        guard let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality) else { return false }
        exporter.outputURL = outputUrl
        exporter.outputFileType = AVFileType.mov
        exporter.shouldOptimizeForNetworkUse = true
        exporter.exportAsynchronously(completionHandler: {
            switch exporter.status {
            case .completed:
                // we can be confident that there is a URL because
                // we got this far. Otherwise it would've failed.
                let url = exporter.outputURL!
                print("MrgrViewController.exportVideo SUCCESS!")
                if exporter.error != nil {
                    print("MrgrViewController.exportVideo Error: \(exporter.error)")
                    print("MrgrViewController.exportVideo Description: \(exporter.description)")
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "videoExportDone"), object: exporter.error)
                } else {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "videoExportDone"), object: url)
                }
                
                break
                
            case .exporting:
                let progress = exporter.progress
                print("MrgrViewController.exportVideo \(progress)")
                
                NotificationCenter.default.post(name: Notification.Name(rawValue: "videoExportProgress"), object: progress)
                break
                
            case .failed:
                print("MrgrViewController.exportVideo Error: \(exporter.error)")
                print("MrgrViewController.exportVideo Description: \(exporter.description)")
                
                NotificationCenter.default.post(name: Notification.Name(rawValue: "videoExportDone"), object: exporter)
                break
                
            default: break
            }
        })
        return true
    }
    
    func getPathStringForFile(named filename: String) -> String {
        return NSTemporaryDirectory() + filename
    }
    
    func getPathForTempFileNamed(_ filename: String) -> URL {
        let outputPath = getPathStringForFile(named: filename)
        let outputUrl = URL(fileURLWithPath: outputPath)
        removeTempFileAtPath(outputPath)
        return outputUrl
    }
    
    func removeTempFileAtPath(_ path: String) {
        let fileManager = FileManager.default
        if (fileManager.fileExists(atPath: path)) {
            do {
                try fileManager.removeItem(atPath: path)
            } catch _ {
            }
        }
    }
    
    // MARK:
    // MARK: About Page
    func showAboutPage() {
        let location = "http://mskr.co/private/147372542885/tumblr_oaa9yaYtLh1ts3t7o"
        guard let url = URL(string:location) else { return }
        UIApplication.shared.openURL(url)
    }
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
