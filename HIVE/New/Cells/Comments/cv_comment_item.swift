//
//  cv_comment_item.swift
//  HIVE
//
//  Created by elitemobile on 3/17/21.
//  Copyright © 2021 Kassy Pop. All rights reserved.
//

import UIKit

class cv_comment_item: UITableViewCell {
    var constantMargin: Int = 20
    @IBOutlet weak var img_topConstraint: NSLayoutConstraint!
    @IBOutlet weak var img_leftConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var v_avatar: UIView!
    @IBOutlet weak var img_avatar: UIImageView!
    @IBOutlet weak var lbl_header: UILabel!
    @IBOutlet weak var lbl_body: ActiveLabel!
    @IBOutlet weak var btn_more: UIButton!
    
    @IBOutlet weak var img_num_likes: UIImageView!
    @IBOutlet weak var lbl_num_likes: UILabel!
    @IBOutlet weak var img_num_comments: UIImageView!
    @IBOutlet weak var lbl_num_comments: UILabel!
    
    @IBOutlet weak var v_line: UIView!
    
    @IBOutlet weak var v_media: UIView!
    @IBOutlet weak var img_media: UIImageView!
    @IBOutlet weak var lbl_bodyTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var v_mediaWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var btn_like: UIButton!
    @IBOutlet weak var btn_comment: UIButton!
    @IBOutlet weak var btn_avatar: UIButton!
    
    @IBOutlet weak var v_like: UIView!
    @IBOutlet weak var v_comment: UIView!
    
    @IBOutlet weak var v_bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var v_showReplies: UIView!
    @IBOutlet weak var btn_showReplies: UIButton!
    
    var opMoreAction: (() -> Void)?
    var opCommentAction: (() -> Void)?
    var opOpenUrlAction: ((URL) -> Void)?
    var opOpenUserAction: ((String) -> Void)?
    var opOpenUserNameAction: ((String) -> Void)?
    var opOpenHashtagAction: ((String) -> Void)?
    var opShowRepliesAction: ((Bool) -> Void)?
    
    var comment: Comment!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initComponents()
    }
    
    func initComponents(){
        v_avatar.makeCircleView()
        img_media.makeRoundView(r: 6)
        img_media.layer.borderColor = UIColor.lightGray.cgColor
        img_media.layer.borderWidth = 0.5
        v_bottomConstraint.constant = 0
        
        lbl_body.lineSpacing = 0
        lbl_body.lineSpacing = 0
        lbl_body.lineBreakMode = NSLineBreakMode.byWordWrapping
        lbl_body.enabledTypes = [.mention, .hashtag, .url]
        lbl_body.configureLinkAttribute = { (type, attributes, isSelected) in
            var atts = attributes
            switch type {
            case .mention:
                atts[NSAttributedString.Key.foregroundColor] = UIColor.active()
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
    }
    
    @IBAction func opMore(_ sender: Any) {
        opMoreAction?()
    }
    
    var isDoingLike: Bool = false
    @IBAction func opLike(_ sender: Any) {
        if isDoingLike{
            return
        }
        isDoingLike = true
        
        self.btn_like.isUserInteractionEnabled = false
        comment.likeComment { [self] (_) in
            self.comment.isLiked { (res) in
                self.img_num_likes.isHighlighted = res
                self.lbl_num_likes.textColor = res ? UIColor.error(): UIColor.inactive()
                self.lbl_num_likes.text = "\(self.comment.num_likes)"
                self.isDoingLike = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.btn_like.isUserInteractionEnabled = true
            }
        }
    }
    
    @IBAction func opComment(_ sender: Any) {
//        if !v_line.isHidden{
//            //header item
//            return
//        }
        
        self.btn_comment.isUserInteractionEnabled = false
        
        opCommentAction?()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.btn_comment.isUserInteractionEnabled = true
        }
    }
    
    @IBAction func opAvatar(_ sender: Any) {
        self.btn_avatar.isUserInteractionEnabled = false
        
        opOpenUserAction?(self.comment.uid)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.btn_avatar.isUserInteractionEnabled = true
        }
    }
    
    func setComment(cmt: Comment, header: Bool = false, myPost: Bool = false, showLabel: Bool = false, second: Bool = false){
        if !header{
            self.img_topConstraint.constant = 20 + CGFloat(cmt.level * 12)
            self.img_leftConstraint.constant = 20 + CGFloat(cmt.level * 12)
        }
        
        self.comment = cmt
        self.v_line.isHidden = true
        
        if Me.uid == cmt.uid || myPost{
            btn_more.isHidden = false
        }
        else{
            btn_more.isHidden = true
        }
        
        Utils.fetchUser(uid: cmt.uid) { (rusr) in
            guard let usr = rusr else {
                self.lbl_header.text = "\(Date(timeIntervalSince1970: cmt.created).timeAgoToDisplay(lowercased: true, cmt: true))"
                return }
            
            self.img_avatar.loadImg(str: usr.thumb.isEmpty ? usr.avatar : usr.thumb, user: true)
            
            let str: String = "\(usr.fname) @\(usr.uname) •\(Date(timeIntervalSince1970: cmt.created).timeAgoToDisplay(lowercased: true, cmt: true))"
            let range_fname = (str as NSString).range(of: usr.fname)
            let str_att = NSAttributedString(string: str)
            let mutableStr = NSMutableAttributedString()
            mutableStr.append(str_att)
            mutableStr.addAttribute(.font, value: UIFont.cFont_medium(size: 16), range: range_fname)
            mutableStr.addAttribute(.foregroundColor, value: UIColor.label, range: range_fname)
            self.lbl_header.attributedText = mutableStr
        }
        
        switch(cmt.type){
        case .TEXT:
            lbl_bodyTopConstraint.constant = 8
            v_media.isHidden = true
            break
        case .IMAGE:
            lbl_bodyTopConstraint.constant = 156
            v_media.isHidden = false
            v_mediaWidthConstraint.constant = cmt.ratio * 140
            
            img_media.loadImg(str: cmt.media)
            break
        case .GIF:
            lbl_bodyTopConstraint.constant = 156
            v_media.isHidden = false
            v_mediaWidthConstraint.constant = cmt.ratio * 140
            
            img_media.loadImg(str: cmt.media)
            break
        }
        
        lbl_body.text = cmt.msg
        lbl_body.handleURLTap { (url) in
            self.opOpenUrlAction?(url)
        }
        lbl_body.handleMentionTap { (mentionName) in
            self.opOpenUserNameAction?(mentionName)
        }
        lbl_body.handleHashtagTap { (hashtag) in
            self.opOpenHashtagAction?(hashtag)
        }
        lbl_body.sizeToFit()
        
        lbl_num_likes.text = "\(comment.num_likes)"
        lbl_num_comments.text = "\(comment.num_commented)"
        comment.isLiked { (res) in
            self.img_num_likes.isHighlighted = res
            self.lbl_num_likes.textColor = res ? UIColor.error() : UIColor.inactive()
        }
        comment.isCommented { (res) in
            self.img_num_comments.isHighlighted = res
            self.lbl_num_comments.textColor = res ? UIColor.active() : UIColor.inactive()
        }

        if header{
            self.v_line.isHidden = true
            v_showReplies.isHidden = true
            v_bottomConstraint.constant = 0
        }
        else if comment.num_commented > 0 && ((second == false && comment.level == 0) || (second == true && comment.level - 1 == 0)){
            v_showReplies.isHidden = false
            v_bottomConstraint.constant = 30

            if showLabel{
                self.btn_showReplies.setTitle("Hide replies", for: .normal)
                v_line.isHidden = false
            }
            else{
                self.btn_showReplies.setTitle("Show replies", for: .normal)
                v_line.isHidden = true
            }
        }
        else{
            v_showReplies.isHidden = true
            v_bottomConstraint.constant = 0
        }
    }
    
    @IBAction func opShowReplies(_ sender: Any) {
        if self.btn_showReplies.title(for: .normal) == "Show replies"{
            self.btn_showReplies.setTitle("Hide replies", for: .normal)
            self.v_line.isHidden = false
            
            self.opShowRepliesAction?(true)
        }
        else {
            self.v_line.isHidden = true
            self.btn_showReplies.setTitle("Show replies", for: .normal)
            
            self.opShowRepliesAction?(false)
        }
    }
}
