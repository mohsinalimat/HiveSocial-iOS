//
//  cv_profile_more.swift
//  HIVE
//
//  Created by elitemobile on 2/24/21.
//  Copyright © 2021 Kassy Pop. All rights reserved.
//

import UIKit
import SwiftMessages
import Firebase

class cv_profile_more: MessageView {
    
    @IBOutlet weak var v_out: UIView!
    @IBOutlet weak var btn_done: UIButton!
    @IBOutlet weak var lbl_block: UILabel!
    
    var opBlockUserAction: (() -> Void)?
    var opReportAccountAction: (() -> Void)?
    var opDoneAction: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initComponents()
    }
    
    func initComponents(){
        v_out.makeRoundView(r: 16, masked: true)
        btn_done.makeCircleView()
    }
    
    @IBAction func opBlockUser(_ sender: Any) {
        opBlockUserAction?()
    }
    @IBAction func opReportAccount(_ sender: Any) {
        opReportAccountAction?()
    }

    @IBAction func opDone(_ sender: Any) {
        self.opDoneAction?()
    }
}
