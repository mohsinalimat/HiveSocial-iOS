//
//  VC_RecoverAccount.swift
//  HIVE
//
//  Created by elitemobile on 8/11/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import UIKit
import Firebase

class VC_RecoverAccount: UIViewController {

    @IBOutlet weak var txt_username: UITextField!
    @IBOutlet weak var v_username: UIView!
    @IBOutlet weak var btn_next: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initComponents()
    }
    
    func initComponents(){
        addSwipeRight()
        
        v_username.makeCircleView()
        btn_next.makeCircleView()
    }
    
    @IBAction func opNext(_ sender: Any) {
        let email: String = txt_username.text!
        
        if email.isEmpty{
            return
        }
        
        Auth.auth().sendPasswordReset(withEmail: email) { (err) in
            if let error = err{
                print(error.localizedDescription)
                return
            }
            
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func opBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}
