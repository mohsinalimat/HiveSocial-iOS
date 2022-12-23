//
//  VC_Comments_New.swift
//  HIVE
//
//  Created by elitemobile on 3/9/21.
//  Copyright © 2021 Kassy Pop. All rights reserved.
//

import UIKit
import GrowingTextView
import IQKeyboardManagerSwift
import CollectionKit
import ESPullToRefresh
import Firebase
import FirebaseFirestore
import GiphyUISDK
import YPImagePicker
import InputBarAccessoryView
import SwiftMessages

class VC_Comments_New_Second: UIViewController {
    //MARK: - variables
    @IBOutlet weak var v_comments: CollectionView!
    
    @IBOutlet weak var img_me: UIImageView!
    @IBOutlet weak var txt_input: GrowingTextView!
    @IBOutlet weak var v_inputBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var v_media: UIView!
    @IBOutlet weak var v_mediaTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var v_mediaWidthRate: NSLayoutConstraint!
    @IBOutlet weak var img_media: UIImageView!
    
    @IBOutlet weak var v_emoji: UIView!
    @IBOutlet weak var v_emoji_collection: CollectionView!
    @IBOutlet weak var v_users: CollectionView!
    @IBOutlet weak var v_usersHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var v_btn_delete: UIView!
    @IBOutlet weak var v_delete_effect: UIView!
    @IBOutlet weak var v_btn_gif: UIView!
    @IBOutlet weak var v_gif_effect: UIView!
    
    var vAccessory: cv_accessoryView_cmt!

    let giphy: GIPHYModel = GIPHYModel()
    var selectedMedia: YPMediaItem? = nil
    var selectedGif: GPHMedia? = nil

    var emojis: [String] = []
    var emojiDataSource: ArrayDataSource<String>! = ArrayDataSource<String>()
    var commentsDataSource: ArrayDataSource<Comment>! = ArrayDataSource<Comment>()
    var usersDataSource: ArrayDataSource<User>! = ArrayDataSource<User>()

    var post: Post!
    var parentComment: Comment!
    
    var users: [String: User] = [:]
    
    var isSending: Bool = false
    var isLoadingMore: Bool = false
    var isBlocked: Bool = false
    var expended: [String: Bool] = [:]
    
    lazy var autocompleteManager: AutocompleteManager = { [unowned self] in
        let manager = AutocompleteManager(for: self.txt_input)
        manager.delegate = self
        manager.dataSource = self
        return manager
    }()

    //MARK: - overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        initComponents()
        setupCommentsView()
        loadData()

        IQKeyboardManager.shared.enable = false
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.commentsDataSource.data = self.commentsDataSource.data.filter{ !(MyBlocks[$0.uid] == true) }
        txt_input.resignFirstResponder()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        txt_input.resignFirstResponder()
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if self.isMovingFromParent || self.isBeingDismissed{
            NotificationCenter.default.removeObserver(self)
            cmtListener?.remove()
            cmtListener = nil
            
            blockTracker?.remove()
            blockTracker = nil
            
            IQKeyboardManager.shared.enable = false
        }
    }
    
    //MARK: - functions
    func initComponents(){
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(adjustForKeyboard),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(adjustForKeyboard),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateReplyButton),
                                               name: UITextView.textDidChangeNotification,
                                               object: nil)
        
        addSwipeRight()

        setupTxtInput()
        setupEmojis()
        setupUserSearch()
        setupMediaView()

        updateReplyButton()
        
        giphy.delegate = self
        
        trackUserBlock()
    }
    @objc func adjustForKeyboard(notification: Notification){
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, to: view.window)
        
        if notification.name == UIResponder.keyboardWillHideNotification{
            v_emoji.isHidden = true
            v_comments.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 72, right: 0)
            v_inputBottomConstraint.constant = 0
        }
        else{
            let window = UIApplication.shared.windows[0]
            let bottomPadding = window.safeAreaInsets.bottom
            print(bottomPadding)

            v_comments.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height + bottomPadding + 72, right: 0)
            v_inputBottomConstraint.constant = keyboardViewEndFrame.height + (bottomPadding != 0 ? -46 : 0)
        }
    }
    var blockTracker: ListenerRegistration? = nil
    func trackUserBlock(){
        if blockTracker != nil || self.parentComment == nil || self.post == nil || self.post.ouid == Me.uid{
            return
        }
        
        blockTracker = FUSER_REF
            .document(self.post.ouid)
            .collection(User.key_collection_blocked)
            .document(Me.uid)
            .addSnapshotListener { (doc, _) in
                if doc?.exists == true{
                    self.isBlocked = true
                    self.navigationController?.popViewController(animated: true)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                        self.showError(msg: "You are not allowed to send comment to this post.")
                    })
                }
            }
    }
    
    //MARK: - setup
    func setupTxtInput(){
        txt_input.makeRoundView(r: 6)
        txt_input.textContainerInset = UIEdgeInsets(top: 11, left: 12, bottom: 11, right: 12)

        vAccessory = Bundle.main.loadNibNamed("cv_accessoryView_cmt", owner: self, options: nil)?[0] as? cv_accessoryView_cmt
        vAccessory.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 46)
        vAccessory.opGifAction = {
            self.v_emoji.isHidden = true
            
            let giphyVC = self.giphy.getGiphyVC()
            self.present(giphyVC, animated: true, completion: nil)
        }
        vAccessory.opMediaAction = {
            self.v_emoji.isHidden = true
            //media
            let picker: YPImagePicker = self.openPicker()
            picker.didFinishPicking { [unowned picker] items, cancelled in
                if cancelled{
                    picker.dismiss(animated: true, completion: nil)
                    return
                }
                for item in items{
                    self.selectedMedia = item
                    self.selectedGif = nil
                    self.setMedia()
                    break
                }
                picker.dismiss(animated: true, completion: nil)
            }
        }
        vAccessory.opEmojiAction = {
            if self.v_emoji.isHidden{
                self.v_users.isHidden = true
                self.v_emoji.isHidden = false
            }
            else{
                self.v_emoji.isHidden = true
            }
        }
        vAccessory.opReplyAction = {
            guard let cid = CUID else { return }
            if Me.uid != cid{
                self.showError(msg: "Please signin again.")
                return
            }
            if Me.uname.isEmpty{
                self.showError(msg: "Please add an username.")
                return
            }
            if Me.avatar.isEmpty{
                self.showError(msg: "Please add an avatar.")
                return
            }
            if self.isBlocked{
                self.navigationController?.popViewController(animated: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.showError(msg: "You are not allowed to send comment to this post.")
                }
                return
            }

            self.vAccessory.lock()

            self.v_emoji.isHidden = true
            self.isSending = true
            self.updateLockStatus()
            
            let cmt = Comment()
            cmt.mid = "cmt_\(Utils.curTimeStr)"
            cmt.created = Utils.curTime
            cmt.uid = Me.uid
            cmt.msg = self.txt_input.text
            cmt.num_likes = 0
            cmt.num_commented = 0
            cmt.type = self.selectedGif != nil ? .GIF : (self.selectedMedia != nil ? .IMAGE : .TEXT)
            //media, ratio
            cmt.level = 0
            cmt.parentId = self.parentComment.mid
            cmt.pid = self.parentComment.pid

            cmt.sendComment(media: self.selectedMedia, gif: self.selectedGif, txt: self.txt_input.text, parentComment: self.parentComment) { (res, str) in
                self.isSending = false
                self.updateLockStatus()

                if res{
                    self.selectedMedia = nil
                    self.selectedGif = nil
                    self.txt_input.text = ""
                    
                    self.setMedia()
                    self.vAccessory.unlock()
                    
                    self.txt_input.resignFirstResponder()
                }
                else{
                    if !str.isEmpty{
                        self.showError(msg: str)
                    }
                    self.vAccessory.unlock()
                }
                
                MyCommented[self.post.pid] = true
                MyCommentedComments[self.parentComment.mid] = true
            }
        }
        
        txt_input.inputAccessoryView = vAccessory
    }
    func setupEmojis(){
        v_emoji.isHidden = true
        emojis.removeAll()
        for i in 0x1F601...0x1F64F{
            let c = String(UnicodeScalar(i) ?? "-")
            emojis.append(c)
        }

        emojiDataSource.data = emojis
        v_emoji_collection.provider = BasicProvider(
            dataSource: emojiDataSource,
            viewSource: ClosureViewSource(viewGenerator: { (item: String, index: Int) -> cv_cmt_emoji_item in
                let v = Bundle.main.loadNibNamed("cv_cmt_emoji_item", owner: self, options: nil)?[0] as! cv_cmt_emoji_item
                return v
            }, viewUpdater: { (v: cv_cmt_emoji_item, item: String, index: Int) in
                v.setEmoji(str: item)
                v.opEmojiClickedAction = {
                    self.txt_input.insertText(item)
                    self.updateReplyButton()
                }
            }),
            sizeSource: { (index: Int, item: String, size: CGSize) -> CGSize in
                return CGSize(width: size.height, height: size.height)
            },
            layout: FlowLayout(spacing: 6).transposed()
        )
    }
    func setupUserSearch(){
        // Configure AutocompleteManager
        let mentionTextAttributes: [NSAttributedString.Key : Any] = [
            .font: UIFont.cFont_medium(size: 16),
            .foregroundColor: UIColor.active(),
            .backgroundColor: UIColor.clear
        ]

        autocompleteManager.register(prefix: "@", with: mentionTextAttributes)
        autocompleteManager.maxSpaceCountDuringCompletion = 1 // Allow for autocompletes with a space

        v_users.makeRoundView(r: 16, masked: true)
        v_users.layer.borderWidth = 0.5
        v_users.layer.borderColor = UIColor(named: "mcol_comment_line")!.cgColor
        v_users.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
        v_users.showsHorizontalScrollIndicator = false
        v_users.showsVerticalScrollIndicator = false
        
        v_users.isHidden = true
        v_users.provider = BasicProvider(
            dataSource: usersDataSource,
            viewSource: ClosureViewSource(viewGenerator: { (usr: User, index: Int) -> cv_comment_user in
                let v = Bundle.main.loadNibNamed("cv_comment_user", owner: self, options: nil)?[0] as! cv_comment_user
                return v
            }, viewUpdater: { (v: cv_comment_user, usr: User, index: Int) in
                v.setUser(usr: usr)

                v.opClickAction = { [self] in
                    guard let session = self.autocompleteManager.currentSession else { return }
                    print("Session alive")
                    session.completion = AutocompleteCompletion(text: usr.uname)
                    autocompleteManager.autocomplete(with: session)
                    
                    DispatchQueue.main.async {
                        self.usersDataSource.data.removeAll()
                        self.v_usersHeightConstraint.constant = 0
                        self.v_users.isHidden = true
                    }
                }
            }),
            sizeSource: { (index: Int, usr: User, size: CGSize) -> CGSize in
                return CGSize(width: size.width, height: 64)
            }
        )
    }
    func setupMediaView(){
        v_media.isHidden = true
        v_media.makeRoundView(r: 6)
        img_me.makeCircleView()
        img_me.loadImg(str: Me.thumb.isEmpty ? Me.avatar : Me.thumb, user: true)

        v_btn_delete.makeCircleView()
        v_btn_gif.makeRoundView(r: 6)
        let effect = UIBlurEffect(style: .dark)
        let effectView = UIVisualEffectView(effect: effect)
        effectView.frame = self.v_delete_effect.bounds
        effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        effectView.alpha = 0.6
        v_delete_effect.addSubview(effectView)
        
        let effect1 = UIBlurEffect(style: .dark)
        let effectView1 = UIVisualEffectView(effect: effect1)
        effectView1.frame = self.v_gif_effect.bounds
        effectView1.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        effectView1.alpha = 0.6
        v_gif_effect.addSubview(effectView1)

        v_btn_delete.isHidden = true
        v_btn_gif.isHidden = true
    }
    func setupCommentsView(){
        v_comments.contentInsetAdjustmentBehavior = .never
        v_comments.clipsToBounds = true
        v_comments.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 500, right: 0)
        v_comments.removeGestureRecognizer(v_comments.tapGestureRecognizer)
        v_comments.showsVerticalScrollIndicator = false
        v_comments.showsHorizontalScrollIndicator = false
        v_comments.delegate = self
        v_comments.keyboardDismissMode = .onDrag
        
        v_comments.provider = ComposedProvider(sections: [
            BasicProvider(
                dataSource: [parentComment],
                viewSource: ClosureViewSource(viewGenerator: { (cmt: Comment, index: Int) -> cv_comment_item in
                    let v = Bundle.main.loadNibNamed("cv_comment_item", owner: self, options: nil)?[0] as! cv_comment_item
                    return v
                }, viewUpdater: { (v: cv_comment_item, cmt: Comment, index: Int) in
                    v.setComment(cmt: cmt, header: true, myPost: self.post.ouid == Me.uid)
                    if cmt.type == .IMAGE{
                        self.addZoombehavior(for: v.img_media, settings: .instaZoomSettings)
                    }
                    v.opCommentAction = {
                        self.openCommentView(cmt: cmt)
                    }
                    v.opMoreAction = {
                        if cmt.uid == Me.uid{
                            print("it's someone else's post, but my comment")
                            //not my post, but my comment
                            let view: cv_comment_more = try! SwiftMessages.viewFromNib()
                            
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
                            
                            view.opDeleteCommentAction = {
                                SwiftMessages.hideAll()
                                
                                cmt.uploadComment(add: false) { (res, err) in
                                    if !res{
                                        self.showError(msg: err)
                                    }
                                    else{
                                        self.commentsDataSource.data = self.commentsDataSource.data.filter{ !(MyBlocks[$0.uid] == true) && $0.mid != cmt.mid }
                                    }
                                }
                            }
                        }
                        else if self.post.ouid == Me.uid{
                            print("\(cmt.pid) - \(Me.uid)")
                            print("it's my posts")
                            //if it's my post
                            //delete, block users to comment
                            let view: cv_comment_more_my_post = try! SwiftMessages.viewFromNib()
                            
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
                            
                            view.opBlockUserAction = {
                                SwiftMessages.hideAll()
                                
                                Utils.fetchUser(uid: cmt.uid) { (rusr) in
                                    guard let usr = rusr else { return }

                                    usr.block()

                                    self.commentsDataSource.data = self.commentsDataSource.data.filter{ !(MyBlocks[$0.uid] == true) && $0.uid != cmt.uid }
                                }
                            }
                            
                            view.opDeleteCommentAction = {
                                SwiftMessages.hideAll()

                                cmt.uploadComment(add: false) { (res, err) in
                                    if !res{
                                        self.showError(msg: err)
                                    }
                                    else{
                                        
                                    }
                                }
                            }
                        }
                    }
                    v.opOpenUserAction = { uid in
                        self.openUser(uid: uid)
                    }
                    v.opOpenUserNameAction = { uname in
                        self.openUser(uname: uname)
                    }
                    v.opOpenUrlAction = { url in
                        self.openURL(url: url)
                    }
                    v.opOpenHashtagAction = { tag in
                        self.openTag(tag: tag)
                    }
                }),
                sizeSource: { (index: Int, cmt: Comment, size: CGSize) -> CGSize in
                    return CGSize(width: size.width, height: Utils.getHeightCmtItem(cmt: cmt, header: true))
                }
            ),
            BasicProvider(
                dataSource: commentsDataSource,
                viewSource: ClosureViewSource(viewGenerator: { (cmt: Comment, index: Int) -> cv_comment_item in
                    let v = Bundle.main.loadNibNamed("cv_comment_item", owner: self, options: nil)?[0] as! cv_comment_item
                    return v
                }, viewUpdater: { (v: cv_comment_item, cmt: Comment, index: Int) in
                    v.setComment(cmt: cmt, myPost: self.post.ouid == Me.uid, showLabel: self.expended[cmt.mid] ?? false, second: true)
                    if cmt.type == .IMAGE{
                        self.addZoombehavior(for: v.img_media, settings: .instaZoomSettings)
                    }
                    v.opCommentAction = {
                        self.openCommentView(cmt: cmt)
                    }
                    v.opMoreAction = {
                        if cmt.uid == Me.uid{
                            print("it's someone else's post, but my comment")
                            //not my post, but my comment
                            let view: cv_comment_more = try! SwiftMessages.viewFromNib()
                            
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
                            
                            view.opDeleteCommentAction = {
                                SwiftMessages.hideAll()
                                
                                cmt.uploadComment(add: false) { (res, err) in
                                    if !res{
                                        self.showError(msg: err)
                                    }
                                    else{
                                        self.commentsDataSource.data.remove(at: index)
                                    }
                                }
                            }
                        }
                        else if self.post.ouid == Me.uid{
                            print("\(cmt.pid) - \(Me.uid)")
                            print("it's my posts")
                            //if it's my post
                            //delete, block users to comment
                            let view: cv_comment_more_my_post = try! SwiftMessages.viewFromNib()
                            
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
                            
                            view.opBlockUserAction = {
                                SwiftMessages.hideAll()
                                
                                Utils.fetchUser(uid: cmt.uid) { (rusr) in
                                    guard let usr = rusr else { return }

                                    usr.block()

                                    self.commentsDataSource.data = self.commentsDataSource.data.filter{ !(MyBlocks[$0.uid] == true) && $0.uid != cmt.uid }
                                }
                            }
                            
                            view.opDeleteCommentAction = {
                                SwiftMessages.hideAll()

                                cmt.uploadComment(add: false) { (res, err) in
                                    if !res{
                                        self.showError(msg: err)
                                    }
                                    else{
                                        self.commentsDataSource.data.remove(at: index)
                                    }
                                }
                            }
                        }
                    }
                    v.opOpenUserAction = { uid in
                        self.openUser(uid: uid)
                    }
                    v.opOpenUserNameAction = { uname in
                        self.openUser(uname: uname)
                    }
                    v.opOpenUrlAction = { url in
                        self.openURL(url: url)
                    }
                    v.opOpenHashtagAction = { tag in
                        self.openTag(tag: tag)
                    }
                    v.opShowRepliesAction = { showComments in
                        if showComments{
                            self.expended[cmt.mid] = true
                            FPOSTS_REF
                                .document(cmt.pid)
                                .collection(cmt.mid)
                                .order(by: Comment.key_created, descending: true)
                                .getDocuments(completion: { (doc, err) in
                                    if let error = err{
                                        print("ERROR VC_Message/ViewDidAppear \(error.localizedDescription)")
                                        return
                                    }
                                    
                                    var subComments: [Comment] = []
                                    doc?.documents.forEach({ (item) in
                                        let cItem = Comment(id: item.documentID, dic: item.data())
                                        cItem.pid = cmt.pid
                                        cItem.level = cmt.level + 1
                                        
                                        if !self.commentsDataSource.data.contains(where: { (cit) -> Bool in
                                            cit.mid == cItem.mid
                                        }){
                                            subComments.append(cItem)
                                            Utils.fetchUser(uid: cItem.uid) { (rusr) in
                                                guard let usr = rusr else { return }
                                                
                                                self.users[cmt.uid] = usr
                                            }
                                        }
                                    })
                                    if index + 1 >= self.commentsDataSource.data.count{
                                        self.commentsDataSource.data.append(contentsOf: subComments)
                                        print("added")
                                    }
                                    else{
                                        self.commentsDataSource.data.insert(contentsOf: subComments, at: index + 1)
                                        print("inserted")
                                    }
                                })
                        }
                        else{
                            self.expended[cmt.mid] = false
                            self.commentsDataSource.data = self.commentsDataSource.data.filter({ (item) -> Bool in
                                if item.parentId == cmt.mid{
                                    self.expended.removeValue(forKey: item.mid)
                                    return false
                                }
                                return true
                            })
                        }
                    }
                }),
                sizeSource: { (index: Int, cmt: Comment, size: CGSize) -> CGSize in
                    return CGSize(width: size.width, height: Utils.getHeightCmtItem(cmt: cmt, second: true))
                }
            )
        ])
    }
    
    //MARK: - load data
    var firstLoading: Bool = true
    var cmtListener: ListenerRegistration? = nil
    func loadData(){
        Utils.fetchUser(uid: post.ouid) { (rusr) in
            guard let usr = rusr else { return }
            self.users[self.post.ouid] = usr
        }
        
        if cmtListener != nil{
            return
        }
        
        cmtListener = FPOSTS_REF
            .document(parentComment.pid)
            .collection(parentComment.mid)
            .order(by: Comment.key_created, descending: true)
            .limit(to: 20)
            .addSnapshotListener({ (doc, err) in
                if let error = err{
                    print("ERROR VC_Message/ViewDidAppear \(error.localizedDescription)")
                    return
                }
                
                doc?.documentChanges.forEach({ (item) in
                    switch(item.type){
                    case .removed:
//                        print("remove")
//                        if let index = self.commentsDataSource.data.firstIndex(where: { (cItem) -> Bool in
//                            return cItem.mid == item.document.documentID
//                        }){
//                            print("removed")
//                            self.commentsDataSource.data.remove(at: index)
//                        }
                        break
                    case .added:
                        let cmt = Comment(id: item.document.documentID, dic: item.document.data())
                        guard MyBlocks[cmt.uid] != true else { break }
                        cmt.level = 1
                        cmt.pid = self.post.pid

                        if !self.commentsDataSource.data.contains(where: { (cit) -> Bool in
                            cit.mid == cmt.mid
                        }){
                            if self.firstLoading{
                                self.commentsDataSource.data.append(cmt)
                            }
                            else{
                                self.commentsDataSource.data.insert(cmt, at: 0)
                            }
                            Utils.fetchUser(uid: cmt.uid) { (rusr) in
                                guard let usr = rusr else { return }
                                self.users[cmt.uid] = usr
                            }
                        }
                        break
                    case .modified:
                        let cmt = Comment(id: item.document.documentID, dic: item.document.data())
                        guard MyBlocks[cmt.uid] != true else { break }
                        cmt.level = 1
                        cmt.pid = self.post.pid

                        Utils.fetchUser(uid: cmt.uid) { (rusr) in
                            guard let usr = rusr else { return }
                            self.users[cmt.uid] = usr
                            
                            if let index = self.commentsDataSource.data.firstIndex(where: { (cItem) -> Bool in
                                return cItem.mid == cmt.mid
                            }){
                                self.commentsDataSource.data[index] = cmt
                            }
                        }
                        break
                    }
                })
                
                self.firstLoading = false
            })
    }
    
    var lastKey: Double = 1000000000000
    func loadMoreData(){
        if self.isLoadingMore { return }
        self.isLoadingMore = true
        guard let last = self.commentsDataSource.data.last, lastKey > last.created else {
            self.isLoadingMore = false
            return }
        if lastKey == last.created{
            self.isLoadingMore = false
            return
        }
        
        lastKey = last.created
        
        FPOSTS_REF
            .document(parentComment.pid)
            .collection(parentComment.mid)
            .whereField(Comment.key_created, isLessThan: lastKey)
            .order(by: Comment.key_created, descending: true)
            .limit(to: 20)
            .getDocuments { (doc, err) in
                if let error = err{
                    print("ERROR VC_Message/ViewDidAppear \(error.localizedDescription)")
                    self.isLoadingMore = false
                    return
                }
                
                doc?.documents.forEach({ (item) in
                    let cmt = Comment(id: item.documentID, dic: item.data())
                    guard MyBlocks[cmt.uid] != true else { return }

                    cmt.pid = self.post.pid
                    cmt.level = 1
                    
                    if !self.commentsDataSource.data.contains(where: { (cit) -> Bool in
                        cit.mid == cmt.mid
                    }){
                        self.commentsDataSource.data.append(cmt)
                    }

                    Utils.fetchUser(uid: cmt.uid) { (rusr) in
                        guard let usr = rusr else { return }
                        
                        self.users[cmt.uid] = usr
                    }
                })
                
                self.isLoadingMore = false
                print("loaded more")
            }
    }
    
    //MARK: - setup input view
    func setMedia(){
        self.v_btn_gif.isHidden = true
        self.v_btn_delete.isHidden = false

        if self.selectedMedia != nil{
            switch self.selectedMedia {
            case .photo(p: let photo):
                self.img_media.image = photo.image
                self.v_mediaTopConstraint.constant = 26
                self.v_media.isHidden = false
                let ratio = photo.image.size.width / photo.image.size.height
                self.v_mediaWidthRate.constant = (ratio - 1) * 140
                break
            default:
                break
            }
        }
        else if selectedGif != nil{
            self.img_media.loadImg(str: self.selectedGif!.url(rendition: .fixedWidth, fileType: .gif)!)
            self.v_mediaTopConstraint.constant = 26
            self.v_media.isHidden = false
            self.v_mediaWidthRate.constant = (self.selectedGif!.aspectRatio - 1) * 140
            
            self.v_btn_gif.isHidden = false
        }
        else{
            self.v_mediaTopConstraint.constant = -140
            self.v_media.isHidden = true
            self.v_mediaWidthRate.constant = 0
        }

        self.updateReplyButton()
    }
    @objc func updateReplyButton(){
        let activated = self.selectedGif != nil || self.selectedMedia != nil || !self.txt_input.text.isEmpty
        self.vAccessory.updateReplyBtn(activated: activated)
        
        guard self.v_users.isHidden == false else { return }
        guard let selectedRange = self.txt_input.selectedTextRange else {
            self.v_users.isHidden = true
            return }
        let cursorOffset = self.txt_input.offset(from: self.txt_input.beginningOfDocument, to: selectedRange.start)
        let txt = self.txt_input.text!
        let substr: String = (txt as NSString).substring(to: cursorOffset)
        guard let editedWord = substr.components(separatedBy: " ").last, editedWord.contains("@") else {
            self.v_users.isHidden = true
            return }

        print("@edited - \(editedWord)")
    }
    func updateLockStatus(){
        txt_input.isUserInteractionEnabled = !isSending
    }
    @IBAction func opDeleteMedia(_ sender: Any) {
        if isSending{
            return
        }
        
        self.selectedMedia = nil
        self.selectedGif = nil
        
        self.setMedia()
    }

    @IBAction func opBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}

extension VC_Comments_New_Second: GIPHYMediaManagerDelegate {
    func got(media: GPHMedia) {
        self.selectedGif = media
        self.selectedMedia = nil
        self.setMedia()
    }
}
extension VC_Comments_New_Second: AutocompleteManagerDelegate, AutocompleteManagerDataSource {
    func autocompleteManager(_ manager: AutocompleteManager, autocompleteSourceFor prefix: String) -> [AutocompleteCompletion] {
        if !self.v_emoji.isHidden{
            self.v_emoji.isHidden = true
        }
        
        if prefix == "@" {
            if let filter = manager.currentSession?.filter{
                usersDataSource.data = filter.isEmpty ? Array(self.users.values) : self.users.values.filter { (usr) -> Bool in
                    usr.uname.contains(filter)
                }
                switch(usersDataSource.data.count){
                case 0:
                    v_usersHeightConstraint.constant = 0
                    break
                case 1:
                    v_usersHeightConstraint.constant = 64
                    break
                case 2:
                    v_usersHeightConstraint.constant = 64 * 2
                    break
                case 3:
                    v_usersHeightConstraint.constant = 64 * 3
                    break
                default:
                    v_usersHeightConstraint.constant = 64 * 3 + 20
                    break
                }
                DispatchQueue.main.async {
                    self.v_users.layoutIfNeeded()
                    self.v_users.isHidden = self.usersDataSource.data.count == 0 ? true : false
                }
            }
            else{
                self.v_users.isHidden = true
            }
        } else if prefix == "#" {
            self.v_users.isHidden = true
        }
        else{
            self.v_users.isHidden = true
        }
        
        self.updateReplyButton()

        return []
    }

    func autocompleteManager(_ manager: AutocompleteManager, tableView: UITableView, cellForRowAt indexPath: IndexPath, for session: AutocompleteSession) -> UITableViewCell {
        return UITableViewCell()
    }

    // MARK: - AutocompleteManagerDelegate
    func autocompleteManager(_ manager: AutocompleteManager, shouldBecomeVisible: Bool) {
        setAutocompleteManager(active: shouldBecomeVisible)
    }

    // Optional
    func autocompleteManager(_ manager: AutocompleteManager, shouldRegister prefix: String, at range: NSRange) -> Bool {
        print("asdfasdf\(prefix)")
        return true
    }

    // Optional
    func autocompleteManager(_ manager: AutocompleteManager, shouldUnregister prefix: String) -> Bool {
        return true
    }

    // Optional
    func autocompleteManager(_ manager: AutocompleteManager, shouldComplete prefix: String, with text: String) -> Bool {
        print("text - \(prefix) - \(text)")
        return true
    }

    // MARK: - AutocompleteManagerDelegate Helper

    func setAutocompleteManager(active: Bool) {
        print("activate - \(active)")
    }
}
extension VC_Comments_New_Second: UIScrollViewDelegate{
    func scrollViewDidScroll(_ scrollView: UIScrollView){
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        let diff = maximumOffset - currentOffset
        if diff <= 1500{
            if self.commentsDataSource.data.count == 0{
                return
            }
            if self.isLoadingMore{
                return
            }
            DispatchQueue.main.async {
                self.loadMoreData()
            }
        }
    }
}
