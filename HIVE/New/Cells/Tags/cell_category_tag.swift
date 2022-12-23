//
//  cell_category_tag.swift
//  HIVE
//
//  Created by elitemobile on 1/4/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import UIKit

class cell_category_tag: UICollectionViewCell {
    @IBOutlet weak var lbl_tag: UILabel!
    @IBOutlet weak var v_tag: UIView!
    
    var opSelectedAction: (() -> Void)?
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initComponents()
    }
    
    func initComponents(){
        v_tag.makeCircleView()
    }
    
    @IBAction func opSelected(_ sender: Any) {
        self.opSelectedAction?()
    }
}
