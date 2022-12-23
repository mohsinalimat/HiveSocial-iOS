//
//  UserPostsManager.swift
//  HIVE
//
//  Created by elitemobile on 11/20/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

protocol UserPostsManagerDelegate: AnyObject{
    func postsUpdated()
    func postsLoadedMore(posts: [Post])
}

struct BindPType {
    var pid: String
    var created: Double
    var type: PostType
}

class UserPostsManager {
    // user
    var user: User!
    static var shared: UserPostsManager!
    
    weak var delegateMedia: UserPostsManagerDelegate?
    weak var delegateState: UserPostsManagerDelegate?
    
    var opPostsLoaded:(() -> Void)?
    
    init(for user: User) {
        self.user = user
        if self.user.uid == Me.uid{
            UserPostsManager.shared = self
        }
        loadPosts()
    }
    
    deinit {
        userPostsMedia.removeAll()
        userPostsStatus.removeAll()
        postIds.removeAll()
        
        delegateMedia = nil
        delegateState = nil
    }
    
    func logout(){
        UserPostsManager.shared = nil
        userPostsMedia.removeAll()
        userPostsStatus.removeAll()
        postIds.removeAll()
        
        delegateMedia = nil
        delegateState = nil
    }
    
    var userPostsMedia: [Post] = []
    var userPostsStatus: [Post] = []
    
    var postIds: [String: BindPType] = [:]
    func loadPosts() {
        let uid: String = user.uid
        print("uid \(uid)")
        
        self.userPostsMedia.removeAll()
        self.userPostsStatus.removeAll()
        self.postIds.removeAll()
        
        FUSER_REF
            .document(uid)
            .collection(User.key_collection_posts)
            .getDocuments { [unowned self](doc, err) in
                if let error = err{
                    print("ERROR: \(error.localizedDescription)")
                    return
                }
                
                var batchGroup: [WriteBatch] = []
                batchGroup.append(FDB_REF.batch())
                var batchIndex = 0
                var operationCount = 0
                
                let taskManager = DispatchGroup()
                doc?.documents.forEach({ (item) in
                    taskManager.enter()
                    if let type = item.data()[Post.key_type] as? Int, let created = item.data()[Post.key_created] as? Double{
                        let pType = PostType(index: type)
                        postIds[item.documentID] = BindPType(pid: item.documentID, created: created, type: pType)
                        taskManager.leave()
                    }
                    else{
                        Utils.fetchPost(pid: item.documentID) { (rpst) in
                            operationCount += 1
                            if operationCount % 200 == 0{
                                batchIndex += 1
                                batchGroup.append(FDB_REF.batch())
                            }
                            
                            guard let batch = batchGroup[batchIndex] as? WriteBatch else {
                                taskManager.leave()
                                return }
                            guard let pst = rpst else {
                                batch.deleteDocument(
                                    FUSER_REF
                                        .document(uid)
                                        .collection(User.key_collection_posts)
                                        .document(item.documentID)
                                )
                                taskManager.leave()
                                
                                return }
                            
                            postIds[item.documentID] = BindPType(pid: item.documentID, created: pst.created, type: pst.type)
                            
                            batch.updateData(
                                [
                                    Post.key_type: pst.type.rawValue
                                ],
                                forDocument:
                                    FUSER_REF
                                    .document(uid)
                                    .collection(User.key_collection_posts)
                                    .document(item.documentID)
                            )
                            taskManager.leave()
                        }
                    }
                })
                
                taskManager.notify(queue: .main) { [weak self] in
                    guard let self = self else {
                        print("Error")
                        return }
                    self.opPostsLoaded?()
                    
                    if self.postIds.count == 0{
                        self.delegateMedia?.postsUpdated()
                        self.delegateState?.postsUpdated()
                        return
                    }
                    let mediaPostsTaskManager = DispatchGroup()
                    self.postIds.filter{$0.value.type == .IMAGE || $0.value.type == .VIDEO}.values.sorted { (bType1, bType2) -> Bool in
                        bType1.created > bType2.created
                    }.prefix(50).forEach { (bType) in
                        self.postIds.removeValue(forKey: bType.pid)
                        
                        mediaPostsTaskManager.enter()
                        Utils.fetchPost(pid: bType.pid) { (rpst) in
                            guard let pst = rpst else {
                                mediaPostsTaskManager.leave()
                                return }
                            
                            self.userPostsMedia.append(pst)
                            mediaPostsTaskManager.leave()
                        }
                    }
                    mediaPostsTaskManager.notify(queue: .main) { [weak self] in
                        guard let self = self else {
                            print("Error")
                            return
                        }
                        self.userPostsMedia.sort { (item1, item2) -> Bool in
                            item1.created > item2.created
                        }
                        self.delegateMedia?.postsUpdated()
                    }
                    
                    let statusPostsTaskManager = DispatchGroup()
                    self.postIds.filter{$0.value.type == .GIF || $0.value.type == .TEXT}.values.sorted { (bType1, bType2) -> Bool in
                        bType1.created > bType2.created
                    }.prefix(10).forEach { (bType) in
                        self.postIds.removeValue(forKey: bType.pid)
                        
                        statusPostsTaskManager.enter()
                        Utils.fetchPost(pid: bType.pid) { (rpst) in
                            guard let pst = rpst else {
                                statusPostsTaskManager.leave()
                                return }
                            
                            self.userPostsStatus.append(pst)
                            statusPostsTaskManager.leave()
                        }
                    }
                    statusPostsTaskManager.notify(queue: .main) { [weak self] in
                        guard let self = self else {
                            print("Error")
                            return }
                        
                        self.userPostsStatus.sort { (item1, item2) -> Bool in
                            item1.created > item2.created
                        }
                        
                        self.delegateState?.postsUpdated()
                    }
                    
                    DispatchQueue.main.async {
                        if operationCount != 0{
                            var doneIndex = 0
                            print("Total batch count - \(batchGroup.count)")
                            batchGroup.forEach { (item) in
                                item.commit { (err) in
                                    if let error = err{
                                        print(error.localizedDescription)
                                        return
                                    }
                                    doneIndex += 1
                                    print("Done => \(doneIndex)")
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
            }
    }
    
    func loadMoreMediaPosts(){
        if self.postIds.count == 0 || self.postIds.filter({$0.value.type == .IMAGE || $0.value.type == .VIDEO}).count == 0{
            self.delegateMedia?.postsLoadedMore(posts: [])
            return
        }
        let postsTaskManager = DispatchGroup()
        var posts: [Post] = []
        self.postIds.filter{$0.value.type == .IMAGE || $0.value.type == .VIDEO}.values.sorted { (bType1, bType2) -> Bool in
            bType1.created > bType2.created
        }.prefix(50).forEach { (bType) in
            self.postIds.removeValue(forKey: bType.pid)
            
            postsTaskManager.enter()
            Utils.fetchPost(pid: bType.pid) { (rpst) in
                guard let pst = rpst else {
                    postsTaskManager.leave()
                    return }
                if self.user.uid == Me.uid{
                    self.userPostsMedia.append(pst)
                }
                self.userPostsMedia.append(pst)
                posts.append(pst)
                postsTaskManager.leave()
            }
        }
        postsTaskManager.notify(queue: .main) { [weak self] in
            guard let self = self else {
                print("Error")
                return }
            
            if self.user.uid == Me.uid{
                self.userPostsMedia.sort { (item1, item2) -> Bool in
                    item1.created > item2.created
                }
            }
            self.delegateMedia?.postsLoadedMore(
                posts: posts.sorted { (item1, item2) -> Bool in
                    item1.created > item2.created
                }
            )
        }
    }
    func loadMoreStatusPosts(){
        if self.postIds.count == 0 || self.postIds.filter({$0.value.type == .GIF || $0.value.type == .TEXT}).count == 0{
            self.delegateState?.postsLoadedMore(posts: [])
            return
        }
        let postsTaskManager = DispatchGroup()
        var posts: [Post] = []
        self.postIds.filter{$0.value.type == .GIF || $0.value.type == .TEXT}.values.sorted { (bType1, bType2) -> Bool in
            bType1.created > bType2.created
        }.prefix(10).forEach { (bType) in
            self.postIds.removeValue(forKey: bType.pid)
            
            postsTaskManager.enter()
            Utils.fetchPost(pid: bType.pid) { (rpst) in
                guard let pst = rpst else {
                    postsTaskManager.leave()
                    return }
                if self.user.uid == Me.uid{
                    self.userPostsStatus.append(pst)
                }
                posts.append(pst)
                postsTaskManager.leave()
            }
        }
        postsTaskManager.notify(queue: .main) { [weak self] in
            guard let self = self else {
                print("Error")
                return }
            
            if self.user.uid == Me.uid{
                self.userPostsStatus.sort { (item1, item2) -> Bool in
                    item1.created > item2.created
                }
            }
            self.delegateState?.postsLoadedMore(
                posts: posts.sorted { (item1, item2) -> Bool in
                    item1.created > item2.created
                }
            )
        }
    }
}
