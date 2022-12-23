//
//  VC_Startup.swift
//  HIVE
//
//  Created by elitemobile on 8/10/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import UIKit
class VC_Startup: UIViewController {
    @IBOutlet weak var btn_signup: UIButton!
    @IBOutlet weak var btn_login: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initComponents()
    }
    
    func initComponents(){
        btn_signup.makeCircleView()
        btn_login.makeCircleView()
    }

    @IBAction func opSignup(_ sender: Any) {
        let sb = UIStoryboard(name: "Auth", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "VC_Signup") as! VC_Signup
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func opLogin(_ sender: Any) {
        let sb = UIStoryboard(name: "Auth", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "VC_Login") as! VC_Login
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
