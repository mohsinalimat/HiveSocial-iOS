//
//  cell_new_post.swift
//  HIVE
//
//  Created by elitemobile on 11/1/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import UIKit

class cell_new_post: UICollectionViewCell {
    @IBOutlet weak var v_out: UIView!
    @IBOutlet weak var img_content: UIImageView!
    @IBOutlet weak var img_play: UIImageView!
    
    var opSelectedAction:(() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initComponents()
    }

    func initComponents(){
        v_out.makeRoundView(r: 4)
    }
    
    @IBAction func opSelect(_ sender: Any) {
        opSelectedAction?()
    }
}
