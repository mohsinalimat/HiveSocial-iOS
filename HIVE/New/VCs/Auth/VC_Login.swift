//
//  LoginVC.swift
//  HIVEcopy
//
//  Created by Kassy Pop on 7/8/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import UIKit
import Firebase
import FBSDKLoginKit
import FBSDKCoreKit
import GoogleSignIn
import CryptoKit
import AuthenticationServices

class VC_Login: UIViewController {
    @IBOutlet weak var v_email: UIView!
    @IBOutlet weak var v_password: UIView!
    @IBOutlet weak var txt_email: UITextField!
    @IBOutlet weak var txt_pass: UITextField!
    @IBOutlet weak var btn_visible: UIButton!
    
    @IBOutlet weak var btn_login: UIButton!
    @IBOutlet weak var v_apple: UIView!
    @IBOutlet weak var v_google: UIView!
    @IBOutlet weak var v_facebook: UIView!
    
    var passVisible: Bool = true
    var isFromSignup: Bool = false
    
    let btn_loginFB = FBLoginButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initComponents()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.view.endEditing(true)
        
        super.viewWillDisappear(animated)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        
        super.traitCollectionDidChange(previousTraitCollection)
        
        v_apple.layer.borderWidth = 1
        v_apple.layer.borderColor = UIColor.label.cgColor
    }
    
    func initComponents(){
        addSwipeRight()
        
        v_email.makeCircleView()
        v_password.makeCircleView()
        
        btn_login.makeCircleView()
        
        v_apple.makeCircleView()
        v_apple.layer.borderWidth = 1
        v_apple.layer.borderColor = UIColor.label.cgColor
        
        v_google.makeCircleView()
        v_google.layer.borderWidth = 1
        v_google.layer.borderColor = UIColor(named: "col_light_dark")!.cgColor
        
        v_facebook.makeCircleView()
        
        updatePassVisible()

        let dismissKeyboardTap = UITapGestureRecognizer(target: self, action: #selector(handleDismissKeyboardTap))
        view.addGestureRecognizer(dismissKeyboardTap)
        
        btn_loginFB.permissions = ["public_profile", "email"]
        btn_loginFB.delegate = self
        
//        GIDSignIn.sharedInstance()?.presentingViewController = self
//        GIDSignIn.sharedInstance()?.delegate = self
    }
    
    @IBAction func opVisible(_ sender: Any) {
        passVisible = !passVisible
        updatePassVisible()
    }
    
    func updatePassVisible(){
        btn_visible.setImage(passVisible ? UIImage(named: "nic_visible") : UIImage(named: "nic_invisible"), for: .normal)
        txt_pass.isSecureTextEntry = passVisible
    }
    
    @IBAction func opForgotPassword(_ sender: Any) {
        let sb = UIStoryboard(name: "Auth", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "VC_RecoverAccount") as! VC_RecoverAccount
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    fileprivate var currentNonce: String?
    @IBAction func opLoginApple(_ sender: Any) {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
//        request.requestedScopes = [.email]
        request.nonce = sha256(nonce)
        
        let authorizationControler = ASAuthorizationController(authorizationRequests: [request])
        authorizationControler.delegate = self
        authorizationControler.presentationContextProvider = self
        authorizationControler.performRequests()
    }
    
    private func sha256(_ input: String) -> String{
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            return String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    @IBAction func opLoginGoogle(_ sender: Any) {
        self.view.endEditing(true)
        
//        GIDSignIn.sharedInstance().signIn()
    }
    
    @IBAction func opLoginFacebook(_ sender: Any) {
        self.view.endEditing(true)
        
        btn_loginFB.sendActions(for: .touchUpInside)
    }
    
    @IBAction func opLogin(_ sender: Any) {
        self.view.endEditing(true)
        
        print("~>Handle login.")
        // properties
        guard
            let email = txt_email.text,
            let password = txt_pass.text, !email.isEmpty, !password.isEmpty else {
            self.showError(title: "Invalid Entry", msg: "Please make sure you have entered a valid username and password before attempting to login")
            return
        }
        
        setupHUD(msg: "Logging In...")
        // sign user in with email and password
        Auth.auth().signIn(withEmail: email, password: password) {(user, error) in
            self.hideHUD()

            // handle error
            if let error = error as NSError? {
                self.handle(error: error)
                return
            }
            
            self.openHome()
        }
    }
    
    func openHome(){
        guard let uid = CUID else { return }

        setupHUD(msg: "Logging In...")
        Utils.fetchUser(uid: uid) { (rusr) in
            self.hideHUD()
            guard let usr = rusr else {
                let usr = User()
                usr.uid = uid
                
                MyFollowings.removeAll()
                MyFollowers.removeAll()
                MyLikedPosts.removeAll()
                MyBlocks.removeAll()
                MyCommented.removeAll()
                
                Me = usr
                Me.saveLocal()
                
                let sb = UIStoryboard(name: "Auth", bundle: nil)
                let vc = sb.instantiateViewController(withIdentifier: "VC_Username") as! VC_Username
                self.navigationController?.pushViewController(vc, animated: true)
                return
            }
            
            MyFollowings.removeAll()
            MyFollowers.removeAll()
            MyLikedPosts.removeAll()
            MyBlocks.removeAll()
            MyCommented.removeAll()
            
            Me = usr
            Me.uid = uid
            Me.saveLocal()
            
            FUSER_REF
                .document(usr.uid)
                .updateData([
                    User.key_u_signed: Utils.curTime
                ])
            
            if Me.uname.isEmpty{
                let sb = UIStoryboard(name: "Auth", bundle: nil)
                let vc = sb.instantiateViewController(withIdentifier: "VC_Username") as! VC_Username
                
                self.navigationController?.pushViewController(vc, animated: true)
            }
            else{
                let pushManager = PushNotificationManager()
                pushManager.registerForPushNotifications()
                
                let sb = UIStoryboard(name: "Main", bundle: nil)
                let vc = sb.instantiateViewController(withIdentifier: "nav_home") as! UINavigationController
                vc.modalPresentationStyle = .overFullScreen
                self.present(vc, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func opSignup(_ sender: Any) {
        self.view.endEditing(true)
        
        if isFromSignup{
            self.navigationController?.popViewController(animated: true)
        }
        else{
            let sb = UIStoryboard(name: "Auth", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "VC_Signup") as! VC_Signup
            vc.isFromLogin = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @objc private func handleDismissKeyboardTap() {
        view.endEditing(true)
    }
    
    private func handle(error: NSError) {
        print("Unable to sign user in with error", error.localizedDescription)
        
        if error.code == AuthErrorCode.invalidEmail.rawValue || error.code == AuthErrorCode.userNotFound.rawValue {
            self.showError(title: "Login Error", msg: "That email address does not exist in our system.")
        } else if error.code == AuthErrorCode.wrongPassword.rawValue {
            if let email = txt_email.text, !email.isEmpty {
                let alert = UIAlertController(title: "Login Error", message: "", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))

                alert.message = "Invalid password.  Do you want to have a reset link sent to your email address?"
                alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { (_) in
                    Auth.auth().sendPasswordReset(withEmail: email) { [weak self] (error) in
                        guard let self = self else { return }
                        guard error == nil else {
                            self.showError(title: "Password Reset", msg: "There was an error reseting your password.  Please check your email address and try again.")
                            return
                        }
                        
                        self.showError(title: "Password Reset", msg: "If the e-mail you provided exists, you should get a link within the next 5 minutes.  Please contact \(EmailAddress.Support) to request a manual password reset if you do not receive a link within 24 hours.")
                    }
                }))
                
                present(alert, animated: true, completion: nil)
            } else {
                self.showError(title: "Login Error", msg: "Please make sure you enter a valid email address.")
            }
        } else {
            self.showError(title: "Login Error", msg: "An unknown login error occurred.  Please check your internet connection and try again.  Contact support at \(EmailAddress.Support) if the issue persists.")
        }
    }
    
    // Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: Array<Character> =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }
}

extension VC_Login: LoginButtonDelegate{
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        if let err = error{
            print(err.localizedDescription)
            return
        }
        
        guard let token = AccessToken.current, !token.isExpired else { return }
        
        let req = FBSDKLoginKit.GraphRequest(
            graphPath: "me",
            parameters: ["fields": "email, name, picture.type(large)"],
            tokenString: token.tokenString,
            version: nil,
            httpMethod: .get
        )
        
        self.setupHUD(msg: "Loading Info...")
        req.start { (connection, result, error) in
            self.hideHUD()
            
            if error == nil{
                guard let info = result as? [String: Any] else { return }
                
                guard let name = info["name"] as? String, !name.isEmpty else { return }
                guard let email = info["email"] as? String, !email.isEmpty else { return }
                
                let credential = FacebookAuthProvider.credential(withAccessToken: token.tokenString)
                
                self.setupHUD(msg: "Logging in...")
                Auth.auth().signIn(with: credential) { (authResult, error) in
                    self.hideHUD()

                    if let error = error as NSError? {
                        self.handle(error: error)
                        return
                    }
                    // User is signed in
                    self.openHome()
                }
            }
            else{
                if let error = error as NSError?{
                    self.handle(error: error)
                }
            }
        }
        
    }
}

//extension VC_Login: GIDSignInDelegate{
//    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
//        if let err = error{
//            print(err.localizedDescription)
//            return
//        }
//
//        guard let name = user.profile.name, !name.isEmpty else { return }
//        guard let email = user.profile.email, !email.isEmpty else { return }
//
//        guard let authentication = user.authentication else { return }
//
//        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
//
//        self.setupHUD(msg: "Logging in...")
//        Auth.auth().signIn(with: credential) { (authResult, error) in
//            self.hideHUD()
//
//            if let error = error as NSError? {
//                self.handle(error: error)
//                return
//            }
//
//            self.openHome()
//        }
//    }
//}

extension VC_Login: ASAuthorizationControllerDelegate{
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
//             Initialize a Firebase credential.
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: idTokenString,
                                                      rawNonce: nonce)
            // Sign in with Firebase.
            self.setupHUD(msg: "Logging in...")
            Auth.auth().signIn(with: credential) { (authResult, error) in
                self.hideHUD()

                if let err = error {
                    // Error. If error.code == .MissingOrInvalidNonce, make sure
                    // you're sending the SHA256-hashed nonce as a hex string with
                    // your request to Apple.
                    self.showError(title: "Login Error", msg: err.localizedDescription)
                    return
                }
                    self.openHome()
            }
        }
    }
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        self.showError(title: "Login Error", msg: error.localizedDescription)
    }
}

extension VC_Login: ASAuthorizationControllerPresentationContextProviding{
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}
