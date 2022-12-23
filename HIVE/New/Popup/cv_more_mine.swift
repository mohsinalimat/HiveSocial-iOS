//
//  cv_more_mine.swift
//  HIVE
//
//  Created by elitemobile on 1/25/21.
//  Copyright © 2021 Kassy Pop. All rights reserved.
//

import UIKit
import SwiftMessages
import Firebase

class cv_more_mine: MessageView {
    
    @IBOutlet weak var v_out: UIView!
    @IBOutlet weak var btn_done: UIButton!
    
    var opEditPostAction: (() -> Void)?
    var opDeletePostAction: (() -> Void)?
    var opDoneAction: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initComponents()
    }
    
    func initComponents(){
        v_out.makeRoundView(r: 16, masked: true)
        btn_done.makeCircleView()
    }
    
    @IBAction func opEditPost(_ sender: Any) {
        self.opEditPostAction?()
    }
    @IBAction func opDeletePost(_ sender: Any) {
        self.opDeletePostAction?()
    }

    @IBAction func opDone(_ sender: Any) {
        self.opDoneAction?()
    }
}
