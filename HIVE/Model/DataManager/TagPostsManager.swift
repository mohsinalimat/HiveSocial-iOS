//
//  TagPostsManager.swift
//  HIVE
//
//  Created by elitemobile on 12/30/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import Foundation
import Firebase

struct TrendingHashTag{
    let tag: String
    var postsCount: Int
    var postIds: [String] = []
}

protocol TagPostsManagerDelegate: class {
    func postsUpdated()
    func postsLoadedMore(posts: [Post])
}

class TagPostsManager {
    static var shared = TagPostsManager()
    var hashTag: String = ""
    var tagPostsMedia: [Post] = []
    var tagPostsState: [Post] = []
    weak var delegateTagDiscover: TagPostsManagerDelegate?
    weak var delegateTagPosts: TagPostsManagerDelegate?
    
    var isLoadingCate: Bool = false
    var catePostIds: [String] = []
    var isNewLoading: Bool = false
    var tagPostIds: [String] = []
    
    init() {
    }
    func logout(){
        tagPostsMedia.removeAll()
        tagPostsState.removeAll()
        catePostIds.removeAll()
        tagPostIds.removeAll()
        
        delegateTagDiscover = nil
        delegateTagPosts = nil
    }
    
    var lastCateDoc: QueryDocumentSnapshot? = nil
    var lastUsedCateDoc: QueryDocumentSnapshot? = nil
    func searchCateData(){
        lastCateDoc = nil
        lastUsedCateDoc = nil
        tagPostsMedia.removeAll()
        tagPostsState.removeAll()
        
        FCATE_REF
            .document("\(selectedCategoryIndex)")
            .collection("posts")
            .whereField(Post.key_created, isLessThan: Utils.curTime)
            .order(by: Post.key_created, descending: true)
            .limit(to: LoadStepCount)
            .getDocuments { (doc, err) in
                if let error = err{
                    print(error.localizedDescription)
                    return
                }
                
                self.lastCateDoc = doc?.documents.last
                self.fetchPosts(doc: doc)
                
            }
    }
    
    func loadMore(){
        DispatchQueue.global(qos: .background).async {
            if self.lastCateDoc == nil || (self.lastCateDoc?.documentID == self.lastUsedCateDoc?.documentID && self.lastUsedCateDoc != nil){
                self.delegateTagDiscover?.postsLoadedMore(posts: [])
                self.delegateTagPosts?.postsLoadedMore(posts: [])
                return
            }
            self.lastUsedCateDoc = self.lastCateDoc
            FCATE_REF
                .document("\(selectedCategoryIndex)")
                .collection("posts")
                .order(by: Post.key_created, descending: true)
                .start(afterDocument: self.lastCateDoc!)
                .limit(to: LoadStepCount)
                .getDocuments { (doc, err) in
                    if let error = err{
                        print(error.localizedDescription)
                        return
                    }
                    
                    self.lastCateDoc = doc?.documents.last
                    self.fetchPosts(doc: doc, more: true)
                }
        }
    }
    
    var lastTagDoc: QueryDocumentSnapshot? = nil
    var lastUsedTagDoc: QueryDocumentSnapshot? = nil
    func searchTagData(tag: String) {
        lastTagDoc = nil
        lastUsedTagDoc = nil
        
        tagPostsMedia.removeAll()
        tagPostsState.removeAll()
        
        self.hashTag = tag
        let query = FHASHTAG_POSTS_REF
            .document(tag.lowercased())
            .collection(Post.key_collection_posts)
            .whereField(Post.key_created, isLessThan: Utils.curTime)
            .order(by: Post.key_created, descending: true)
            .limit(to: LoadStepCount)
        query.getDocuments { [unowned self](doc, err) in
            if err != nil{
                return
            }
            
            self.lastTagDoc = doc?.documents.last
            self.fetchPosts(doc: doc)
        }
    }
    func loadMoreTagData(){
        DispatchQueue.global(qos: .background).async {
            if self.lastTagDoc == nil || self.hashTag.isEmpty || (self.lastTagDoc?.documentID == self.lastUsedTagDoc?.documentID && self.lastUsedTagDoc != nil){
                self.delegateTagDiscover?.postsLoadedMore(posts: [])
                self.delegateTagPosts?.postsLoadedMore(posts: [])
                return
            }
            
            let query = FHASHTAG_POSTS_REF
                .document(self.hashTag.lowercased())
                .collection(Post.key_collection_posts)
                .order(by: Post.key_created, descending: true)
                .start(afterDocument: self.lastTagDoc!)
                .limit(to: LoadStepCount)
            query.getDocuments { [unowned self](doc, err) in
                if err != nil{
                    self.delegateTagDiscover?.postsLoadedMore(posts: [])
                    self.delegateTagPosts?.postsLoadedMore(posts: [])
                    return
                }
                
                self.lastTagDoc = doc?.documents.last
                self.fetchPosts(doc: doc, more: true)
            }
        }
    }
    
    func fetchPosts(doc: QuerySnapshot?, more: Bool = false){
        if doc?.documents.count ?? 0 == 0{
            self.delegateTagDiscover?.postsLoadedMore(posts: [])
            self.delegateTagPosts?.postsLoadedMore(posts: [])

            return
        }
        
        let taskGroup = DispatchGroup()
        var postsMedia: [Post] = []
        var postsState: [Post] = []
        
        doc?.documents.forEach({ (item) in
            taskGroup.enter()
            Utils.fetchPost(pid: item.documentID) { (rpst) in
                guard let pst = rpst else {
                    taskGroup.leave()
                    return }
                
                if Me.uid == vipUser{
                    if MyBlocks.keys.contains(pst.ouid){
                        taskGroup.leave()
                        return
                    }
                }
                else{
                    if pst.is_private || MyBlocks.keys.contains(pst.ouid){
                        taskGroup.leave()
                        return
                    }
                }
                
                if pst.type == .VIDEO || pst.type == .IMAGE{
                    postsMedia.append(pst)
                    taskGroup.leave()
                }
                else{
                    if pst.opid.isEmpty{
                        postsState.append(pst)
                        taskGroup.leave()
                    }
                    else{
                        Utils.fullPost(post: pst) { (post) in
                            postsState.append(post)
                            taskGroup.leave()
                        }
                    }
                }
            }
        })
        
        taskGroup.notify(queue: .main) { [weak self] in
            guard let self = self else {
                print("Error")
                return }
            postsMedia = postsMedia.sorted(by: { (pst1, pst2) -> Bool in
                pst1.created > pst2.created
            })
            postsState = postsState.sorted(by: { (pst1, pst2) -> Bool in
                pst1.created > pst2.created
            })
            
            if more{
                self.delegateTagDiscover?.postsLoadedMore(posts: postsMedia)
                self.delegateTagPosts?.postsLoadedMore(posts: postsState)
            }
            else{
                self.tagPostsMedia = postsMedia
                self.tagPostsState = postsState
                
                self.delegateTagDiscover?.postsUpdated()
                self.delegateTagPosts?.postsUpdated()
            }
        }
    }
}
