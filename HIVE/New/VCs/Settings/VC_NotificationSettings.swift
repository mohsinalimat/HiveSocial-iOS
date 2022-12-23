//
//  VC_NotificationSettings.swift
//  HIVE
//
//  Created by elitemobile on 12/29/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import UIKit
import Firebase

class VC_NotificationSettings: UIViewController {

    @IBOutlet weak var sw_push_notification: UISwitch!
    
    @IBOutlet weak var sw_likes: UISwitch!
    @IBOutlet weak var sw_follow: UISwitch!
    @IBOutlet weak var sw_message: UISwitch!
    @IBOutlet weak var sw_comment: UISwitch!
    
    @IBOutlet weak var sw_sms: UISwitch!
    @IBOutlet weak var sw_email: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initComponents()
    }
    
    func initComponents(){
        guard (CUID) != nil else {
            self.navigationController?.popViewController(animated: true)
            return
        }
        
        sw_push_notification.isOn = Me.push_notification
        sw_likes.isOn = Me.push_likes
        sw_follow.isOn = Me.push_follow
        sw_message.isOn = Me.push_message
        sw_comment.isOn = Me.push_comment
        sw_sms.isOn = Me.push_sms
        sw_email.isOn = Me.push_email
        
        self.addSwipeRight()
    }
    
    @IBAction func opChangePushNotification(_ sender: Any) {
        guard let cuid = CUID else { return }
        
        sw_likes.isOn = sw_push_notification.isOn
        sw_follow.isOn = sw_push_notification.isOn
        sw_message.isOn = sw_push_notification.isOn
        sw_comment.isOn = sw_push_notification.isOn
        
        FUSER_REF
            .document(cuid)
            .setData([
                User.key_push_notification: sw_push_notification.isOn,
                User.key_push_likes: sw_likes.isOn,
                User.key_push_follow: sw_follow.isOn,
                User.key_push_message: sw_message.isOn,
                User.key_push_comment: sw_comment.isOn
            ], merge: true) { (err) in
                if let error = err{
                    print(error.localizedDescription)
                    return
                }
                print("updated push notification")
                
                Me.push_notification = self.sw_push_notification.isOn
                Me.push_likes = self.sw_likes.isOn
                Me.push_follow = self.sw_follow.isOn
                Me.push_message = self.sw_message.isOn
                Me.push_comment = self.sw_comment.isOn
                
                Me.saveLocal()
            }
    }
    @IBAction func opChangeLikes(_ sender: Any) {
        guard let cuid = CUID else { return }
        
        if sw_likes.isOn{
            sw_push_notification.isOn = true
        }
        
        FUSER_REF
            .document(cuid)
            .setData([
                User.key_push_notification: sw_push_notification.isOn,
                User.key_push_likes: sw_likes.isOn
            ], merge: true) { (err) in
                if let error = err{
                    print(error.localizedDescription)
                    return
                }
                print("updated notification - likes")
                
                Me.push_notification = self.sw_push_notification.isOn
                Me.push_likes = self.sw_likes.isOn
                
                Me.saveLocal()
            }
    }
    @IBAction func opChangeFollow(_ sender: Any) {
        guard let cuid = CUID else { return }
        
        if sw_follow.isOn{
            sw_push_notification.isOn = true
        }
        
        FUSER_REF
            .document(cuid)
            .setData([
                User.key_push_notification: sw_push_notification.isOn,
                User.key_push_follow: sw_follow.isOn
            ], merge: true) { (err) in
                if let error = err{
                    print(error.localizedDescription)
                    return
                }
                print("updated notification - follow")
                
                Me.push_notification = self.sw_push_notification.isOn
                Me.push_follow = self.sw_follow.isOn
                
                Me.saveLocal()
            }
    }
    @IBAction func opChangeMessage(_ sender: Any) {
        guard let cuid = CUID else { return }
        
        if sw_message.isOn{
            sw_push_notification.isOn = true
        }
        
        FUSER_REF
            .document(cuid)
            .setData([
                User.key_push_notification: sw_push_notification.isOn,
                User.key_push_message: sw_message.isOn
            ], merge: true) { (err) in
                if let error = err{
                    print(error.localizedDescription)
                    return
                }
                print("updated notification - message")
                
                Me.push_notification = self.sw_push_notification.isOn
                Me.push_message = self.sw_message.isOn
                
                Me.saveLocal()
            }
    }
    @IBAction func opChangeComment(_ sender: Any) {
        guard let cuid = CUID else { return }
        
        if sw_comment.isOn{
            sw_push_notification.isOn = true
        }
        
        FUSER_REF
            .document(cuid)
            .setData([
                User.key_push_notification: sw_push_notification.isOn,
                User.key_push_comment: sw_comment.isOn
            ], merge: true) { (err) in
                if let error = err{
                    print(error.localizedDescription)
                    return
                }
                print("updated notification - comments")
                
                Me.push_notification = self.sw_push_notification.isOn
                Me.push_comment = self.sw_comment.isOn
                
                Me.saveLocal()
            }
    }
    
    @IBAction func opChangeSMS(_ sender: Any) {
        guard let cuid = CUID else { return }
        
        FUSER_REF
            .document(cuid)
            .setData([
                User.key_push_sms: sw_sms.isOn
            ], merge: true) { (err) in
                if let error = err{
                    print(error.localizedDescription)
                    return
                }
                
                print("updated sms setting")
                
                Me.push_sms = self.sw_sms.isOn
                
                Me.saveLocal()

            }
    }
    @IBAction func opChangeEmail(_ sender: Any) {
        guard let cuid = CUID else { return }
        
        FUSER_REF
            .document(cuid)
            .setData([
                User.key_push_email: sw_email.isOn
            ], merge: true) { (err) in
                if let error = err{
                    print(error.localizedDescription)
                    return
                }
                print("updated email setting")
                
                Me.push_email = self.sw_email.isOn
                
                Me.saveLocal()
            }
    }
    
    
    @IBAction func opBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func opSave(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}
