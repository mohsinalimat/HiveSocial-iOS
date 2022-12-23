//
//  Extensions.swift
//  HIVEcopy
//
//  Created by Kassy Pop on 7/8/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import UIKit
import Firebase
import StoreKit
import SDWebImage
import AVKit
import MessageUI
import MediaPlayer
import MBProgressHUD
import YPImagePicker
import SwiftMessages

extension Date {
    func timeAgoToDisplay(lowercased: Bool = false, cmt: Bool = false) -> String {
        var secondsAgo = Int(Date().timeIntervalSince(self))
        if secondsAgo < 0 {
            secondsAgo = 0
        }
        
        let minute = 60
        let hour = 60 * minute
        let day = 24 * hour
        let week = 7 * day
        let month = 4 * week
        
        let quotient: Int
        let unit: String
        
        if secondsAgo < minute {
            quotient = secondsAgo
            unit = "second"
        } else if secondsAgo < hour {
            quotient = secondsAgo / minute
            unit = "min"
        } else if secondsAgo < day {
            quotient = secondsAgo / hour
            unit = "h"
        } else if secondsAgo < week {
            quotient = secondsAgo / day
            unit = "d"
        } else if secondsAgo < month {
            quotient = secondsAgo / week
            unit = "w"
        } else {
            quotient = secondsAgo / month
            unit = "m"
        }
        
        if lowercased{
            if cmt{
                return " \(quotient)\(unit)\(quotient == 1 ? "" : "")".lowercased()
            }
            else{
                return " \(quotient)\(unit)\(quotient == 1 ? "" : "") ago".lowercased()
            }
        }
        else{
            if cmt{
                return "\(quotient)\(unit)\(quotient == 1 ? "" : "")"
            }
            else{
                return "\(quotient)\(unit)\(quotient == 1 ? "" : "") ago"
            }
        }
    }
    
    static var yesterday: Date { return Date().dayBefore }
    static var tomorrow: Date { return Date().dayAfter }
    
    var dayBefore: Date{
        return Calendar.current.date(byAdding: .day, value: -1, to: self)!
    }
    var dayAfter: Date{
        return Calendar.current.date(byAdding: .day, value: 1, to: self)!
    }
}

extension UIView {
    func addContentView(v: UIView){
        self.subviews.forEach { (sView) in
            sView.removeFromSuperview()
        }
        
        self.addSubview(v)
        
        v.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: v, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: v, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: v, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: v, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0).isActive = true
    }
    
    func addShadow(circle: Bool = true, shadowCol: CGColor = UIColor.label.cgColor, shadowOpacity: Float = 0.4, shadowRadius: CGFloat = 2){
        self.layer.shadowColor = shadowCol
        self.layer.shadowOpacity = shadowOpacity
        self.layer.shadowOffset = .zero
        self.layer.shadowRadius = shadowRadius
        self.layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.main.scale
    }
    
    func makeCircleView(){
        makeRoundView(r: self.layer.bounds.height / 2)
    }
    
    func makeRoundView(r: CGFloat = 5, masked: Bool = false){
        self.clipsToBounds = true
        self.layer.cornerRadius = r
        
        if masked{
            self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        }
    }
    
    func preventMultiTab(sender: Any){
        if let btn = sender as? UIButton{
            btn.isUserInteractionEnabled = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            if let btn = sender as? UIButton{
                btn.isUserInteractionEnabled = true
            }
        }) 
    }
}

extension UIImage{
    static func avatar() -> UIImage{
        return UIImage(named: "img_no_profile_image")!
    }
    
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    // Reduce image size further if needed targetImageSize is capped.
    func resized500() -> UIImage {
        if case let YPImageSize.cappedTo(size: capped) = YPImageSize.cappedTo(size: 500) {
            let size = cappedSize(for: self.size, cappedAt: capped)
            if let resizedImage = self.resized(to: size) {
                return resizedImage
            }
        }
        return self
    }
    func resized100() -> UIImage {
        if case let YPImageSize.cappedTo(size: capped) = YPImageSize.cappedTo(size: 200) {
            let size = cappedSize(for: self.size, cappedAt: capped)
            if let resizedImage = self.resized(to: size) {
                return resizedImage
            }
        }
        return self
    }
    func cappedSize(for size: CGSize, cappedAt: CGFloat) -> CGSize {
        var cappedWidth: CGFloat = 0
        var cappedHeight: CGFloat = 0
        if size.width > size.height {
            // Landscape
            let heightRatio = size.height / size.width
            cappedWidth = min(size.width, cappedAt)
            cappedHeight = cappedWidth * heightRatio
        } else if size.height > size.width {
            // Portrait
            let widthRatio = size.width / size.height
            cappedHeight = min(size.height, cappedAt)
            cappedWidth = cappedHeight * widthRatio
        } else {
            // Squared
            cappedWidth = min(size.width, cappedAt)
            cappedHeight = min(size.height, cappedAt)
        }
        return CGSize(width: cappedWidth, height: cappedHeight)
    }
}
extension UIImageView {
    func loadImg(str: String, thumb: String = "", thumbImg: UIImage? = nil, user: Bool = false, cell_size: CGSize = CGSize.zero) {
        guard !str.isEmpty, let url = URL(string: str) else {
            self.image = user ? UIImage.avatar() : nil
            return
        }
        
        if user{
            if !thumb.isEmpty, let thumbUrl = URL(string: thumb){
                if thumbImg != nil{
                    self.sd_setImage(with: url, placeholderImage: thumbImg, completed: nil)
                }
                else{
                    self.sd_setImage(with: thumbUrl, placeholderImage: UIImage.avatar()) { (img, _, _, _) in
                        self.sd_setImage(with: url, placeholderImage: img, completed: nil)
                    }
                }
            }
            else{
                if thumbImg != nil{
                    self.sd_setImage(with: url, placeholderImage: thumbImg, completed: nil)
                }
                else{
                    self.sd_setImage(with: url, placeholderImage: UIImage.avatar(), completed: nil)
                }
            }
        }
        else{
            if !thumb.isEmpty, let thumbUrl = URL(string: thumb){
                if thumbImg != nil{
                    self.sd_setImage(with: url, placeholderImage: thumbImg, options: .highPriority, completed: nil)
                }
                else{
                    self.sd_setImage(with: thumbUrl, placeholderImage: nil, options: .highPriority) { (img, _, _, _) in
                        self.sd_setImage(with: url, placeholderImage: img, options: .highPriority, completed: nil)
                    }
                }
            }
            else{
                if thumbImg != nil{
                    self.sd_setImage(with: url, placeholderImage: thumbImg, options: .highPriority, completed: nil)
                }
                else{
//                    self.sd_setImage(with: url, placeholderImage: nil, options: .highPriority, progress: nil) { (img, _, _, _) in
//                        guard let img = img, let cgImg = img.cgImage else {
//                            return
//                        }
//
//                        let coreImage = CIImage(cgImage: cgImg)
//                        if let filter = CIFilter(name: "CIUnsharpMask"){
//
//                            filter.setValue(coreImage, forKey: kCIInputImageKey)
//                            filter.setValue(2, forKey: kCIInputIntensityKey)
//                            filter.setValue(1, forKey: kCIInputRadiusKey)
//
//                            guard let output = filter.outputImage else {
//                                self.image = img
//                                return
//                            }
//                            self.image = UIImage(ciImage: output)
//                            print("Done")
//                        }
//                    }
                    self.sd_setImage(with: url, placeholderImage: nil, options: .highPriority, completed: nil)
                }
            }
        }
    }
}

extension UIViewController: MFMailComposeViewControllerDelegate {
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            if result == .sent{
                let view: cv_report_done = try! SwiftMessages.viewFromNib()
                
                var config = SwiftMessages.defaultConfig
                config.presentationContext = .window(windowLevel: UIWindow.Level.statusBar)
                config.duration = .forever
                config.presentationStyle = .bottom
                config.dimMode = .gray(interactive: true)
                
                SwiftMessages.show(config: config, view: view)
                
                view.opDoneAction = {
                    SwiftMessages.hideAll()
                }
            }
            else{
                self.showError(title: "Mail Delivery", msg: "It was not reported")
            }
        }
    }
}

extension UIViewController {
    func openImagePicker(size: CGFloat = 800) -> YPImagePicker{
        var config = YPImagePickerConfiguration()
        config.isScrollToChangeModesEnabled = true
        config.onlySquareImagesFromCamera = true
        config.usesFrontCamera = false
        config.showsPhotoFilters = false
        config.showsVideoTrimmer = false
        config.shouldSaveNewPicturesToAlbum = false
        config.albumName = "HiveAlbum"
        config.startOnScreen = YPPickerScreen.library
        config.screens = [.library, .photo]
        config.wordings.save = "Next"
        
        config.targetImageSize = YPImageSize.cappedTo(size: size)
        config.overlayView = UIView()
        config.hidesStatusBar = false
        config.hidesBottomBar = false
        config.preferredStatusBarStyle = UIStatusBarStyle.default
        
        config.colors.bottomMenuItemSelectedTextColor = UIColor.active()
        config.colors.bottomMenuItemUnselectedTextColor = UIColor.lightGray
        config.colors.tintColor = UIColor.active()
        
        config.library.mediaType = .photo
        config.library.maxNumberOfItems = 1
        config.library.minNumberOfItems = 1
        
        config.maxCameraZoomFactor = 10.0
        
        let picker = YPImagePicker(configuration: config)
        present(picker, animated: true, completion: nil)
        
        return picker
    }
    
    func openPicker(size: CGFloat = 800) -> YPImagePicker{
        var config = YPImagePickerConfiguration()
        config.isScrollToChangeModesEnabled = true
        config.onlySquareImagesFromCamera = true
        config.usesFrontCamera = false
        config.showsPhotoFilters = false
        config.showsVideoTrimmer = true
        config.shouldSaveNewPicturesToAlbum = false
        config.albumName = "HiveAlbum"
        config.startOnScreen = YPPickerScreen.library
        config.screens = [.library, .photo, .video]
        config.wordings.save = "Next"
        
        config.targetImageSize = YPImageSize.cappedTo(size: size)
        config.overlayView = UIView()
        config.hidesStatusBar = false
        config.hidesBottomBar = false
        config.preferredStatusBarStyle = UIStatusBarStyle.default
        
        config.colors.bottomMenuItemSelectedTextColor = UIColor.active()
        config.colors.bottomMenuItemUnselectedTextColor = UIColor.lightGray
        config.colors.tintColor = UIColor.active()
        
        config.library.mediaType = .photoAndVideo
        config.library.maxNumberOfItems = 1
        config.library.minNumberOfItems = 1
        config.maxCameraZoomFactor = 10.0
        
        config.video.recordingTimeLimit = 120
        config.video.fileType = .mov
        config.video.libraryTimeLimit = 120
        config.video.minimumTimeLimit = 2
        config.video.trimmerMaxDuration = 120
        config.video.trimmerMinDuration = 2
        config.video.compression = AVAssetExportPresetMediumQuality
        
        let picker = YPImagePicker(configuration: config)
        picker.modalPresentationStyle = .overFullScreen
        present(picker, animated: true, completion: nil)
        
        return picker
    }
    
    func openUser(uid: String){
        Utils.fetchUser(uid: uid) { (rusr) in
            guard let usr = rusr else { return }
            self.openUser(usr: usr)
        }
    }
    func openUser(uname: String){
        Utils.fetchUser(uname: uname) { (rusr) in
            guard let usr = rusr else { return }
            self.openUser(usr: usr)
        }
    }
    func openUser(usr: User?){
        guard let targetUser = usr else { return }
        
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "VC_Profile") as! VC_Profile
        
        vc.userToLoad = targetUser
        vc.showBackButton = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func openURL(url: URL){
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "VC_Web") as! VC_Web
        vc.urlToLoad = url
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func openChat(){
        let sb = UIStoryboard(name: "Chat", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "VC_Chat") as! VC_Chat
        
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func openMessage(user: User){
        guard let cid = CUID else { return }
        if user.uid == cid { return }
        
        if MyBlocks[user.uid] == true{
            self.showError(msg: "You blocked this user.")
            return
        }
        
        let uids = [cid, user.uid].sorted()
        let chnId = "\(uids[0])\(uids[1])"
        
        if let chnItem = ChatChannels.first(where: { (item) -> Bool in
            item.value.channelId == chnId
        }){
            chnItem.value.userIds = uids
            self.openMessage(chn: chnItem.value)
        }
        else{
            let chn = MockChannel()
            chn.channelId = chnId
            chn.userIds = uids
            chn.targetUser = user
            
            FCHAT_REF
                .whereField(MockChannel.key_members, isEqualTo: uids)
                .getDocuments { (doc, err) in
                    if let error = err{
                        print(error.localizedDescription)
                        print("error")
                        self.openMessage(chn: chn)
                        return
                    }
                    
                    if doc?.documents.count ?? 0 > 0{
                        doc?.documents.forEach({ (item) in
                            print("found")
                            let chn: MockChannel = MockChannel(id: item.documentID, dic: item.data())
                            chn.targetUser = user
                            ChatChannels[item.documentID] = chn
                            
                            self.openMessage(chn: chn)
                            return
                        })
                    }
                    else{
                        print("non-existing")
                        self.openMessage(chn: chn)
                    }
                }
        }
    }
    
    func openMessage(chn: MockChannel){
        let vc = VC_Message()
        vc.currentChatChannel = chn
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func openMore(pst: Post?){
        guard let uid = CUID else { return }
        guard let post = pst else { return }
        
        if post.ouid == uid{
            //mine
            let view: cv_more_mine = try! SwiftMessages.viewFromNib()
            
            var config = SwiftMessages.defaultConfig
            config.presentationContext = .window(windowLevel: UIWindow.Level.statusBar)
            config.duration = .forever
            config.presentationStyle = .bottom
            config.dimMode = .gray(interactive: true)
            config.interactiveHide = true
            
            SwiftMessages.show(config: config, view: view)
            
            view.opDoneAction = {
                SwiftMessages.hideAll()
            }
            
            view.opEditPostAction = {
                SwiftMessages.hideAll()
                
                self.openPostView(post: post, edit: true)
            }
            view.opDeletePostAction = {
                SwiftMessages.hideAll()
                
                post.deletePost()
            }
        }
        else{
            //other users
            let view: cv_more = try! SwiftMessages.viewFromNib()
            
            var config = SwiftMessages.defaultConfig
            config.presentationContext = .window(windowLevel: UIWindow.Level.statusBar)
            config.duration = .forever
            config.presentationStyle = .bottom
            config.dimMode = .gray(interactive: true)
            config.interactiveHide = true
            
            if adminUser.contains(Me.uid){
                view.lbl_option_first.text = "Delete Post"
                view.lbl_option_second.text = "Delete User"
            }
            
            SwiftMessages.show(config: config, view: view)
            
            view.opDoneAction = {
                SwiftMessages.hideAll()
            }
            
            view.opBlockUserAction = {
                SwiftMessages.hideAll()
                
                Utils.fetchUser(uid: post.ouid) { (rusr) in
                    guard let usr = rusr else { return }
                    
                    usr.block()
                }
            }
            view.opReportPostAction = {
                SwiftMessages.hideAll()
                if adminUser.contains(Me.uid){
                    //delete post
                    let removeAlert = UIAlertController(title: "Delete", message: "Are you sure you want to delete this post?", preferredStyle: .alert)
                    removeAlert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (_) in
                        FPOSTS_REF
                            .document(post.pid)
                            .delete()
                        FPIDS_REF
                            .document(post.pid)
                            .delete()
                        DBPosts.removeValue(forKey: post.pid)
                        
                        self.showSuccess(msg: "Successfully removed!")
                    }))
                    removeAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    self.present(removeAlert, animated: true, completion: nil)
                }
                else{
                    if MFMailComposeViewController.canSendMail() {
                        let mail = MFMailComposeViewController()
                        mail.mailComposeDelegate = self
                        mail.setToRecipients([EmailAddress.ReportPost])
                        mail.setSubject("REPORTING POST: \(post.pid)")
                        mail.setMessageBody("<p>Reporting Post: \(post.pid)</p><p>With Content: \(post.desc)</p><p>Type additional comments below:</p>", isHTML: true)
                        self.present(mail, animated: true, completion: nil)
                    } else {
                        self.showError(title: "Mail Not Setup", msg: "You do not have an e-mail account setup for Apple's Mail app.  Please report postID: \(post.pid) to \(EmailAddress.ReportPost)")
                    }
                }
            }
            
            view.opReportAccountAction = {
                SwiftMessages.hideAll()
                
                if adminUser.contains(Me.uid){
                    let removeAlert = UIAlertController(title: "Delete", message: "Are you sure you want to delete this user?", preferredStyle: .alert)
                    removeAlert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (_) in
                        var user = User()
                        user.uid = post.ouid
                        user.removeUserAndPosts { (res) in
                            DBUsers.removeValue(forKey: user.uid)
                            
                            if res{
                                self.showSuccess(msg: "Successfully removed!")
                            }
                            else{
                                self.showError(msg: "Error in removing this user! Try again later!")
                            }
                            
                            DispatchQueue.main.async {
                                self.navigationController?.popViewController(animated: true)
                            }
                        }
                    }))
                    removeAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    self.present(removeAlert, animated: true, completion: nil)
                }
                else{
                    if MFMailComposeViewController.canSendMail() {
                        let mail = MFMailComposeViewController()
                        mail.mailComposeDelegate = self
                        mail.setToRecipients([EmailAddress.ReportPost])
                        mail.setSubject("REPORTING Account: \(post.ouid)")
                        mail.setMessageBody("<p>Reporting Account: \(post.ouid)</p><p>With Content: \(post.pid)</p><p>Type additional comments below:</p>", isHTML: true)
                        self.present(mail, animated: true, completion: nil)
                    } else {
                        self.showError(title: "Mail Not Setup", msg: "You do not have an e-mail account setup for Apple's Mail app.  Please report userID: \(post.ouid) to \(EmailAddress.ReportPost)")
                    }
                }
            }
        }
    }
    
    func openTag(tag: String){
        let sb = UIStoryboard(name: "TB_CL", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "VC_Hashtag") as! VC_Hashtag
        
        vc.hashtag = tag
        //        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func openPost(pid: String){
        Utils.fetchPost(pid: pid) { (pst) in
            if let rpst = pst{
                self.openPost(post: rpst)
            }
        }
    }
    func openPost(post: Post, thumb: UIImage? = nil){
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "VC_FeedItem") as! VC_FeedItem
        vc.post = post
        vc.thumb = thumb
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func openCommentView(post: Post){
        let sb = UIStoryboard(name: "Chat", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "VC_Comments_New") as! VC_Comments_New
        
        vc.post = post
        vc.hidesBottomBarWhenPushed = true
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func openCommentView(cmt: Comment){
        Utils.fetchPost(pid: cmt.pid) { (rpst) in
            guard let pst = rpst else { return}
            
            let sb = UIStoryboard(name: "Chat", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "VC_Comments_New_Second") as! VC_Comments_New_Second
            
            vc.parentComment = cmt
            vc.post = pst
            
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func openPostView(post: Post, edit: Bool = false){
        guard let cid = CUID else { return }
        if Me.uid != cid{
            self.showError(msg: "Please signin again to post!")
            return
        }
        if Me.uname.isEmpty{
            self.showError(msg: "Please enter username to post!")
            return
        }
        if Me.avatar.isEmpty{
            self.showError(msg: "Please add avatar to post!")
            return
        }
        
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "VC_Post") as! VC_Post
        
        if edit{
            vc.postToEdit = post
        }
        else{
            vc.postToRepost = post
        }
        
        let nav: UINavigationController = UINavigationController(rootViewController: vc)
        nav.isNavigationBarHidden = true
        nav.modalPresentationStyle = .overFullScreen
        nav.modalTransitionStyle = .coverVertical
        self.present(nav, animated: true, completion: nil)
    }
}

extension UIViewController{
    func showError(title: String = "Error", msg: String = "", btnTitle: String = "", btnHandler: ((UIButton) -> Void)? = nil, warning: Bool = false){
        DispatchQueue.main.async {
            let view = MessageView.viewFromNib(layout: .cardView)
            view.configureDropShadow()
            if warning{
                view.configureTheme(.info)
            }
            else{
                view.configureTheme(backgroundColor: UIColor.error(), foregroundColor: UIColor.white)
            }
            view.backgroundColor = UIColor.error()
            view.titleLabel?.textAlignment = .center
            view.bodyLabel?.textAlignment = .center
            if btnTitle.isEmpty{
                view.configureContent(title: title, body: msg)
                view.button?.isHidden = true
            }
            else{
                view.configureContent(title: title, body: msg, iconImage: nil, iconText: nil, buttonImage: nil, buttonTitle: btnTitle, buttonTapHandler: btnHandler)
                view.button?.isHidden = false
                view.buttonTapHandler = { _ in
                    SwiftMessages.hide()
                }
            }
            view.tapHandler = { _ in
                SwiftMessages.hide()
            }
            SwiftMessages.show(view: view)
        }
    }
    func showSuccess(title: String = "Success", msg: String = "", btnTitle: String = "", btnHandler: ((UIButton) -> Void)? = nil){
        DispatchQueue.main.async {
            let view = MessageView.viewFromNib(layout: .cardView)
            view.configureDropShadow()
            view.configureTheme(backgroundColor: UIColor.success(), foregroundColor: UIColor.white)
            if btnTitle.isEmpty{
                view.configureContent(title: title, body: msg)
                view.button?.isHidden = true
            }
            else{
                view.configureContent(title: title, body: msg, iconImage: nil, iconText: nil, buttonImage: nil, buttonTitle: btnTitle, buttonTapHandler: btnHandler)
                view.button?.isHidden = false
                view.buttonTapHandler = { _ in
                    SwiftMessages.hide()
                }
            }
            view.tapHandler = { _ in
                SwiftMessages.hide()
            }
            SwiftMessages.show(view: view)
        }
    }
    
    func setupPost(v: cell_media_table, post: Post){
        if post.type == .IMAGE{
            self.addZoombehavior(for: v.img_content, settings: .instaZoomSettings)
        }
        v.opOpenUserAction = { (targetUser: User?) in
            self.openUser(usr: targetUser)
        }
        v.opOpenLinkAction = { (url: URL) in
            self.openURL(url: url)
        }
        v.opMoreAction = { (pst: Post?) in
            self.openMore(pst: pst)
        }
        v.opOpenHashTag = { (tag: String) in
            self.openTag(tag: tag)
        }
        
        v.opOpenLikedUsers = {
            
        }
        v.opOpenCommentsAction = {
            self.openCommentView(post: post)
        }
        v.opShareToAction = {
            
        }
        v.opRepostAction = {
            if post.ouid == CUID{
                return
            }
            self.openPostView(post: post, edit: false)
        }
    }
    
    func addSwipeRight(){
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.swipeRight))
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)
    }
    
    @objc func swipeRight(gesture: UISwipeGestureRecognizer){
        if(self.navigationController != nil){
            self.navigationController?.popViewController(animated: true)
        }
        else{
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func setupHUD(msg: String = "Loading..."){
        DispatchQueue.main.async {
            let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
            hud.contentColor = UIColor.brand()
            hud.label.text = msg
            if #available(iOS 13.0, *) {
                hud.backgroundView.color = UIColor{ (UITraitCollection: UITraitCollection) -> UIColor in
                    if UITraitCollection.userInterfaceStyle == .dark{
                        return UIColor.white
                    }
                    else{
                        return UIColor.black
                    }
                }
            } else {
                hud.backgroundView.color = UIColor.black
            }
            
            hud.backgroundView.alpha = 0.4
        }
    }
    
    func hideHUD(){
        DispatchQueue.main.async {
            MBProgressHUD.hide(for: self.view, animated: true)
        }
    }
}

extension SKCloudServiceSetupViewController {
    private struct AssociatedKeys {
        static var window: UInt8 = 0
    }
    
    var viewWindow: UIWindow? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.window) as? UIWindow
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.window, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func show(animated: Bool) {
        let window = UIWindow(frame: UIScreen.main.bounds)
        viewWindow = window
        window.rootViewController = UIViewController()
        window.windowLevel = UIWindow.Level.alert
        window.makeKeyAndVisible()
        window.rootViewController!.present(self, animated: animated, completion: nil)
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        viewWindow?.isHidden = true
        viewWindow = nil
    }
}

extension UILabel {
    func indexOfAttributedTextCharacterAtPoint(point: CGPoint) -> Int {
        assert(self.attributedText != nil, "This method is developed for attributed string")
        let textStorage = NSTextStorage(attributedString: self.attributedText!)
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        let textContainer = NSTextContainer(size: self.frame.size)
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = self.numberOfLines
        textContainer.lineBreakMode = self.lineBreakMode
        layoutManager.addTextContainer(textContainer)
        
        let index = layoutManager.characterIndex(for: point, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        return index
    }
}

extension UITextField{
    @IBInspectable var placeHolderColor: UIColor?{
        get{
            return self.placeHolderColor
        }
        set{
            self.attributedPlaceholder = NSAttributedString(string: self.placeholder != nil ? self.placeholder! : "", attributes: [NSAttributedString.Key.foregroundColor: newValue!])
        }
    }
}

extension UIFont{
    static func cFont_regular(size: CGFloat = 17) -> UIFont{
        return UIFont(name: "Gilroy-Regular", size: size)!
    }
    static func cFont_bold(size: CGFloat = 17) -> UIFont{
        return UIFont(name: "Gilroy-Bold", size: size)!
    }
    static func cFont_medium(size: CGFloat = 17) -> UIFont{
        return UIFont(name: "Gilroy-SemiBold", size: size)!
    }
}

extension UIColor{
    static func brand() -> UIColor{
        return UIColor(named: "col_brand")!
    }
    static func bg() -> UIColor{
        return UIColor(named: "col_bg")!
    }
    
    static func active() -> UIColor{
        return UIColor(named: "col_btn_send_active")!
    }
    static func inactive() -> UIColor{
        return UIColor(named: "col_btn_send")!
    }
    
    static func error() -> UIColor{
        return UIColor(named: "mcol_error")!
    }
    static func success() -> UIColor{
        return UIColor(named: "mcol_success")!
    }
}
