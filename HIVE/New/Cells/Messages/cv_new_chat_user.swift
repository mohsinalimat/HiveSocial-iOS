//
//  cv_new_chat_user.swift
//  HIVE
//
//  Created by elitemobile on 11/18/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import UIKit
import BEMCheckBox

class cv_new_chat_user: UITableViewCell {
    @IBOutlet weak var img_avatar: UIImageView!
    @IBOutlet weak var lbl_fname: UILabel!
    @IBOutlet weak var lbl_uname: UILabel!
    @IBOutlet weak var chk_checked: BEMCheckBox!
    @IBOutlet weak var v_content: UIView!
    @IBOutlet weak var v_cate: UIView!
    @IBOutlet weak var lbl_ta: UILabel!
    
    var opSelectedAction: (() -> Void)?
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
        lbl_uname.text = usr.uname
    }
    
    func setSong(song: Song){
        v_content.isHidden = false
        v_cate.isHidden = true
        
        lbl_fname.text = song.title
        lbl_uname.text = song.artist

        let url = song.artworkUrl.absoluteString
        if url.isEmpty{
            img_avatar.image = UIImage(named: "mic_widget_apple")
        }
        else{
            img_avatar.loadImg(str: url)
        }
    }
    
    func setCate(tag: String){
        v_cate.isHidden = false
        v_content.isHidden = true
        
        lbl_ta.text = tag
    }
    
    @IBAction func opSelected(_ sender: Any) {
        self.opSelectedAction?()
    }
}
