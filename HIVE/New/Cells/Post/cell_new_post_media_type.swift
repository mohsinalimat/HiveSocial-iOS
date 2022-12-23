//
//  cell_new_post_media_type.swift
//  HIVE
//
//  Created by elitemobile on 11/9/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import UIKit

class cell_new_post_media_type: UICollectionViewCell {

    @IBOutlet weak var v_bg: UIView!
    @IBOutlet weak var img_item: UIImageView!
    @IBOutlet weak var img_play: UIImageView!
    
    var opSelectedAction: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initComponents()
    }

    func initComponents(){
        img_item.makeRoundView(r: 4)
        img_item.layer.borderWidth = 0.5
        img_item.layer.borderColor = UIColor(named: "col_lbl_body")!.cgColor
    }
    
    @IBAction func opSelected(_ sender: Any) {
        self.opSelectedAction?()
    }
}
