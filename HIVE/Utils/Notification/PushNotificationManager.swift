//
//  PushNotificationManager.swift
//  FirebaseStarterKit
//
//  Created by elitemobile on 11/25/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import Firebase
import FirebaseMessaging
import UIKit
import UserNotifications

class PushNotificationManager: NSObject, MessagingDelegate, UNUserNotificationCenterDelegate {
    
    override init() {
        super.init()
    }

    func registerForPushNotifications() {
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
            // For iOS 10 data message (sent via FCM)
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
        }
        Messaging.messaging().delegate = self

        UIApplication.shared.registerForRemoteNotifications()
        updateFirebasePushTokenIfNeeded()
    }

    func updateFirebasePushTokenIfNeeded() {
        guard let cuid = CUID else { return }
        guard let token = Messaging.messaging().fcmToken else { return }
        
        if Me.uid == cuid && Me.token != token{
            FUSER_REF
                .document(cuid)
                .updateData([
                    User.key_token: token
                ]) { (err) in
                    if let error = err{
                        print("PUSH TOKEN FAILED TO UPDATE: \(error.localizedDescription)")
                        return
                    }
                    print("PUSH TOKEN UPDATED SUCCESSFULLY.")
                }
        }
    }

//    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
//        print(remoteMessage.appData) // or do whatever
//    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let fcmToken = fcmToken{
            updateFirebasePushTokenIfNeeded()
            
            let dataDict: [String: String] = ["token": fcmToken]
            NotificationCenter.default.post(name: NSNotification.Name("FCMToken"), object: nil, userInfo: dataDict)
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print(response)
        print(response.notification.request.content.userInfo)
        
        completionHandler()
    }
}
