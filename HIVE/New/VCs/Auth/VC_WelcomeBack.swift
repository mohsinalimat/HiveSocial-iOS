//
//  VC_WelcomeBack.swift
//  HIVE
//
//  Created by elitemobile on 8/10/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import UIKit

class VC_WelcomeBack: UIViewController {
    
    @IBOutlet weak var img_avatar: UIImageView!
    @IBOutlet weak var lbl_username: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initComponents()
    }
    
    func initComponents(){
        img_avatar.makeCircleView()
        
    }
    
    @IBAction func opFaceId(_ sender: Any) {
        
    }
    
    @IBAction func opNotMe(_ sender: Any) {
        
    }
}
