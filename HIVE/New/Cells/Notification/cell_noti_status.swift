//
//  cell_noti_status.swift
//  HIVE
//
//  Created by elitemobile on 9/20/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import UIKit

class cell_noti_status: UIView {

    @IBOutlet weak var imt_profile: UIImageView!
    @IBOutlet weak var img_post: UIImageView!
    @IBOutlet weak var lbl_content: UILabel!
    
    var opOpenUser: (() -> Void)?
    var opOpenPost: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initComponent()
    }
    
    func initComponent(){
        
    }
    
    @IBAction func opFollow(_ sender: Any) {
    }

}
