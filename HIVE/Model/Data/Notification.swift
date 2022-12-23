//
//  Notification.swift
//  HIVEcopy
//
//  Created by Kassy Pop on 8/12/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

enum NotiType: Int {
    case Like = 0
    case Comment = 1
    case Follow = 2
    case CommentMention = 3
    case PostMention = 4
    case Lock = 5
    case ChatMessage = 6
    case CommentLike = 7
    case CommentOnComment = 8
    
    var description: String {
        switch self {
        case .Like: return " liked your post"
        case .Comment: return " commented on your post"
        case .Follow: return " started following you"
        case .CommentMention: return " mentioned you in a comment"
        case .PostMention: return " mentioned you in a post"
        case .Lock: return " sent follow request"
        case .ChatMessage: return " sent message"
        case .CommentLike: return " liked your comment"
        case .CommentOnComment: return " replied to your comment"
        }
    }
    
    init(index: Int) {
        switch index {
        case 0: self = .Like
        case 1: self = .Comment
        case 2: self = .Follow
        case 3: self = .CommentMention
        case 4: self = .PostMention
        case 5: self = .Lock
        case 6: self = .ChatMessage
        case 7: self = .CommentLike
        case 8: self = .CommentOnComment
        default: self = .Like
        }
    }
}

enum NotiAcceptType: Int{
    case Nothing = 0
    case Accepted = 1
    case Declined = 2
    
    init(index: Int){
        switch index{
        case 0: self = .Nothing
        case 1: self = .Accepted
        case 2: self = .Declined
        default: self = .Nothing
        }
    }
}
class Noti {
    var id: String = ""
    var created: Double = 0
    var uid: String = ""
    var pid: String = ""
    var cmtId: String = ""

    var type: NotiType = .Like

    var cmtMsg: String = ""
    var chatMsg: String = ""
    
    var acceptStatus: NotiAcceptType = .Nothing
    
    static let key_created: String = "created"
    static let key_type: String = "type"
    
    static let key_uid: String = "uid"
    static let key_pid: String = "postId"
    static let key_cmtId: String = "commentId"
    
    static let key_cmtTxt: String = "commentTxt"
    static let key_chatMsg: String = "chatTxt"
    
    static let key_accepted: String = "accepted"
    
    static let key_collection_notifications: String = "notifications"
    static let key_last_checked: String = "last_checked"
    static let key_unread_count: String = "unread"
    
    init(id: String, dic: [String: Any]){
        self.id = id
        
        if let created = dic[Noti.key_created] as? Double {
            self.created = created
        }
        if let type = dic[Noti.key_type] as? Int {
            self.type = NotiType(index: type)
        }
        
        if let uid = dic[Noti.key_uid] as? String {
            self.uid = uid
        }
        if let pid = dic[Noti.key_pid] as? String {
            self.pid = pid
        }
        if let cmtId = dic[Noti.key_cmtId] as? String {
            self.cmtId = cmtId
        }
        
        if let cmtTxt = dic[Noti.key_cmtTxt] as? String{
            self.cmtMsg = cmtTxt
        }
        if let chatTxt = dic[Noti.key_chatMsg] as? String{
            self.chatMsg = chatTxt
        }
        
        if let accepted = dic[Noti.key_accepted] as? Int{
            self.acceptStatus = NotiAcceptType(index: accepted)
        }
    }
    
    static func sendFollowRequest(uid: String){
        guard let cuid = CUID else { return }
        
        let nid = Utils.curTimeStr
        
        let data: [String : Any] = [
            Noti.key_created: Utils.curTime,
            Noti.key_uid: cuid,
            Noti.key_type: NotiType.Lock.rawValue]
        
        FNOTIFICATIONS_REF
            .document(uid)
            .collection(Noti.key_collection_notifications)
            .document(nid)
            .setData(data)
        FNOTIFICATIONS_REF
            .document(uid)
            .setData([
                Noti.key_unread_count: FieldValue.increment(Int64(1))
            ], merge: true)
        
        Utils.fetchUser(uid: uid) { (rusr) in
            guard let usr = rusr, usr.push_follow else { return }
            
            PushNotificationSender.sendNotification(to: uid, title: "Hive", body: "\(Me.displayName) sent follow request.")
        }
    }
    
    static func sendFollow(uid: String){
        guard let cuid = CUID else { return }
        let nid = Utils.curTimeStr
        
        let data: [String : Any] = [
            Noti.key_created: Utils.curTime,
            Noti.key_uid: cuid,
            Noti.key_type: NotiType.Follow.rawValue]
        
        FNOTIFICATIONS_REF
            .document(uid)
            .collection(Noti.key_collection_notifications)
            .document(nid)
            .setData(data)
        FNOTIFICATIONS_REF
            .document(uid)
            .setData([
                Noti.key_unread_count: FieldValue.increment(Int64(1))
            ], merge: true)
        
        Utils.fetchUser(uid: uid) { (rusr) in
            guard let usr = rusr, usr.push_follow else { return }
            
            PushNotificationSender.sendNotification(to: uid, title: "Hive", body: "\(Me.displayName) started following you.")
        }
    }
    
    static func sendPostLike(uid: String, pid: String){
        guard let cuid = CUID else { return }
        if cuid == uid { return }
        
        let nid = Utils.curTimeStr
        
        let data: [String : Any] = [
            Noti.key_created: Utils.curTime,
            Noti.key_uid: cuid,
            Noti.key_type: NotiType.Like.rawValue,
            Noti.key_pid: pid]
        
        FNOTIFICATIONS_REF
            .document(uid)
            .collection(Noti.key_collection_notifications)
            .document(nid)
            .setData(data)
        FNOTIFICATIONS_REF
            .document(uid)
            .setData([
                Noti.key_unread_count: FieldValue.increment(Int64(1))
            ], merge: true)
        
        Utils.fetchUser(uid: uid) { (rusr) in
            guard let usr = rusr, usr.push_likes else { return }
            
            PushNotificationSender.sendNotification(to: uid, title: "Hive", body: "\(Me.displayName) liked your post.")
        }
    }
    
    static func sendMessageNotification(uid: String, msg: String, command: Bool = false){
        guard let cuid = CUID else { return }
        guard cuid != uid else { return }

        let nid = Utils.curTimeStr
        
        let data: [String : Any] = [
            Noti.key_created: Utils.curTime,
            Noti.key_uid: cuid,
            Noti.key_type: NotiType.ChatMessage.rawValue,
            Noti.key_chatMsg: msg]
        
        FNOTIFICATIONS_REF
            .document(uid)
            .collection(Noti.key_collection_notifications)
            .document(nid)
            .setData(data)
        FNOTIFICATIONS_REF
            .document(uid)
            .setData([
                Noti.key_unread_count: FieldValue.increment(Int64(1))
            ], merge: true)
        
        if command{
            PushNotificationSender.sendNotification(to: uid, title: "Hive", body: "\(Me.displayName) sent you a message - \(msg)")
        }
        else{
            Utils.fetchUser(uid: uid) { (rusr) in
                guard let usr = rusr, usr.push_message else { return }
                
                PushNotificationSender.sendNotification(to: uid, title: "Hive", body: "\(Me.displayName) sent you a message - \(msg)")
            }
        }
    }
    
    static func sendCommentLikeNotification(cmt: Comment){
        guard let cuid = CUID else { return }
        if cmt.uid != cuid{
            let nid = Utils.curTimeStr

            let data: [String : Any] = [
                Noti.key_created: Utils.curTime,
                Noti.key_uid: cuid,
                Noti.key_type: NotiType.CommentLike.rawValue,
                Noti.key_pid: cmt.pid,
                Noti.key_cmtTxt: cmt.msg]
            
            FNOTIFICATIONS_REF
                .document(cmt.uid)
                .collection(Noti.key_collection_notifications)
                .document(nid)
                .setData(data)
            FNOTIFICATIONS_REF
                .document(cmt.uid)
                .setData([
                    Noti.key_unread_count: FieldValue.increment(Int64(1))
                ], merge: true)
            
            Utils.fetchUser(uid: cmt.uid) { (rusr) in
                guard let usr = rusr, usr.push_comment else { return }
                PushNotificationSender.sendNotification(to: cmt.uid, title: "Hive", body: "\(Me.displayName) liked your comment - \(cmt.msg)")
            }
        }
    }
    static func sendCommentNotification(cmt: Comment, parent: Comment? = nil){
        guard let cuid = CUID else { return }
        Utils.fetchPost(pid: cmt.pid) { (rpst) in
            guard let pst = rpst else { return }
            
            if cuid != pst.ouid{
                let nid = Utils.curTimeStr
                
                let data: [String : Any] = [
                    Noti.key_created: Utils.curTime,
                    Noti.key_uid: cuid,
                    Noti.key_type: NotiType.Comment.rawValue,
                    Noti.key_pid: cmt.pid,
                    Noti.key_cmtTxt: cmt.msg]
                
                FNOTIFICATIONS_REF
                    .document(pst.ouid)
                    .collection(Noti.key_collection_notifications)
                    .document(nid)
                    .setData(data)
                FNOTIFICATIONS_REF
                    .document(pst.ouid)
                    .setData([
                        Noti.key_unread_count: FieldValue.increment(Int64(1))
                    ], merge: true)
                
                Utils.fetchUser(uid: pst.ouid) { (rusr) in
                    guard let usr = rusr, usr.push_comment else { return }
                    PushNotificationSender.sendNotification(to: pst.ouid, title: "Hive", body: "\(Me.displayName) commented on your post - \(cmt.msg)")
                }
            }
            
            if let parentCmt = parent, !cmt.parentId.isEmpty{
                let pnid = Utils.curTimeStr
                
                let pdata: [String : Any] = [
                    Noti.key_created: Utils.curTime,
                    Noti.key_uid: cuid,
                    Noti.key_type: NotiType.CommentOnComment.rawValue,
                    Noti.key_pid: cmt.pid,
                    Noti.key_cmtTxt: cmt.msg]
                
                FNOTIFICATIONS_REF
                    .document(parentCmt.uid)
                    .collection(Noti.key_collection_notifications)
                    .document(pnid)
                    .setData(pdata)
                FNOTIFICATIONS_REF
                    .document(parentCmt.uid)
                    .setData([
                        Noti.key_unread_count: FieldValue.increment(Int64(1))
                    ], merge: true)
                
                Utils.fetchUser(uid: parentCmt.uid) { (rusr) in
                    guard let usr = rusr, usr.push_comment else { return }
                    PushNotificationSender.sendNotification(to: parentCmt.uid, title: "Hive", body: "\(Me.displayName) replied on your comment - \(cmt.msg)")
                }
            }
            
            Utils.fetchUserName(msg: cmt.msg).forEach { (uname) in
                Utils.fetchUser(uname: uname) { (rusr) in
                    guard let usr = rusr, usr.push_comment else { return }

                    let nid = Utils.curTimeStr
                    let data: [String: Any] = [
                        Noti.key_created: Utils.curTime,
                        Noti.key_uid: cuid,
                        Noti.key_type: NotiType.CommentMention.rawValue,
                        Noti.key_cmtId: cmt.mid,
                        Noti.key_pid: cmt.pid,
                        Noti.key_cmtTxt: cmt.msg
                    ]
                    
                    FNOTIFICATIONS_REF
                        .document(usr.uid)
                        .collection(Noti.key_collection_notifications)
                        .document(nid)
                        .setData(data)
                    FNOTIFICATIONS_REF
                        .document(usr.uid)
                        .setData([
                            Noti.key_unread_count: FieldValue.increment(Int64(1))
                        ], merge: true)
                    
                    PushNotificationSender.sendNotification(to: usr.uid, title: "Hive", body: "\(Me.displayName) mentioned you on the post - \(cmt.msg)")
                }
            }
        }
    }
    
    func acceptFollowRequest(){
        guard let cuid = CUID else { return }
        let uid = self.uid

        FUSER_REF
            .document(uid)
            .collection(User.key_collection_following)
            .document(cuid)
            .setData([
                User.key_created: Utils.curTime
            ])
        FUSER_REF
            .document(uid)
            .updateData([
                User.key_num_following: FieldValue.increment(Int64(1))
            ])
        
        FUSER_REF
            .document(cuid)
            .collection(User.key_collection_followers)
            .document(uid)
            .setData([
                User.key_uid: uid,
                User.key_created: Utils.curTime
            ])
        FUSER_REF
            .document(cuid)
            .updateData([
                User.key_num_followers: FieldValue.increment(Int64(1))
            ])

        FNOTIFICATIONS_REF
            .document(cuid)
            .collection(Noti.key_collection_notifications)
            .document(self.id)
            .setData([
                Noti.key_accepted: NotiAcceptType.Accepted.rawValue
            ], merge: true)
        
        acceptStatus = .Accepted
    }
    
    func declineFollowRequest(){
        guard let cid = CUID else { return }
        let uid = self.uid

        FUSER_REF
            .document(uid)
            .collection(User.key_collection_following)
            .document(cid)
            .delete()
        
        FUSER_REF
            .document(cid)
            .collection(User.key_collection_followers)
            .document(uid)
            .delete()
        
        FNOTIFICATIONS_REF
            .document(cid)
            .collection(Noti.key_collection_notifications)
            .document(self.id)
            .setData([
                Noti.key_accepted: NotiAcceptType.Declined.rawValue
            ],
            merge: true)

        acceptStatus = .Declined
    }
}
