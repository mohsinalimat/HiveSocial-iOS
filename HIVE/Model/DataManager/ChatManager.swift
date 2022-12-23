//
//  ChatManager.swift
//  HIVE
//
//  Created by elitemobile on 11/10/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

protocol ChannelsUpdated{
    func channelsUpdated()
}

class ChatManager{
    static let shared: ChatManager = ChatManager()
    
    var delegateChatChannels: ChannelsUpdated?
    var chatListener: ListenerRegistration?
    
    init(){
    }
    
    func logout(){
        delegateChatChannels = nil
        ChatChannels.removeAll()
        
        chatListener?.remove()
        chatListener = nil
    }
    
    func loadChannels(){
        guard let cid = CUID else { return }
        if chatListener != nil{
            return
        }
        
        chatListener = FCHAT_REF
            .whereField(MockChannel.key_members, arrayContains: cid)
            .addSnapshotListener { (doc, err) in
                if let error = err{
                    print(error.localizedDescription)
                    return
                }
                
                doc?.documentChanges.forEach({ (item) in
                    switch(item.type){
                    case .removed:
                        ChatChannels.removeValue(forKey: item.document.documentID)
                        self.delegateChatChannels?.channelsUpdated()
                        break
                    default:
                        let chn: MockChannel = MockChannel(id: item.document.documentID, dic: item.document.data())
                        if chn.targetUserId().isEmpty || chn.lastMsg == nil{
                            return
                        }
                        Utils.fetchUser(uid: chn.targetUserId()) { (rusr) in
                            guard let usr = rusr else { return }
                            chn.targetUser = usr
                            ChatChannels[item.document.documentID] = chn
                            self.delegateChatChannels?.channelsUpdated()
                        }
                        break
                    }
                })
            }
    }
}
