//
//  cell_category_item.swift
//  HIVE
//
//  Created by elitemobile on 12/14/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import UIKit

class cell_category_item: UICollectionViewCell {
    @IBOutlet weak var v_out: UIView!
    @IBOutlet weak var v_in: UIView!
    @IBOutlet weak var img_category: UIImageView!
    @IBOutlet weak var lbl_title: UILabel!
    
    var opSelectAction: (() -> Void)?
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initComponents()
    }
    
    func initComponents(){
        v_in.makeRoundView()
        v_out.makeRoundView()
        
        v_out.layer.borderColor = UIColor(named:"col_btn_send_active")!.cgColor
    }
    
    @IBAction func opSelect(_ sender: Any) {
        opSelectAction?()
    }
}
