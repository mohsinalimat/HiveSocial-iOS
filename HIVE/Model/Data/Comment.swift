//
//  Comment.swift
//  HIVEcopy
//
//  Created by Kassy Pop on 8/14/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import Foundation
import CoreLocation
import MessageKit
import AVFoundation
import Firebase
import YPImagePicker
import GiphyUISDK

enum CommentType: Int{
    case TEXT = 0
    case IMAGE = 1
    case GIF = 2
    
    init(index: Int) {
        switch index {
        case 0: self = .TEXT
        case 1: self = .IMAGE
        case 2: self = .GIF
        default: self = .TEXT
        }
    }
}

class Comment{
    var mid: String = ""
    var created: Double = 0
    var uid: String = ""
    var msg: String = ""
    var num_likes: Int = 0
    var num_commented: Int = 0
    var type: CommentType = .TEXT
    var media: String = ""
    var ratio: CGFloat = 0
    var level: Int = 0
    var parentId: String = ""
    var pid: String = ""
    
    //MARK: - keys.
    static var key_mid = "messageId"
    static var key_created = "creationDate"
    static var key_uid = "uid"
    static var key_msg = "commentText"
    static var key_num_likes = "num_likes"
    static var key_num_commented = "num_commented"
    static var key_type = "type"
    static var key_media = "media"
    static var key_ratio = "ratio"
//    static var key_level = "level"
    static var key_parentId = "parentId"
    static var key_pid = "pid"
    
    init(){
        
    }
    
    init(id: String, dic: [String: Any]){
        self.mid = id
        if let created = dic[Comment.key_created] as? Double{
            self.created = created
        }
        if let uid = dic[Comment.key_uid] as? String{
            self.uid = uid
        }
        if let msg = dic[Comment.key_msg] as? String{
            self.msg = msg
        }
        if let num_likes = dic[Comment.key_num_likes] as? Int{
            self.num_likes = num_likes
            if self.num_likes < 0{
                self.num_likes = 0
            }
        }
        if let num_commented = dic[Comment.key_num_commented] as? Int{
            self.num_commented = num_commented
            if self.num_commented < 0{
                self.num_commented = 0
            }
        }
        if let type = dic[Comment.key_type] as? Int{
            self.type = CommentType(index: type)
        }
        if let media = dic[Comment.key_media] as? String{
            self.media = media
        }
        if let ratio = dic[Comment.key_ratio] as? CGFloat{
            self.ratio = ratio
        }
//        if let level = dic[Comment.key_level] as? Int{
//            self.level = level
//        }
        if let parentId = dic[Comment.key_parentId] as? String{
            self.parentId = parentId
        }
        if let pid = dic[Comment.key_pid] as? String{
            self.pid = pid
        }
    }
    
    func sendComment(media: YPMediaItem? = nil, gif: GPHMedia? = nil, txt: String, parentComment: Comment? = nil, completion: @escaping(Bool, String) -> ()){
        guard let cuid = CUID else { return }
        if let media = media{
            switch(media){
            case .photo(p: let ypImage):
                guard let uploadData = ypImage.image.jpegData(compressionQuality: 0.7) else {
                    completion(false, "Error in uploading image.")
                    return }
                let ratio = ypImage.image.size.width / ypImage.image.size.height
                let filename = "img_\(Utils.curTimeStr)"
                let storageRef = STORAGE_COMMENT_MEDIA_REF.child(cuid).child("image").child(filename)
                storageRef.putData(uploadData, metadata: nil) { (metadata, error) in
                    if let error = error {
                        print(error.localizedDescription)
                        completion(false, error.localizedDescription)
                        return
                    }
                    storageRef.downloadURL(completion: { (url, error) in
                        guard let imgUrl = url?.absoluteString else {
                            completion(false, "Error in uploading image.")
                            return }
                        
                        self.media = imgUrl
                        self.ratio = CGFloat(ratio)
                        
                        self.uploadComment(txt: txt, parent: parentComment) { (res, str) in
                            completion(res, str)
                        }
                    })
                }
                break
            case .video(v: _):
                break
            }
        }
        else if let gif = gif{
            let gifUrl: String = gif.url(rendition: .fixedWidth, fileType: .gif)!
            self.media = gifUrl
            self.ratio = gif.aspectRatio
            
            self.uploadComment(txt: txt, parent: parentComment) { (res, str) in
                completion(res, str)
            }
        }
        else{
            self.uploadComment(txt: txt, parent: parentComment) { (res, str) in
                completion(res, str)
            }
        }
    }
    
    func uploadComment(txt: String = "", parent: Comment? = nil, add: Bool = true, completion: @escaping(Bool, String) -> ()){
        self.msg = txt
        
        let doc = FPOSTS_REF
            .document(self.pid)
            .collection(self.parentId.isEmpty ? Post.key_collection_comments : self.parentId)
            .document(self.mid)
        if add{
            doc.setData(self.getJson()) { (err) in
                if let error = err{
                    print(error.localizedDescription)
                    completion(false, error.localizedDescription)
                    return
                }
                
                FPOSTS_REF
                    .document(self.pid)
                    .setData([
                        Post.key_num_comments: FieldValue.increment(Int64(1))
                    ], merge: true)
                if !self.parentId.isEmpty{
                    if let parentCmt = parent{
                        FPOSTS_REF
                            .document(self.pid)
                            .collection(parentCmt.parentId.isEmpty ? Post.key_collection_comments : parentCmt.parentId)
                            .document(parentCmt.mid)
                            .setData([
                                Comment.key_num_commented: FieldValue.increment(Int64(1))
                            ], merge: true)
                        parentCmt.num_commented += 1
                    }
                    FUSER_REF
                        .document(Me.uid)
                        .collection(User.key_collection_comments_commented)
                        .document(self.parentId)
                        .setData([
                            "count": FieldValue.increment(Int64(1))
                        ], merge: true)
                }
                
                FUSER_REF
                    .document(Me.uid)
                    .collection(User.key_collection_posts_commented)
                    .document(self.pid)
                    .setData([
                        "count": FieldValue.increment(Int64(1))
                    ], merge: true)
                
                Noti.sendCommentNotification(cmt: self, parent: parent)
                
                completion(true, "Success")
            }
        }
        else{
            doc.delete { (err) in
                if let error = err{
                    print(error.localizedDescription)
                    completion(false, error.localizedDescription)
                    return
                }
                
                FPOSTS_REF
                    .document(self.pid)
                    .setData([
                        Post.key_num_comments: FieldValue.increment(Int64(-1))
                    ], merge: true)
                
                if !self.parentId.isEmpty{
                    if let parentCmt = parent{
                        FPOSTS_REF
                            .document(self.pid)
                            .collection(parentCmt.parentId.isEmpty ? Post.key_collection_comments : parentCmt.parentId)
                            .document(parentCmt.mid)
                            .setData([
                                Comment.key_num_commented: FieldValue.increment(Int64(-1))
                            ], merge: true)
                        
                        parentCmt.num_commented -= 1
                        if parentCmt.num_commented < 0{
                            parentCmt.num_commented = 0
                            
                            FPOSTS_REF
                                .document(self.pid)
                                .collection(parentCmt.parentId.isEmpty ? Post.key_collection_comments : parentCmt.parentId)
                                .document(parentCmt.mid)
                                .updateData([
                                    Comment.key_num_commented: 0
                                ])
                            
                            MyCommentedComments[parentCmt.mid] = false
                        }
                        else if parentCmt.num_commented == 0{
                            MyCommentedComments[parentCmt.mid] = false
                        }
                    }
                    FUSER_REF
                        .document(Me.uid)
                        .collection(User.key_collection_comments_commented)
                        .document(self.parentId)
                        .updateData([
                            "count": FieldValue.increment(Int64(-1))
                        ])
                }
                
                FUSER_REF
                    .document(Me.uid)
                    .collection(User.key_collection_posts_commented)
                    .document(self.pid)
                    .updateData([
                        "count": FieldValue.increment(Int64(-1))
                    ])
                
                completion(true, "Success")
            }
        }
    }
    
    func getJson() -> [String: Any]{
        let data: [String : Any] = [
            Comment.key_created: self.created,
            Comment.key_uid: self.uid,
            Comment.key_msg: self.msg,
            Comment.key_num_likes: self.num_likes,
            Comment.key_num_commented: self.num_commented,
            Comment.key_type: self.type.rawValue,
            Comment.key_media: self.media,
            Comment.key_ratio: self.ratio,
//            Comment.key_level: self.level,
            Comment.key_parentId: self.parentId,
            Comment.key_pid: self.pid
        ]
        
        return data
    }
    
    func getDesc() -> String{
        return msg
    }
    
    func likeComment(completion: @escaping(Bool) -> ()){
        self.isLiked { (res) in
            FPOSTS_REF
                .document(self.pid)
                .collection(self.parentId.isEmpty ? Post.key_collection_comments : self.parentId)
                .document(self.mid)
                .setData([
                    Comment.key_num_likes: FieldValue.increment(Int64(res ? -1 : 1))
                ], merge: true)
            
            let doc = FUSER_REF
                .document(Me.uid)
                .collection(User.key_collection_comments_liked)
                .document(self.mid)
            if res{
                //needs to unlike
                doc.delete()
                MyLikedComments[self.mid] = false
            }
            else{
                //needs to like
                doc.setData([:])
                MyLikedComments[self.mid] = true
                
                //send like comment notification
                Noti.sendCommentLikeNotification(cmt: self)
            }

            self.num_likes += res ? -1 : 1
            if self.num_likes < 0{
                self.num_likes = 0
                FPOSTS_REF
                    .document(self.pid)
                    .collection(self.parentId.isEmpty ? Post.key_collection_comments : self.parentId)
                    .document(self.mid)
                    .updateData([
                        Comment.key_num_likes: 0
                    ])
            }

            completion(true)
        }
    }
    
    func isCommented(completion: @escaping(Bool) -> ()){
        if let commented = MyCommentedComments[self.mid]{
            completion(commented)
        }
        else{
            
            FUSER_REF
                .document(Me.uid)
                .collection(User.key_collection_comments_commented)
                .document(self.mid)
                .getDocument { (doc, _) in
                    if doc?.exists == true, let data = doc?.data(), let count = data["count"] as? Int{
                        if count > 0{
                            MyCommentedComments[self.mid] = true
                            completion(true)
                        }
                        else{
                            MyCommentedComments[self.mid] = false
                            completion(false)
                        }
                    }
                    else{
                        MyCommentedComments[self.mid] = false
                        completion(false)
                    }
                }
        }
    }
    
    func isLiked(completion: @escaping(Bool) -> ()){
        if let liked = MyLikedComments[self.mid] {
            completion(liked)
        }
        else{
            FUSER_REF
                .document(Me.uid)
                .collection(User.key_collection_comments_liked)
                .document(self.mid)
                .getDocument { (doc, _) in
                    if doc?.exists == true{
                        MyLikedComments[self.mid] = true
                        completion(true)
                    }
                    else{
                        MyLikedComments[self.mid] = false
                        completion(false)
                    }
                }
        }
    }
}
