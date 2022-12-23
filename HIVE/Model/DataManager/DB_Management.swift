//
//  DB_Management.swift
//  HIVE
//
//  Created by elitemobile on 1/18/21.
//  Copyright © 2021 Kassy Pop. All rights reserved.
//

import Foundation
import Firebase

//update all posts and all users feed
public class DB_Management{
    var allPosts: [String: Post] = [:]
    
    func updateAllUsersFeed(){
        guard let cuid = CUID else { return }
        print(cuid)
        
        var count: Int = 0
        FPOSTS_REF
            .whereField(User.key_u_signed, isGreaterThan: 0)
            .getDocuments { (doc, err) in
                if let error = err{
                    print(error.localizedDescription)
                    return
                }
                
                var allUsersPosts: [String: [String: Post]] = [:]
                doc?.documents.forEach({ (item) in
                    let post = Post(pid: item.documentID, dic: item.data())
                    if post.pid.isEmpty || post.ouid.isEmpty{
                        print("Post Ids Error - \(post.pid)")
                        return
                    }
                    
                    if allUsersPosts[post.ouid] == nil{
                        allUsersPosts[post.ouid] = [:]
                    }
                    
                    allUsersPosts[post.ouid]![post.pid] = post
                })
                
                print("all posts count - \(doc?.documents.count ?? 0)")
                print("users that having posts - \(allUsersPosts.keys.count)")
                
                FUSER_REF
                    .whereField(User.key_num_following, isGreaterThan: 0)
                    .getDocuments { (doc, err) in
                        if let error = err{
                            print(error.localizedDescription)
                            return
                        }
                        
                        doc?.documents.forEach({ (item) in
                            FUSER_REF
                                .document(item.documentID)
                                .collection(User.key_collection_following)
                                .getDocuments { (fDoc, err) in
                                    count += 1
                                    if let error = err{
                                        print(error.localizedDescription)
                                        return
                                    }
                                    
                                    print("got followings - \(count) ---- uid ->\(item.documentID)")
                                    var followings: [String: FollowStatus] = [:]
                                    fDoc?.documents.forEach({ (fItem) in
                                        guard let uid = fItem.data()["uid"] as? String else { return }
                                        var time = Utils.curTime
                                        if let rtime = fItem.data()[User.key_created] as? Double{
                                            time = rtime
                                        }
                                        else{
                                            FUSER_REF
                                                .document(item.documentID)
                                                .collection(User.key_collection_following)
                                                .document(fItem.documentID)
                                                .updateData([
                                                    User.key_created: Utils.curTime
                                                ])
                                        }
                                        
                                        if let fType = fItem.data()["type"] as? Int {
                                            followings[uid] = FollowStatus(time: time, followType: FollowType(index: fType))
                                        }
                                        else{
                                            followings[uid] = FollowStatus(time: time, followType: .Following)
                                        }
                                        
                                    })
                                    
                                    FUSER_REF
                                        .document(item.documentID)
                                        .updateData([
                                            "update_feed": Utils.curTime
                                        ])
                                    
                                    followings.forEach { (fItem) in
                                        if fItem.value.followType == .Following{
                                            allUsersPosts[fItem.key]?.forEach({ (postVal) in
                                                FUSER_REF
                                                    .document(item.documentID)
                                                    .collection(User.key_collection_feed)
                                                    .document(postVal.key)
                                                    .setData([
                                                        "created": postVal.value.created,
                                                        "pid": postVal.key
                                                    ], merge: true)
                                            })
                                        }
                                    }
                                }
                        })
                        
                        print("users that having followings - \(doc?.documents.count ?? 0)")
                    }
            }
    }
    func updateAllPosts(){
        guard let cuid = CUID else { return }
        print(cuid)
        
        var count: Int = 0
        FPOSTS_REF
            .getDocuments { (doc, err) in
                if let error = err{
                    print(error.localizedDescription)
                    return
                }
                
                var allUsersPosts: [String: [String: Post]] = [:]
                doc?.documents.forEach({ (item) in
                    let post = Post(pid: item.documentID, dic: item.data())
                    if post.pid.isEmpty || post.ouid.isEmpty{
                        print("Post Ids Error - \(post.pid)")
                        return
                    }
                    
                    if allUsersPosts[post.ouid] == nil{
                        allUsersPosts[post.ouid] = [:]
                    }
                    
                    allUsersPosts[post.ouid]![post.pid] = post
                })
                
                print("all posts count - \(doc?.documents.count ?? 0)")
                print("users that having posts - \(allUsersPosts.keys.count)")
                
                var allUsers: [String: User] = [:]
                FUSER_REF
                    .getDocuments { (doc, err) in
                        if let error = err{
                            print(error.localizedDescription)
                            return
                        }
                        
                        doc?.documents.forEach({ (item) in
                            let usr = User(uid: item.documentID, data: item.data())
                            allUsers[usr.uid] = usr
                        })
                        
                        print("all users - \(doc?.documents.count ?? 0)")
                        
                        allUsersPosts.forEach { (item) in
                            guard let usr = allUsers[item.key] else { return }
                            item.value.forEach { (pst) in
                                FPOSTS_REF
                                    .document(pst.key)
                                    .updateData([
                                        Post.key_avatar: usr.thumb.isEmpty ? usr.avatar : usr.thumb,
                                        Post.key_uname: usr.uname
                                    ], completion: { (err) in
                                        if let error = err{
                                            print(error.localizedDescription)
                                            return
                                        }
                                        count += 1
                                        
                                        print("posts done - \(count) - \(pst.key)")
                                    })
                            }
                        }
                    }
            }
    }
    
    func updateFeaturedFeed(){
        //0207 - 09:33
        var count = 0
        FPOSTS_REF
            .whereField(Post.key_created, isGreaterThan: Utils.curTime - 60 * 60 * 10)
            .whereField(Post.key_created, isLessThan: Utils.curTime)
            .whereField(Post.key_type, in: [PostType.IMAGE.rawValue, PostType.VIDEO.rawValue])
            .limit(to: 1000)
            .getDocuments { (doc, err) in
                print(doc?.documents.count ?? 0)
                doc?.documents.forEach({ (doc) in
                    let post = Post(pid: doc.documentID, dic: doc.data())
                    let date = Date(timeIntervalSince1970: post.created)
                    let timeformat = DateFormatter()
                    timeformat.dateFormat = "yyyy_MM_dd"
                    let dateStr = timeformat.string(from: date)
                    
                    FPIDS_DATE_REF.document(dateStr).collection("posts").document(post.pid).setData([
                        Post.key_created: post.created
                    ])
                    FPIDS_DATE_REF.document(dateStr).setData([
                        "count": FieldValue.increment(Int64(1)),
                        "lastused": post.created
                    ], merge: true)
                })
            }
        
        return
    }
    func updateCategoriesFeed(categoryIndex: Int = 14){
        if categoryIndex >= categories.count{
            return
        }
        let item = categories[categoryIndex]
        let cateKeys = item[3] as! [String]
        let category = item[0] as! String
        var catePids: [String: String] = [:]
        var index = 0
        cateKeys
            .forEach { (key) in
                FHASHTAG_POSTS_REF
                    .document(key.lowercased())
                    .collection(Post.key_collection_posts)
                    .getDocuments { (doc, err) in
                        doc?.documents.forEach({ (keyItem) in
                            if catePids[keyItem.documentID] == nil{
                                catePids[keyItem.documentID] = "exist"
                                FCATE_REF
                                    .document("\(categoryIndex)")
                                    .collection("posts")
                                    .document(keyItem.documentID)
                                    .setData(
                                        keyItem.data()
                                    ) { (err) in
                                        if err == nil{
                                            index += 1
                                            print(index)
                                            
                                            if index == catePids.count{
                                                self.updateCategoriesFeed(categoryIndex: categoryIndex + 1)
                                            }
                                        }
                                    }
                            }
                        })
                        print("\(category) - #\(key) - \(doc?.documents.count ?? 0) - real - \(catePids.count)")
                    }
            }
    }
}
extension DB_Management{
    static func updateUserFollowers(lastUsedRef: QueryDocumentSnapshot? = nil){
        var query = FUSER_REF
            .whereField(User.key_u_signed, isGreaterThan: 0)
            .order(by: User.key_u_created, descending: true)
        if lastUsedRef != nil{
            query = query.start(afterDocument: lastUsedRef!)
        }
        query = query.limit(to: 500)
        query.getDocuments { (doc, err) in
            if let error = err{
                print(error.localizedDescription)
                return
            }
            
            if doc?.documents.count ?? 0 == 0{
                print("FINISHED!!!")
                return
            }
            
            let taskGroup = DispatchGroup()
            doc?.documents.forEach({ (item) in
                taskGroup.enter()
                let num_following = item.data()["num_following"] as? Int ?? 0
                let num_followers = item.data()["num_followers"] as? Int ?? 0
                FUSER_REF
                    .document(item.documentID)
                    .collection(User.key_collection_following)
                    .getDocuments { (doc, err) in
                        if let error = err{
                            print(error.localizedDescription)
                            taskGroup.leave()
                            return
                        }
                        let count = doc?.documents.count ?? 0
                        
                        if (count > 0 && count != num_following) || num_following < 0{
                            FUSER_REF.document(item.documentID).updateData([
                                "num_following": count
                            ])
                        }
                        taskGroup.leave()
                    }
                taskGroup.enter()
                FUSER_REF
                    .document(item.documentID)
                    .collection(User.key_collection_followers)
                    .getDocuments { (doc, err) in
                        if let error = err{
                            print(error.localizedDescription)
                            taskGroup.leave()
                            return
                        }
                        let count = doc?.documents.count ?? 0
                        if (count > 0 && count != num_followers) || num_followers < 0{
                            FUSER_REF.document(item.documentID).updateData([
                                "num_followers": count
                            ])
                        }
                        taskGroup.leave()
                    }
            })
            
            taskGroup.notify(queue: .main) {
                DispatchQueue.main.async {
                    guard let lUsedRef = doc?.documents.last else {
                        print("FINISHED")
                        return
                    }
                    self.updateUserFollowers(lastUsedRef: lUsedRef)
                }
            }
        }
    }
}
//MARK: - update hashTAG count
extension DB_Management{
    static func updateHashTagCount(){
        FHASHTAG_POSTS_REF
//            .whereField(HashTag.key_tag, isEqualTo: "art")
            .whereField(HashTag.key_last_used, isGreaterThan: 0)
            .order(by: HashTag.key_last_used, descending: true)
            .limit(to: 1000)
            .getDocuments { (doc, err) in
                if let error = err{
                    print(error.localizedDescription)
                    return
                }
                
                doc?.documents.forEach({ (item) in
                    THashtags.append(item.documentID)
                })
                
                print(THashtags.count)
                DB_Management.updateHashTag(index: 0)
            }
    }
    static func updateHashTag(index: Int, Tcount: Int = 0, lastUsedRef: QueryDocumentSnapshot? = nil){
        if index >= THashtags.count{
            print("Finished!!!")
            return
        }
        let hashTag = THashtags[index]
        if hashTag.isEmpty{
            DB_Management.updateHashTag(index: index + 1)
            return
        }
        var query = FHASHTAG_POSTS_REF
            .document(hashTag)
            .collection("posts")
            .order(by: Post.key_created, descending: true)
        if lastUsedRef != nil{
            query = query.start(afterDocument: lastUsedRef!)
        }
        query = query.limit(to: 500)
        query.getDocuments { (doc, err) in
            if let error = err{
                print(error.localizedDescription)
                return
            }
            let count = doc?.documents.count ?? 0
            let lUsedRef = doc?.documents.last
            
            if count == 500{
                DB_Management.updateHashTag(index: index, Tcount: Tcount + count, lastUsedRef: lUsedRef)
            }
            else{
                var totalCount = Tcount + count
                if hashTag.contains("gay"){
                    totalCount = 0
                }
                FHASHTAG_POSTS_REF
                    .document(hashTag)
                    .updateData([
                        "tcount": totalCount,
                        "count": totalCount
                    ]) { (err) in
                        print("\(hashTag) + \(totalCount)")
                        if let error = err{
                            print(error.localizedDescription)
                            DB_Management.updateHashTag(index: index + 1)
                            return
                        }
                        DB_Management.updateHashTag(index: index + 1)
                    }
            }
        }
    }
}

//MARK: - send push notification to all users
extension DB_Management{
    static func sendMessageToAllUsers(lastUsedRef: QueryDocumentSnapshot? = nil){
        var query = FUSER_REF
            .whereField(User.key_u_signed, isGreaterThan: 0)
            .order(by: User.key_u_signed, descending: true)
        if lastUsedRef != nil{
            query = query.start(afterDocument: lastUsedRef!)
        }
        query = query.limit(to: 500)
        query.getDocuments { (doc, err) in
            if let error = err{
                print(error.localizedDescription)
                return
            }
            
            print(doc?.documents.count ?? 0)
            
            doc?.documents.forEach({ (item) in
                let usr = User(uid: item.documentID, data: item.data())
                DB_Management.sendNotificationContents(targetUid: usr.uid, targetUserToken: usr.token)
                TCount += 1
                
                print("Done - \(TCount) - \(usr.uid)")
            })
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                DispatchQueue.main.async {
                    let last = doc?.documents.last
                    if last != nil{
                        if last?.documentID != lastUsedRef?.documentID{
                            DB_Management.sendMessageToAllUsers(lastUsedRef: last)
                            print("Next")
                        }
                    }
                    else{
                        print("FINISHED!!!")
                    }
                }
            }
        }
    }
    
    static func sendNotificationContents(targetUid: String, targetUserToken: String){
        let msg: String = "Please update to Hive 1.14 to use Direct Message features."
        let nid = Utils.curTimeStr
        let data: [String : Any] = [
            Noti.key_created: Utils.curTime,
            Noti.key_uid: Me.uid,
            Noti.key_type: NotiType.ChatMessage.rawValue,
            Noti.key_chatMsg: msg]
        FNOTIFICATIONS_REF
            .document(targetUid)
            .collection(Noti.key_collection_notifications)
            .document(nid)
            .setData(data)
        if !targetUserToken.isEmpty{
            PushNotificationSender.sendPushNotification(to: targetUserToken, title: "Hive Support", body: msg, badge: 1)
        }
    }
}

//MARK: - update chat database
extension DB_Management{
    static func convertOldChatToNew(){
        FCHAT_REF
//            .whereField(MockChannel.key_members, arrayContains: "9AO5A79cTTVYswOb70RRfiT478G3")
            .getDocuments { (doc, err) in
                if let error = err{
                    print(error.localizedDescription)
                    return
                }
                print("Total Count - \(doc?.documents.count ?? 0)")
                doc?.documents.forEach({ (item) in
                    if (item.data()["lastMessage"] as? Double) != nil{
                        newChannels[item.documentID] = item.data()
                    }
                })
                print("channels count - \(newChannels.count)")
                DB_Management.convertMsgs()
            }
    }
    
    static func convertMsgs(){
        if newChannels.count == 0{
            print("FINISHED!!!")
            return
        }
        let chns = newChannels.prefix(100)
        let tasks = DispatchGroup()
        chns.forEach { (item) in
            newChannels.removeValue(forKey: item.key)
            
            tasks.enter()
            FCHAT_REF
                .document(item.key)
                .collection(MockChannel.key_collection_msgs)
                .order(by: MockMessage.key_timestamp, descending: true)
                .limit(to: 1)
                .getDocuments { (doc, err) in
                    if let error = err{
                        print(error.localizedDescription)
                        tasks.leave()
                        return
                    }
                    
                    if let doc = doc?.documents.first, let data = doc.data() as? [String: Any]{
                        let msg = MockMessage(id: doc.documentID, dic: data)
                        FCHAT_REF
                            .document(item.key)
                            .updateData([
                                MockChannel.key_last_msg: msg.getJson()
                            ]) { (err) in
                                if let error = err {
                                    print(error.localizedDescription)
                                    tasks.leave()
                                    return
                                }
                                TCount += 1
                                print("done - \(TCount)")
                                tasks.leave()
                            }
                    }
                    else{
                        tasks.leave()
                    }
                }
        }
        
        tasks.notify(queue: .main) {
            DispatchQueue.main.async {
                DB_Management.convertMsgs()
            }
        }
    }
}

//MARK: - Updated posts identifiers.
extension DB_Management{
    static func deleteOldPostIds(){
        FPIDS_REF
            .whereField(Post.key_created, isLessThan: Utils.curTime - 60 * 60 * 24 * 5)
            .order(by: Post.key_created, descending: true)
            .limit(to: 10000)
            .getDocuments { (doc, err) in
                print(doc?.documents.count ?? 0)
                var index = 0
                var batchIndex = 0
                var batches: [WriteBatch] = []
                batches.append(FDB_REF.batch())
                doc?.documents.forEach({ (item) in
                    guard let time = item.data()["created"] as? Double else { return }
                    print(Date(timeIntervalSince1970: time))
                    index += 1
                    if index % 200 == 0{
                        batches.append(FDB_REF.batch())
                        batchIndex += 1
                    }
                    
                    let batch = batches[batchIndex]
                    batch.deleteDocument(FPIDS_REF.document(item.documentID))
                })
                
                var doneIndex = 0
                batches.forEach { (item) in
                    item.commit { (err) in
                        if let error = err{
                            print(error.localizedDescription)
                            return
                        }
                        doneIndex += 1
                        print("Done => \(doneIndex)")
                    }
                }
            }
    }
    static func updatePostIds(lastDoc: QueryDocumentSnapshot? = nil){
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        var query = FPOSTS_REF
            .whereField(Post.key_created, isLessThan: Utils.curTime)
            .whereField(Post.key_type, in: [PostType.IMAGE.rawValue, PostType.VIDEO.rawValue])
            .order(by: Post.key_created, descending: true)
        
        if lastDoc != nil{
            query = query.start(afterDocument: lastDoc!)
        }
        query = query.limit(to: 100)
        
        query.getDocuments { (doc, err) in
            if let error = err{
                print(error.localizedDescription)
                return
            }

            let batch = FDB_REF.batch()
            
            doc?.documents.forEach({ (item) in
                let post = Post(pid: item.documentID, dic: item.data())
                guard post.type == .IMAGE || post.type == .VIDEO else {
                    print("Error type")
                    return }
                let bucketId : String = formatter.string(from: Date(timeIntervalSince1970: post.created))
                print(bucketId)

                batch.setData([
                    Post.key_created: post.created
                ], forDocument: FPIDS_DATE_REF.document(bucketId).collection("posts").document(item.documentID))
                batch.setData([
                    "count": FieldValue.increment(Int64(1))
                ], forDocument: FPIDS_DATE_REF.document(bucketId), merge: true)
            })
            
            batch.commit { (err) in
                if let error = err{
                    print(error.localizedDescription)
                    return
                }
                
                let lDoc = doc?.documents.last
                
                if lDoc?.documentID != lastDoc?.documentID{
                    DispatchQueue.main.async {
                        DB_Management.updatePostIds(lastDoc: lDoc)
                    }
                }
            }
        }
    }
}

extension DB_Management{
    static func updateFollowers(){
        let uid: String = "9YhbXLYhuebcrVS0600zFHjiH7h2"
        FUSER_REF
            .document(uid)
            .collection(User.key_collection_following)
            .getDocuments { (doc, err) in
                if let error = err{
                    print(error.localizedDescription)
                    return
                }
                let count = doc?.documents.count ?? 0
                print("following \(count)")
                FUSER_REF
                    .document(uid)
                    .updateData([
                        User.key_num_following: count
                    ])
            }
        FUSER_REF
            .document(uid)
            .collection(User.key_collection_followers)
            .getDocuments { (doc, err) in
                if let error = err{
                    print(error.localizedDescription)
                    return
                }
                let count = doc?.documents.count ?? 0
                print("followers \(count)")
                FUSER_REF
                    .document(uid)
                    .updateData([
                        User.key_num_followers: count
                    ])
            }
    }
}
