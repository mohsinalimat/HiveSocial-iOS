//
//  PostManager.swift
//  HIVE
//
//  Created by elitemobile on 11/20/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift
import SDWebImage

protocol FeaturedPostsDelegate: class {
    func postsUpdated(posts: [Post])
    func postsLoadedMore(posts: [Post])
}

struct TrendingTag{
    var tag: String
    var count: Int
    var lastUsed: Double
}

class FeaturedPostsManager{
    static var shared = FeaturedPostsManager()
    var delegate: FeaturedPostsDelegate? = nil
    
    var lastFeaturedDoc: QueryDocumentSnapshot? = nil
    var featuredPosts: [String: Post] = [:]
    
    func logout(){
        self.featuredPosts.removeAll()
        delegate = nil
        lastFeaturedDoc = nil
    }
    
    func loadData(){
        featuredPosts.removeAll()
        
        self.lastFeaturedDoc = nil
        self.lastUsedFeaturedDoc = nil
        
//        let bucketId = Utils.dayBefore(day: Utils.today())
//        print(bucketId)
//        let query = FPIDS_DATE_REF.document(bucketId).collection("posts")
        let query = FPIDS_REF
            .whereField(Post.key_created, isLessThan: Utils.curTime)
            .order(by: Post.key_created, descending: true)
            .limit(to: Me.uid == vipUser ? 500 : LoadStepCount)
        query.getDocuments { [unowned self](doc, err) in
            if let error = err{
                print(error.localizedDescription)
                self.delegate?.postsUpdated(posts: [])
                return
            }
            print(doc?.documents.count ?? 0)
            self.lastFeaturedDoc = doc?.documents.last
            self.fetchPosts(doc: doc)
        }
    }
    
    var lastUsedFeaturedDoc: QueryDocumentSnapshot? = nil
    func loadMoreData(){
        DispatchQueue.global(qos: .background).async {
            if self.lastFeaturedDoc == nil || (self.lastUsedFeaturedDoc?.documentID == self.lastFeaturedDoc?.documentID && self.lastUsedFeaturedDoc != nil){
                self.delegate?.postsLoadedMore(posts: [])
                return }
            
            self.lastUsedFeaturedDoc = self.lastFeaturedDoc
//            let bucketId = Utils.dayBefore(day: Utils.today())
//            let query = FPIDS_DATE_REF.document(bucketId).collection("posts")
            let query = FPIDS_REF
                .order(by: Post.key_created, descending: true)
                .start(afterDocument: self.lastFeaturedDoc!)
                .limit(to: Me.uid == vipUser ? 500 : LoadStepCount)
            
            query.getDocuments { [unowned self](doc, err) in
                if let error = err{
                    print(error.localizedDescription)
                    self.delegate?.postsLoadedMore(posts: [])
                    return
                }
                self.lastFeaturedDoc = doc?.documents.last
                self.fetchPosts(doc: doc, more: true)
            }
        }
    }
    
    func fetchPosts(doc: QuerySnapshot?, more: Bool = false){
        if doc?.documents.count ?? 0 == 0{
            if more{
                self.delegate?.postsLoadedMore(posts: [])
            }
            else{
                self.delegate?.postsUpdated(posts: [])
            }
            return
        }
        
        let taskGroup = DispatchGroup()
        var posts: [Post] = []
        
        let curTime = Utils.curTime
        doc?.documents.forEach({ (item) in
            taskGroup.enter()
            Utils.fetchPost(pid: item.documentID) { (rpst) in
                guard let pst = rpst else {
                    FPIDS_REF
                        .document(item.documentID)
                        .delete()

                    taskGroup.leave()
                    return }
                if Me.uid == vipUser{
                    if MyBlocks.keys.contains(pst.ouid){
                        taskGroup.leave()
                        return
                    }
                }
                else{
                    if MyBlocks.keys.contains(pst.ouid) || pst.is_private{
                        taskGroup.leave()
                        return
                    }
                }
                if pst.type == .VIDEO || pst.type == .IMAGE{
                    posts.append(pst)
                    self.featuredPosts[pst.pid] = pst
                }
                else{
                    FPIDS_REF
                        .document(item.documentID)
                        .delete()
                }
                taskGroup.leave()
            }
        })
        
        taskGroup.notify(queue: .main) { [weak self] in
            guard let self = self else {
                print("Error")
                return }
            print("time - \(Utils.curTime - curTime)")
            posts = posts.sorted(by: { (pst1, pst2) -> Bool in
                pst1.created > pst2.created
            })
            if more{
                self.delegate?.postsLoadedMore(posts: posts)
            }
            else{
                self.delegate?.postsUpdated(posts: posts)
            }
        }
    }
    
    func filterPosts(){
        self.featuredPosts = self.featuredPosts.filter({ (item) -> Bool in
            !MyBlocks.keys.contains(item.value.ouid)
        })
        
        self.delegate?.postsUpdated(posts: Array(self.featuredPosts.values.sorted(by: { (item1, item2) -> Bool in
            item1.created > item2.created
        })))
    }
}
