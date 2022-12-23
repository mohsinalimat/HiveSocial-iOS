//
//  cv_report_done.swift
//  HIVE
//
//  Created by elitemobile on 11/1/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import UIKit
import SwiftMessages

class cv_report_done: MessageView {
    @IBOutlet weak var btn_done: UIButton!
    @IBOutlet weak var v_out: UIView!
    
    var opDoneAction: (() -> Void)?
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initComponents()
    }
    
    func initComponents(){
        btn_done.makeCircleView()
        v_out.makeRoundView(r: 16, masked: true)
    }
    
    @IBAction func opDone(_ sender: Any) {
        opDoneAction?()
    }
}
