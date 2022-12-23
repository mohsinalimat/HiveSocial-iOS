//
//  cv_tabbar.swift
//  HIVE
//
//  Created by elitemobile on 11/11/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import UIKit

class cv_tabbar: UIView {
    @IBOutlet weak var img_tab_0: UIImageView!
    @IBOutlet weak var img_tab_1: UIImageView!
    @IBOutlet weak var img_tab_2: UIImageView!
    @IBOutlet weak var img_tab_3: UIImageView!
    @IBOutlet weak var img_tab_4: UIImageView!
    @IBOutlet weak var img_avatar_out: UIImageView!
    
    @IBOutlet weak var img_notification: UIImageView!
    @IBOutlet weak var v_music: UIView!
    
    var selectedIndex: Int = 0
    var opSelectAction1: (() -> Void)?
    var opSelectAction2: (() -> Void)?
    var opSelectAction3: (() -> Void)?
    var opSelectAction4: (() -> Void)?
    var opSelectAction5: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initComponents()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
    }
    
    func initComponents(){
        img_notification.isHidden = true
        img_tab_4.makeCircleView()
        img_avatar_out.makeCircleView()
        updateIndex()
        v_music.isHidden = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateAvatar), name: NSNotification.Name(rawValue: "updateAvatar"), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(showMusicCover), name: NSNotification.Name(rawValue: "showMusicCover"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(hideMusicCover), name: NSNotification.Name(rawValue: "hideMusicCover"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(showNotificationBadge), name: NSNotification.Name(rawValue: "showNotificationBadge"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(hideNotificationBadge), name: NSNotification.Name(rawValue: "hideNotificationBadge"), object: nil)

    }
    
    @objc func showNotificationBadge(){
        self.img_notification.isHidden = false
    }
    @objc func hideNotificationBadge(){
        self.img_notification.isHidden = true
    }
    
    @objc func showMusicCover(){
        if !self.v_music.isHidden{
            return
        }
        v_music.alpha = 0
        v_music.isHidden = true
        UIView.transition(with: self.v_music, duration: 0.5, options: .transitionCrossDissolve, animations: {
            self.v_music.isHidden = false
            self.v_music.alpha = 1
        }, completion: { (_) in
        })
    }
    @objc func hideMusicCover(){
        if self.v_music.isHidden{
            return
        }
        v_music.alpha = 1
        v_music.isHidden = false
        UIView.transition(with: self.v_music, duration: 0.5, options: .transitionCrossDissolve, animations: {
            self.v_music.alpha = 0
        }, completion: { (_) in
            self.v_music.isHidden = true
        })
    }
    
    @objc func updateAvatar(){
        img_tab_4.loadImg(str: Me.avatar, user: true)
        img_avatar_out.layer.borderWidth = 1
        img_avatar_out.layer.borderColor = selectedIndex == 4 ? UIColor.brand().cgColor : UIColor.lightGray.cgColor
    }
    
    func updateNotification(isExisting: Bool = false){
        img_notification.isHidden = !isExisting
    }
    
    func updateIndex(){
        img_tab_0.isHighlighted = selectedIndex == 0
        img_tab_1.isHighlighted = selectedIndex == 1
        img_tab_2.isHighlighted = selectedIndex == 2
        img_tab_3.isHighlighted = selectedIndex == 3
        updateAvatar()
    }
    
    @IBAction func opFeed(_ sender: Any) {
        selectedIndex = 0
        updateIndex()
        
        self.opSelectAction1?()
    }
    
    @IBAction func opSearch(_ sender: Any) {
        selectedIndex = 1
        updateIndex()
        
        self.opSelectAction2?()
    }
    
    @IBAction func opPost(_ sender: Any) {
        self.opSelectAction3?()
    }
    
    @IBAction func opAlarm(_ sender: Any) {
        selectedIndex = 3
        updateIndex()
        
        self.opSelectAction4?()
    }
    
    @IBAction func opProfile(_ sender: Any) {
        selectedIndex = 4
        updateIndex()
        
        self.opSelectAction5?()
    }
}
