//
//  VC_Signup.swift
//  HIVE
//
//  Created by elitemobile on 8/10/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import UIKit
import Firebase
import BEMCheckBox

class VC_Signup: UIViewController {

    @IBOutlet weak var v_name: UIView!
    @IBOutlet weak var v_email: UIView!
    @IBOutlet weak var v_password: UIView!
    
    @IBOutlet weak var txt_name: UITextField!
    @IBOutlet weak var txt_email: UITextField!
    @IBOutlet weak var txt_password: UITextField!
    
    @IBOutlet weak var v_chk: BEMCheckBox!
    @IBOutlet weak var btn_visible: UIButton!
    @IBOutlet weak var btn_done: UIButton!
    
    @IBOutlet weak var lbl_terms: UILabel!
    var passVisible: Bool = true
    var isFromLogin: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initComponents()
    }
    
    let str_agreement = "I agree with Hive's terms & conditions"
    let url_terms: String = "terms & conditions"

    func initComponents(){
        addSwipeRight()
        
        v_name.makeCircleView()
        v_email.makeCircleView()
        v_password.makeCircleView()
        
        btn_done.makeCircleView()
        v_chk.boxType = .square
        
        updatePassVisible()
        setupAgreement()
        
        let dismissKeyboardTap = UITapGestureRecognizer(target: self, action: #selector(handleDismissKeyboardTap))
        view.addGestureRecognizer(dismissKeyboardTap)
    }
    
    func setupAgreement(){
        let range_term = (str_agreement as NSString).range(of: url_terms)
        let range_all = (str_agreement as NSString).range(of: str_agreement)
        
        let str_att = NSAttributedString(string: str_agreement)
        
        let mutableStr = NSMutableAttributedString()
        mutableStr.append(str_att)
        
        mutableStr.addAttribute(.font, value: UIFont.cFont_regular(size: 14), range: range_all)
        mutableStr.addAttribute(.foregroundColor, value: UIColor(named: "col_light_dark")!, range: range_all)
        mutableStr.addAttribute(.font, value: UIFont.cFont_bold(size: 15), range: range_term)
        
        lbl_terms.attributedText = mutableStr
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleLabelTapped))
        lbl_terms.addGestureRecognizer(tap)
        lbl_terms.isUserInteractionEnabled = true
    }

    @IBAction func opLogin(_ sender: Any) {
        if isFromLogin{
            self.navigationController?.popViewController(animated: true)
        }
        else{
            let sb = UIStoryboard(name: "Auth", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "VC_Login") as! VC_Login
            vc.isFromSignup = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func actionViewTerms(){
        let storyboard = UIStoryboard(name: "Auth", bundle: nil)
        let termsVC = storyboard.instantiateViewController(withIdentifier: "VC_Terms") as! VC_Terms
        termsVC.modalPresentationStyle = .overFullScreen
        self.v_chk.setOn(true, animated: true)
        present(termsVC, animated: true, completion: nil)
    }

    @IBAction func opDone(_ sender: Any) {
        let name: String = txt_name.text!
        let email: String = txt_email.text!
        let password: String = txt_password.text!
        
        if name.isEmpty || email.isEmpty || password.isEmpty{
            //show alert
            self.showError(title: "Invalid Entry", msg: "Please make sure you have entered a your name, email and password before attempting to signup")
            return
        }
        
        if !self.v_chk.on{
            let readAlert = UIAlertController(title: "Read Terms", message: "You must first read the terms before you agree to them.", preferredStyle: .alert)
            readAlert.addAction(UIAlertAction(title: "Read", style: .default, handler: { (_) in
                self.actionViewTerms()
            }))
            readAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(readAlert, animated: true, completion: nil)

            return
        }
        
        setupHUD(msg: "Signing Up...")

        Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
            self.hideHUD()
            // handle error
            if let error = error as NSError? {
                self.handle(error: error)
                return
            }
            
            let usr = User()
            usr.email = email
            usr.fname = name
            
            MyFollowings.removeAll()
            MyFollowers.removeAll()
            MyLikedPosts.removeAll()
            MyBlocks.removeAll()
            
            Me = usr
            guard let uid = CUID else { return }
            
            Me.uid = uid
            Me.saveLocal()
            
            let sb = UIStoryboard(name: "Auth", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "VC_Username") as! VC_Username
            
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func handle(error: NSError) {
        print("~>DEBUG: Failed to create user with error: \(error)")
        
        var msg: String = ""
        if error.code == AuthErrorCode.emailAlreadyInUse.rawValue {
            msg = "That e-mail is already in user.  Please contact \(EmailAddress.Support) to recover a lost password."
        } else if error.code == AuthErrorCode.weakPassword.rawValue {
            msg = "That password is too weak, please try another one."
        } else if error.code == AuthErrorCode.invalidEmail.rawValue {
            msg = "The email address you entered is not valid."
        } else {
            msg = "An unknown error occurred.  Please check your internet connection and try again."
        }
        
        self.showError(title: "Signup Error", msg: msg)
    }

    @IBAction func opVisible(_ sender: Any) {
        passVisible = !passVisible
        
        updatePassVisible()
    }
    
    func updatePassVisible(){
        btn_visible.setImage(UIImage(named: passVisible ? "nic_visible" : "nic_invisible"), for: .normal)
        
        txt_password.isSecureTextEntry = passVisible
    }
    
    @objc private func handleDismissKeyboardTap() {
        view.endEditing(true)
    }
}

extension VC_Signup{
    @objc func handleLabelTapped(gesture: UITapGestureRecognizer){
        let termString = str_agreement as NSString
        let termRange = termString.range(of: url_terms)
        
        let tapLocation = gesture.location(in: lbl_terms)
        let index = lbl_terms.indexOfAttributedTextCharacterAtPoint(point: tapLocation)
        
        if checkRange(termRange, contain: index) == true {
            self.actionViewTerms()
        }
    }
    
    func checkRange(_ range: NSRange, contain index: Int) -> Bool {
        return index > range.location && index < range.location + range.length
    }
}
