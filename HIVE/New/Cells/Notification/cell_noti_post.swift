//
//  cell_noti_post.swift
//  HIVE
//
//  Created by elitemobile on 9/20/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import UIKit
import Firebase

class cell_noti_post: UIView {

    @IBOutlet weak var img_profile: UIImageView!
    @IBOutlet weak var img_post: UIImageView!
    @IBOutlet weak var lbl_content: UILabel!
    
    var opOpenUserAction: ((User) -> Void)?
    var opOpenPostAction: ((Post) -> Void)?
    
    @IBOutlet weak var postImageViewWidthConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initComponent()
    }
    
    func initComponent(){
        img_profile.makeCircleView()
        img_post.makeRoundView(r: 2)
    }
    
    @IBAction func opOpenUser(_ sender: Any) {
        if let usr = self.user{
            opOpenUserAction?(usr)
        }
    }
    
    @IBAction func opOpenPost(_ sender: Any) {
        if let pst = self.post{
            opOpenPostAction?(pst)
        }
    }

    var noti: Noti!
    var post: Post!
    var user: User!
    func setNoti(noti: Noti){
        self.noti = noti
        Utils.fetchUser(uid: noti.uid) { (rusr) in
            guard let usr = rusr else { return }
            self.user = usr
            self.img_profile.loadImg(str: usr.thumb.isEmpty ? usr.avatar : usr.thumb, user: true)
            
            if usr.displayName.isEmpty {
                self.lbl_content.isHidden = true
                return
            }
            let attributedText = NSMutableAttributedString(string: usr.displayName, attributes: [NSAttributedString.Key.font: UIFont.cFont_medium(size: 17)])
            
            var desc = noti.type.description
            if !noti.chatMsg.isEmpty{
                desc += " - \(noti.chatMsg)"
            }
            else if !noti.cmtMsg.isEmpty{
                desc += "- \(noti.cmtMsg)"
            }
            
            attributedText.append(NSAttributedString(string: desc, attributes: [NSAttributedString.Key.font: UIFont.cFont_regular(size: 17)]))
            let time: String = Date(timeIntervalSince1970: noti.created).timeAgoToDisplay(lowercased: true)
            attributedText.append(NSAttributedString(string: time, attributes: [NSAttributedString.Key.font: UIFont.cFont_regular(size: 15), NSAttributedString.Key.foregroundColor: UIColor.lightGray]))
            
            self.lbl_content.isHidden = false
            self.lbl_content.attributedText = attributedText
        }
        
        if noti.pid.isEmpty{
            self.img_post.isHidden = true
            self.postImageViewWidthConstraint.constant = 0
            return
        }
        else{
            self.img_post.isHidden = false
            self.postImageViewWidthConstraint.constant = 48
        }
        
        Utils.fetchPost(pid: noti.pid, quickLoad: true) { (rpst) in
            guard let pst = rpst else { return }
            self.post = pst
            if let repost = pst.opost{
                self.setPost(pst: repost)
            }
            else{
                self.setPost(pst: pst)
            }
        }
    }
    
    func setPost(pst: Post){
        self.img_post.isHidden = false
        switch pst.type {
            case .IMAGE:
                if let imgUrl = pst.media.first as? String, !imgUrl.isEmpty{
                    self.img_post.loadImg(str: imgUrl)
                }
                break
            case .VIDEO:
                if let vidUrl = pst.media.first as? [String: String], vidUrl.count > 0{
                    self.img_post.loadImg(str: vidUrl.values.first!)
                }
                break
            case .GIF:
                if let gifUrl = pst.media.first as? String, !gifUrl.isEmpty{
                    self.img_post.loadImg(str: gifUrl)
                }
                break
            default:
                break
        }
    }

}
