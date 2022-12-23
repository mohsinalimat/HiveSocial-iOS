//
//  cv_accessoryView_cmt.swift
//  HIVE
//
//  Created by elitemobile on 3/9/21.
//  Copyright © 2021 Kassy Pop. All rights reserved.
//

import UIKit

class cv_accessoryView_cmt: UIView {
    @IBOutlet weak var img_gif: UIImageView!
    @IBOutlet weak var img_media: UIImageView!
    @IBOutlet weak var img_emoji: UIImageView!
    
    @IBOutlet weak var btn_gif: UIButton!
    @IBOutlet weak var btn_media: UIButton!
    @IBOutlet weak var btn_emoji: UIButton!
    @IBOutlet weak var btn_reply: UIButton!
    
    var selectedIndex: Int = -1
    
    var opGifAction: (() -> Void)?
    var opMediaAction: (() -> Void)?
    var opEmojiAction: (() -> Void)?
    var opReplyAction: (() -> Void)?

    var locked: Bool = false
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initComponents()
    }
    
    func initComponents(){
        btn_reply.makeRoundView(r: 6)
        updateButtons()
        updateLockStatus()
        updateReplyBtn(activated: false)
    }
    
    func updateButtons(){
        img_gif.tintColor = selectedIndex == 0 ? UIColor.active() : UIColor.inactive()
        img_media.tintColor = selectedIndex == 1 ? UIColor.active() : UIColor.inactive()
        img_emoji.tintColor = selectedIndex == 2 ? UIColor.active() : UIColor.inactive()
    }
    
    func updateLockStatus(){
        btn_gif.isEnabled = !locked
        btn_media.isEnabled = !locked
        btn_emoji.isEnabled = !locked
        updateReplyBtn(activated: !locked)
    }
    
    @IBAction func opGif(_ sender: Any) {
        selectedIndex = 0
        updateButtons()
        opGifAction?()
    }
    
    @IBAction func opMedia(_ sender: Any) {
        selectedIndex = 1
        updateButtons()
        opMediaAction?()
    }
    
    @IBAction func opEmoji(_ sender: Any) {
        selectedIndex = 2
        updateButtons()
        opEmojiAction?()
    }
    
    @IBAction func opReply(_ sender: Any) {
        if locked{
            return
        }
        self.opReplyAction?()
    }
    
    func lock(){
        locked = true
        updateLockStatus()
    }
    
    func updateReplyBtn(activated: Bool){
        self.btn_reply.isEnabled = activated
        self.btn_reply.alpha = activated ? 1 : 0.3
    }
    
    func unlock(){
        selectedIndex = -1
        locked = false
        updateButtons()
        updateReplyBtn(activated: false)
        updateLockStatus()
    }
}
