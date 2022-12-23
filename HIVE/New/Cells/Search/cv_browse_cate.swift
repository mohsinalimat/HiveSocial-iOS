//
//  cv_browse_cate.swift
//  HIVE
//
//  Created by elitemobile on 10/1/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import UIKit

class cv_browse_cate: UIView{
    
    @IBOutlet weak var img_bg: UIImageView!
    @IBOutlet weak var lbl_name: UILabel!
    @IBOutlet weak var lbl_desc: UILabel!
    @IBOutlet weak var lbl_num: UILabel!
    
    var opOpenCategory: (() -> Void)?
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initComponents()
    }
    
    func initComponents(){
        
    }
    
    @IBAction func opSelected(_ sender: Any) {
        self.opOpenCategory?()
    }
}
