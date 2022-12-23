//
//  LikedPostsManager.swift
//  HIVE
//
//  Created by elitemobile on 2/17/21.
//  Copyright © 2021 Kassy Pop. All rights reserved.
//

import Foundation
import Firebase

protocol MyLikedPostDelegate: class{
    func myLikedPostsUpdated()
    func myLikedPostsLoadedMore(posts: [Post])
}

class LikedPostsManager{
    static var shared = LikedPostsManager()
    
    var likedPostsUid: String = ""
    
    var myLikedPostsDelegateMedia: MyLikedPostDelegate?
    var myLikedPostsDelegateStatus: MyLikedPostDelegate?
    
    var likedPostsMedia: [Post] = []
    var likedPostsStatus: [Post] = []
    
    var lastLikedDoc: QueryDocumentSnapshot? = nil
    var lastCalledLikedDoc: QueryDocumentSnapshot? = nil
    
    
    func loadMyLikedPosts(){
        likedPostsMedia.removeAll()
        likedPostsStatus.removeAll()
        self.lastLikedDoc = nil
        self.lastCalledLikedDoc = nil
        
        FUSER_REF
            .document(likedPostsUid)
            .collection(User.key_collection_posts_liked)
            .order(by: User.key_created, descending: true)
            .limit(to: LoadStepCount)
            .getDocuments { [unowned self](doc, err) in
                if err != nil{
                    self.myLikedPostsDelegateMedia?.myLikedPostsUpdated()
                    self.myLikedPostsDelegateStatus?.myLikedPostsUpdated()
                    
                    return
                }
                
                self.lastLikedDoc = doc?.documents.last
                self.fetchPosts(doc: doc, more: true)
            }
    }
    func loadMoreLikedPosts(){
        DispatchQueue.global(qos: .background).async {
            if self.lastLikedDoc == nil || (self.lastCalledLikedDoc?.documentID == self.lastLikedDoc?.documentID && self.lastCalledLikedDoc != nil){
                self.myLikedPostsDelegateMedia?.myLikedPostsLoadedMore(posts: [])
                self.myLikedPostsDelegateStatus?.myLikedPostsLoadedMore(posts: [])
                return
            }
            
            self.lastCalledLikedDoc = self.lastLikedDoc
            
            FUSER_REF
                .document(self.likedPostsUid)
                .collection(User.key_collection_posts_liked)
                .order(by: User.key_created, descending: true)
                .start(afterDocument: self.lastLikedDoc!)
                .limit(to: LoadStepCount)
                .getDocuments { [unowned self](doc, err) in
                    if err != nil{
                        self.myLikedPostsDelegateMedia?.myLikedPostsLoadedMore(posts: [])
                        self.myLikedPostsDelegateStatus?.myLikedPostsLoadedMore(posts: [])
                        return
                    }
                    
                    self.lastLikedDoc = doc?.documents.last
                    self.fetchPosts(doc: doc, more: true)
                }
        }
    }
    func fetchPosts(doc: QuerySnapshot?, more: Bool = false){
        let taskGroup = DispatchGroup()
        var postsMedia: [Post] = []
        var postsState: [Post] = []
        doc?.documents.forEach({ (item) in
            if self.likedPostsUid == Me.uid{
                MyLikedPosts[item.documentID] = true
            }
            
            taskGroup.enter()
            Utils.fetchPost(pid: item.documentID) { (rpst) in
                guard let pst = rpst else {
                    taskGroup.leave()
                    return }
                
                if pst.opid.isEmpty{
                    if pst.type == .VIDEO || pst.type == .IMAGE{
                        postsMedia.append(pst)
                    }
                    else{
                        postsState.append(pst)
                    }
                    taskGroup.leave()
                }
                else{
                    Utils.fullPost(post: pst) { (fPost) in
                        postsState.append(pst)
                        taskGroup.leave()
                    }
                }
            }
        })
        taskGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            
            postsMedia = postsMedia.sorted { (pst1, pst2) -> Bool in
                pst1.created > pst2.created
            }
            postsState = postsState.sorted(by: { (pst1, pst2) -> Bool in
                pst1.created > pst2.created
            })
            if more{
                self.myLikedPostsDelegateMedia?.myLikedPostsLoadedMore(posts: postsMedia)
                self.myLikedPostsDelegateStatus?.myLikedPostsLoadedMore(posts: postsState)
            }
            else{
                self.likedPostsMedia = postsMedia
                self.likedPostsStatus = postsState
                
                self.myLikedPostsDelegateMedia?.myLikedPostsUpdated()
                self.myLikedPostsDelegateStatus?.myLikedPostsUpdated()
            }
        }
    }
}
