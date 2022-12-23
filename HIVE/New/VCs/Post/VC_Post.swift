//
//  VC_Post.swift
//  HIVE
//
//  Created by Daniel Pratt on 8/29/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import UIKit
import MobileCoreServices
import Firebase
import GiphyUISDK
import CollectionKit
import YPImagePicker
import IQKeyboardManagerSwift

class VC_Post: UIViewController {
    
    @IBOutlet weak var img_avatar: UIImageView!
    @IBOutlet weak var txt_content_txt: UITextView!
    @IBOutlet weak var txt_placeHolder: UITextField!
    @IBOutlet weak var btn_post: UIButton!
    @IBOutlet weak var imgWidthConstraint: NSLayoutConstraint!
    
    let giphy: GIPHYModel = GIPHYModel()

    var selectedMedia: YPMediaItem? = nil
    var selectedGif: GPHMedia? = nil
    
    var postToEdit: Post? = nil
    var postToRepost: Post? = nil
    var vAccessory: cv_accessoryView!
    
    var locked: Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()

        initComponents()
    }
    
    func initComponents(){
        img_avatar.makeCircleView()
        img_avatar.loadImg(str: Me.avatar, user: true)
        
        giphy.delegate = self
        txt_content_txt.delegate = self
        
        initSelectors()
        setupPost()
        setupDismissGestures()
        updatePostbutton()
        checkBlocked()
    }
    
    func checkBlocked(){
        if Me.blocked{
            self.showError(msg: "You are blocked from admin.")
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func setupPost(){
        if let post = postToEdit {
            btn_post.setTitle("Update", for: .normal)
            txt_content_txt.text = post.desc
            txt_placeHolder.isHidden = !post.desc.isEmpty
        }
        else if postToRepost != nil{
            btn_post.setTitle("Repost", for: .normal)
            txt_content_txt.text = ""
            txt_placeHolder.isHidden = false
        }
        else {
            btn_post.setTitle("Post", for: .normal)
            txt_content_txt.text = ""
            txt_placeHolder.isHidden = false
        }
    }
    
    func initSelectors(){
        vAccessory = Bundle.main.loadNibNamed("cv_accessoryView", owner: self, options: nil)?[0] as? cv_accessoryView
        vAccessory.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 74)
        
        if let post = postToEdit{
            vAccessory.setPost(pst: post, edit: true)
        }
        else if let post = postToRepost{
            vAccessory.setPost(pst: post, edit: false)
        }
        else{
            
        }
        
        vAccessory.opSelectMediaAction = { (index) in
            if self.locked { return }
            
            if index == 0{
                //media
                let picker: YPImagePicker = self.openPicker(size: 1000)
                picker.didFinishPicking { [unowned picker] items, cancelled in
                    if cancelled{
                        picker.dismiss(animated: true, completion: nil)
                        return
                    }
                    for item in items{
                        
                        switch item {
                        case .photo(p: let photo):
                            print(photo.image.size)
                            
                            let bcf = ByteCountFormatter()
                            bcf.allowedUnits = [.useKB]
                            bcf.countStyle = .file

                            guard let originalData = photo.image.jpegData(compressionQuality: 0.8) else { return }
                            print(photo.image.size)
                            print("original image size: \(bcf.string(fromByteCount: Int64(originalData.count)))")

                            let resized = photo.image.resized500()
                            guard let thumbData = resized.jpegData(compressionQuality: 0.5) else { return }
                            print(resized.size)
                            print("thumb size: \(bcf.string(fromByteCount: Int64(thumbData.count)))")

                            break
                        default:
                            break
                        }
                        
                        self.selectedMedia = item
                        self.selectedGif = nil
                        
                        self.vAccessory.setMedia(media: item)
                        
                        self.updatePostbutton()
                        break
                    }
                    picker.dismiss(animated: true, completion: nil)
                }
            }
            else{
                //gif
                let giphyVC = self.giphy.getGiphyVC()
                self.present(giphyVC, animated: true, completion: nil)
            }
        }

        vAccessory.opDeleteMediaAction = {
            if self.locked { return }
            
            self.selectedMedia = nil
            self.selectedGif = nil
            
            self.updatePostbutton()
        }
        
        txt_content_txt.inputAccessoryView = vAccessory
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.txt_content_txt.becomeFirstResponder()
        }
    }
    
    func setupDismissGestures() {
        // enable dismissing view by touching outside
        let touchOutside = UITapGestureRecognizer(target: self, action: #selector(handle(_:)))
        touchOutside.numberOfTapsRequired = 1
        view.addGestureRecognizer(touchOutside)
        
        // enable dismissing view by swiping down
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeDown.direction = .down
        swipeDown.numberOfTouchesRequired = 1
        view.addGestureRecognizer(swipeDown)
    }
    
    func updatePostbutton(){
        var activeStatus: Bool = false
        if postToEdit != nil || postToRepost != nil{
            activeStatus = true
        }
        else if selectedGif != nil || selectedMedia != nil{
            activeStatus = true
        }
        else if !txt_content_txt.text.isEmpty{
            activeStatus = true
        }
        
        btn_post.setTitleColor(activeStatus ? (postToRepost != nil ? UIColor.brand() : UIColor.active()) : UIColor.secondaryLabel, for: .normal)
    }
    
    func updateLockStatus(){
        btn_post.isEnabled = !self.locked
        self.vAccessory.setLocked(locked: self.locked)
    }
    
    @IBAction func shareButtonTapped(_ sender: Any) {
        guard let cuid = CUID else { return }
        
        if self.locked { return }
        self.locked = true
        self.updateLockStatus()
        
        var desc: String = txt_content_txt.text!
        desc = desc.trimmingCharacters(in: .whitespaces)
        
        self.vAccessory.showGradientView()
        
        if desc.isEmpty && (postToEdit == nil && postToRepost == nil && selectedGif == nil && selectedMedia == nil){
            self.vAccessory.hideGradientView()
            self.locked = false
            self.updateLockStatus()
            
            self.showError(title: "Error", msg: "Please write caption for the post.")
            return
        }

        if let pst = postToEdit{
            pst.editPost(newDesc: desc) { (res, err) in
                self.vAccessory.hideGradientView()
                self.locked = false
                self.updateLockStatus()
                
                if let error = err{
                    self.showError(title: "Error", msg: error.localizedDescription)
                    return
                }
                    
                self.dismiss(animated: true, completion: nil)
            }
        }
        else if let pst = postToRepost{
            let newPost = Post()
            newPost.created = Utils.curTime
            newPost.desc = desc
            newPost.type = .TEXT
            newPost.ouid = cuid
            newPost.opid = pst.opost != nil ? pst.opost!.pid : pst.pid
            newPost.oavatar = Me.thumb.isEmpty ? Me.avatar : Me.thumb
            newPost.ouname = Me.uname
            
            newPost.uploadPost(ptype: .TEXT) { (res, err) in
                self.vAccessory.hideGradientView()
                self.locked = false
                self.updateLockStatus()
                
                if let error = err{
                    self.showError(title: "Error", msg: error.localizedDescription)
                    return
                }
                
                self.dismiss(animated: true, completion: nil)
            }
        }
        else{
            if self.selectedGif != nil || self.selectedMedia != nil{
                let pst = Post()
                pst.uploadPost(withMedia: self.selectedGif, ypMedia: self.selectedMedia, desc: desc) { (res, pType, err) in
                    if let error = err{
                        self.vAccessory.hideGradientView()
                        self.locked = false
                        self.updateLockStatus()
                        
                        self.showError(msg: error.localizedDescription)
                        return
                    }
                    if res, let type = pType{
                        pst.uploadPost(ptype: type) { (res, err) in
                            self.vAccessory.hideGradientView()
                            self.locked = false
                            self.updateLockStatus()
                            
                            if let error = err{
                                self.showError(msg: error.localizedDescription)
                                return
                            }
                            
                            self.dismiss(animated: true, completion: nil)
                        }
                    }
                    else{
                        self.vAccessory.hideGradientView()
                        self.locked = false
                        self.updateLockStatus()
                        
                        self.showError(msg: "Error happened. Try again later.")
                        return
                    }
                }
            }
            else {
                let pst = Post()
                pst.uploadPost(desc: desc)  { (res, pType, err) in
                    if let error = err{
                        self.vAccessory.hideGradientView()
                        self.locked = false
                        self.updateLockStatus()
                        
                        self.showError(title: "Error", msg: error.localizedDescription)
                        return
                    }
                    if res, let type = pType{
                        pst.uploadPost(ptype: type) { (res, err) in
                            self.vAccessory.hideGradientView()
                            self.locked = false
                            self.updateLockStatus()
                            
                            if let error = err{
                                self.showError(title: "Error", msg: error.localizedDescription)
                                return
                            }
                            
                            self.dismiss(animated: true, completion: nil)
                        }
                    }
                    else{
                        self.vAccessory.hideGradientView()
                        self.locked = false
                        self.updateLockStatus()
                        
                        self.showError(title: "Error", msg: "Error happened. Try again later.")
                        return
                    }
                }
            }
        }
    }
    
    // MARK: - Gesture Action Handling
    @objc private func handle(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        if !view.frame.contains(location) { dismiss(animated: true, completion: nil) }
    }
    
    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func opCancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension VC_Post: GIPHYMediaManagerDelegate {
    func got(media: GPHMedia) {
        self.selectedGif = media
        self.selectedMedia = nil
        
        self.updatePostbutton()
        
        self.vAccessory.setMedia(gif: media)
    }
}

extension VC_Post: UITextViewDelegate {
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        self.txt_placeHolder.isHidden = !textView.text.isEmpty
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if self.locked{
            return false
        }
        
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        self.txt_placeHolder.isHidden = !textView.text.isEmpty
        self.updatePostbutton()
    }
}
