//
//  cv_comment_more.swift
//  HIVE
//
//  Created by elitemobile on 3/15/21.
//  Copyright © 2021 Kassy Pop. All rights reserved.
//

import UIKit

class cv_comment_more: UIView {
    
    @IBOutlet weak var btn_done: UIButton!
    
    var opDeleteCommentAction: (() -> Void)?
    var opDoneAction: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initComponents()
    }
    
    func initComponents(){
        btn_done.makeCircleView()
    }
    
    @IBAction func opDeleteComment(_ sender: Any) {
        opDeleteCommentAction?()
    }
    
    @IBAction func opDone(_ sender: Any) {
        opDoneAction?()
    }
}
