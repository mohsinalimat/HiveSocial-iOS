//
//  cell_blocked.swift
//  HIVE
//
//  Created by elitemobile on 1/26/21.
//  Copyright © 2021 Kassy Pop. All rights reserved.
//

import UIKit

class cell_blocked: UITableViewCell {
    @IBOutlet weak var img_avatar: UIImageView!
    @IBOutlet weak var lbl_uname: UILabel!
    @IBOutlet weak var v_block: UIView!
    @IBOutlet weak var btn_block: UIButton!
    
    var opUnblockAction: (() -> Void)?
    var opOpenAction: (() -> Void)?
    
    var user: User!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initComponents()
    }
    
    func initComponents(){
        img_avatar.makeCircleView()
        
        btn_block.makeRoundView(r: 8)
        
        v_block.makeRoundView(r: 8)

        btn_block.layer.borderWidth = 2
        btn_block.layer.borderColor = UIColor.error().cgColor
    }
    
    func setUser(usr: User){
        self.user = usr
        
        self.img_avatar.loadImg(str: usr.thumb.isEmpty ? usr.avatar : usr.thumb, user: true)
        self.lbl_uname.text = user.displayName
    }

    @IBAction func opOpen(_ sender: Any) {
        self.opOpenAction?()
    }
    
    @IBAction func opUnblock(_ sender: Any) {
        if btn_block.title(for: .normal) == "Unblock"{
            self.user.unblock()
            btn_block.setTitle("Block", for: .normal)
        }
        else {
            self.user.block()
            btn_block.setTitle("Unblock", for: .normal)
        }
    }
}
