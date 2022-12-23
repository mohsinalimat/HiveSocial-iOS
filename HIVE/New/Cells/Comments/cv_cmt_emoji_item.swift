//
//  cv_cmt_emoji_item.swift
//  HIVE
//
//  Created by elitemobile on 3/9/21.
//  Copyright © 2021 Kassy Pop. All rights reserved.
//

import UIKit

class cv_cmt_emoji_item: UIView {
    @IBOutlet weak var lbl_emoji: UILabel!
    
    var opEmojiClickedAction: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initComponents()
    }
    
    func initComponents(){
    }
    
    func setEmoji(str: String){
        lbl_emoji.text = str
    }
    
    @IBAction func opEmojiClicked(_ sender: Any) {
        opEmojiClickedAction?()
    }
}
