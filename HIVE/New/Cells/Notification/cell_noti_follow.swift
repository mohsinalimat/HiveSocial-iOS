//
//  cell_noti_follow.swift
//  HIVE
//
//  Created by elitemobile on 9/20/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import UIKit
import Firebase

class cell_noti_follow: UIView {
    
    @IBOutlet weak var img_profile: UIImageView!
    @IBOutlet weak var btn_follow: UIButton!
    @IBOutlet weak var lbl_content: UILabel!
    
    var opOpenUserAction: ((User) -> Void)?
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initComponents()
    }
    
    func initComponents(){
        img_profile.makeCircleView()
        btn_follow.makeRoundView(r: 2)
    }
    
    var noti: Noti!
    var user: User!
    func setNoti(noti: Noti){
        self.noti = noti
        
        Utils.fetchUser(uid: noti.uid) { (rusr) in
            guard let usr = rusr else { return }
            self.user = usr
            self.img_profile.loadImg(str: usr.thumb.isEmpty ? usr.avatar : usr.thumb, user: true)

            let attributedText = NSMutableAttributedString(string: usr.displayName, attributes: [NSAttributedString.Key.font: UIFont.cFont_medium(size: 17)])
            attributedText.append(NSAttributedString(string: noti.type.description, attributes: [NSAttributedString.Key.font: UIFont.cFont_regular(size: 17)]))

            let time: String = Date(timeIntervalSince1970: noti.created).timeAgoToDisplay(lowercased: true)
            attributedText.append(NSAttributedString(string: time, attributes: [NSAttributedString.Key.font: UIFont.cFont_regular(size: 15), NSAttributedString.Key.foregroundColor: UIColor.lightGray]))
            self.lbl_content.attributedText = attributedText

            usr.isFollowing { (type) in
                Utils.configureFollowButton(btn: self.btn_follow, type: type)
            }
        }
    }

    @IBAction func opOpenUser(_ sender: Any) {
        if let usr = self.user{
            self.opOpenUserAction?(usr)
        }
    }
    @IBAction func opFollow(_ sender: Any) {
        if let usr = self.user{
            if self.btn_follow.titleLabel?.text == "Follow" {
                user.follow(follow: true)
            } else {
                user.follow(follow: false)
            }
            
            usr.isFollowing { (type) in
                Utils.configureFollowButton(btn: self.btn_follow, type: type)
            }
        }
    }
}
