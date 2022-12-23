//
//  AppDelegate.swift
//  HIVEcopy
//
//  Created by Kassy Pop on 7/8/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import UIKit
import Firebase
import GiphyUISDK
import IQKeyboardManagerSwift
import AVKit
//import FBSDKCoreKit
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        IQKeyboardManager.shared.enable = true
        
        FirebaseApp.configure()

        //facebook
//        ApplicationDelegate.shared.application(
//            application,
//            didFinishLaunchingWithOptions: launchOptions
//        )
        
        //google
//        GIDSignIn.sharedInstance()?.clientID = FirebaseApp.app()?.options.clientID
        
        //gif
        Giphy.configure(apiKey: GIPHYConstant.apiKey)
//        GiphyCore.shared.apiKey = GIPHYConstant.apiKey
                
        if Auth.auth().currentUser != nil {
            let usr = User()
            usr.loadLocal()
            if usr.uid.isEmpty {
                usr.saveLocal()
                
                do{
                    try Auth.auth().signOut()
                }
                catch(_){
                    print("error in signout")
                }
                
                return true
            }

            Me = usr

            FUSER_REF
                .document(usr.uid)
                .updateData([
                    User.key_u_signed: Utils.curTime
                ])
            
            Utils.fetchUser(uid: Me.uid) { (rusr) in
                guard let usr = rusr else { return }
                
                Me = usr
                Me.saveLocal()
            }

            let sb = UIStoryboard(name: "Main", bundle: nil)
            let nav_home = sb.instantiateViewController(withIdentifier: "nav_home") as! UINavigationController

            self.window?.rootViewController = nav_home
            self.window?.makeKeyAndVisible()
        }

        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).backgroundColor = UIColor.clear
        
        return true
    }
    
//    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
//        let googleDidHandle = GIDSignIn.sharedInstance().handle(url)
        
//        let facebookDidHandle = ApplicationDelegate.shared.application(
//            app,
//            open: url,
//            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
//            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
//        )
        
//        return facebookDidHandle// || googleDidHandle
//    }
}
