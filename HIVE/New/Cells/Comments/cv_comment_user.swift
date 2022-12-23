//
//  cv_comment_user.swift
//  HIVE
//
//  Created by elitemobile on 3/26/21.
//  Copyright © 2021 Kassy Pop. All rights reserved.
//

import UIKit

class cv_comment_user: UIView {
    
    @IBOutlet weak var img_avatar: UIImageView!
    @IBOutlet weak var lbl_fname: UILabel!
    @IBOutlet weak var lbl_uname: UILabel!
    
    var opClickAction: (() -> Void)?
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initComponents()
    }
    
    func initComponents(){
        img_avatar.makeCircleView()
    }
    
    func setUser(usr: User){
        img_avatar.loadImg(str: usr.thumb.isEmpty ? usr.avatar : usr.thumb, user: true)
        
        lbl_fname.text = usr.fname
        lbl_uname.text = "@\(usr.uname)"
    }
    
    @IBAction func opClick(_ sender: Any) {
        self.opClickAction?()
    }
}
