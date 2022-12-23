//
//  PushNotificationSender.swift
//  FirebaseStarterKit
//
//  Created by elitemobile on 11/25/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import UIKit
import Firebase

class PushNotificationSender {
    static func sendPushNotification(to token: String, title: String, body: String, badge: Int = 0) {
        let urlString = "https://fcm.googleapis.com/fcm/send"
        let url = NSURL(string: urlString)!
        let paramString: [String : Any] = ["to" : token,
                                           "notification" : ["title" : title, "body" : body, "sound": "default", "badge": badge],
                                           "data" : ["user" : "test_id"],
                                           "priority": "high"
        ]
        
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject:paramString, options: [.prettyPrinted])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("key=AAAA2LIpQBk:APA91bHwYsAjdBtpAmGroKKT7Up7BhMeRQgkhY-Ig2zKfln6vIKJoWsULZxIK6geU9F6TWeyiYVADCGl7U0MOfnErkgHMwTIgy3M5ErkhgQUSdxaixeTjoUakdQY3dUN4YNJXZmpFdIA", forHTTPHeaderField: "Authorization")
        
        let task =  URLSession.shared.dataTask(with: request as URLRequest)  { (data, response, error) in
            do {
                if let jsonData = data {
                    if let jsonDataDict  = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject] {
                        NSLog("Received data:\n\(jsonDataDict))")
                    }
                }
            } catch let err as NSError {
                print(err.debugDescription)
            }
        }
        task.resume()
    }
    
    static func sendNotification(to userId: String, title: String, body: String){
        Utils.fetchUser(uid: userId) { (rusr) in
            guard let usr = rusr else { return }
            if !usr.token.isEmpty{
                FNOTIFICATIONS_REF
                    .document(userId)
                    .getDocument { (doc, err) in
                        if let data = doc?.data(), let count = data[Noti.key_unread_count] as? Int{
                            PushNotificationSender.sendPushNotification(to: usr.token, title: title, body: body, badge: count + 1)
                        }
                        else{
                            PushNotificationSender.sendPushNotification(to: usr.token, title: title, body: body, badge: 1)
                        }
                    }
            }
        }
    }
}
