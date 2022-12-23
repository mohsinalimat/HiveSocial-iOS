//
//  cv_comment_post_header.swift
//  HIVE
//
//  Created by elitemobile on 3/17/21.
//  Copyright © 2021 Kassy Pop. All rights reserved.
//

import UIKit

class cv_comment_post_header: UITableViewCell {
    @IBOutlet weak var v_avatar: UIView!
    @IBOutlet weak var img_avatar: UIImageView!
    @IBOutlet weak var lbl_header: UILabel!
    @IBOutlet weak var lbl_body: ActiveLabel!
    @IBOutlet weak var btn_more: UIButton!
    
    var opMoreAction: (() -> Void)?
    var opOpenUserAction: ((String) -> Void)?
    var opOpenUserNameAction: ((String) -> Void)?
    var opOpenUrlAction: ((URL) -> Void)?
    var opOpenHashtagAction: ((String) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initComponents()
    }
    
    func initComponents(){
        v_avatar.makeCircleView()
        
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
    
    func setPost(post: Post){
        img_avatar.loadImg(str: post.oavatar, user: true)
        Utils.fetchUser(uid: post.ouid) { (rusr) in
            guard let usr = rusr else {
                self.lbl_header.text = "@\(post.ouname) •\(Date(timeIntervalSince1970: post.created).timeAgoToDisplay(lowercased: true, cmt: true))"
                return }

            let str: String = "\(usr.fname) @\(usr.uname) •\(Date(timeIntervalSince1970: post.created).timeAgoToDisplay(lowercased: true, cmt: true))"
            
            let range_fname = (str as NSString).range(of: usr.fname)
            let str_att = NSAttributedString(string: str)
            let mutableStr = NSMutableAttributedString()
            mutableStr.append(str_att)
            
            mutableStr.addAttribute(.font, value: UIFont.cFont_medium(size: 16), range: range_fname)
            mutableStr.addAttribute(.foregroundColor, value: UIColor.label, range: range_fname)
            
            self.lbl_header.attributedText = mutableStr
        }
        
        lbl_body.text = post.getDesc(cmt: true)
        
        lbl_body.handleURLTap { (url) in
            print("Clicked Link")
        }
        
        lbl_body.handleMentionTap { [weak self] (mentionName) in
            print("Clicked Username")
            guard let self = self else { return }
        }
        
        lbl_body.handleHashtagTap { (hashtag) in
            print("Clicked HashTag")
        }
        
        lbl_body.sizeToFit()
    }
    
    func setComment(cmt: Comment){
        
    }
}
