//
//  cell_noti_header.swift
//  HIVE
//
//  Created by elitemobile on 9/21/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import UIKit

class cell_noti_header: UIView {

    @IBOutlet weak var lbl_noti_count: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func refreshNotificationsCount(){
        FNOTIFICATIONS_REF
            .document(Me.uid)
            .getDocument(completion: { (doc, err) in
                if let error = err{
                    print(error.localizedDescription)
                    return
                }
                
                if let data = doc?.data(), let count = data[Noti.key_unread_count] as? Int{
                    if count > 0{
                        self.lbl_noti_count.text = "\(count) New Notifications"
                    }
                    else{
                        self.lbl_noti_count.text = "0 New Notifications"
                    }
                }
                else{
                    self.lbl_noti_count.text = "0 New Notifications"
                }
            })
        
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        NotificationCenter.default.post(name: NSNotification.Name("hideNotificationBadge"), object: nil, userInfo: nil)
    }
}
