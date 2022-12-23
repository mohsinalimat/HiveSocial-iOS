//
//  cell_follow.swift
//  HIVEcopy
//
//  Created by Kassy Pop on 7/31/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import UIKit
import Firebase

class cell_follow: UIView {
    
    @IBOutlet weak var img_profile: UIImageView!
    @IBOutlet weak var btn_follow: UIButton!
    @IBOutlet weak var lbl_content: UILabel!

    // MARK: - Properties
    
    var user: User!
    var opOpenAction: (() -> Void)?
    var opFollowAction: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initComponents()
    }
    
    func initComponents(){
        img_profile.makeCircleView()
        btn_follow.makeRoundView()
    }
    
    func setUser(usr: User){
        self.user = usr
        
        // hide follow button from current user
        if user.uid == CUID  {
            self.btn_follow.isHidden = true
        }

        self.img_profile.loadImg(str: usr.thumb.isEmpty ? usr.avatar : usr.thumb, user: true)
        self.lbl_content.text = user.displayName

        user.isFollowing { (type) in
            Utils.configureFollowButton(btn: self.btn_follow, type: type)
        }
    }
    
    @IBAction func opOpen(_ sender: Any) {
        opOpenAction?()
    }
    
    @IBAction func opFollow(_ sender: Any) {
        user.isFollowing { (type) in
            switch(type){
            case .AbleToFollow:
                self.user.follow()
                break
            case .Declined:
                break
            case .Following:
                self.user.follow(follow: false)
                break
            case .Requested:
                break
            }
            self.user.isFollowing { (type) in
                Utils.configureFollowButton(btn: self.btn_follow, type: type)
            }
        }
    }
}
