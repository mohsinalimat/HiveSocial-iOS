//
//  VC_Menu.swift
//  HIVE
//
//  Created by elitemobile on 12/2/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import UIKit
import Firebase

class VC_Menu: UIViewController {
    
    @IBOutlet weak var img_userAvatar: UIImageView!
    @IBOutlet weak var lbl_username: UILabel!
    
    @IBOutlet weak var btn_close: UIButton!
    
    @IBOutlet weak var v_editProfile: UIView!
    @IBOutlet weak var v_accountSetting: UIView!
    @IBOutlet weak var v_likedPosts: UIView!
    @IBOutlet weak var v_music: UIView!
    @IBOutlet weak var v_notifications: UIView!
    @IBOutlet weak var v_blocked: UIView!
    
    @IBOutlet weak var btn_logout: UIButton!
    
    @IBOutlet weak var ic_edit_profile: UIImageView!
    @IBOutlet weak var ic_account_setting: UIImageView!
    @IBOutlet weak var ic_liked_posts: UIImageView!
    @IBOutlet weak var ic_music: UIImageView!
    @IBOutlet weak var ic_notifications: UIImageView!
    @IBOutlet weak var ic_blocked: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initComponents()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        lbl_username.text = Me.uname
        if !Me.avatar.isEmpty{
            img_userAvatar.loadImg(str: Me.avatar, user: true)
        }
    }
    func initComponents(){
        addSwipeRight()
        
        v_editProfile.makeRoundView(r: 2)
        v_accountSetting.makeRoundView(r: 2)
        v_likedPosts.makeRoundView(r: 2)
        v_music.makeRoundView(r: 2)
        v_notifications.makeRoundView(r: 2)
        
        ic_edit_profile.image = UIImage(named: "mic_settings_user")?.withRenderingMode(.alwaysTemplate)
        ic_account_setting.image = UIImage(named: "mic_settings_account")?.withRenderingMode(.alwaysTemplate)
        ic_liked_posts.image = UIImage(named: "mic_settings_like")?.withRenderingMode(.alwaysTemplate)
        ic_music.image = UIImage(named: "mic_settings_music")?.withRenderingMode(.alwaysTemplate)
        ic_notifications.image = UIImage(named: "mic_settings_notification")?.withRenderingMode(.alwaysTemplate)
        ic_blocked.image = UIImage(named: "mic_block_black")?.withRenderingMode(.alwaysTemplate)


        btn_close.setImage(UIImage(named: "mic_settings_close")?.withRenderingMode(.alwaysTemplate), for: .normal)
        btn_close.makeRoundView(r: 10)

        img_userAvatar.makeCircleView()
        
        v_editProfile.layer.borderWidth = 0.5
        v_editProfile.layer.borderColor = UIColor(named: "col_v_outline")!.cgColor
        v_accountSetting.layer.borderWidth = 0.5
        v_accountSetting.layer.borderColor = UIColor(named: "col_v_outline")!.cgColor
        v_likedPosts.layer.borderWidth = 0.5
        v_likedPosts.layer.borderColor = UIColor(named: "col_v_outline")!.cgColor
        v_music.layer.borderWidth = 0.5
        v_music.layer.borderColor = UIColor(named: "col_v_outline")!.cgColor
        v_notifications.layer.borderWidth = 0.5
        v_notifications.layer.borderColor = UIColor(named: "col_v_outline")!.cgColor
        v_blocked.layer.borderWidth = 0.5
        v_blocked.layer.borderColor = UIColor(named: "col_v_outline")!.cgColor

        v_editProfile.addShadow(circle: true, shadowCol: UIColor(named: "col_v_outline_shadow")!.cgColor, shadowOpacity: 1, shadowRadius: 3)
        v_accountSetting.addShadow(circle: true, shadowCol: UIColor(named: "col_v_outline_shadow")!.cgColor, shadowOpacity: 1, shadowRadius: 3)
        v_likedPosts.addShadow(circle: true, shadowCol: UIColor(named: "col_v_outline_shadow")!.cgColor, shadowOpacity: 1, shadowRadius: 3)
        v_music.addShadow(circle: true, shadowCol: UIColor(named: "col_v_outline_shadow")!.cgColor, shadowOpacity: 1, shadowRadius: 3)
        v_notifications.addShadow(circle: true, shadowCol: UIColor(named: "col_v_outline_shadow")!.cgColor, shadowOpacity: 1, shadowRadius: 3)
        v_blocked.addShadow(circle: true, shadowCol: UIColor(named: "col_v_outline_shadow")!.cgColor, shadowOpacity: 1, shadowRadius: 3)

        btn_logout.makeRoundView(r: 4)
    }
    
    @IBAction func opEditProfile(_ sender: Any) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "VC_EditProfile") as! VC_EditProfile
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func opAccountSettings(_ sender: Any) {
        let sb = UIStoryboard(name: "Menu", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "VC_AccountSettings") as! VC_AccountSettings
        
        self.navigationController?.pushViewController(vc, animated: true)
    }

    var count = 0
    @IBAction func opLikedPosts(_ sender: Any) {
        if Me.uid == vipUser{
            count += 1
            if count == 7{
                let sb = UIStoryboard(name: "TB_CL", bundle: nil)
                let vc = sb.instantiateViewController(withIdentifier: "VC_Hashtag") as! VC_Hashtag
                
                vc.isLikedPosts = true
                vc.uid = Me.uid
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
        else{
            let sb = UIStoryboard(name: "TB_CL", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "VC_Hashtag") as! VC_Hashtag
            
            vc.isLikedPosts = true
            vc.uid = Me.uid
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func opMusic(_ sender: Any) {
        let sb = UIStoryboard(name: "Menu", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "VC_MusicSettings") as! VC_MusicSettings

        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func opNotifications(_ sender: Any) {
        let sb = UIStoryboard(name: "Menu", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "VC_NotificationSettings") as! VC_NotificationSettings
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func opBlocked(_ sender: Any) {
        let sb = UIStoryboard(name: "TB_CL", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "VC_Blocked") as! VC_Blocked
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func opLogout(_ sender: Any) {
        let logoutAlert = UIAlertController(title: "Logout", message: "Are you sure you want to logout?", preferredStyle: .alert)
        logoutAlert.addAction(UIAlertAction(title: "Logout", style: .destructive, handler: { (_) in
            self.logout()
        }))
        logoutAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(logoutAlert, animated: true, completion: nil)
    }
    
    @IBAction func opClose(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func logout() {
        do {
            FeedPostsManager.shared.logout()
            FeaturedPostsManager.shared.logout()
            SearchManager.shared.logout()
            TagPostsManager.shared.logout()
            ChatManager.shared.logout()
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "logoutProfile"), object: nil)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "logoutHome"), object: nil)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "logoutAlert"), object: nil)


            try Auth.auth().signOut()
                
            Me = User()
            Me.saveLocal()
        } catch let error {
            print("~>There was an error logging out: \(error)")
            return
        }
        
        checkIfUserIsLoggedIn()
    }

    func checkIfUserIsLoggedIn() {
        if Auth.auth().currentUser == nil {
            DispatchQueue.main.async {
                let sb = UIStoryboard(name: "Auth", bundle: nil)
                let nav_auth = sb.instantiateViewController(withIdentifier: "nav_auth") as! UINavigationController
                
                nav_auth.modalPresentationStyle = .overFullScreen
                self.present(nav_auth, animated: true) {
                }
            }
            return
        }
    }
}
