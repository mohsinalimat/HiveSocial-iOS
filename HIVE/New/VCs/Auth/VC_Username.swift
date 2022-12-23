//
//  VC_Username.swift
//  HIVE
//
//  Created by elitemobile on 10/15/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import UIKit
import Firebase

class VC_Username: UIViewController {

    @IBOutlet weak var v_username: UIView!
    @IBOutlet weak var txt_username: UITextField!
    @IBOutlet weak var btn_next: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initComponents()
    }
    
    func initComponents(){
        v_username.makeCircleView()
        btn_next.makeCircleView()
    }
    
    @IBAction func opNext(_ sender: Any) {
        guard let uid = CUID else { return }
        let uname = txt_username.text!.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).filter{!" \n\t\r".contains($0)}
        
        if uname.isEmpty{
            //show error alert
            self.showError(title: "Invalid Entry", msg: "Please enter username")
            return
        }

        self.setupHUD(msg: "Validating...")
        Utils.isValidUserName(uname: uname) { (res) in
            self.hideHUD()
            if !res{
                let dic: [String: Any] = [
                    User.key_fname: Me.fname,
                    User.key_uname: uname,
                    User.key_u_created: Utils.curTime
                ]
                
                self.setupHUD(msg: "Saving...")
                FUSER_REF
                    .document(uid)
                    .setData(dic, merge: true) { (err) in
                        self.hideHUD()
                        
                        if let error = err{
                            print(error.localizedDescription)
                            self.showError(title: "Error", msg: error.localizedDescription)
                            return
                        }

                        self.showSuccess(title: "Success", msg: "Username change successful")
                        Me.uname = uname

                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            //valid username
                            let sb = UIStoryboard(name: "Auth", bundle: nil)
                            let vc = sb.instantiateViewController(withIdentifier: "VC_HeaderImage") as! VC_HeaderImage
                            
                            self.navigationController?.pushViewController(vc, animated: true)
                        }
                    }
            }
            else{
                self.showError(title: "Username Taken", msg: "Try another username to join")
            }
        }
    }
}
