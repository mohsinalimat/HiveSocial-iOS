//
//  cell_media_table1.swift
//  HIVE
//
//  Created by elitemobile on 12/8/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import UIKit
import Firebase

class cell_media_table: UITableViewCell {
    
    //MARK: - variables
    @IBOutlet weak var v_out: UIView!
    @IBOutlet weak var img_avatar: UIImageView!
    @IBOutlet weak var lbl_uname: UILabel!
    
    @IBOutlet weak var img_content: UIImageView!
    @IBOutlet weak var vid_content: AGVideoPlayerView!
    @IBOutlet weak var img_gif: UIImageView!
    
    @IBOutlet weak var btn_likes: UIButton!
    @IBOutlet weak var btn_comments: UIButton!
    @IBOutlet weak var btn_repost: UIButton!
    @IBOutlet weak var btn_share: UIButton!
    @IBOutlet weak var btn_reposter: UIButton!
    @IBOutlet weak var btn_openUser: UIButton!
    
    @IBOutlet weak var lbl_desc_media: ActiveLabel!
    @IBOutlet weak var lbl_desc_txt: ActiveLabel!
    @IBOutlet weak var lbl_reposted: UILabel!
    
    @IBOutlet weak var btn_num_likes: UIButton!
    @IBOutlet weak var btn_view_comments: UIButton!
    
    @IBOutlet weak var v_media: UIView!
    @IBOutlet weak var v_media_height_constraint: NSLayoutConstraint!
    @IBOutlet weak var v_reposted_height_constraint: NSLayoutConstraint!
    
    var opOpenUserAction: ((User?) -> Void)?
    var opMoreAction: ((Post?) -> Void)?
    var opOpenCommentsAction: (() -> Void)?
    var opOpenLikedUsersAction: (() -> Void)?
    var opRepostAction: (() -> Void)?
    var opOpenLinkAction: ((URL) -> Void)?
    var opOpenHashTag: ((String) -> Void)?
    var opOpenLikedUsers: (() -> Void)?
    var opShareToAction: (() -> Void)?
    
    var isDoubleTap: Bool = false
    var mustAutoPlay: Bool = false
    
    //MARK: - functions
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initComponents()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.v_out.layer.borderColor = UIColor(named: "mcol_card_border")!.cgColor
    }
    
    func initComponents(){
        v_out.makeRoundView(r: 4)
        v_out.layer.borderWidth = 0.5
        v_out.layer.borderColor = UIColor(named: "mcol_card_border")!.cgColor
        
        img_avatar.makeCircleView()
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(self.handleDoubleTap))
        doubleTap.numberOfTouchesRequired = 1
        doubleTap.numberOfTapsRequired = 2
        self.img_content.addGestureRecognizer(doubleTap)
        
        lbl_desc_media.lineSpacing = 0
        lbl_desc_media.lineSpacing = 0
        lbl_desc_media.lineBreakMode = NSLineBreakMode.byWordWrapping
        lbl_desc_media.enabledTypes = [.mention, .hashtag, .url]
        lbl_desc_media.configureLinkAttribute = { (type, attributes, isSelected) in
            var atts = attributes
            switch type {
            case .mention:
                atts[NSAttributedString.Key.foregroundColor] = UIColor.label
                atts[NSAttributedString.Key.font] = UIFont.cFont_bold(size: 16)
                break
            case .hashtag, .url:
                atts[NSAttributedString.Key.foregroundColor] = UIColor.active()
                atts[NSAttributedString.Key.font] = UIFont.cFont_medium(size: 16)
                break
            default:
                atts[NSAttributedString.Key.font] = UIFont.cFont_regular(size: 16)
                break
            }
            return atts
        }
        lbl_desc_txt.lineSpacing = 0
        lbl_desc_txt.lineSpacing = 0
        lbl_desc_txt.lineBreakMode = NSLineBreakMode.byWordWrapping
        lbl_desc_txt.enabledTypes = [.mention, .hashtag, .url]
        lbl_desc_txt.configureLinkAttribute = { (type, attributes, isSelected) in
            var atts = attributes
            switch type {
            case .mention:
                atts[NSAttributedString.Key.foregroundColor] = UIColor.label
                atts[NSAttributedString.Key.font] = UIFont.cFont_bold(size: 16)
                break
            case .hashtag, .url:
                atts[NSAttributedString.Key.foregroundColor] = UIColor.active()
                atts[NSAttributedString.Key.font] = UIFont.cFont_medium(size: 16)
                break
            default:
                atts[NSAttributedString.Key.font] = UIFont.cFont_regular(size: 16)
                break
            }
            return atts
        }
        
        v_reposted_height_constraint.constant = 0
    }

    //MARK: - setup
    var post: Post!
    func setPost(post: Post, thumb: UIImage? = nil){
        if let pst = DBPosts[post.pid]{
            self.post = pst
        }
        else{
            self.post = post
        }
        
        self.img_content.image = nil
        self.img_avatar.image = UIImage.avatar()
        btn_view_comments.setTitle(Date(timeIntervalSince1970: self.post.created).timeAgoToDisplay(), for: .normal)
        v_reposted_height_constraint.constant = self.post.opid.isEmpty ? 0 : 36
        
        if let opst = self.post.opost{
            lbl_reposted.text = self.post.ouname + " Reposted"
            
            if self.post.ouid == Me.uid{
                self.post.oavatar = Me.thumb.isEmpty ? Me.avatar : Me.thumb
                self.post.ouname = Me.uname
            }
            img_avatar.loadImg(str: opst.oavatar, user: true)
            lbl_uname.text = opst.ouname
        }
        else{
            if self.post.ouid == Me.uid{
                self.post.oavatar = Me.thumb.isEmpty ? Me.avatar : Me.thumb
                self.post.ouname = Me.uname
            }
            
            img_avatar.loadImg(str: self.post.oavatar, user: true)
            lbl_uname.text = self.post.ouname
        }
        
        setupLike()
        setupComment()
        setupReposts()
//        setupShare()
        
        let type = self.post.getType()
        
        img_gif.isHidden = type != .GIF
        lbl_desc_txt.isHidden = type != .TEXT
        lbl_desc_media.isHidden = type == .TEXT
        
        switch(type){
        case .TEXT:
            v_media_height_constraint.constant = Utils.calculateCellHeight(txt: self.post.getDesc(), width: UIScreen.main.bounds.width - 8 - 32)
            
            img_content.isHidden = true
            vid_content.isHidden = true
            vid_content.cleanView()
            
            lbl_desc_txt.customize { (lbl) in
                self.setupDesc(lbl: lbl)
            }
            break
        case .GIF, .IMAGE, .VIDEO:
            lbl_desc_txt.isHidden = true
            lbl_desc_media.isHidden = false

            var ratio: Double = 1
            if let fratio = self.post.ratio.first{
                ratio = fratio
            }
            else if let opost = self.post.opost, let ofratio = opost.ratio.first{
                ratio = ofratio
            }

            if type == .VIDEO{
                v_media_height_constraint.constant = (UIScreen.main.bounds.width - 8)
            }
            else{
                v_media_height_constraint.constant = (UIScreen.main.bounds.width - 8) * CGFloat(ratio)
            }
            
            if let opost = self.post.opost{
                setupMedia(pst: opost, thumb: thumb)
            }
            else{
                setupMedia(pst: self.post, thumb: thumb)
            }
            
            lbl_desc_media.customize { (lbl) in
                self.setupDesc(lbl: lbl)
            }
            break
        }
        
        self.layoutSubviews()
    }
    func setupMedia(pst: Post, thumb: UIImage? = nil){
        img_content.isHidden = true
        vid_content.isHidden = true
        vid_content.cleanView()
        
        switch pst.type {
        case .IMAGE:
            img_content.isHidden = false
            if let imgUrl = pst.media.first as? String, !imgUrl.isEmpty{
                if Me.uid == vipUser{
                    img_content.loadImg(str: imgUrl, thumbImg: thumb)
                }
                else{
                    if let thumbUrl = pst.thumb.first as? String, !thumbUrl.isEmpty{
                        if thumb != nil{
                            img_content.loadImg(str: imgUrl, thumbImg: thumb)
                        }
                        else{
                            img_content.loadImg(str: imgUrl, thumb: thumbUrl)
                        }
                    }
                    else{
                        img_content.loadImg(str: imgUrl, thumbImg: thumb)
                    }
                }
            }
            else{
                print("This is Error - IMAGE")
                print(pst.pid)
            }
            break
        case .VIDEO:
            img_content.isHidden = true
            vid_content.isHidden = false
            if let vidUrl = pst.media.first as? [String: String], vidUrl.count > 0{
                vid_content.previewImageView.image = thumb
                vid_content.previewImageUrl = URL(string: vidUrl.values.first!)
//                if Me.uid != vipUser{
                    vid_content.videoUrl = URL(string: vidUrl.keys.first!)
                    if mustAutoPlay{
                        vid_content.shouldAutoplay = false
                    }
                    else{
                        vid_content.shouldAutoplay = true
                    }
                    vid_content.shouldAutoRepeat = true
                    vid_content.showsCustomControls = true
                    vid_content.shouldSwitchToFullscreen = true
//                }
            }
            else{
                print("This is Error - VIDEO - Real Error")
                print(pst.pid)
            }
            break
        case .GIF:
            img_content.isHidden = false
            if let gifUrl = pst.media.first as? String, !gifUrl.isEmpty{
                img_content.loadImg(str: gifUrl)
            }
            else{
                print("This is Error - GIF")
                print(pst.pid)
            }
            break
        default:
            print("This is Error - REAL ERROR - TABLECELL")
            print(pst.pid)
            break
        }
    }
    func setupDesc(lbl: ActiveLabel) {
        lbl.text = post.getDesc()
        
        lbl.handleURLTap { (url) in
            print("Clicked Link")
            self.opOpenLinkAction?(url)
        }
        
        lbl.handleMentionTap { [weak self] (mentionName) in
            print("Clicked Username")
            guard let self = self else { return }
            if mentionName == self.post.ouname {
                Utils.fetchUser(uid: self.post.ouid) { (rusr) in
                    guard let usr = rusr else { return }
                    self.opOpenUserAction?(usr)
                }
            } else {
                Utils.fetchUser(uname: mentionName) { (rusr) in
                    guard let usr = rusr else { return }
                    self.opOpenUserAction?(usr)
                }
            }
        }
        
        lbl.handleHashtagTap { (hashtag) in
            print("Clicked HashTag")
            self.opOpenHashTag?(hashtag)
        }
        
        lbl.sizeToFit()
    }
    func setupLike() {
        self.btn_likes.setImage(UIImage(named: "nic_like"), for: .normal)
        btn_num_likes.setTitle("\(post.num_likes) Likes", for: .normal)
        if post.ouid == Me.uid || Me.uid == vipUser{
            Utils.reloadPost(pid: self.post.pid) { (rpst) in
                guard let pst = rpst else { return }
                if pst.num_likes != self.post.num_likes{
                    self.btn_num_likes.setTitle("\(pst.num_likes) Likes", for: .normal)
                    self.post.num_likes = pst.num_likes
                    DBPosts[pst.pid] = self.post
                }
            }
        }
        
        post.isLikedPost { (res) in
            self.btn_likes.setImage(UIImage(named: res ? "nic_liked" : "nic_like"), for: .normal)
        }
    }
    func setupComment(){
        self.btn_comments.setImage(UIImage(named: "nic_comment"), for: .normal)
        post.isCommented { (res) in
            self.btn_comments.setImage(UIImage(named: res ? "nic_commented" : "nic_comment"), for: .normal)
        }
    }
    func setupReposts(){
        self.btn_repost.setImage(UIImage(named: "nic_repost"), for: .normal)
        post.isReposted { (res) in
            self.btn_repost.setImage(UIImage(named: res ? "nic_reposted" : "nic_repost"), for: .normal)
        }
    }
    func setupShare(){
        self.btn_share.setImage(UIImage(named: "nic_share"), for: .normal)
        post.isShared { (res) in
            self.btn_share.setImage(UIImage(named: res ? "nic_shared" : "nic_share"), for: .normal)
        }
    }
    
    //MARK: - button actions
    var isDoingUser: Bool = false
    var isDoingLike: Bool = false
    var isDoingReposter: Bool = false
    @IBAction func opOpenUser(_ sender: Any) {
        guard let pst = post else { return }
        if isDoingUser{
            return
        }
        isDoingUser = true
        
        btn_openUser.isUserInteractionEnabled = false
        if let opostUid = pst.opost?.ouid{
            Utils.fetchUser(uid: opostUid) { (rusr) in
                self.isDoingUser = false
                
                self.btn_openUser.isUserInteractionEnabled = true
                guard let usr = rusr else { return }
                self.opOpenUserAction?(usr)
            }
        }
        else{
            Utils.fetchUser(uid: pst.ouid) { (rusr) in
                self.isDoingUser = false
                
                self.btn_openUser.isUserInteractionEnabled = true
                guard let usr = rusr else { return }
                self.opOpenUserAction?(usr)
            }
        }
    }
    @IBAction func opMore(_ sender: Any) {
        self.opMoreAction?(post)
    }
    @objc private func handleDoubleTap() {
        if isDoubleTap { return }
        isDoubleTap = true
        likeButtonTapped(self)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isDoubleTap = false
        }
    }
    @IBAction func opShareTo(_ sender: Any) {
        self.opShareToAction?()
    }
    @IBAction func likeButtonTapped(_ sender: Any) {
        guard let post = post else { return }
        
        if isDoingLike{
            return
        }
        isDoingLike = true
        self.btn_likes.isUserInteractionEnabled = false
        post.isLikedPost { (res) in
            if res && self.isDoubleTap {
                self.isDoingLike = false
                return }
            
            self.btn_likes.setImage(UIImage(named: !res ? "nic_liked" : "nic_like"), for: .normal)

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.btn_likes.isUserInteractionEnabled = true
            }

            post.opLike(newLike: !res) { (likes) in
                self.btn_num_likes.setTitle("\(likes) Likes", for: .normal)
                
                self.isDoingLike = false
            }
        }
    }
    @IBAction func opOpenReposter(_ sender: Any) {
        if isDoingReposter{
            return
        }
        isDoingReposter = true
        self.btn_reposter.isUserInteractionEnabled = false
        Utils.fetchUser(uid: self.post.ouid) { (rusr) in
            self.btn_reposter.isUserInteractionEnabled = true
            self.isDoingReposter = false
            guard let usr = rusr else { return }
            self.opOpenUserAction?(usr)
        }
    }
    @IBAction func opOpenLikes(_ sender: Any) {
        self.opOpenLikedUsers?()
    }
    @IBAction func opOpenComment(_ sender: Any) {
        btn_comments.isUserInteractionEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.btn_comments.isUserInteractionEnabled = true
        }
        self.opOpenCommentsAction?()
    }
    @IBAction func repostButtonTapped(_ sender: Any) {
        btn_repost.isUserInteractionEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.btn_repost.isUserInteractionEnabled = true
        }
        self.opRepostAction?()
    }
}
