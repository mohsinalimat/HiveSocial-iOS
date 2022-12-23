//
//  TermsViewController.swift
//  HIVE
//
//  Created by Daniel Pratt on 10/8/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import UIKit

class VC_Terms: UIViewController {
    
    @IBOutlet weak var outterView: UIView!
    @IBOutlet weak var btn_done: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initComponents()
    }
    
    func initComponents(){
        outterView.layer.cornerRadius = 16
        btn_done.makeCircleView()
    }
    
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}
