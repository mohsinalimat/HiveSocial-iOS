//
//  Post.swift
//  HIVEcopy
//
//  Created by Kassy Pop on 8/7/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//
import Foundation
import GiphyUISDK
import Firebase
import FirebaseFirestoreSwift
import YPImagePicker

enum PostType: Int {
    case IMAGE = 1
    case VIDEO = 2
    case GIF = 3
    case TEXT = 4
//    case MULTI = 5
    
    init(index: Int) {
        switch index {
            case 1: self = .IMAGE
            case 2: self = .VIDEO
            case 3: self = .GIF
            case 4: self = .TEXT
//            case 5: self = .MULTI
            default: self = .TEXT
        }
    }
}

enum VisibleType {
    case All
    case Media
    case Status
}

class HashTag{
    var tag: String = ""
    var count: Int = 0
    var lastUsed: Double = 0
    
    static let key_count: String = "count"
    static let key_last_used: String = "lastused"
    static let key_tag: String = "tag"
    
    init(tag: String!, dic: [String: Any]){
        self.tag = tag
        
        if let lastUsed = dic[HashTag.key_last_used] as? Double{
            self.lastUsed = lastUsed
        }
        if let count = dic[HashTag.key_count] as? Int{
            self.count = count
        }
    }
}
class Post {
    var pid: String = ""
    var ouid: String = ""
    var oavatar: String = ""
    var ouname: String = ""
    
    var opid: String = ""
    var type: PostType = .TEXT
    var created: Double = 0

    var desc: String = ""
    var media: [Any] = []
    var thumb: [Any] = []
    var ratio: [Double] = []
    
    var num_likes: Int = 0
    var num_comments: Int = 0
    var is_private: Bool = false
    
    var opost: Post?
    
    //keys
    static let key_avatar: String = "oavatar"
    static let key_uname: String = "ouname"
    static let key_owner: String = "ouid"
    static let key_original_post_id: String = "opid"
    static let key_type: String = "type"
    static let key_created: String = "created"
    
    static let key_desc: String = "desc"
    static let key_media: String = "media"
    static let key_thumb: String = "thumb"
    static let key_ratio: String = "media_ratio"

    static let key_num_likes: String = "num_likes"
    static let key_num_comments: String = "num_comments"
    static let key_private: String = "is_private"
    
    static let key_collection_liked_users: String = "liked_users"
    static let key_collection_posts: String = "posts"
    static let key_collection_comments: String = "comments"
    
    init(){
    }
    
    init(pid: String!, dic: [String: Any]){
        self.pid = pid
        
        if let ouid = dic[Post.key_owner] as? String{
            self.ouid = ouid
        }
        if let avatar = dic[Post.key_avatar] as? String{
            self.oavatar = avatar
        }
        if let uname = dic[Post.key_uname] as? String{
            self.ouname = uname.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).filter{!" \n\t\r".contains($0)}
        }
        if let opid = dic[Post.key_original_post_id] as? String{
            self.opid = opid
        }
        if let type = dic[Post.key_type] as? Int{
            self.type = PostType(index: type)
        }
        if let created = dic[Post.key_created] as? Double{
            self.created = created
        }
        
        if let desc = dic[Post.key_desc] as? String {
            self.desc = desc
        }
        if let media = dic[Post.key_media] as? [Any]{
            self.media = media
        }
        if let thumb = dic[Post.key_thumb] as? [Any]{
            self.thumb = thumb
        }
        if let ratio = dic[Post.key_ratio] as? [Double]{
            self.ratio = ratio
        }
        
        if let likes = dic[Post.key_num_likes] as? Int{
            self.num_likes = likes
            if self.num_likes < 0{
                self.num_likes = 0
            }
        }
        if let comments = dic[Post.key_num_comments] as? Int{
            self.num_comments = comments
            if self.num_comments < 0{
                self.num_comments = 0
            }
        }
        
        if let is_private = dic[Post.key_private] as? Bool{
            self.is_private = is_private
        }
    }
    
    func opLike(newLike: Bool = true, completion: @escaping(Int) -> ()) {
        guard (CUID) != nil else { return }
        
        FDB_Operations.likePost(pid: self.pid, like: newLike)
        if Me.uid != vipUser{
            self.num_likes = self.num_likes + (newLike ? 1 : -1)
        }
        MyLikedPosts[self.pid] = newLike
        
        if newLike {
            if Me.uid != vipUser{
                Noti.sendPostLike(uid: self.ouid, pid: self.pid)
            }
        }
        
        DBPosts[self.pid] = self
        
        completion(self.num_likes)
    }
    
    func deletePost() {
        //decrease number of posts for me.
        FeedPostsManager.shared.myFeedPosts.removeValue(forKey: self.pid)
        FeaturedPostsManager.shared.featuredPosts.removeValue(forKey: self.pid)
        
        NotificationCenter.default.post(name: NSNotification.Name("deleteCompletion"), object: nil, userInfo: nil)
        FeedPostsManager.shared.delegate?.postsUpdated()

        FDB_Operations.uploadPost(pid: self.pid, add: false, type: self.type)
        FDB_Operations.updateHashTags(pst: self, add: false)

        Me.num_posts -= 1
        DBPosts.removeValue(forKey: self.pid)
        
        DispatchQueue.main.async {
            FeedPostsManager.shared.myFeedPosts.removeValue(forKey: self.pid)
            FeedPostsManager.shared.delegate?.postsUpdated()

            if self.type == .IMAGE || self.type == .VIDEO{
                FeaturedPostsManager.shared.featuredPosts.removeValue(forKey: self.pid)
                FeaturedPostsManager.shared.delegate?.postsUpdated(posts: Array(FeaturedPostsManager.shared.featuredPosts.values.sorted(by: { (item1, item2) -> Bool in
                    item1.created > item2.created
                })))
            }
            if let postManager = UserPostsManager.shared{
                if self.type == .IMAGE || self.type == .VIDEO{
                    if let fIndex = postManager.userPostsMedia.firstIndex(where: { (item) -> Bool in
                        item.pid == self.pid
                    }){
                        postManager.userPostsMedia.remove(at: fIndex)
                    }
                    postManager.delegateMedia?.postsUpdated()
                }
                else{
                    if let fIndex = postManager.userPostsStatus.firstIndex(where: { (item) -> Bool in
                        item.pid == self.pid
                    }){
                        postManager.userPostsStatus.remove(at: fIndex)
                    }
                    postManager.delegateState?.postsUpdated()
                }
            }
        }
    }
    
    func uploadPost(withMedia gifMedia: GPHMedia? = nil, ypMedia: YPMediaItem? = nil, desc: String, completion: @escaping(Bool, PostType?, Error?) -> ()) {
        self.desc = desc
        guard let cuid = CUID else { return }
        if let gif = gifMedia, let urlString = gif.url(rendition: .fixedWidth, fileType: .gif){
            self.media = [urlString]
            self.ratio = [Double(1 / gif.aspectRatio)]
            completion(true, .GIF, nil)
        }
        else if let yp: YPMediaItem = ypMedia{
            switch(yp){
            case .photo(p: let ypImage):
                guard let uploadData = ypImage.image.jpegData(compressionQuality: 0.8) else {
                    completion(false, nil, nil)
                    return }
                let resized = ypImage.image.resized500()
                guard let thumbData = resized.jpegData(compressionQuality: 0.5) else {
                    completion(false, nil, nil)
                    return }
                
                let ratio = ypImage.image.size.height / ypImage.image.size.width
                let filename = "img_\(Utils.curTimeStr)"
                let thumbname = "\(filename)_thumb"
                let storageRef = STORAGE_POST_IMAGES_REF.child(cuid).child("image").child(filename)
                let thumbRef = STORAGE_POST_IMAGES_REF.child(cuid).child("image").child(thumbname)
                storageRef.putData(uploadData, metadata: nil) { (metadata, error) in
                    if let error = error {
                        completion(false, nil, error)
                        return
                    }
                    storageRef.downloadURL(completion: { (url, error) in
                        guard let imgUrl = url?.absoluteString else {
                            completion(false, nil, error)
                            return }
                        
                        thumbRef.putData(thumbData, metadata: nil){ (metadata, error) in
                            if let error = error {
                                completion(false, nil, error)
                                return
                            }
                            thumbRef.downloadURL { (url, error) in
                                guard let thumbUrl = url?.absoluteString else {
                                    completion(false, nil, error)
                                    return
                                }

                                self.media = [imgUrl]
                                self.ratio = [Double(ratio)]
                                self.thumb = [thumbUrl]

                                completion(true, .IMAGE, nil)
                            }
                        }
                    })
                }
                break
            case .video(v: let ypVideo):
                guard let imgUploadData = ypVideo.thumbnail.jpegData(compressionQuality: 1) else {
                    completion(false, nil, nil)
                    return }
                let resized = ypVideo.thumbnail.resized500()
                guard let thumbData = resized.jpegData(compressionQuality: 0.5) else {
                    completion(false, nil, nil)
                    return }

                let thumbRatio = ypVideo.thumbnail.size.height / ypVideo.thumbnail.size.width
                
                let videoUploadData: Data
                do {
                    videoUploadData = try Data(contentsOf: ypVideo.url)
                } catch let error{
                    completion(false, nil, error)
                    return
                }
                
                let imgName = "thumb_\(Utils.curTimeStr)"
                let thumbname = "\(imgName)_thumb"
                let vidName = "vid_\(Utils.curTimeStr).mov"
                let storageRefImg = STORAGE_POST_IMAGES_REF.child(cuid).child("thumb").child(imgName)
                let thumbRef = STORAGE_POST_IMAGES_REF.child(cuid).child("thumb").child(thumbname)
                storageRefImg.putData(imgUploadData, metadata: nil) { (metadata, error) in
                    if let error = error {
                        completion(false, nil, error)
                        return
                    }
                    storageRefImg.downloadURL(completion: { (url, error) in
                        guard let imgUrl = url?.absoluteString else {
                            completion(false, nil, error)
                            return }
                        thumbRef.putData(thumbData, metadata: nil){ (metadata, error) in
                            if let error = error {
                                completion(false, nil, error)
                                return
                            }
                            thumbRef.downloadURL { (url, error) in
                                guard let thumbUrl = url?.absoluteString else {
                                    completion(false, nil, error)
                                    return
                                }

                                let storageRef_vid = STORAGE_POST_VIDEO_REF.child(cuid).child("video").child(vidName)
                                DispatchQueue.global(qos: .utility).async {
                                    storageRef_vid.putData(videoUploadData, metadata: nil) { (metadata, error) in
                                        if let error = error {
                                            print("Failed to upload image to storage.", error.localizedDescription)
                                            completion(false, nil, error)
                                            return
                                        } else {
                                            storageRef_vid.downloadURL(completion: { (vurl, error) in
                                                guard let videoUrl = vurl?.absoluteString else {
                                                    completion(false, nil, error)
                                                    return
                                                }
                                                self.media = [[videoUrl: imgUrl]]
                                                self.ratio = [Double(thumbRatio)]
                                                self.thumb = [thumbUrl]
                                                
                                                completion(true, .VIDEO, nil)
                                            })
                                        }
                                    }
                                }
                            }
                        }
                    })
                }
                break
            }
        }
        else{
            completion(true, .TEXT, nil)
        }
    }
    func uploadPost(ptype: PostType, completion: @escaping(Bool, Error?) -> ()){
        guard let cuid = CUID else { return }
        
        self.pid = self.pid.isEmpty ? Utils.curTimeStr : self.pid
        self.type = ptype
        self.created = Utils.curTime
        self.ouname = Me.uname
        self.oavatar = Me.thumb.isEmpty ? Me.avatar : Me.thumb
        self.is_private = Me.is_private
        self.ouid = cuid
        self.type = ptype
        
        let data: [String: Any] = [
            Post.key_desc: self.desc,
            Post.key_media: self.media,
            Post.key_ratio: self.ratio,
            Post.key_thumb: self.thumb,
            Post.key_type: self.type.rawValue,
            Post.key_owner: self.ouid,
            Post.key_created: self.created,
            Post.key_original_post_id: self.opid,
            Post.key_uname: self.ouname,
            Post.key_avatar: self.oavatar,
            Post.key_private: self.is_private
        ]
        
        FDB_Operations.updateHashTags(pst: self, add: true)
        FDB_Operations.uploadPost(pid: self.pid, add: true, data: data, type: self.type)
        
        Me.num_posts += 1

        DispatchQueue.main.async {
            DBPosts[self.pid] = self
            
            FeedPostsManager.shared.myFeedPosts[self.pid] = self
            FeedPostsManager.shared.delegate?.postsUpdated()
            
            if let postManager = UserPostsManager.shared{
                if self.type == .IMAGE || self.type == .VIDEO{
                    if postManager.userPostsMedia.count == 0{
                        postManager.userPostsMedia.append(self)
                    }
                    else{
                        postManager.userPostsMedia.insert(self, at: 0)
                    }
                    
                    postManager.delegateMedia?.postsUpdated()
                }
                else{
                    if postManager.userPostsStatus.count == 0{
                        postManager.userPostsStatus.append(self)
                    }
                    else{
                        postManager.userPostsStatus.insert(self, at: 0)
                    }
                    
                    postManager.delegateState?.postsUpdated()
                }
            }
        }

        completion(true, nil)
    }
        
    func editPost(newDesc: String, completion: @escaping(Bool, Error?) -> ()){
        FDB_Operations.updateHashTags(pst: self, add: false)
        
        self.desc = newDesc
        FPOSTS_REF
            .document(self.pid)
            .updateData([
                Post.key_desc: self.desc
            ], completion: { (err) in
                if let error = err{
                    print(error.localizedDescription)
                    completion(false, error)
                    return
                }
                
                FDB_Operations.updateHashTags(pst: self, add: true)
                
                DispatchQueue.main.async {
                    FeedPostsManager.shared.myFeedPosts[self.pid] = self
                    FeedPostsManager.shared.delegate?.postsUpdated()
                    
                    if let postManager = UserPostsManager.shared{
                        if self.type == .IMAGE || self.type == .VIDEO{
                            if let fIndex = postManager.userPostsMedia.firstIndex(where: { (item) -> Bool in
                                item.pid == self.pid
                            }){
                                postManager.userPostsMedia[fIndex] = self
                                postManager.delegateMedia?.postsUpdated()
                            }
                        }
                        else{
                            if let fIndex = postManager.userPostsStatus.firstIndex(where: { (item) -> Bool in
                                item.pid == self.pid
                            }){
                                postManager.userPostsStatus[fIndex] = self
                                postManager.delegateState?.postsUpdated()
                            }
                        }
                    }
                }

                completion(true, nil)
            })
    }
    
    func getDesc(cmt: Bool = false) -> String{
        var txt: String = ""
        if let opost = self.opost{
            if self.desc.isEmpty{
                if opost.desc.isEmpty{
                    txt = ""
                }
                else{
                    if cmt{
                        txt = "\(opost.desc)"
                    }
                    else{
                        txt = "@\(opost.ouname) \(opost.desc)"
                    }
                }
            }
            else{
                if opost.desc.isEmpty{
                    if cmt{
                        txt = "\(self.desc)"
                    }
                    else{
                        txt = "@\(self.ouname) \(self.desc)"
                    }
                }
                else{
                    if cmt{
                        txt = "\(self.desc)\n@\(opost.ouname) \(opost.desc)"
                    }
                    else{
                        txt = "@\(self.ouname) \(self.desc)\n@\(opost.ouname) \(opost.desc)"
                    }
                }
            }
        }
        else{
            if self.desc.isEmpty{
                txt = ""
            }
            else{
                if cmt{
                    txt = "\(self.desc)"
                }
                else{
                    txt = "@\(self.ouname) \(self.desc)"
                }
            }
        }
        return txt
    }
    
    func getType() -> PostType{
        var type = self.type
        if let opst = self.opost{
            type = opst.type
        }
        return type
    }
}

extension Post{
    func isLikedPost(completion: @escaping(Bool) -> ()){
        if let res = MyLikedPosts[self.pid]{
            completion(res)
        }
        else{
            FPOSTS_REF
                .document(self.pid)
                .collection(Post.key_collection_liked_users)
                .document(Me.uid)
                .getDocument { (doc, err) in
                    if doc?.exists == true{
                        MyLikedPosts[self.pid] = true
                        completion(true)
                    }
                    else{
                        MyLikedPosts[self.pid] = false
                        completion(false)
                    }
                }
        }
    }
    func isCommented(completion: @escaping((Bool) -> ())){
        if let res = MyCommented[self.pid]{
            completion(res)
        }
        else{
            FUSER_REF
                .document(Me.uid)
                .collection(User.key_collection_posts_commented)
                .document(self.pid)
                .getDocument { (doc, err) in
                    if doc?.exists == true, let data = doc?.data(), let count = data["count"] as? Int{
                        if count > 0{
                            MyCommented[self.pid] = true
                            completion(true)
                        }
                        else{
                            MyCommented[self.pid] = false
                            completion(false)
                        }
                    }
                    else{
                        MyCommented[self.pid] = false
                        completion(false)
                    }
                }
        }
    }
    func isReposted(completion: @escaping((Bool) -> ())){
        if !self.opid.isEmpty && self.ouid == Me.uid{
            completion(true)
        }
        else{
            completion(false)
        }
    }
    func isShared(completion: @escaping((Bool) -> ())){
        completion(false)
    }
}
