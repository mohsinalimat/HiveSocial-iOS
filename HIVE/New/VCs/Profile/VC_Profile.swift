//
//  VC_Profile.swift
//  HIVE
//
//  Created by Daniel Pratt on 9/27/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import UIKit
import MediaPlayer
import StoreKit
import Firebase
import XLPagerTabStrip
import Zoomy
import GradientLoadingBar
import CollectionKit
import SwiftMessages
import MessageUI

class VC_Profile: BaseButtonBarPagerTabStripViewController<cell_youtube_icon> {
    
    // MARK: - IBOutlets
    @IBOutlet weak var scrollView: UIScrollView!
    
    // user info
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lbl_username: UILabel!
    @IBOutlet weak var imgUser: UIImageView!
    @IBOutlet weak var imgBanner: UIImageView!
    @IBOutlet weak var imgBannerBlur: UIImageView!
    
    @IBOutlet weak var v_editFollow: UIView!
    @IBOutlet weak var btnEditFollow: UIButton!
    @IBOutlet weak var btnSendMsg: UIButton!
    @IBOutlet weak var btn_song: UIButton!
    
    @IBOutlet weak var lblNumPosts: UILabel!
    @IBOutlet weak var lblNumFollowers: UILabel!
    @IBOutlet weak var lblNumFollowing: UILabel!
    
    @IBOutlet weak var lblBio: ActiveLabel!
    @IBOutlet weak var btnLink: UIButton!
    
    @IBOutlet weak var btn_menu: UIButton!
    @IBOutlet weak var v_back: UIView!
    @IBOutlet weak var v_avatar: UIView!
    @IBOutlet weak var v_private: UIView!
    @IBOutlet weak var v_blocked: UIView!
    @IBOutlet weak var v_posts: UIView!

    @IBOutlet weak var v_topHeight: UIView!
    @IBOutlet weak var scrollViewHeight: NSLayoutConstraint!
    @IBOutlet weak var linkViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var v_music: UIView!
    @IBOutlet weak var carouselSongs: iCarousel!
    @IBOutlet weak var v_collection_songs: CollectionView!
    
    var isMusicPlaying: Bool = false
    // MARK: - Properties
    
    // Post Manager
    var manager: UserPostsManager!
    var child_1:VC_Profile_Media!
    var child_2:VC_Profile_State!
    // media player
    var musicNeedsReload: Bool = true
    private let musicPlayerController: MPMusicPlayerController = MPMusicPlayerController.applicationQueuePlayer
    private var songTitleLoadAttemptCounter: Int = 0
    private var countryCodeErrorCount: Int = 0
    
    var showBackButton: Bool = false
    var userToLoad: User!
    var user: User! {
        didSet {
            trackUserData()
            if user.songs.count > 0 && (self.musicNeedsReload && Me.play_song){
                self.reloadMusic()
            }
            
            btn_song.isHidden = user.uid == Me.uid || user.songs.count == 0
            
            v_back.isHidden = user.uid == Me.uid && !showBackButton

            updateUserImages()
            
            lbl_username.text = "@\(user.uname)"
            lblName.text = user.fname
            lblBio.text = user.bio
            
            self.initLink()
            
            self.view.layoutIfNeeded()

            DispatchQueue.main.async {
                self.scrollViewHeight.constant = self.v_topHeight.bounds.height - 64
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func updateUserImages(){
        imgUser.loadImg(str: user.avatar, user: true)
        imgBanner.loadImg(str: user.banner)
    }
    private var isMusicLoaded: Bool = false

    override func viewDidLoad() {
        setupBarButtonView()
        super.viewDidLoad()
        
        initComponents()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.user != nil && self.user.uid == Me.uid{
            self.user = Me
        }
        else{
            if (self.user.songs.count > 0 && Me.play_song && musicNeedsReload){
                print("~>Music needs reload")
                self.reloadMusic()
            }
        }
    }
    
    var selectedMusicIndex: Int = 0
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if self.musicPlayerController.playbackState == .playing{
            self.musicPlayerController.pause()
            self.musicNeedsReload = true
        }
        
        isMusicLoaded = false
        
        if self.isMovingFromParent || self.isBeingDismissed{
            NotificationCenter.default.removeObserver(self)
            
            self.removeObserver()
        }
        
        if v_music.alpha == 1{
            self.v_music.alpha = 0
            self.v_music.isHidden = true
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "hideMusicCover"), object: nil)
        }
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        var diff = Double(Int(self.v_topHeight.bounds.height - 64) - abs(Int(self.scrollView.contentOffset.y)))
        if diff < 0 {
            diff = 0
        }
        if diff < 200{
            self.imgBannerBlur.alpha = 1
        }
        else {
            self.imgBannerBlur.alpha = 0
        }
    }
    
    func initComponents(){
        scrollView.delegate = self
        v_music.isHidden = true
        
        lblBio.enabledTypes = [.url, .hashtag]
        lblBio.configureLinkAttribute = { [weak self] (type, attributes, isSelected) in
            guard let _ = self else { return [:] }
            var atts = attributes
            switch type {
                case .url:
                    atts[NSAttributedString.Key.foregroundColor] = UIColor.active()
                    atts[NSAttributedString.Key.font] = UIFont.cFont_medium(size: 16)
                    break
                default:
                    atts[NSAttributedString.Key.foregroundColor] = UIColor.label
                    atts[NSAttributedString.Key.font] = UIFont.cFont_medium(size: 16)
                    break
            }
            return atts
        }
        lblBio.handleURLTap { [weak self] (url) in
            guard let self = self else { return }
            self.openURL(url: url)
        }
        lblBio.handleHashtagTap { (hashtag) in
            self.openTag(tag: hashtag)
        }

        if userToLoad == nil || userToLoad.uid == Me.uid{
            userToLoad = Me
            
            btnEditFollow.setTitle("Edit", for: .normal)
            v_editFollow.backgroundColor = UIColor.label.withAlphaComponent(0.1)
            btnEditFollow.setTitleColor(UIColor(named: "col_lbl_post")!, for: .normal)
        }
        else{
            btnEditFollow.setTitle("Follow", for: .normal)
            btnEditFollow.setTitleColor(UIColor(red: 0, green: 157/255, blue: 255/255, alpha: 1), for: .normal)
            btnEditFollow.layer.borderWidth = 2
            btnEditFollow.layer.borderColor = UIColor(red: 0, green: 157/255, blue: 255/255, alpha: 1).cgColor
            v_editFollow.backgroundColor = UIColor(red: 0, green: 157/255, blue: 255/255, alpha: 0.2)
        }
            
        self.user = userToLoad
        self.initButtons()
        self.updateUserFollowingStatus()

        if self.user.uid == Me.uid{
            btn_menu.setImage(UIImage(named: "mic_settings_menu")?.withRenderingMode(.alwaysTemplate), for: .normal)
        }
        btn_menu.makeRoundView(r: 10)
        
        self.manager = UserPostsManager(for: user)
        self.child_1.manager = self.manager
        self.child_2.manager = self.manager
        self.manager.opPostsLoaded = {
            self.lblNumPosts.text = "   \(self.manager.postIds.count) Posts   "
            if self.manager.postIds.count != self.user.num_posts{
                self.user.num_posts = self.manager.postIds.count
                DBUsers[self.user.uid] = self.user
                
                if self.user.uid == Me.uid{
                    Me.num_posts = self.user.num_posts
                    Me.updateNumPosts()
                    Me.saveLocal()
                }
            }
        }

        btnEditFollow.makeRoundView(r: 8)
        v_editFollow.makeRoundView(r: 8)
        imgUser.makeCircleView()
        v_avatar.makeCircleView()
        
        addSwipeRight()
        
        var settings: Settings = Settings.backgroundEnabledSettings
            .with(actionOnTapImageView: Action.zoomToFit)
            .with(actionOnTapOverlay: Action.dismissOverlay)
            .with(actionOnTapBackgroundView: Action.dismissOverlay)
        settings.secundaryBackgroundColor = UIColor.black.withAlphaComponent(0.6)
        addZoombehavior(for: self.imgUser, settings: settings)
        
        let effect = UIBlurEffect(style: .dark)
        let effectView = UIVisualEffectView(effect: effect)
        effectView.frame = self.imgBanner.bounds
        effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        effectView.alpha = 0.6
        imgBannerBlur.addSubview(effectView)
        imgBannerBlur.alpha = 0
        
        let effect1 = UIBlurEffect(style: .light)
        let effectView1 = UIVisualEffectView(effect: effect1)
        effectView1.frame = self.v_posts.bounds
        effectView1.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        effectView1.alpha = 0.8
        v_posts.addSubview(effectView1)
        v_posts.makeRoundView(r: 12)

        self.musicPlayerController.beginGeneratingPlaybackNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(setSongInfo), name: .MPMusicPlayerControllerPlaybackStateDidChange, object: self.musicPlayerController)
        NotificationCenter.default.addObserver(self, selector: #selector(setSongInfo), name: .MPMusicPlayerControllerNowPlayingItemDidChange, object: self.musicPlayerController)
        NotificationCenter.default.addObserver(self, selector: #selector(logoutProfile), name: NSNotification.Name(rawValue: "logoutProfile"), object: nil)

        self.view.layoutIfNeeded()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .MPMusicPlayerControllerPlaybackStateDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: .MPMusicPlayerControllerNowPlayingItemDidChange, object: nil)
        
        if isMusicPlaying{
            musicPlayerController.endGeneratingPlaybackNotifications()
        }
        
        self.removeObserver()
    }
    
    func initLink(){
        if !user.website.isEmpty{
            if user.website.hasPrefix("http://") || user.website.hasPrefix("https://"){
                self.btnLink.setTitle(user.website, for: .normal)
                self.linkViewHeight.constant = 32
            }
            else if let url = URL(string: String(format: "http://%@", user.website)){
                self.btnLink.setTitle("\(url.absoluteString)", for: .normal)
                self.linkViewHeight.constant = 32
            }
            else{
                self.linkViewHeight.constant = 0
            }
        }
        else{
            self.linkViewHeight.constant = 0
        }
    }
    
    
    var userTracker: ListenerRegistration? = nil
    func removeObserver(){
        userTracker?.remove()
        userTracker = nil
        
        TargetUserTracker?.remove()
        TargetUserTracker = nil
    }
    
    @objc func logoutProfile(){
        NotificationCenter.default.removeObserver(self, name: .MPMusicPlayerControllerPlaybackStateDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: .MPMusicPlayerControllerNowPlayingItemDidChange, object: nil)
        
        NotificationCenter.default.removeObserver(self)
        if isMusicPlaying{
            musicPlayerController.endGeneratingPlaybackNotifications()
        }
        
        self.removeObserver()
    }
    
    var blocked: Bool = false
    var TargetUserTracker: ListenerRegistration? = nil
    func trackUserData() {
        self.lblNumPosts.text = "   \(user.num_posts >= 0 ? user.num_posts : 0) Posts   "
        self.lblNumFollowing.text = "\(user.num_following >= 0 ? user.num_following : 0)"
        self.lblNumFollowers.text = "\(user.num_followers >= 0 ? user.num_followers : 0)"
        
        if userTracker == nil{
            userTracker = FUSER_REF
                .document(self.user.uid)
                .addSnapshotListener({ (doc, _) in
                    if let data = doc?.data(){
                        let usr = User(uid: self.user.uid, data: data)
                        DBUsers[self.user.uid] = usr

                        self.lblNumFollowing.text = "\(usr.num_following >= 0 ? usr.num_following : 0)"
                        self.lblNumFollowers.text = "\(usr.num_followers >= 0 ? usr.num_followers : 0)"
                        self.lblNumPosts.text = "   \(usr.num_posts >= 0 ? usr.num_posts : 0) Posts   "
                        
                        if self.user.uid == Me.uid{
                            Me = self.user
                            Me.saveLocal()
                        }
                    }
                })
        }
        
        guard self.user.uid != Me.uid else { return }
        if TargetUserTracker != nil { return }
        
        TargetUserTracker = FUSER_REF
            .document(self.user.uid)
            .collection(User.key_collection_blocked)
            .document(Me.uid)
            .addSnapshotListener { (doc, _) in
                if doc?.exists == true{
                    self.blocked = true
                    self.showError(msg: "You are not allowed to see this user profile.")
                    if Me.uid != vipUser{
                        self.initButtons()
                        self.updateUserFollowingStatus()
                    }
                }
                else{
                    if self.blocked{
                        self.blocked = false
                        
                        self.initButtons()
                        self.updateUserFollowingStatus()
                    }
                }
            }
    }
    
    // MARK: - Button Handling
    @IBAction func opOpenMenu(_ sender: Any) {
        if self.user.uid == Me.uid{
            let sb = UIStoryboard(name: "Menu", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "VC_Menu") as! VC_Menu
            
            self.navigationController?.pushViewController(vc, animated: true)
        }
        else{
            //other users
            let view: cv_profile_more = try! SwiftMessages.viewFromNib()
            
            var config = SwiftMessages.defaultConfig
            config.presentationContext = .window(windowLevel: UIWindow.Level.statusBar)
            config.duration = .forever
            config.presentationStyle = .bottom
            config.dimMode = .gray(interactive: true)
            config.interactiveHide = true
            
            view.lbl_block.text = MyBlocks.keys.contains(self.user.uid) ? "Unblock User" : "Block User"

            SwiftMessages.show(config: config, view: view)
            
            view.opDoneAction = {
                SwiftMessages.hideAll()
            }
            
            view.opBlockUserAction = {
                if MyBlocks.keys.contains(self.user.uid){
                    self.user.unblock()
                }
                else{
                    self.user.block()
                }
                
                self.initButtons()
                self.updateUserFollowingStatus()
                
                SwiftMessages.hideAll()
            }
            view.opReportAccountAction = {
                SwiftMessages.hideAll()
                
                if MFMailComposeViewController.canSendMail() {
                    let mail = MFMailComposeViewController()
                    mail.mailComposeDelegate = self
                    mail.setToRecipients([EmailAddress.ReportPost])
                    mail.setSubject("REPORTING Account: \(self.user.uid)")
                    mail.setMessageBody("<p>Reporting Account: \(self.user.uid)</p><p>With Content: xxx </p><p>Type additional comments below:</p>", isHTML: true)
                    self.present(mail, animated: true, completion: nil)
                } else {
                    self.showError(title: "Mail Not Setup", msg: "You do not have an e-mail account setup for Apple's Mail app.  Please report userID: \(self.user.uid) to \(EmailAddress.ReportPost)")
                }
            }
        }
    }
    @IBAction func opMusic(_ sender: Any) {
        v_music.alpha = 0
        v_music.isHidden = true
        UIView.transition(with: self.v_music, duration: 0.5, options: .transitionCrossDissolve, animations: {
            self.setupMusic()
            self.v_music.isHidden = false
            self.v_music.alpha = 1
        }, completion: { (_) in
        })
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "showMusicCover"), object: nil)
    }
    @IBAction func opMessage(_ sender: Any) {
        if self.user.uid == Me.uid{
            v_music.alpha = 0
            v_music.isHidden = true
            UIView.transition(with: self.v_music, duration: 0.5, options: .transitionCrossDissolve, animations: {
                self.setupMusic()
                self.v_music.isHidden = false
                self.v_music.alpha = 1
            }, completion: { (_) in
            })
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "showMusicCover"), object: nil)
        }
        else{
            self.btnSendMsg.isUserInteractionEnabled = false
            self.openMessage(user: self.user)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.btnSendMsg.isUserInteractionEnabled = true
            }
        }
    }
    @IBAction func opLink(_ sender: Any) {
        if let url = URL(string: self.btnLink.title(for: .normal)!){
            self.openURL(url: url)
        }
    }

    @IBAction func opOpenFollowers(_ sender: Any) {
        let sb = UIStoryboard(name: "TB_CL", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "VC_Follow") as! VC_Follow
        
        vc.ltitle = "Followers"
        vc.user = self.user
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
    @IBAction func opOpenFollowing(_ sender: Any) {
        let sb = UIStoryboard(name: "TB_CL", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "VC_Follow") as! VC_Follow
        
        vc.ltitle = "Following"
        vc.user = self.user
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
    @IBAction func opBack(_ sender: Any) {
        if Me.uid == vipUser && self.user.uid != Me.uid{
            let sb = UIStoryboard(name: "TB_CL", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "VC_Hashtag") as! VC_Hashtag
            
            vc.isLikedPosts = true
            vc.uid = self.user.uid
            self.navigationController?.pushViewController(vc, animated: true)
        }
        else{
            self.navigationController?.popViewController(animated: true)
        }
    }

    @IBAction func opFollow(_ sender: Any) {
        self.btnEditFollow.isUserInteractionEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.btnEditFollow.isUserInteractionEnabled = true
        }
        
        if btnEditFollow.titleLabel?.text == "Edit"{
            let sb = UIStoryboard(name: "Main", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "VC_EditProfile") as! VC_EditProfile
            
            vc.opUpdateProfile = {
                self.user = Me
            }
            
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
        else if btnEditFollow.titleLabel?.text == "Follow" {
            if !self.user.is_private{
                self.user.num_followers += 1
                self.lblNumFollowers.text = "\(self.user.num_followers)"
            }
            user.follow()
            self.updateUserFollowingStatus()
        } else if btnEditFollow.titleLabel?.text == "Following"{
            self.user.num_followers -= 1
            self.lblNumFollowers.text = "\(self.user.num_followers)"

            user.follow(follow: false)
            self.updateUserFollowingStatus()
        }
    }

    var isRemoved: Bool = false
    @IBAction func opRemoveUser(_ sender: Any) {
        if isRemoved{
            return
        }
        if adminUser.contains(Me.uid) && Me.uid != self.user.uid{
            let removeAlert = UIAlertController(title: "Delete", message: "Are you sure you want to delete this user?", preferredStyle: .alert)
            removeAlert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (_) in
                self.isRemoved = true
                self.user.removeUserAndPosts { (res) in
                    DBUsers.removeValue(forKey: self.user.uid)
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
    }
    
    func initButtons(){
        btnSendMsg.isEnabled = true
        btn_song.isEnabled = true

        if self.blocked{
            btnSendMsg.setImage(UIImage(named: "mic_profile_message_blocked"), for: .normal)
            btn_song.setImage(UIImage(named: "mic_profile_music_blocked"), for: .normal)
            
            btnSendMsg.isEnabled = false
            btn_song.isEnabled = false
            
            v_blocked.isHidden = false
        }
        else if self.user.uid == Me.uid{
            self.v_private.isHidden = true
            btn_song.isHidden = true

            if Me.songs.count > 0{
                btnSendMsg.isHidden = false
                btnSendMsg.setImage(UIImage(named: "mic_profile_music"), for: .normal)
            }
            else{
                btnSendMsg.isHidden = true
            }
        }
        else{
            if MyBlocks.keys.contains(self.user.uid){
                btnSendMsg.setImage(UIImage(named: "mic_profile_message_blocked"), for: .normal)
                btn_song.setImage(UIImage(named: "mic_profile_music_blocked"), for: .normal)
                
                btnSendMsg.isEnabled = false
                btn_song.isEnabled = false
                
                v_blocked.isHidden = false
            }
            else{
                btnSendMsg.setImage(UIImage(named: "mic_profile_message"), for: .normal)
                btn_song.setImage(UIImage(named: "mic_profile_music"), for: .normal)
                
                v_blocked.isHidden = true
                
                
                self.user.isFollowing { (fType) in
                    if fType == .Following{
                        self.v_private.isHidden = true
                    }
                    else{
                        if Me.uid == vipUser{
                            self.v_private.isHidden = true
                        }
                        else{
                            self.v_private.isHidden = !self.user.is_private
                        }
                    }
                }
                
                self.btn_song.isHidden = self.user.songs.count == 0
                self.btnSendMsg.isHidden = false
            }
        }
    }

    func updateUserFollowingStatus(){
        guard let cid = CUID else { return }
        if self.blocked{
            self.btnEditFollow.setTitle("Blocked", for: .normal)
            self.btnEditFollow.setTitleColor(UIColor(red: 97/255, green: 105/255, blue: 123/255, alpha: 0.4), for: .normal)
            self.v_editFollow.backgroundColor = UIColor(red: 97/255, green: 105/255, blue: 123/255, alpha: 0.2)
            self.btnEditFollow.layer.borderWidth = 0
        }
        else if self.user.uid == cid{
            self.btnEditFollow.setTitle("Edit", for: .normal)
            self.v_editFollow.backgroundColor = UIColor.label.withAlphaComponent(0.1)
            self.btnEditFollow.setTitleColor(UIColor(named: "col_lbl_post")!, for: .normal)
            self.btnEditFollow.layer.borderWidth = 0
        }
        else{
            if MyBlocks.keys.contains(self.user.uid){
                self.btnEditFollow.setTitle("Blocked", for: .normal)
                self.btnEditFollow.setTitleColor(UIColor(red: 97/255, green: 105/255, blue: 123/255, alpha: 0.4), for: .normal)
                self.v_editFollow.backgroundColor = UIColor(red: 97/255, green: 105/255, blue: 123/255, alpha: 0.2)
                self.btnEditFollow.layer.borderWidth = 0
            }
            else{
                user.isFollowing { (type) in
                    switch(type){
                    case .Following:
                        self.btnEditFollow.setTitle("Following", for: .normal)
                        self.btnEditFollow.setTitleColor(UIColor.white, for: .normal)
                        self.v_editFollow.backgroundColor = UIColor(red: 0, green: 157/255, blue: 255/255, alpha: 1)
                        self.btnEditFollow.layer.borderWidth = 0
                        break
                    case .AbleToFollow:
                        self.btnEditFollow.setTitle("Follow", for: .normal)
                        self.btnEditFollow.setTitleColor(UIColor(red: 0, green: 157/255, blue: 255/255, alpha: 1), for: .normal)
                        self.btnEditFollow.layer.borderWidth = 2
                        self.btnEditFollow.layer.borderColor = UIColor(red: 0, green: 157/255, blue: 255/255, alpha: 1).cgColor
                        self.v_editFollow.backgroundColor = UIColor(red: 0, green: 157/255, blue: 255/255, alpha: 0.2)
                        break
                    case .Requested:
                        self.btnEditFollow.titleLabel?.font = UIFont.cFont_regular(size: 13)
                        self.btnEditFollow.setTitle("Requested", for: .normal)
                        self.btnEditFollow.setTitleColor(UIColor(red: 0, green: 157/255, blue: 255/255, alpha: 1), for: .normal)
                        self.v_editFollow.backgroundColor = UIColor(red: 0, green: 157/255, blue: 255/255, alpha: 0.2)
                        self.btnEditFollow.layer.borderWidth = 0
                        break
                    case .Declined:
                        self.btnEditFollow.setTitle("Follow", for: .normal)
                        self.btnEditFollow.setTitleColor(UIColor(red: 0, green: 157/255, blue: 255/255, alpha: 1), for: .normal)
                        self.btnEditFollow.layer.borderWidth = 2
                        self.btnEditFollow.layer.borderColor = UIColor(red: 0, green: 157/255, blue: 255/255, alpha: 1).cgColor
                        self.v_editFollow.backgroundColor = UIColor(red: 0, green: 157/255, blue: 255/255, alpha: 0.2)
                        
                        break
                    }
                }
            }
        }
    }

    // MARK: - Music related functions
    func setupMusic(){
        if self.user == nil { return }
        guard user.songs.count > 0 else { return }
        
        carouselSongs.isPagingEnabled = true
        carouselSongs.bounces = true
        carouselSongs.type = .custom
        
        carouselSongs.delegate = self
        carouselSongs.dataSource = self
        
        carouselSongs.reloadData()

        v_collection_songs.provider = BasicProvider(
            dataSource: user.songs,
            viewSource: ClosureViewSource(viewGenerator: { (song: FirebaseSong, index: Int) -> cv_song_player_item in
                let v = Bundle.main.loadNibNamed("cv_song_player_item", owner: self, options: nil)?[0] as! cv_song_player_item
                return v
            }, viewUpdater: { (v: cv_song_player_item, song: FirebaseSong, index: Int) in
                v.setupSong(song: song)
                v.opSongSelectedAction = {
                    self.carouselSongs.currentItemIndex = index
                }
            }),
            sizeSource: { (index: Int, song: FirebaseSong, size: CGSize) -> CGSize in
                return CGSize(width: size.height, height: size.height)
            },
            layout: FlowLayout(spacing: 12).transposed()
        )
    }
    func checkMusicAuth() {
        if AuthorizationManager.shared.isAuthorized {
            if !self.isMusicLoaded {
                self.loadProfileMusic()
            }
            
            return
        }
        
        print("~>Checking music auth")
        AuthorizationManager.authorize(completionIfAuthorized: {
            print("~>Authorized")
            AuthorizationManager.withCapabilities { [weak self] (capabilities) in
                
                print("~>Capabilities")
                
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    
                    if !self.isMusicLoaded {
                        self.loadProfileMusic()
                    }
                }
                
            }
        }) {
            print("~>Not authorized.")
        }
    }
    func loadProfileMusic() {
        guard !self.isMusicLoaded else { return }
        guard let user = self.user else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.loadProfileMusic()
                return
            }
            return
        }
        
        SKCloudServiceController().requestStorefrontCountryCode { (result, error) in
            if let error = error {
                print("~>There was an error getting the country code: \(error)")
                self.countryCodeErrorCount += 1
                
                if self.countryCodeErrorCount <= 5 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.loadProfileMusic()
                    }
                    return
                } else {
                    self.countryCodeErrorCount = 0
                }
            }
            
            let countryCode: String
            if let code = result {
                countryCode = code
            } else {
                countryCode = "us"
            }
            
            self.isMusicLoaded = true
            var songs: [Song] = []
            if user.songs.count > 0, user.songs[0].country == countryCode{
                user.songs.forEach { (song) in
                    songs.append(Song(from: song))
                }
                
                if songs.count > 0 {
                    if self.user.uid == Me.uid{
                        self.btnSendMsg.isHidden = false
                    }
                    else{
                        self.btn_song.isHidden = false
                    }
                }
                
                self.startPlayback(withSongs: songs)
            }
            else if let user = self.user, user.songs.count > 0 {
                // user has songs, they just aren't from the logged in user's country
                self.searchForSongs()
            } else if self.user == nil {
                // make one extra check
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isMusicLoaded = false
                    self.loadProfileMusic()
                }
            } else {
                if self.user.uid == Me.uid{
                    self.btnSendMsg.isHidden = true
                }
                else{
                    self.btn_song.isHidden = true
                }
            }
        }
    }
    func reloadMusic() {
        if musicPlayerController.playbackState == .playing {
            return
//            musicPlayerController.stop()
        }
        isMusicLoaded = false
        loadProfileMusic()
    }
    func searchForSongs() {
        guard let user = user else { return }
        var songs: [String] = []
        user.songs.forEach { (song) in
            songs.append("\(song.artworkUrl) \(song.title)")
        }
        guard songs.count > 0 else {
            return
        }
        Song.search(forSongs: songs, completion: { [weak self] (songs, errors) in
            guard let self = self else { return }
            guard songs.count > 0 else {
                self.isMusicLoaded = false
                print("~>Error gettings songs: \(errors)")
                return
            }
            self.startPlayback(withSongs: songs)
        })
    }
    func startPlayback(withSongs songs: [Song]) {
        let songIDs = songs.map { (song) -> String in
            return song.id
        }
        musicPlayerController.setQueue(with: songIDs)
        musicPlayerController.repeatMode = .all
        musicPlayerController.prepareToPlay { (err) in
            if err != nil{
                let errorCode: Int = (err! as NSError).code
                print("~~~~~~~~~~~~>Music player error - \(err!.localizedDescription) : errorCode - \(errorCode)")
                return
            }
            else{
                print("~~~~~~~~~~~~>Music player SUCCESS!")
                self.musicPlayerController.beginGeneratingPlaybackNotifications()
                self.isMusicPlaying = true
                self.playMusic()
                
                NotificationCenter.default.addObserver(forName: .MPMusicPlayerControllerPlaybackStateDidChange, object: self.musicPlayerController, queue: OperationQueue.main) { [weak self] (_) in
                    guard let self = self else { return }
                    self.setSongInfo()
                }
            }
        }
    }
    
    @IBAction func opCloseMusicPlayerView(_ sender: Any) {
        v_music.alpha = 1
        v_music.isHidden = false
        UIView.transition(with: self.v_music, duration: 0.5, options: .transitionCrossDissolve, animations: {
            self.v_music.alpha = 0
        }, completion: { (_) in
            self.v_music.isHidden = true
        })
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "hideMusicCover"), object: nil)
    }
    
    func findSongWithPersistentIdString(persistentIDString: String) -> MPMediaItem? {
        let predicate = MPMediaPropertyPredicate(value: persistentIDString, forProperty: MPMediaItemPropertyPersistentID)
        let songQuery = MPMediaQuery()
        songQuery.addFilterPredicate(predicate)
        
        var song: MPMediaItem?
        if let items = songQuery.items, items.count > 0{
            song = items[0]
        }
        return song
    }
    func playMusic(newItem: Bool = false){
        guard isMusicLoaded else { return }
//        if newItem{
//            let sId = user.songs[self.selectedMusicIndex].id
//            self.musicPlayerController.skipToNextItem()
//        }
        if newItem || self.selectedMusicIndex != self.musicPlayerController.indexOfNowPlayingItem{
            let fSong = self.user.songs[self.selectedMusicIndex]
            var found: Bool = false
            self.user.songs.forEach { (item) in
                if found { return }
                self.musicPlayerController.skipToNextItem()
                if let song = self.musicPlayerController.nowPlayingItem, let title = song.title, let artist = song.artist{
                    if title == fSong.title && artist == fSong.artist{
                        found = true

                        return
                    }
                }
            }
            print(found ? "YES!!! Found a song" : "NO!!! Can't find a song")
        }
        self.isMusicPlaying = true
        musicPlayerController.play()

        setSongInfo()
    }
    
    @objc func setSongInfo() {
        DispatchQueue.main.async {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.carouselSongs.reloadData()
            }
        }
    }
    
    
    //MARK: - setup BarView
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?){
        super.traitCollectionDidChange(previousTraitCollection)
        settings.style.buttonBarBackgroundColor = buttonBarColor
        settings.style.buttonBarItemBackgroundColor = buttonBarColor
    }
    func setupBarButtonView(){
        let sb = UIStoryboard(name: "Main", bundle: nil)
        child_1 = sb.instantiateViewController(withIdentifier: "VC_Profile_Media") as? VC_Profile_Media
        child_2 = sb.instantiateViewController(withIdentifier: "VC_Profile_State") as? VC_Profile_State
//        child_1.parentDelegate = self
//        child_2.parentDelegate = self
        
        buttonBarItemSpec = ButtonBarItemSpec.nibFile(nibName: "cell_youtube_icon", bundle: Bundle(for: cell_youtube_icon.self), width: { _ in
            return self.buttonBarView.bounds.width / 2
        })

        // change selected bar color
        settings.style.buttonBarBackgroundColor = buttonBarColor
        settings.style.buttonBarItemBackgroundColor = buttonBarColor
        settings.style.selectedBarBackgroundColor = UIColor.clear//UIColor(named: "col_profile_selected")!
        settings.style.selectedBarHeight = 0.0
        settings.style.buttonBarMinimumLineSpacing = 0
        settings.style.buttonBarMinimumInteritemSpacing = 0
        settings.style.buttonBarItemTitleColor = UIColor(named: "col_profile_selected")!
        settings.style.buttonBarItemsShouldFillAvailableWidth = false
        settings.style.buttonBarLeftContentInset = 0
        settings.style.buttonBarRightContentInset = 0

        var backConfirmed: Bool = false
        changeCurrentIndexProgressive = {(oldCell: cell_youtube_icon?, newCell: cell_youtube_icon?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) -> Void in
            if !backConfirmed &&
                self.currentIndex == 0 &&
                oldCell == nil &&
                ((progressPercentage > 0 && progressPercentage < 0.5) ||
                    (progressPercentage < 0 && progressPercentage > -0.5)) &&
                self.user.uid != CUID{
                
                backConfirmed = true
                self.navigationController?.popViewController(animated: true)
                
                return
            }

            guard changeCurrentIndex == true else { return }
            oldCell?.iconImage.tintColor = .darkGray
            oldCell?.backgroundColor = .clear

            newCell?.iconImage.tintColor = UIColor.active()
            newCell?.backgroundColor = UIColor.clear//UIColor(named: "col_profile_selected")!
        }
    }
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        return [child_1, child_2]
    }
    override func configure(cell: cell_youtube_icon, for indicatorInfo: IndicatorInfo) {
        cell.iconImage.image = indicatorInfo.image?.withRenderingMode(.alwaysTemplate)
        cell.iconImage.tintColor = .white
    }
    override func updateIndicator(for viewController: PagerTabStripViewController, fromIndex: Int, toIndex: Int, withProgressPercentage progressPercentage: CGFloat, indexWasChanged: Bool) {
        super.updateIndicator(for: viewController, fromIndex: fromIndex, toIndex: toIndex, withProgressPercentage: progressPercentage, indexWasChanged: indexWasChanged)
        if indexWasChanged && toIndex > -1 && toIndex < viewControllers.count {
            let child = viewControllers[toIndex] as! IndicatorInfoProvider // swiftlint:disable:this force_cast
            UIView.performWithoutAnimation({ [weak self] () -> Void in
                guard let me = self else { return }
                me.navigationItem.leftBarButtonItem?.title =  child.indicatorInfo(for: me).title
            })
        }
    }
}

extension VC_Profile: iCarouselDataSource, iCarouselDelegate {
    func numberOfItems(in carousel: iCarousel) -> Int {
        if self.user == nil && self.user.songs.count == 0{
            return 0
        }
        return user.songs.count
    }
    func carouselCurrentItemIndexDidChange(_ carousel: iCarousel) {
    }
    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        let v = Bundle.main.loadNibNamed("cv_user_song", owner: self, options: nil)?[0] as! cv_user_song
        v.frame.size = CGSize(width: carousel.bounds.width - 90, height: carousel.bounds.height)
        if self.musicPlayerController.playbackState == .playing{
            if self.musicPlayerController.indexOfNowPlayingItem == index{
                v.setupSong(song: user.songs[index], isPlaying: true)
            }
            else{
                v.setupSong(song: user.songs[index], isPlaying: false)
            }
        }
        else{
            v.setupSong(song: user.songs[index], isPlaying: false)
        }
        v.opPlayAction = {
            if self.isMusicLoaded && !self.musicNeedsReload && self.selectedMusicIndex == index && self.musicPlayerController.playbackState == .paused{
                self.musicPlayerController.play()
                return
            }
            else{
                self.selectedMusicIndex = index
                if self.isMusicLoaded{
                    self.playMusic(newItem: true)
                }
                else{
                    self.isMusicLoaded = false
                    self.checkMusicAuth()
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.carouselSongs.reloadData()
            }
        }
        v.opPauseAction = {
            if self.musicPlayerController.playbackState == .playing{
                self.musicPlayerController.pause()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.carouselSongs.reloadData()
            }
        }
        return v
    }
    func carousel(_ carousel: iCarousel, valueFor option: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
        switch option {
            case .spacing:
                return value * 1.05
            
            default:
                break
        }
        
        return value
    }
    func carousel(_ carousel: iCarousel, didSelectItemAt index: Int) {
    }
    func carousel(_ carousel: iCarousel, itemTransformForOffset offset: CGFloat, baseTransform transform: CATransform3D) -> CATransform3D {
        let spacing: CGFloat = 0.15
        let distance: CGFloat = 90
        let clampedOffset = min(1.0, max(-1.0, offset))
        
        var offset = offset
        
        let z: CGFloat = CGFloat(-abs(clampedOffset)) * distance
        
        offset += clampedOffset * spacing
        
        return CATransform3DTranslate(transform, offset * carousel.itemWidth, 0.5, z)
    }
}
