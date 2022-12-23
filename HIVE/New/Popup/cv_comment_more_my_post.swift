//
//  cv_comment_more_my_post.swift
//  HIVE
//
//  Created by elitemobile on 3/26/21.
//  Copyright © 2021 Kassy Pop. All rights reserved.
//

import UIKit

class cv_comment_more_my_post: UIView {
    
    @IBOutlet weak var btn_done: UIButton!
    
    var opDeleteCommentAction: (() -> Void)?
    var opBlockUserAction: (() -> Void)?
    var opDoneAction: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initComponents()
    }
    
    func initComponents(){
        btn_done.makeCircleView()
    }
    
    @IBAction func opBlockUser(_ sender: Any) {
        opBlockUserAction?()
    }
    
    @IBAction func opDeleteComment(_ sender: Any) {
        opDeleteCommentAction?()
    }

    @IBAction func opDone(_ sender: Any) {
        opDoneAction?()
    }
    
}
