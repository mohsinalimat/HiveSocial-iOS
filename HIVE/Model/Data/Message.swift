//
//  Message.swift
//  HIVEcopy
//
//  Created by Kassy Pop on 8/24/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import Foundation
import CoreLocation
import MessageKit
import AVFoundation
import Firebase

final internal class ChatData {
    static let shared = ChatData()
    
    private init() {}
    
    enum MessageTypes: String, CaseIterable {
        case Text
    }
    
    var currentSender: MockUser {
        return MockUser(senderId: Me.uid, displayName: Me.displayName, displayImage: Me.avatar)
    }
}

class MockChannel {
    var channelId: String!
    
    //users in channel
    var userIds: [String] = []
    //last message
    var lastMsg: MockMessage!
    var deletedTime: Double = 0
    var lastSeen: Double = 0
    var targetUser: User!
    var targetUserOnline: Bool = false
    var activated: Bool = false
    
    //MARK: - string for the variables
    static let key_members: String = "users"
    static let key_last_msg: String = "lastMessage"
    static let key_deleted_time: String = "deleted_"
    static let key_last_seen: String = "last_seen_"
    static let key_online: String = "online_"
    
    static let key_collection_msgs: String = "messages"
    init(){
    }
    init(id: String, dic: [String: Any]) {
        channelId = id
        if let ids = dic[MockChannel.key_members] as? [String]{
            self.userIds = ids.sorted()
        }
        let targetUserId = self.targetUserId()

        guard !targetUserId.isEmpty else { return }
        if let online = dic[MockChannel.key_online + targetUserId] as? Bool{
            self.targetUserOnline = online
        }
        if let lMsg = dic[MockChannel.key_last_msg] as? [String: Any]{
            self.lastMsg = MockMessage(dic: lMsg)
        }
        
        guard let cid = CUID else { return }
        if let deleted = dic[MockChannel.key_deleted_time + cid] as? Double{
            self.deletedTime = deleted
        }
        if let lastSeen = dic[MockChannel.key_last_seen + cid] as? Double{
            self.lastSeen = lastSeen
        }
        
        activated = true
    }
    func getJson() -> [String: Any]{
        var data: [String: Any] = [
            MockChannel.key_members: self.userIds.sorted(),
            MockChannel.key_online + Me.uid: true,
            MockChannel.key_last_seen + Me.uid: Utils.curTime
        ]
        
        if self.lastMsg != nil{
            data[MockChannel.key_last_msg] = self.lastMsg.getJson()
        }
        
        return data
    }

    func targetUserId() -> String{
        guard let cid = CUID else {
            return ""
        }
        var receiverId: String = ""
        if let index = userIds.firstIndex(where: { (id) -> Bool in
            cid == id
        }){
            receiverId = userIds[(index + 1) % 2]
        }
        return receiverId
    }
    func delete(){
        guard let cid = CUID else { return }
        ChatChannels.removeValue(forKey: self.channelId)
        FCHAT_REF
            .document(self.channelId)
            .setData([
                MockChannel.key_deleted_time + cid: Utils.curTime
            ], merge: true)
    }
    func setLastSeen(){
        guard let cid = CUID else { return }
        self.lastSeen = Utils.curTime
        FCHAT_REF
            .document(self.channelId)
            .setData([
                MockChannel.key_last_seen + cid: self.lastSeen
            ], merge: true)
    }
    func setOnline(online: Bool = true){
        guard let cid = CUID else { return }
        FCHAT_REF
            .document(self.channelId)
            .setData([
                MockChannel.key_online + cid: online
            ], merge: true)
    }
}
private struct ImageMediaItem: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
    init(image: UIImage) {
        self.image = image
        self.size = CGSize(width: 240, height: 240)
        self.placeholderImage = UIImage()
    }
    init(imageURL: URL) {
        self.url = imageURL
        self.size = CGSize(width: 240, height: 240)
        self.placeholderImage = UIImage(named: "mic_top_camera")!
    }
}

class MockMessage: MessageType{
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    var user: MockUser
    
    var sender: SenderType{
        return user
    }
    
    //MARK: - string variables.
    static let key_msg_id: String = "id"
    static let key_timestamp: String = "created"
    static let key_sender: String = "sender"
    static let key_msg_content: String = "txt"
    static let key_msg_type: String = "type"
    
    init(kind: MessageKind, user: MockUser, messageId: String, date: Date) {
        self.messageId = messageId
        self.kind = kind
        self.user = user
        self.sentDate = date
    }

    convenience init(imageURL: URL, user: MockUser, messageId: String, date: Date) {
        let mediaItem = ImageMediaItem(imageURL: imageURL)
        self.init(kind: .photo(mediaItem), user: user, messageId: messageId, date: date)
    }

    convenience init(text: String, user: MockUser, messageId: String, date: Date) {
        self.init(kind: .text(text), user: user, messageId: messageId, date: date)
    }
    
    init(id: String = "", dic: [String: Any]){
        self.messageId = id
        self.sentDate = Date()
        self.kind = .text("")
        self.user = MockUser(senderId: "", displayName: "", displayImage: "")
        
        if let timestamp = dic[MockMessage.key_timestamp] as? Double{
            self.sentDate = Date(timeIntervalSince1970: timestamp)
        }
        
        if let msg = dic[MockMessage.key_msg_content] as? String{
            if let msgType = dic[MockMessage.key_msg_type] as? String{
                if msgType == "photo"{
                    let mediaItem = ImageMediaItem(imageURL: URL(string: msg)!)
                    self.kind = .photo(mediaItem)
                }
                else if msgType == "text"{
                    self.kind = .text(msg)
                }
            }
            else{
                self.kind = .text(msg)
            }
        }
        
        if let senderId = dic[MockMessage.key_sender] as? String{
            self.user = MockUser(senderId: senderId, displayName: "", displayImage: "")
            Utils.fetchUser(uid: senderId) { (rusr) in
                guard let usr = rusr else { return }
                self.user = MockUser(senderId: senderId, displayName: usr.displayName, displayImage: usr.thumb.isEmpty ? usr.avatar : usr.thumb)
            }
        }
    }
    
    func getJson() -> [String: Any]{
        var msgTxt: String = ""
        switch(self.kind){
            case .text(let txt):
                msgTxt = txt
                let data = [
                    MockMessage.key_timestamp: self.sentDate.timeIntervalSince1970,
                    MockMessage.key_sender: self.sender.senderId,
                    MockMessage.key_msg_content: msgTxt,
                    MockMessage.key_msg_type: "text"
                ] as [String : Any]
                
                return data
            case .photo(let mediaItem):
                msgTxt = mediaItem.url?.absoluteString ?? ""
                
                let data = [
                    MockMessage.key_timestamp: self.sentDate.timeIntervalSince1970,
                    MockMessage.key_sender: self.sender.senderId,
                    MockMessage.key_msg_content: msgTxt,
                    MockMessage.key_msg_type: "photo"
                ] as [String : Any]
                
                return data

            default:
                break
        }
        
        return [:]
    }
}

struct MockUser: SenderType, Equatable{
    var senderId: String
    var displayName: String
    var displayImage: String
}
