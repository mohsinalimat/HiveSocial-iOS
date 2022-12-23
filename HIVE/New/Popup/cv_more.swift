//
//  cv_more.swift
//  HIVE
//
//  Created by elitemobile on 11/1/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import UIKit
import SwiftMessages
import Firebase

class cv_more: MessageView {
    
    @IBOutlet weak var lbl_option_first: UILabel!
    @IBOutlet weak var lbl_option_second: UILabel!
    @IBOutlet weak var v_out: UIView!
    @IBOutlet weak var btn_done: UIButton!
    
    var opBlockUserAction: (() -> Void)?
    var opReportPostAction: (() -> Void)?
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
    
    @IBAction func opReportPost(_ sender: Any) {
        self.opReportPostAction?()
    }
    
    @IBAction func opReportAccountAction(_ sender: Any) {
        self.opReportAccountAction?()
    }
    
    @IBAction func opBlockUser(_ sender: Any) {
        self.opBlockUserAction?()
    }
    
    @IBAction func opDone(_ sender: Any) {
        self.opDoneAction?()
    }
}
