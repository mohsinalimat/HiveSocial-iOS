//
//  User.swift
//  HIVEcopy
//
//  Created by Kassy Pop on 7/29/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//
import Firebase

struct FirebaseSong: Codable {
    let title: String
    let artist: String
    let id: String
    let artworkUrl: String
    let country: String
    
    static func getSong(from dictionary: [String:Any]) -> FirebaseSong? {
        if let title = dictionary["title"] as? String, let artist = dictionary["artist"] as? String, let id = dictionary["id"] as? String, let artworkUrl = dictionary["artworkUrl"] as? String, let country = dictionary["country"] as? String {
            return FirebaseSong(title: title, artist: artist, id: id, artworkUrl: artworkUrl, country: country)
        } else {
            return nil
        }
    }
    
    func exportForFirebase() -> [String:String] {
        return [
            "title" : title,
            "artist" : artist,
            "id" : id,
            "artworkUrl" : artworkUrl,
            "country" : country
        ]
    }
}

enum FollowType: Int{
    case AbleToFollow = 0
    case Following = 1
    case Requested = 2
    case Declined = 3
    
    init(index: Int) {
        switch index {
            case 0: self = .AbleToFollow
            case 1: self = .Following
            case 2: self = .Requested
            case 3: self = .Declined
            default: self = .AbleToFollow
        }
    }
}
class User {
    // attributes
    var uid: String = ""

    var uname: String = ""
    var fname: String = ""
    var bio: String = ""
    var avatar: String = ""
    var thumb: String = ""
    var banner: String = ""
    var songs: [FirebaseSong] = []
    var following_cate: [Int] = []
    var website: String = ""
    
    var token: String = ""
    var is_private: Bool = false

    var email: String = ""
    var phone: String = ""

    var num_followers: Int = 0
    var num_following: Int = 0
    var num_posts: Int = 0

    var blocked: Bool = false
    
    static let key_uid: String = "uid"
    static let key_uname: String = "uname"
    static let key_fname: String = "fname"
    static let key_bio: String = "bio"
    static let key_avatar: String = "avatar"
    static let key_thumb: String = "thumb"
    static let key_banner: String = "banner"
    static let key_songs: String = "songs"
    static let key_following_categories: String = "following_cate"
    static let key_website: String = "website"

    static let key_token: String = "token"
    static let key_private: String = "is_private"

    static let key_phone: String = "phone"
    static let key_email: String = "email"
    
    static let key_num_following: String = "num_following"
    static let key_num_followers: String = "num_followers"
    static let key_num_posts: String = "num_posts"
    
    static let key_collection_posts: String = "posts"
    static let key_collection_posts_liked: String = "posts_liked"
    static let key_collection_posts_commented: String = "posts_commented"
    static let key_collection_comments_liked: String = "comments_liked"
    static let key_collection_comments_commented: String = "comments_commented"
    static let key_collection_following: String = "following"
    static let key_collection_followers: String = "followers"
    static let key_collection_feed: String = "feed"
    static let key_collection_blocked: String = "blocked"
    
    static let key_created: String = "created"
    static let key_following_type: String = "followingType"
    
    static let key_u_created: String = "created"
    static let key_u_signed: String = "signedin"
    
    var push_notification: Bool = true
    var push_likes: Bool = true
    var push_follow: Bool = true
    var push_message: Bool = true
    var push_comment: Bool = true
    
    var push_sms: Bool = true
    var push_email: Bool = true
    var play_song: Bool = true
    
    static var key_push_notification: String = "push_notification"
    static var key_push_likes: String = "push_likes"
    static var key_push_follow: String = "push_follow"
    static var key_push_message: String = "push_message"
    static var key_push_comment: String = "push_comment"
    
    static var key_push_sms: String = "push_sms"
    static var key_push_email: String = "push_email"
    static var key_play_song: String = "play_song"

    var displayName: String {
        get{
            return uname.isEmpty ? fname : uname
        }
    }
    
    init(){
    }
    
    init(uid: String, data: [String: Any]) {
        self.uid = uid
        if let uname = data[User.key_uname] as? String {
            self.uname = uname.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).filter{!" \n\t\r".contains($0)}
        }
        if let fname = data[User.key_fname] as? String {
            self.fname = fname
        }
        if let bio = data[User.key_bio] as? String {
            self.bio = bio
        }
        if let avatar = data[User.key_avatar] as? String {
            self.avatar = avatar
        }
        if let thumb = data[User.key_thumb] as? String{
            self.thumb = thumb
        }
        if let banner = data[User.key_banner] as? String {
            self.banner = banner
        }

        if let token = data[User.key_token] as? String{
            self.token = token
        }
        if let is_private = data[User.key_private] as? Bool{
            self.is_private = is_private
        }

        if let phone = data[User.key_phone] as? String {
            self.phone = phone
        }
        if let email = data[User.key_email] as? String {
            self.email = email
        }

        if let num_follower = data[User.key_num_followers] as? Int{
            self.num_followers = num_follower
            if self.num_followers < 0{
                self.num_followers = 0
            }
        }
        if let num_following = data[User.key_num_following] as? Int{
            self.num_following = num_following
            if self.num_following < 0{
                self.num_following = 0
            }
        }
        if let num_post = data[User.key_num_posts] as? Int{
            self.num_posts = num_post
            if self.num_posts < 0{
                self.num_posts = 0
            }
        }
        
        if let cate = data[User.key_following_categories] as? [Int]{
            self.following_cate = cate.filter{$0 < categories.count}
        }
        if let sData = data[User.key_songs] as? [Any]{
            sData.forEach { (sItem) in
                if let item = sItem as? [String: Any], let song = FirebaseSong.getSong(from: item){
                    self.songs.append(song)
                }
            }
        }
        
        if let site = data[User.key_website] as? String{
            self.website = site
        }
        
        if let notification = data[User.key_push_notification] as? Bool {
            self.push_notification = notification
        }
        if let likes = data[User.key_push_likes] as? Bool{
            self.push_likes = likes
        }
        if let follow = data[User.key_push_follow] as? Bool{
            self.push_follow = follow
        }
        if let message = data[User.key_push_message] as? Bool{
            self.push_message = message
        }
        if let comment = data[User.key_push_comment] as? Bool{
            self.push_comment = comment
        }
        
        if let sms = data[User.key_push_sms] as? Bool{
            self.push_sms = sms
        }
        if let email = data[User.key_push_email] as? Bool{
            self.push_email = email
        }
        if let play_song = data[User.key_play_song] as? Bool{
            self.play_song = play_song
        }
    }
    
    func follow(follow: Bool = true) {
        guard let cid = CUID else { return }
        if cid == self.uid { return }
        
        if follow{
            if is_private{
                //following status -  .Requested
                MyFollowings[self.uid] = FollowStatus(time: Utils.curTime, followType: .Requested)
                FDB_Operations.sendFollowRequest(uid: uid)
                Noti.sendFollowRequest(uid: self.uid)
            }
            else{
                //following status -  .Following
                MyFollowings[self.uid] = FollowStatus(time: Utils.curTime, followType: .Following)
                FDB_Operations.userFollow(uid: self.uid, add: true)
                Noti.sendFollow(uid: self.uid)
                
                Me.num_following += 1
            }
        }
        else{
            //following status -  .AbleToFollow
            MyFollowings[self.uid] = FollowStatus(time: Utils.curTime, followType: .AbleToFollow)
            FDB_Operations.userFollow(uid: self.uid, add: false)
            
            Me.num_following -= 1
        }
    }
    
    func updateFollowingCategories(completion: @escaping((Bool) -> ())){
        FUSER_REF
            .document(self.uid)
            .updateData([
                User.key_following_categories: self.following_cate
            ]) { (_) in
                completion(true)
            }
    }
    
    func updateNumPosts(){
        FUSER_REF
            .document(self.uid)
            .updateData([
                User.key_num_posts: self.num_posts
            ])
    }
    
    func updateSong(){
        var songsJson: [Any] = []
        self.songs.forEach { (song) in
            songsJson.append(song.exportForFirebase())
        }
        FUSER_REF
            .document(self.uid)
            .updateData([
                User.key_songs: songsJson
            ])
    }
    
    func updateUserPostsInfo(){
        FUSER_REF
            .document(self.uid)
            .collection(User.key_collection_posts)
            .getDocuments { (doc, _) in
                doc?.documents.forEach({ (pItem) in
                    FPOSTS_REF
                        .document(pItem.documentID)
                        .updateData([
                            Post.key_avatar: self.thumb.isEmpty ? self.avatar : self.thumb,
                            Post.key_uname: self.uname,
                            Post.key_private: self.is_private
                        ])
                })
            }
    }
    
    func block(){
        guard let cuid = CUID else { return }
        guard cuid != self.uid else { return }
        
        FUSER_REF.document(cuid).collection(User.key_collection_blocked).document(self.uid).setData([:])

        isFollowing { (fType) in
            if fType == .Following{
                FDB_Operations.userFollow(uid: self.uid, add: false)
            }
        }
        
        MyBlocks[self.uid] = true
        MyFollowings.removeValue(forKey: self.uid)
        
        FeedPostsManager.shared.filterPosts()
        FeaturedPostsManager.shared.filterPosts()
    }
    
    func unblock(){
        guard let cuid = CUID else { return }
        guard cuid != self.uid else { return }
        
        FUSER_REF
            .document(cuid)
            .collection(User.key_collection_blocked)
            .document(self.uid)
            .delete()

        MyBlocks.removeValue(forKey: self.uid)

        FeedPostsManager.shared.filterPosts()
        FeaturedPostsManager.shared.filterPosts()
    }
    
    func isFollowing(completion: @escaping(FollowType) -> ()){
        if let res = MyFollowings[self.uid]{
            completion(res.followType)
        }
        else{
            FUSER_REF
                .document(Me.uid)
                .collection(User.key_collection_following)
                .document(self.uid)
                .getDocument { (doc, _) in
                    if let doc = doc, let data = doc.data(){
                        if let fType = data["type"] as? Int {
                            MyFollowings[self.uid] = FollowStatus(time: Utils.curTime, followType: FollowType(index: fType))
                            completion(FollowType(index: fType))
                        }
                        else{
                            MyFollowings[self.uid] = FollowStatus(time: Utils.curTime, followType: .Following)
                            completion(.Following)
                        }
                    }
                    else{
                        MyFollowings[self.uid] = FollowStatus(time: Utils.curTime, followType: .AbleToFollow)
                        completion(.AbleToFollow)
                    }
                }
        }
    }
    
}
 
extension User{
    func saveLocal(){
        let df = UserDefaults.standard
        df.set(self.uid, forKey: User.key_uid)
        df.set(self.fname, forKey: User.key_fname)
        df.set(self.uname, forKey: User.key_uname)
        df.set(self.bio, forKey: User.key_bio)
        df.set(self.avatar, forKey: User.key_avatar)
        df.set(self.banner, forKey: User.key_banner)
        df.set(self.website, forKey: User.key_website)
        
        df.set(self.following_cate, forKey: User.key_following_categories)
        
        var songsData: [Any] = []
        self.songs.forEach { (song) in
            songsData.append(song.exportForFirebase())
        }
        
        df.set(songsData, forKey: User.key_songs)
        
        df.set(self.email, forKey: User.key_email)
        df.set(self.phone, forKey: User.key_phone)

        df.set(self.num_posts, forKey: User.key_num_posts)
        df.set(self.num_following, forKey: User.key_num_following)
        df.set(self.num_followers, forKey: User.key_num_followers)
        
        df.set(self.push_notification, forKey: User.key_push_notification)
        df.set(self.push_likes, forKey: User.key_push_likes)
        df.set(self.push_follow, forKey: User.key_push_follow)
        df.set(self.push_message, forKey: User.key_push_message)
        df.set(self.push_comment, forKey: User.key_push_comment)
        df.set(self.push_sms, forKey: User.key_push_sms)
        df.set(self.push_email, forKey: User.key_push_email)
        df.set(self.play_song, forKey: User.key_play_song)
    }
    
    func loadLocal(){
        let df = UserDefaults.standard
        
        if let id = df.string(forKey: User.key_uid){
            self.uid = id
        }
        if let fname = df.string(forKey: User.key_fname){
            self.fname = fname.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let uname = df.string(forKey: User.key_uname){
            self.uname = uname.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let bio = df.string(forKey: User.key_bio){
            self.bio = bio
        }
        if let avatar = df.string(forKey: User.key_avatar){
            self.avatar = avatar
        }
        if let banner = df.string(forKey: User.key_banner){
            self.banner = banner
        }
        if let site = df.string(forKey: User.key_website){
            self.website = site
        }
        
        if let cate = df.array(forKey: User.key_following_categories) as? [Int]{
            self.following_cate = cate.filter{ $0 < categories.count }
        }
        
        if let songs = df.array(forKey: User.key_songs){
            songs.forEach { (item) in
                if let sData = item as? [String: Any], let song = FirebaseSong.getSong(from: sData){
                    self.songs.append(song)
                }
            }
        }
        
        if let email = df.string(forKey: User.key_email){
            self.email = email
        }
        if let phone = df.string(forKey: User.key_phone){
            self.phone = phone
        }
        
        self.num_following = df.integer(forKey: User.key_num_following)
        self.num_followers = df.integer(forKey: User.key_num_followers)
        self.num_posts = df.integer(forKey: User.key_num_posts)
        
        if df.object(forKey: User.key_push_notification) != nil{
            self.push_notification = df.bool(forKey: User.key_push_notification)
        }
        if df.object(forKey: User.key_push_likes) != nil{
            self.push_likes = df.bool(forKey: User.key_push_likes)
        }
        if df.object(forKey: User.key_push_follow) != nil{
            self.push_follow = df.bool(forKey: User.key_push_follow)
        }
        if df.object(forKey: User.key_push_message) != nil{
            self.push_message = df.bool(forKey: User.key_push_message)
        }
        if df.object(forKey: User.key_push_comment) != nil{
            self.push_comment = df.bool(forKey: User.key_push_comment)
        }
        if df.object(forKey: User.key_push_sms) != nil{
            self.push_sms = df.bool(forKey: User.key_push_sms)
        }
        if df.object(forKey: User.key_push_email) != nil{
            self.push_email = df.bool(forKey: User.key_push_email)
        }
        if df.object(forKey: User.key_play_song) != nil{
            self.play_song = df.bool(forKey: User.key_play_song)
        }
    }
}

//Admin actions
extension User{
    func removeUserAndPosts(completion: @escaping((Bool) -> ())){
        if !adminUser.contains(Me.uid) || self.uid == Me.uid { return }
        
        FBLOCKED_REF
            .document(self.uid)
            .setData([
                "blocked": true
            ])
        
        FUSER_REF
            .document(self.uid)
            .collection(User.key_collection_posts)
            .getDocuments { (doc, err) in
                doc?.documents.forEach({ (item) in
                    DBPosts.removeValue(forKey: item.documentID)
                    FPOSTS_REF
                        .document(item.documentID)
                        .delete()
                    FPIDS_REF
                        .document(item.documentID)
                        .delete()
                })
                
                FUSER_REF
                    .document(self.uid)
                    .delete { (err) in
                        if let error = err{
                            print(error.localizedDescription)
                            completion(false)
                            return
                        }
                        completion(true)
                    }
            }
    }
}
