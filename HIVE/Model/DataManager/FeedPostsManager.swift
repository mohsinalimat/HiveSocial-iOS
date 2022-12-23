//
//  FeedPostsManager.swift
//  HIVE
//
//  Created by elitemobile on 2/17/21.
//  Copyright © 2021 Kassy Pop. All rights reserved.
//

import Foundation
import Firebase

protocol FeedPostsDelegate: class {
    func postsUpdated()
}

class FeedPostsManager{
    static var shared = FeedPostsManager()
    var delegate: FeedPostsDelegate?
    
    var lastFeedDoc: QueryDocumentSnapshot? = nil
    var lastUsedFeedDoc: QueryDocumentSnapshot? = nil
    var myFeedPosts: [String: Post] = [:]
    
    var handlerUserFollowers: ListenerRegistration?
    var handlerUserBlocked: ListenerRegistration?
    
    var postIds: [String] = []
    func logout(){
        myFeedPosts.removeAll()
        
        delegate = nil
        
        handlerUserFollowers?.remove()
        handlerUserFollowers = nil
        handlerUserBlocked?.remove()
        handlerUserBlocked = nil
        
        MyFollowers.removeAll()
        MyFollowings.removeAll()
        MyLikedPosts.removeAll()
        MyBlocks.removeAll()
        MyCommented.removeAll()
        MyCommentedComments.removeAll()
        MyLikedComments.removeAll()
        
        postIds.removeAll()
    }

    func loadUserFeed(){
        guard let cid = CUID else { return }
        self.lastFeedDoc = nil
        self.lastUsedFeedDoc = nil
        self.myFeedPosts.removeAll()
        self.postIds.removeAll()
        FUSER_REF
            .document(cid)
            .collection(User.key_collection_feed)
            .whereField(Post.key_created, isLessThan: Utils.curTime)
            .order(by: Post.key_created, descending: true)
            .limit(to: Me.uid == vipUser ? 100 : 10)
            .getDocuments { [unowned self](doc, err) in
                if err != nil{
                    self.delegate?.postsUpdated()
                    return
                }
                self.lastFeedDoc = doc?.documents.last
                self.fetchFeedPosts(doc: doc)
            }
        
        self.loadCurrentUserStatus()
    }
    func loadMoreUserFeed(){
        guard let cid = CUID else { return }
        DispatchQueue.global(qos: .background).async {
            if self.lastFeedDoc == nil || (self.lastFeedDoc?.documentID == self.lastUsedFeedDoc?.documentID && self.lastUsedFeedDoc != nil){
                self.delegate?.postsUpdated()
                return }
            
            self.lastUsedFeedDoc = self.lastFeedDoc
            
            FUSER_REF
                .document(cid)
                .collection(User.key_collection_feed)
                .order(by: Post.key_created, descending: true)
                .start(afterDocument: self.lastFeedDoc!)
                .limit(to: Me.uid == vipUser ? 100 : 10)
                .getDocuments { [unowned self](doc, err) in
                    if let error = err{
                        print(error.localizedDescription)
                        self.delegate?.postsUpdated()
                        return
                    }
                    
                    self.lastFeedDoc = doc?.documents.last
                    self.fetchFeedPosts(doc: doc)
                }
        }
    }
    private func fetchFeedPosts(doc: QuerySnapshot?){
        if doc?.documents.count ?? 0 == 0{
            self.delegate?.postsUpdated()
            return
        }
        let taskGroup = DispatchGroup()
        doc?.documents.forEach({ (item) in
            taskGroup.enter()
            self.postIds.append(item.documentID)
            Utils.fetchPost(pid: item.documentID) { (rpst) in
                guard let pst = rpst else {
                    FPIDS_REF
                        .document(item.documentID)
                        .delete()
                    FUSER_REF
                        .document(Me.uid)
                        .collection(User.key_collection_feed)
                        .document(item.documentID)
                        .delete()
                    taskGroup.leave()
                    return }
                
                if MyBlocks.keys.contains(pst.ouid){
                    taskGroup.leave()
                    return
                }
                self.myFeedPosts[pst.pid] = pst
                if pst.opid.isEmpty{
                    taskGroup.leave()
                }
                else{
                    Utils.fullPost(post: pst) { (fPost) in
                        self.myFeedPosts[pst.pid] = fPost
                        taskGroup.leave()
                    }
                }
            }
        })
        taskGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.delegate?.postsUpdated()
        }
    }
    func filterPosts(){
        self.myFeedPosts = self.myFeedPosts.filter({ (item) -> Bool in
            !MyBlocks.keys.contains(item.value.ouid)
        })
        
        self.delegate?.postsUpdated()
    }

}

extension FeedPostsManager{
    func loadCurrentUserStatus(){
        guard let cid = CUID else { return }
        
        if handlerUserFollowers != nil{
            return
        }
        if handlerUserBlocked != nil{
            return
        }
        
        handlerUserFollowers = FUSER_REF
            .document(cid)
            .collection(User.key_collection_followers)
            .addSnapshotListener({ (doc, _) in
                doc?.documentChanges.forEach({ (item) in
                    switch(item.type){
                    case .removed:
                        MyFollowers.removeValue(forKey: item.document.documentID)
                        break
                    default:
                        MyFollowers[item.document.documentID] = true
                        break
                    }
                })
            })
        handlerUserBlocked = FUSER_REF
            .document(cid)
            .collection(User.key_collection_blocked)
            .addSnapshotListener({ (doc, _) in
                doc?.documentChanges.forEach({ (item) in
                    switch(item.type){
                    case .removed:
                        MyBlocks.removeValue(forKey: item.document.documentID)
                        break
                    default:
                        MyBlocks[item.document.documentID] = true
                        break
                    }
                })
            })
    }
}
