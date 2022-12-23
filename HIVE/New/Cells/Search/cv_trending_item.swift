//
//  cv_trending_item.swift
//  HIVE
//
//  Created by elitemobile on 10/1/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import UIKit

class cv_trending_item: UIView{
    @IBOutlet weak var img_bg: UIImageView!
    @IBOutlet weak var img_owner: UIImageView!
    @IBOutlet weak var lbl_name: UILabel!
    @IBOutlet weak var lbl_desc: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initComponents()
    }
    
    func initComponents(){
        img_owner.makeCircleView()
    }

}
