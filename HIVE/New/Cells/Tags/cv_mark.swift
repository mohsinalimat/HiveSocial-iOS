//
//  cv_mark.swift
//  HIVE
//
//  Created by elitemobile on 12/3/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import UIKit

class cv_mark: UIView {
    @IBOutlet weak var v_out: UIView!
    @IBOutlet weak var lbl_title: UILabel!
    @IBOutlet weak var img_cate: UIImageView!
    
    var opSelectedAction: (() -> Void)?
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initComponents()
    }
    
    func initComponents(){
        v_out.makeRoundView(r: 6)
    }
    
    func setCategory(index: Int){
        let cate = categories[index]
        
        lbl_title.text = cate[0] as! String
        img_cate.image = UIImage(named: cate[1] as! String)
    }
    
    @IBAction func opSelected(_ sender: Any) {
        opSelectedAction?()
    }
}
