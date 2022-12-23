//
//  cv_chat.swift
//  HIVE
//
//  Created by elitemobile on 11/10/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import UIKit
import SwipeCellKit

class cv_chat: SwipeTableViewCell {

    @IBOutlet weak var img_avatar: UIImageView!
    @IBOutlet weak var lbl_uname: UILabel!
    @IBOutlet weak var lbl_msg: UILabel!
    @IBOutlet weak var lbl_tago: UILabel!
    @IBOutlet weak var img_msg_new: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initComponents()
    }

    func initComponents(){
        img_avatar.makeCircleView()
        img_msg_new.makeCircleView()
    }
    
    var channel: MockChannel!
    func setChannel(chn: MockChannel){
        self.channel = chn
        
        let uid = chn.targetUserId()
        if uid.isEmpty { return }
        if let tuser = chn.targetUser{
            self.img_avatar.loadImg(str: tuser.thumb.isEmpty ? tuser.avatar : tuser.thumb, user: true)
            self.lbl_uname.text = tuser.displayName
        }
        
        guard let lmsg = chn.lastMsg else { return }
        self.setUnreadMessage(unread: lmsg.sentDate.timeIntervalSince1970 > chn.lastSeen && lmsg.sender.senderId == uid)
        
        switch(lmsg.kind){
            case .text(let txt):
                self.lbl_msg.text = txt
                break
            default:
                break
        }
        
        self.lbl_tago.text = lmsg.sentDate.timeAgoToDisplay()
    }
    
    func setUnreadMessage(unread: Bool = false){
        lbl_tago.textColor = UIColor(named: unread ? "col_btn_send_active" : "col_lbl_caption")
        lbl_msg.textColor = UIColor(named: unread ? "col_btn_send_active" : "col_lbl_caption")
        lbl_uname.textColor = unread ? UIColor.active() : UIColor.label
        img_msg_new.isHidden = !unread
    }
}
