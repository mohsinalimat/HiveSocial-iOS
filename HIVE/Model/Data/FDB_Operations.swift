//
//  FDB_Operations.swift
//  HIVE
//
//  Created by elitemobile on 2/15/21.
//  Copyright © 2021 Kassy Pop. All rights reserved.
//

import Foundation
import Firebase

//MARK: - OPERATIONS FOR POST

public class FDB_Operations{
    
    //MARK: - Like / UnLike
    static func likePost(pid: String, like: Bool = false){
        guard let cid = CUID else { return }

        if like{
            FUSER_REF.document(cid)
                .collection(User.key_collection_posts_liked).document(pid)
                .setData([
                    Post.key_created: Utils.curTime
                ])
            FPOSTS_REF.document(pid)
                .collection(Post.key_collection_liked_users).document(cid)
                .setData([
                    Post.key_created: Utils.curTime,
                ])
        }
        else{
            FUSER_REF.document(cid)
                .collection(User.key_collection_posts_liked).document(pid)
                .delete()
            FPOSTS_REF.document(pid)
                .collection(Post.key_collection_liked_users).document(cid)
                .delete()
        }
        
        if Me.uid != vipUser{
            FDB_Operations.updatePostNumLikes(pid: pid, increase: like)
        }
    }
    static func updatePostNumLikes(pid: String, increase: Bool = false){
        let postRef = FPOSTS_REF.document(pid)
        FDB_REF.runTransaction { (transaction, _) -> Any? in
            let sfDocument: DocumentSnapshot
            do{
                try sfDocument = transaction.getDocument(postRef)
            } catch _ as NSError{
                return nil
            }
            guard let data = sfDocument.data() else {
                return nil
            }
            
            let pst = Post(pid: pid, dic: data)
            transaction.updateData([
                Post.key_num_likes: increase ? pst.num_likes + 1 : pst.num_likes - 1
            ], forDocument: postRef)
            
            return nil
        } completion: { (object, error) in
            if let error = error{
                print("Error in updating post num_likes: \(error.localizedDescription)")
            }
            else{
            }
        }
    }
    
    //MARK: - Upload / Delete / Update POST
    static func uploadPost(pid: String, add: Bool = false, data: [String: Any] = [:], type: PostType){
        guard let cid = CUID else { return }
        
        if add{
            FPOSTS_REF.document(pid)
                .setData(data)
            FUSER_REF.document(cid)
                .collection(User.key_collection_posts).document(pid)
                .setData([
                    Post.key_created: Utils.curTime,
                    Post.key_type: type.rawValue
                ])
            if type == .IMAGE || type == .VIDEO{
                FPIDS_REF.document(pid)
                    .setData([
                        Post.key_created: Utils.curTime
                    ])
            }
        }
        else{
            FPOSTS_REF.document(pid).delete()
            FUSER_REF.document(cid)
                .collection(User.key_collection_posts).document(pid)
                .delete()
            FPIDS_REF.document(pid)
                .delete()
            
            FDB_Operations.deletePostLiked(pid: pid)
        }
        
        FDB_Operations.updateMyNumPosts(increase: add)
        FDB_Operations.updateUsersFeed(pid: pid, add: add)
    }
    static func updateUsersFeed(pid: String, add: Bool = false){
        guard let cid = CUID else { return }
        
        var batchGroup: [WriteBatch] = []
        batchGroup.append(FDB_REF.batch())
        var batchIndex = 0
        var operationIndex = 0
        if add{
            FUSER_REF.document(cid).collection(User.key_collection_feed).document(pid)
                .setData([
                    Post.key_created: Utils.curTime
                ])
            
            MyFollowers.keys.forEach { (key) in
                operationIndex += 1
                if operationIndex % 200 == 0{
                    batchGroup.append(FDB_REF.batch())
                    batchIndex += 1
                }
                let batch = batchGroup[batchIndex]
                batch.setData([
                    Post.key_created: Utils.curTime
                ], forDocument:
                    FUSER_REF.document(key)
                        .collection(User.key_collection_feed).document(pid)
                )
            }
        }
        else{
            FUSER_REF.document(cid).collection(User.key_collection_feed).document(pid)
                .delete()
            MyFollowers.keys.forEach { (key) in
                operationIndex += 1
                if operationIndex % 200 == 0{
                    batchGroup.append(FDB_REF.batch())
                    batchIndex += 1
                }
                let batch = batchGroup[batchIndex]
                batch.deleteDocument(
                    FUSER_REF.document(key)
                        .collection(User.key_collection_feed).document(pid)
                )
            }
        }
        if operationIndex != 0{
            var doneIndex = 0
            print("Total count - \(batchGroup.count)")
            batchGroup.forEach { (item) in
                item.commit { (err) in
                    doneIndex += 1
                    if let error = err{
                        print(error.localizedDescription)
                    }
                    if doneIndex == batchGroup.count{
                        batchGroup.removeAll()
                    }
                }
            }
        }
        else{
            batchGroup.removeAll()
        }
    }
    static private func deletePostLiked(pid: String){
        FPOSTS_REF
            .document(pid)
            .collection(Post.key_collection_liked_users)
            .getDocuments { (doc, _) in
                doc?.documents.forEach({ (item) in
                    FUSER_REF.document(item.documentID)
                        .collection(User.key_collection_posts_liked).document(pid).delete()
                    FPOSTS_REF.document(pid)
                        .collection(Post.key_collection_liked_users).document(item.documentID).delete()
                })
            }
    }
    
    //MARK: - Hashtags for the post
    static func updateHashTags(pst: Post, add: Bool = false) {
        if !pst.desc.contains("#") { return }
        
        let tags: [String] = Utils.fetchTags(post: pst)
        for index in 0 ..< categories.count{
            let category = categories[index]
            let cateTags = category[3] as! [String]
            var exist = false
            cateTags.forEach { (cateTag) in
                if exist { return }
                let cateTagItem = cateTag.lowercased()
                tags.forEach { (tag) in
                    if exist { return }
                    let tagItem = tag.lowercased()
                    if cateTagItem == tagItem{
                        exist = true
                    }
                }
            }
            if exist{
                if add{
                    FCATE_REF.document("\(index)")
                        .collection(Post.key_collection_posts).document(pst.pid)
                        .setData([
                            Post.key_created: Utils.curTime,
                            Post.key_type: pst.type.rawValue
                        ])
                }
                else{
                    FCATE_REF.document("\(index)")
                        .collection(Post.key_collection_posts).document(pst.pid)
                        .delete()
                }
            }
        }

        tags.forEach { (tag) in
            FDB_Operations.updateHashTagCount(tag: tag, increase: add)

            if add{
                FHASHTAG_POSTS_REF.document(tag)
                    .collection(Post.key_collection_posts).document(pst.pid)
                    .setData([
                        Post.key_created: Utils.curTime
                    ])
            }
            else{
                FHASHTAG_POSTS_REF.document(tag)
                    .collection(Post.key_collection_posts).document(pst.pid)
                    .delete()
            }
            
        }
    }
    static private func updateHashTagCount(tag: String, increase: Bool = false){
        let tagRef = FHASHTAG_POSTS_REF.document(tag)
        tagRef.setData([
            HashTag.key_count: FieldValue.increment(Int64(increase ? 1 : -1)),
            HashTag.key_last_used: Utils.curTime,
            HashTag.key_tag: tag
        ], merge: true)
//        FDB_REF.runTransaction { (transaction, _) -> Any? in
//            let sfDocument: DocumentSnapshot
//            do{
//                try sfDocument = transaction.getDocument(tagRef)
//            } catch _ as NSError{
//                return nil
//            }
//            guard let data = sfDocument.data() else {
//                if increase{
//                    transaction.setData([
//                        HashTag.key_count: 1,
//                        HashTag.key_tag: tag,
//                        HashTag.key_last_used: Utils.curTime
//                    ], forDocument: tagRef)
//                }
//                return nil
//            }
//
//            let htag = HashTag(tag: tag, dic: data)
//            transaction.updateData([
//                HashTag.key_count: increase ? htag.count + 1 : htag.count - 1,
//                HashTag.key_last_used: Utils.curTime
//            ], forDocument: tagRef)
//
//            return nil
//        } completion: { (object, error) in
//            if let error = error{
//                print("Error in updating post num_likes: \(error.localizedDescription)")
//            }
//            else{
//                print("Success in updating post num_likes!")
//            }
//        }
    }
}

//MARK: - OPERATIONS FOR USER
extension FDB_Operations{
    //MARK: - User Actions
    static func userFollow(uid: String, add: Bool = false){
        guard let cid = CUID else { return }
        if add{
            FUSER_REF.document(cid).collection(User.key_collection_following).document(uid)
                .setData([
                    User.key_created: Utils.curTime
                ])
            FUSER_REF.document(uid).collection(User.key_collection_followers).document(cid)
                .setData([
                    User.key_created: Utils.curTime
                ])
        }
        else{
            FUSER_REF.document(cid).collection(User.key_collection_following).document(uid)
                .delete()
            FUSER_REF.document(uid).collection(User.key_collection_followers).document(cid)
                .delete()
        }
        
        FDB_Operations.updateMyNumFollowing(uid: uid, increase: add)
        FDB_Operations.updateMyFeedAfterFollow(uid: uid, add: add)
    }
    static private func updateMyFeedAfterFollow(uid: String, add: Bool = false){
        guard let cid = CUID else { return }

        FUSER_REF
            .document(uid)
            .collection(User.key_collection_posts)
            .getDocuments { (doc, _) in
                if doc?.documents.count ?? 0 == 0{
                    return
                }
                
                var batchGroup: [WriteBatch] = []
                batchGroup.append(FDB_REF.batch())
                var batchIndex = 0
                var operationCount = 0
                doc?.documents.forEach({ (pItem) in
                    operationCount += 1
                    if operationCount % 200 == 0{
                        batchGroup.append(FDB_REF.batch())
                        batchIndex += 1
                    }
                    let batch = batchGroup[batchIndex]
                    if add{
                        batch.setData(
                            pItem.data(),
                            forDocument:
                                FUSER_REF.document(cid).collection(User.key_collection_feed).document(pItem.documentID)
                        )
                    }
                    else{
                        batch.deleteDocument(
                            FUSER_REF.document(cid).collection(User.key_collection_feed).document(pItem.documentID)
                        )
                    }
                })
                
                if operationCount != 0{
                    print("Total count - \(batchGroup.count)")
                    var doneIndex = 0
                    batchGroup.forEach { (item) in
                        item.commit { (err) in
                            doneIndex += 1
                            if let error = err{
                                print(error.localizedDescription)
                            }
                            if doneIndex == batchGroup.count{
                                batchGroup.removeAll()
                            }
                        }
                    }
                }
                else{
                    batchGroup.removeAll()
                }
            }

    }
    static func sendFollowRequest(uid: String){
        guard let cid = CUID else { return }
        FUSER_REF.document(cid).collection(User.key_collection_following).document(uid)
            .setData([
                User.key_created: Utils.curTime,
                User.key_following_type: FollowType.Requested.rawValue
            ])
        FUSER_REF.document(uid).collection(User.key_collection_followers).document(cid)
            .setData([
                User.key_created: Utils.curTime,
                User.key_following_type: FollowType.Requested.rawValue
            ])
    }
    
    //MARK: - update NUMBER properties for USER
    static func updateMyNumPosts(increase: Bool = false){
        guard let cid = CUID else { return }
        let meRef = FUSER_REF.document(cid)
        FDB_REF.runTransaction { (transaction, _) -> Any? in
            let sfDocument: DocumentSnapshot
            do{
                try sfDocument = transaction.getDocument(meRef)
            } catch _ as NSError{
                return nil
            }
            guard let data = sfDocument.data() else {
                return nil
            }
            
            let usr = User(uid: cid, data: data)
            transaction.updateData([
                User.key_num_posts: increase ? usr.num_posts + 1 : usr.num_posts - 1
            ], forDocument: meRef)
            
            return nil
        } completion: { (object, error) in
            if let error = error{
                print("Error in updating my posts count: \(error.localizedDescription)")
            }
            else{
                print("Success in updating my posts count!")
            }
        }
    }
    
    static func updateMyNumFollowing(uid: String, increase: Bool = false){
        guard let cid = CUID else { return }
        
        let meRef = FUSER_REF.document(cid)
        FDB_REF.runTransaction { (transaction, _) -> Any? in
            let sfDocument: DocumentSnapshot
            do{
                try sfDocument = transaction.getDocument(meRef)
            } catch _ as NSError{
                return nil
            }
            guard let data = sfDocument.data() else {
                return nil
            }
            
            let usr = User(uid: cid, data: data)
            transaction.updateData([
                User.key_num_following: increase ? usr.num_following + 1 : usr.num_following - 1
            ], forDocument: meRef)
            
            return nil
        } completion: { (object, error) in
            if let error = error{
                print("Error in updating my following: \(error.localizedDescription)")
            }
            else{
                print("Success in updating my following!")
            }
        }
        
        let targetRef = FUSER_REF.document(uid)
        FDB_REF.runTransaction { (transaction, _) -> Any? in
            let sfDocument: DocumentSnapshot
            do{
                try sfDocument = transaction.getDocument(targetRef)
            } catch _ as NSError{
                return nil
            }
            guard let data = sfDocument.data() else {
                return nil
            }
            
            let usr = User(uid: uid, data: data)
            transaction.updateData([
                User.key_num_followers: increase ? usr.num_followers + 1 : usr.num_followers - 1
            ], forDocument: targetRef)
            
            return nil
        } completion: { (object, error) in
            if let error = error{
                print("Error in updating target user's followers: \(error.localizedDescription)")
            }
            else{
                print("Success in updating target user's followers!")
            }
        }
    }
    
    static func acceptFollowRequest(uid: String){
        guard let cid = CUID else { return }
        
    }
    static func declineFollowRequest(uid: String){
        guard let cid = CUID else { return }
    }
}
