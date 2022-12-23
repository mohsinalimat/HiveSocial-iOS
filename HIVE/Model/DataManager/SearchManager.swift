//
//  SearchManager.swift
//  HIVE
//
//  Created by elitemobile on 11/20/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import Foundation
import Firebase

struct TrendingResult {
    let postIds: [String]
    let trendingCount: Int
    let trendingDate: Double
}

struct SuggestionResult{
    let tag: String
    let user: User?
}

protocol SearchManagerDelegate{
    func updateSearchResult()
}

class SearchManager {
    
    var searchSuggestions: [SuggestionResult] = []
    var isSearching: Bool = false
    
    static var shared = SearchManager()
    var delegateSearch: SearchManagerDelegate?
    
    func logout(){
        delegateSearch = nil
        
        searchSuggestions.removeAll()
    }
    
    func getSuggestions(for text: String) {
        guard !isSearching && text.count > 2 else { return }
        searchSuggestions = []
        isSearching = true
        
        let searchGroup = DispatchGroup()
        let isHashtag = text.first == "#"

        if(isHashtag){
            let startTxt = String(text.dropFirst()).lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let endTxt: String = (startTxt + "\u{f8ff}").lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

            searchGroup.enter()
            FHASHTAG_POSTS_REF
                .whereField("tag", isGreaterThanOrEqualTo: startTxt.lowercased())
                .whereField("tag", isLessThanOrEqualTo: endTxt.lowercased())
                .limit(to: 20)
                .getDocuments { (keysDoc, err) in
                    if let error = err{
                        print(error.localizedDescription)
                        searchGroup.leave()
                        return
                    }
                    
                    keysDoc?.documents.forEach({ (keyDoc) in
                        let keyTag = keyDoc.documentID
                        print("searched tag - \(keyTag)")
                        self.searchSuggestions.append(SuggestionResult(tag: "#\(keyTag)", user: nil))
                    })
                    
                    searchGroup.leave()
                }
        }
        else{
            searchGroup.enter()
            
            let startTxt: String = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let endTxt: String = (text + "\u{f8ff}").lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            FUSER_REF
                .whereField(User.key_uname, isGreaterThanOrEqualTo: startTxt)
                .whereField(User.key_uname, isLessThanOrEqualTo: endTxt)
                .limit(to: 20)
                .getDocuments { (doc, err) in
                    if let error = err{
                        print(error.localizedDescription)
                        searchGroup.leave()
                        return
                    }
                    
                    doc?.documents.forEach({ (item) in
                        let usr = User(uid: item.documentID, data: item.data())
                        self.searchSuggestions.append(SuggestionResult(tag: "", user: usr))
                        print("searched user - \(usr.uname)")
                    })
                    
                    searchGroup.leave()
                }
        }
        
        searchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.delegateSearch?.updateSearchResult()
            self.isSearching = false
        }
    }
}
