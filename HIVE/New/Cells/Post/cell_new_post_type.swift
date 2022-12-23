//
//  cell_new_post_type.swift
//  HIVE
//
//  Created by elitemobile on 11/1/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import UIKit

class cell_new_post_type: UICollectionViewCell {
    
    @IBOutlet weak var v_bg: UIView!
    @IBOutlet weak var img_type: UIImageView!
    
    var opSelectedAction: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initComponents()
    }

    func initComponents(){
        
    }
    
    @IBAction func opSelected(_ sender: Any) {
        self.opSelectedAction?()
    }
}
