//
//  Utils.swift
//  HIVE
//
//  Created by elitemobile on 1/14/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import Foundation
import Firebase
import UIKit
import SDWebImage

public class Utils{
    static var curTime: Double {
        get{
            return Date().timeIntervalSince1970
        }
    }
    static var curTimeStr: String{
        get {
            return String(Date().timeIntervalSince1970)
        }
    }
    static func getCellHeight(post: Post, cellWidth: CGFloat = UIScreen.main.bounds.width - 8) -> CGFloat{
        let labelWidth = cellWidth
        let txt = post.getDesc()
        var labelHeight = Utils.calculateCellHeight(txt: txt, width: labelWidth - 32)
        var ratio: Double = 1.0
        
        if let fratio = post.ratio.first{
            ratio = fratio
        }
        else if let opost = post.opost, let ofratio = opost.ratio.first{
            ratio = ofratio
        }
        
        if labelHeight > 0 && labelHeight < 21 {
            labelHeight = 21
        }
        
        var cellHeight: CGFloat = 0
        switch(post.getType()){
        case .TEXT:
            cellHeight = (post.opid.isEmpty ? 0 : 36) //repost
                + 185
                + labelHeight
            break
        default:
            cellHeight = (post.opid.isEmpty ? 0 : 36)
                + labelWidth * (post.getType() == .VIDEO ? 1 : CGFloat(ratio))
                + labelHeight
                + 185
            break
        }
        
        return cellHeight
    }
    
    static func calculateCellHeight(txt: String, width: CGFloat) -> CGFloat{
        let label:ActiveLabel = ActiveLabel(frame: CGRect(x: 0, y: 0, width: width, height: 0))
        
        label.enabledTypes = [.mention, .hashtag, .url]
        label.font = UIFont.cFont_regular(size: 16)
        label.configureLinkAttribute = { (type, attributes, isSelected) in
            var atts = attributes
            switch type {
            case .mention:
                atts[NSAttributedString.Key.font] = UIFont.cFont_bold(size: 16)
                break
            case .hashtag, .url:
                atts[NSAttributedString.Key.font] = UIFont.cFont_medium(size: 16)
                break
            default:
                atts[NSAttributedString.Key.font] = UIFont.cFont_regular(size: 16)
                break
            }
            return atts
        }
        label.numberOfLines = 0
        label.lineSpacing = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.customize { (lbl) in
            lbl.text = txt
        }
        label.sizeToFit()
        return label.frame.height * 1.175
    }
}

//height for comments
extension Utils{
    static func getHeightCmtPostHeader(post: Post) -> CGFloat{
        let width = UIScreen.main.bounds.width - 72
        return Utils.calculateCellHeight(txt: post.getDesc(), width: width) + 61
    }
    static func getHeightCmtItem(cmt: Comment, header: Bool = false, second: Bool = false) -> CGFloat{
        if header{
            let width = UIScreen.main.bounds.width - 76
            return Utils.calculateCellHeight(txt: cmt.getDesc(), width: CGFloat(width)) + 100 + (cmt.media.isEmpty ? 0 : 148)
        }
        else{
            let width = UIScreen.main.bounds.width - 76 - CGFloat(cmt.level * 12)
            if second{
                return Utils.calculateCellHeight(txt: cmt.getDesc(), width: CGFloat(width)) + 100 + (cmt.media.isEmpty ? 0 : 148) + CGFloat(cmt.level * 12) + (cmt.num_commented == 0 ? 0 : (cmt.level - 1 == 0 ? 30 : 0))
            }
            else{
                return Utils.calculateCellHeight(txt: cmt.getDesc(), width: CGFloat(width)) + 100 + (cmt.media.isEmpty ? 0 : 148) + CGFloat(cmt.level * 12) + (cmt.num_commented == 0 ? 0 : (cmt.level == 0 ? 30 : 0))
            }
        }
    }
}

//database tasks
extension Utils{
    static func fetchUser(uname: String, completion: @escaping(User?) -> ()){
        FUSER_REF
            .whereField(User.key_uname, isEqualTo: uname.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))
            .getDocuments { (doc, err) in
                if let error = err{
                    print(error.localizedDescription)
                    
                    completion(nil)
                    return
                }
                
                if let first = doc?.documents.first{
                    let usr = User(uid: first.documentID, data: first.data())
                    completion(usr)
                }
            }
    }
    static func fetchUser(uid: String, completion: @escaping(User?) -> ()) {
        if let usr = DBUsers[uid]{
            completion(usr)
        }
        else{
            FUSER_REF
                .document(uid)
                .getDocument { (doc, err) in
                    if let error = err{
                        print("ERROR IN FETCHING USER DATA: \(error.localizedDescription)")
                        
                        completion(nil)
                        return
                    }
                    
                    if let data = doc?.data(){
                        let usr = User(uid: uid, data: data)
                        DBUsers[uid] = usr
                        completion(usr)
                    }
                    else{
                        print("EMPTY USER DATA")
                        completion(nil)
                    }
                }
        }
    }
    static func reloadPost(pid: String, completion: @escaping(Post?) -> ()){
        FPOSTS_REF
            .document(pid)
            .getDocument { (doc, err) in
                if let error = err{
                    print("ERROR \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                if let data = doc?.data(), let uid = data[Post.key_owner] as? String{
                    let pst = Post(pid: pid, dic: data)
                    completion(pst)
                }
            }
    }
    static func fetchPost(pid: String, owner: User? = nil, quickLoad: Bool = false, completion: @escaping(Post?) -> ()) {
        if let pst = DBPosts[pid]{
            completion(pst)
            return
        }
        FPOSTS_REF
            .document(pid)
            .getDocument { (doc, err) in
                if let error = err{
                    print("ERROR \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                if let data = doc?.data(), let uid = data[Post.key_owner] as? String{
                    let pst = Post(pid: pid, dic: data)
                    if quickLoad{
                        if let usr = owner, pst.ouname.isEmpty{
                            pst.ouname = usr.uname
                            pst.oavatar = usr.thumb.isEmpty ? usr.avatar : usr.thumb
                        }
                        
                        DBPosts[pid] = pst
                        completion(pst)
                        return
                    }
                    if pst.ouname.isEmpty{
                        if let usr = owner{
                            pst.ouname = usr.uname
                            pst.oavatar = usr.thumb.isEmpty ? usr.avatar : usr.thumb

                            DBPosts[pid] = pst
                            completion(pst)
                        }
                        else{
                            Utils.fetchUser(uid: uid) { (rusr) in
                                guard let usr = rusr else { return }
                                
                                pst.ouname = usr.uname
                                pst.oavatar = usr.thumb.isEmpty ? usr.avatar : usr.thumb
                                
                                if pst.opid.isEmpty{
                                    DBPosts[pid] = pst
                                    completion(pst)
                                }
                                else{
                                    Utils.fetchPost(pid: pst.opid) { (rpst) in
                                        guard let opst = rpst else {
                                            completion(pst)
                                            return }
                                        
                                        pst.opost = opst
                                        DBPosts[pid] = pst
                                        completion(pst)
                                    }
                                }
                            }
                        }
                    }
                    else{
                        if pst.opid.isEmpty{
                            completion(pst)
                        }
                        else{
                            Utils.fetchPost(pid: pst.opid) { (rpst) in
                                guard let opst = rpst else {
                                    DBPosts[pid] = pst
                                    completion(pst)
                                    return }
                                
                                pst.opost = opst
                                DBPosts[pid] = pst
                                completion(pst)
                            }
                        }
                    }
                }
                else{
                    completion(nil)
                }
            }
    }
    static func isFollowingCatePost(post: Post) -> Bool{
        for index in Me.following_cate{
            let cate = categories[index]
            for tag in (cate[3] as! [String]){
                if post.desc.contains("#\(tag)"){
                    return true
                }
            }
        }
        return false
    }
    static func fetchUserName(msg: String) -> [String]{
        let desc: String = msg
        if desc.isEmpty || !desc.contains("@") { return [] }
        
        var result: [String] = []
        
        let text = desc
        let textLength = text.utf16.count
        let range = NSRange(location: 0, length: textLength)
        
        let matches = RegexParser.getElements(from: text, with: RegexParser.mentionPattern, range: range)
        let nsstring = text as NSString
        
        for match in matches where match.range.length > 2 {
            let range = NSRange(location: match.range.location + 1, length: match.range.length - 1)
            var word = nsstring.substring(with: range).lowercased().trimmingCharacters(in: .whitespacesAndNewlines).filter{!" \n\t\r".contains($0)}
            if word.hasPrefix("@") {
                word.remove(at: word.startIndex)
            }
            else if word.hasPrefix("#") {
                word.remove(at: word.startIndex)
            }
            
            if !word.isEmpty && !result.contains(word){
                result.append(word)
            }
        }
        
        return result
    }
    static func fetchTags(post: Post?) -> [String]{
        guard let pst = post else { return [] }
        let desc: String = pst.desc
        if desc.isEmpty || !desc.contains("#") { return [] }
        
        var result: [String] = []
        
        let text = desc
        let textLength = text.utf16.count
        let range = NSRange(location: 0, length: textLength)
        
        let matches = RegexParser.getElements(from: text, with: RegexParser.hashtagPattern, range: range)
        let nsstring = text as NSString
        
        for match in matches where match.range.length > 2 {
            let range = NSRange(location: match.range.location + 1, length: match.range.length - 1)
            var word = nsstring.substring(with: range).lowercased().trimmingCharacters(in: .whitespacesAndNewlines).filter{!" \n\t\r".contains($0)}
            if word.hasPrefix("@") {
                word.remove(at: word.startIndex)
            }
            else if word.hasPrefix("#") {
                word.remove(at: word.startIndex)
            }
            
            if !word.isEmpty && !result.contains(word){
                result.append(word)
            }
        }
        
        return result
    }
    static func fullPost(post: Post, completion: @escaping((Post) -> ())){
        if post.opid.isEmpty{
            //original post
            if post.ouname.isEmpty{
                Utils.fetchUser(uid: post.ouid) { (rusr) in
                    guard let usr = rusr else {
                        completion(post)
                        return
                    }
                    post.oavatar = usr.thumb.isEmpty ? usr.avatar : usr.thumb
                    post.ouname = usr.uname

                    DBPosts[post.pid] = post
                    completion(post)
                }
            }
            else{
                completion(post)
            }
        }
        else{
            if post.ouname.isEmpty{
                Utils.fetchUser(uid: post.ouid) { (rusr) in
                    guard let usr = rusr else {
                        completion(post)
                        return
                    }
                    post.oavatar = usr.thumb.isEmpty ? usr.avatar : usr.thumb
                    post.ouname = usr.uname
                    DBPosts[post.pid] = post
                    completion(post)
                }
            }
            else{
                Utils.fetchPost(pid: post.opid) { (rpst) in
                    guard let pst = rpst else {
                        completion(post)
                        return
                    }
                    post.opost = pst
                    
                    if pst.oavatar.isEmpty || pst.ouname.isEmpty{
                        Utils.fetchUser(uid: pst.ouid) { (rusr) in
                            guard let usr = rusr else {
                                completion(post)
                                return }
                            
                            pst.ouname = usr.uname
                            pst.oavatar = usr.thumb.isEmpty ? usr.avatar : usr.thumb
                            
                            post.opost = pst
                            DBPosts[post.pid] = post
                            completion(post)
                        }
                    }
                    else{
                        completion(post)
                    }
                }
            }
            
        }
    }
}

extension Utils{
    static func isValidUserName(uname: String, completion: @escaping(Bool) -> ()){
        guard let uid = CUID else {
            completion(true)
            return }
        
        FUSER_REF
            .whereField(User.key_uname, isEqualTo: uname.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))
            .getDocuments { (doc, err) in
                if let error = err{
                    print(error.localizedDescription)
                    completion(true)
                    return
                }
                
                var exist = false
                if let count = doc?.documents.count, count > 0{
                    doc?.documents.forEach({ (item) in
                        if item.documentID != uid{
                            exist = true
                            completion(exist)
                            return
                        }
                    })
                    completion(exist)
                }
                else{
                    completion(false)
                }
            }
    }
        
    static func logError(desc: String = "", err: Error){
        print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
        print("ERROR: \(desc) ::: \(err.localizedDescription)")
        print("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
    }
}

extension Utils{
    static func configureFollowButton(btn: UIButton, type: FollowType){
        switch(type){
        case .AbleToFollow:
            btn.setTitle("Follow", for: .normal)
            btn.setTitleColor(UIColor.inactive(), for: .normal)
            btn.layer.borderWidth = 1
            btn.layer.borderColor = UIColor.inactive().cgColor
            btn.backgroundColor = UIColor.bg()
            btn.isEnabled = true
            btn.alpha = 1
            
            break
        case .Following:
            btn.setTitle("Following", for: .normal)
            btn.setTitleColor(UIColor.white, for: .normal)
            btn.backgroundColor = UIColor.active()
            btn.layer.borderWidth = 0
            btn.isEnabled = true
            btn.alpha = 1
            
            break
        case .Requested:
            //locked user - requested
            btn.setTitle("Requested", for: .normal)
            btn.setTitleColor(UIColor.inactive(), for: .normal)
            btn.layer.borderWidth = 1
            btn.layer.borderColor = UIColor.inactive().cgColor
            btn.backgroundColor = UIColor.bg()
            btn.isEnabled = false
            btn.alpha = 0.7
            
            break
        case .Declined:
            //declined
            btn.setTitle("Locked", for: .normal)
            btn.setTitleColor(UIColor.inactive(), for: .normal)
            btn.layer.borderWidth = 1
            btn.layer.borderColor = UIColor.inactive().cgColor
            btn.backgroundColor = UIColor.bg()
            btn.isEnabled = false
            btn.alpha = 0.7
            
            break
        }
    }
}

extension Utils{
    static func today() -> String{
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"

        return formatter.string(from: Date())
    }
    
    static func dayBefore(day: String) -> String{
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        guard let date = formatter.date(from: day) else {
            print("ERROR IN DATE CONVERSION")
            return ""
        }
        
        return formatter.string(from: date.dayBefore)
    }
}
