//
//  VC_AccountSettings.swift
//  HIVE
//
//  Created by elitemobile on 12/6/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import UIKit
import Firebase

class VC_AccountSettings: UIViewController {
    
    @IBOutlet weak var txt_username: UITextField!
    @IBOutlet weak var txt_phone: UITextField!
    @IBOutlet weak var btn_updateEmail: UIButton!
    @IBOutlet weak var btn_updatePass: UIButton!
    
    @IBOutlet weak var v_username: UIView!
    @IBOutlet weak var v_phone: UIView!
    
    @IBOutlet weak var btn_save: UIButton!
    @IBOutlet weak var sw_option: UISwitch!
    
    var user: User!
    
    var unameChanged: Bool = false
    var phoneChanged: Bool = false
    var privateChanged: Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadUserData()
        initComponents()
        updateSaveButton()
    }
    
    func initComponents(){
        addSwipeRight()
        
        v_username.makeRoundView(r: 2)
        v_phone.makeRoundView(r: 2)
        
        btn_updateEmail.makeRoundView(r: 4)
        btn_updatePass.makeRoundView(r: 4)
        
        txt_phone.delegate = self
        txt_username.delegate = self
    }
    
    func loadUserData(){
        self.user = Me
        
        self.txt_username.text = self.user.uname
        self.txt_phone.text = self.user.phone
        self.sw_option.isOn = self.user.is_private
    }
    
    @IBAction func opChangePrivate(_ sender: Any) {
        privateChanged = self.sw_option.isOn != Me.is_private
        updateSaveButton()
    }
    
    func updateSaveButton(){
        if unameChanged || phoneChanged || privateChanged{
            btn_save.setTitleColor(UIColor.active(), for: .normal)
        }
        else{
            btn_save.setTitleColor(UIColor.secondaryLabel, for: .normal)
        }
    }
    
    var isSaving: Bool = false
    func saveUserData(){
        guard let cid = CUID else { return }
        
        if isSaving{
            return
        }
        isSaving = false
        
        let username = txt_username.text!.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let phone = txt_phone.text!
        let isPrivate = sw_option.isOn
        
        self.setupHUD(msg: "Saving...")
        FUSER_REF
            .document(cid)
            .updateData([
                User.key_uname: username,
                User.key_phone: phone.trimmingCharacters(in: .whitespacesAndNewlines),
                User.key_private: isPrivate
            ]) { (err) in
                if let error = err{
                    print(error.localizedDescription)
                    self.hideHUD()
                    self.showError(msg: "Error in updating info. Try again later!")
                    return
                }

                Me.phone = phone
                if self.unameChanged || self.privateChanged{
                    Me.is_private = isPrivate
                    Me.uname = username
                    
                    Me.updateUserPostsInfo()
                }
                Me.saveLocal()
                
                self.unameChanged = false
                self.phoneChanged = false
                self.privateChanged = false
                
                self.updateSaveButton()
                self.isSaving = false
                
                self.hideHUD()
                self.showSuccess(title: "Success", msg: "Successfully Updated")
                DispatchQueue.main.async {
                    self.navigationController?.popViewController(animated: true)
                }

            }
    }
    
    @IBAction func opSave(_ sender: Any) {
        if !unameChanged && !phoneChanged && !privateChanged{
            return
        }
        if isSaving{
            return
        }
        if !checkItems(){
            return
        }
        
        let uname = txt_username.text!.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if unameChanged{
            self.setupHUD(msg: "Validating...")
            Utils.isValidUserName(uname: uname) { (res) in
                self.hideHUD()
                if res{
                    self.showError(title: "Username Taken", msg: "Try another username to join")
                }
                else{
                    self.saveUserData()
                }
            }
        }
        else{
            self.saveUserData()
        }
    }
    
    @IBAction func opChangeEmail(_ sender: Any) {
        guard let usr = Auth.auth().currentUser else { return }
        
        let alert = UIAlertController(title: "Hive", message: "Change Email Address", preferredStyle: .alert)
        alert.addTextField { (txt_oldEmail) in
            txt_oldEmail.text = usr.email
            txt_oldEmail.isEnabled = false
            txt_oldEmail.textColor = .lightGray
        }
        alert.addTextField { (txt_email) in
            txt_email.placeholder = "New Email Address"
            DispatchQueue.main.async {
                txt_email.becomeFirstResponder()
            }
        }
        
        alert.addAction(UIAlertAction(title: "Change", style: .default, handler: { (_) in
            let email: String = alert.textFields?[1].text ?? ""
            if !email.isEmpty{
                self.setupHUD(msg: "Updating...")
                usr.updateEmail(to: email) { (err) in
                    self.hideHUD()
                    if let error = err{
                        self.showError(title: "Error", msg: error.localizedDescription)
                        return
                    }
                    
                    self.showSuccess(title: "Success", msg: "Email updated successfully")
                }
            }
            else{
                self.showError(title: "Error", msg: "Please make sure you entered valid email address")
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    @IBAction func opChangePass(_ sender: Any) {
        guard let usr = Auth.auth().currentUser else { return }
        let alert = UIAlertController(title: "Hive", message: "Change Password", preferredStyle: .alert)
        alert.addTextField { (txt_pass) in
            txt_pass.placeholder = "New Password"
        }
        alert.addTextField { (txt_passConfirm) in
            txt_passConfirm.placeholder = "Confirm New Password"
        }
        
        alert.addAction(UIAlertAction(title: "Update", style: .default, handler: { (_) in
            let pass: String = alert.textFields?[0].text ?? ""
            let passConfirm: String = alert.textFields?[1].text ?? ""
            
            if !pass.isEmpty && pass == passConfirm{
                self.setupHUD(msg: "Updating...")
                usr.updatePassword(to: pass) { (err) in
                    self.hideHUD()
                    if let error = err{
                        self.showError(title: "Error", msg: error.localizedDescription)
                        return
                    }
                    
                    self.showSuccess(title: "Success", msg: "Password updated successfully")
                }
            }
            else{
                self.showError(title: "Error", msg: "Please make sure you entered valid password")
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func checkItems() -> Bool{
        let username = txt_username.text!
        let phone = txt_phone.text!
        
        if username != Me.uname && username.isEmpty{
            self.showError(title: "Error", msg: "Please enter correct value for UserName")
            txt_username.becomeFirstResponder()
            return false
        }
        if phone != Me.phone && phone.isEmpty{
            self.showError(title: "Error", msg: "Please enter correct value for Phone")
            txt_phone.becomeFirstResponder()
            return false
        }
        
        return true
    }
    
    @IBAction func opCancel(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}
extension VC_AccountSettings: UITextFieldDelegate{
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        switch(textField){
        case txt_username:
            self.unameChanged = textField.text!.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) != Me.uname
            break
        case txt_phone:
            self.phoneChanged = textField.text != Me.phone
            break
        default:
            break
        }
        self.updateSaveButton()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        switch(textField){
        case txt_username:
            self.unameChanged = textField.text!.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) != Me.uname
            break
        case txt_phone:
            self.phoneChanged = textField.text != Me.phone
            break
        default:
            break
        }
        self.updateSaveButton()
        return true
    }
}
