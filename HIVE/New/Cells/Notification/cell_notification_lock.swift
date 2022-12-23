//
//  cell_notification_lock.swift
//  HIVE
//
//  Created by elitemobile on 2/4/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import UIKit
import Firebase

class cell_notification_lock: UITableViewCell {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var notificationLabel: UILabel!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var declineButton: UIButton!
    
    @IBOutlet weak var constraintAcceptButtonWidth: NSLayoutConstraint!
    @IBOutlet weak var constraintAcceptButtonRight: NSLayoutConstraint!

    @IBOutlet weak var constraintDeclineButtonWidth: NSLayoutConstraint!
    @IBOutlet weak var constraintNotificationLabelRight: NSLayoutConstraint!
    
    var opAcceptAction: (() -> Void)?
    var opDeclineAction: (() -> Void)?
    var opOpenUserAction: ((User) -> Void)?

    var noti: Noti!
    var user: User!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        initComponents()
    }
    
    func initComponents(){
        //profileImageView
        profileImageView.makeCircleView()
        
        acceptButton.makeRoundView(r: 2)
        declineButton.makeRoundView(r: 2)
    }
    
    @IBAction func opAccept(_ sender: Any) {
        noti.acceptFollowRequest()
        updateButtons()
    }

    @IBAction func opDecline(_ sender: Any) {
        noti.declineFollowRequest()
        updateButtons()
    }
    
    func updateButtons(){
        if noti.acceptStatus == .Accepted{
            //accepted
            declineButton.isHidden = true
            acceptButton.setTitle("Accepted", for: .normal)
            acceptButton.isEnabled = false
            acceptButton.alpha = 0.7
            
            constraintAcceptButtonRight.constant = 0
            constraintAcceptButtonWidth.constant = 92
            constraintNotificationLabelRight.constant = 100
        }
        else if noti.acceptStatus == .Declined{
            //declined
            acceptButton.isHidden = true
            declineButton.setTitle("Declined", for: .normal)
            declineButton.isEnabled = false
            declineButton.alpha = 0.7

            constraintDeclineButtonWidth.constant = 92
            constraintNotificationLabelRight.constant = 100
        }
    }
    
    @IBAction func opOpenUser(_ sender: Any) {
        if let usr = self.user{
            self.opOpenUserAction?(usr)
        }
    }
    
    func setNoti(noti: Noti){
        self.noti = noti
        
        self.updateButtons()
        
        Utils.fetchUser(uid: noti.uid) { (rusr) in
            guard let usr = rusr else { return }
            self.user = usr
            self.profileImageView.loadImg(str: usr.thumb.isEmpty ? usr.avatar : usr.thumb, user: true)
            let attributedText = NSMutableAttributedString(string: usr.displayName, attributes: [NSAttributedString.Key.font: UIFont.cFont_medium(size: 17)])
            attributedText.append(NSAttributedString(string: noti.type.description, attributes: [NSAttributedString.Key.font: UIFont.cFont_regular(size: 17)]))

            let time: String = Date(timeIntervalSince1970: noti.created).timeAgoToDisplay(lowercased: true)
            attributedText.append(NSAttributedString(string: time, attributes: [NSAttributedString.Key.font: UIFont.cFont_regular(size: 15), NSAttributedString.Key.foregroundColor: UIColor.lightGray]))
            self.notificationLabel.attributedText = attributedText
        }
    }
}
