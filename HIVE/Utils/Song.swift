//
//  Song.swift
//  HIVE
//
//  Created by Daniel Pratt on 9/20/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import Foundation

enum MusicError: Error {
    case invalidUrl
    case noData
    case jsonDecoding
    case networkError(innerError: Error?)
}

struct Song {
    let title: String
    let artist: String
    let id: String
    let artworkUrl: URL
    
    init(id: String, title: String, artist: String, artworkUrl: URL) {
        self.title = title
        self.artist = artist
        self.id = id
        self.artworkUrl = artworkUrl
    }
    
    init(from fireSong: FirebaseSong) {
        self.init(id: fireSong.id, title: fireSong.title, artist: fireSong.artist, artworkUrl: URL(string: fireSong.artworkUrl)!)
    }
    
    init?(queryItems: [URLQueryItem]) {
        guard let title = queryItems.first(where: { queryItem in queryItem.name == Song.AttributesKeys.title.stringValue })?.value,
            let artist = queryItems.first(where: { queryItem in queryItem.name == Song.AttributesKeys.artist.stringValue })?.value,
            let id = queryItems.first(where: { queryItem in queryItem.name == Song.CodingKeys.id.stringValue })?.value,
            let artworkUrlString = queryItems.first(where: { queryItem in queryItem.name == Song.AttributesKeys.artwork.stringValue })?.value else { return nil }
        self.title = title
        self.artist = artist
        self.id = id
        
        guard let artworkUrl = URL(string: artworkUrlString) else { return nil }
        self.artworkUrl = artworkUrl
    }
    
    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        items.append(URLQueryItem(name: Song.AttributesKeys.title.stringValue, value: title))
        items.append(URLQueryItem(name: Song.AttributesKeys.artist.stringValue, value: artist))
        items.append(URLQueryItem(name: Song.CodingKeys.id.stringValue, value: id))
        items.append(URLQueryItem(name: Song.AttributesKeys.artwork.stringValue, value: artworkUrl.absoluteString))
        return items
    }
}

extension Song: Decodable {
    enum CodingKeys: String, CodingKey {
        case id
        case attributes
    }
    
    enum AttributesKeys: String, CodingKey {
        case title = "name"
        case artist = "artistName"
        case artwork
    }
    
    enum ArtworkKeys: String, CodingKey {
        case url
    }
    
    init(from decoder: Decoder) throws {
        let topContainer = try decoder.container(keyedBy: CodingKeys.self)
        let id = try topContainer.decode(String.self, forKey: .id)
        
        let attributes = try topContainer.nestedContainer(keyedBy: AttributesKeys.self, forKey: .attributes)
        let title = try attributes.decode(String.self, forKey: .title)
        let artist = try attributes.decode(String.self, forKey: .artist)
        
        let artwork = try attributes.nestedContainer(keyedBy: ArtworkKeys.self, forKey: .artwork)
        let artworkUrlTemplate = try artwork.decode(String.self, forKey: .url)
        let urlString = artworkUrlTemplate.replacingOccurrences(of: "{w}", with: "150").replacingOccurrences(of: "{h}", with: "150")
        guard let url = URL(string: urlString) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [ArtworkKeys.url], debugDescription: "Artwork URL not in URL format"))
        }
        
        self.init(id: id, title: title, artist: artist, artworkUrl: url)
    }
}

extension Song {
    
    static func getSearchHint(for search: String, completion: @escaping (_ hints: [String], _ error: Error?) -> Void) {
        AuthorizationManager.withAPIData { (developerToken, countryCode) in
            // generate search string
            guard let text = search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                print("~>Unable to generate query from string")
                return
            }
            
            guard let url = URL(string: "https://api.music.apple.com/v1/catalog/\(countryCode)/search/hints?term=\(text)&limit=10") else {
                print("~>Unable to construct search hint url")
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(developerToken)", forHTTPHeaderField: "Authorization")
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
//                if let response = response as? HTTPURLResponse {
//                    print("~>Response code: \(response.statusCode)")
//                }
                
                let completeOnMain: ([String], Error?) -> Void = { hints, error in
                    DispatchQueue.main.async {
                        completion(hints, error)
                    }
                }
                
                if let error = error {
                    completeOnMain([], MusicError.networkError(innerError: error))
                    return
                }
                guard let data = data else {
                    completeOnMain([], MusicError.noData)
                    return
                }
                
                guard let jsonData = try? JSONSerialization.jsonObject(with: data),
                let dataDictionary = jsonData as? [String: Any],
                let results = dataDictionary["results"] as? [String:Any],
                let hints = results["terms"] as? [String] else {
                        completeOnMain([], MusicError.jsonDecoding)
                        return
                }
                
                // send back search hint results
                completeOnMain(hints, nil)
            }
            task.resume()
        }
    }
    
    static func search(for search: String, maxResults: Int = 10, completion: @escaping (_ songs: [Song]?, _ error: Error?) -> Void) {
        AuthorizationManager.withAPIData { (developerToken, countryCode) in
            print("~>Country code: \(countryCode)")
            // generate search string
            guard let text = search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                print("~>Unable to generate query from string")
                return
            }
            
            guard let url = URL(string: "https://api.music.apple.com/v1/catalog/\(countryCode)/search?term=\(text)&limit=\(maxResults)&types=songs") else {
                print("~>Unable to construct search hint url")
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(developerToken)", forHTTPHeaderField: "Authorization")
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
//                if let response = response as? HTTPURLResponse {
//                    print("~>Response code: \(response.statusCode)")
//                }
                
                let completeOnMain: ([Song]?, Error?) -> Void = { songs, error in
                    DispatchQueue.main.async {
                        completion(songs, error)
                    }
                }
                
                if let error = error {
                    completeOnMain([], MusicError.networkError(innerError: error))
                    return
                }
                guard let data = data else {
                    completeOnMain([], MusicError.noData)
                    return
                }
                
                guard let jsonData = try? JSONSerialization.jsonObject(with: data),
                    let dataDictionary = jsonData as? [String: Any],
                    let results = dataDictionary["results"] as? [String:Any],
                    let songsArray = results["songs"] as? [String: Any],
                    let songsDictionary = songsArray["data"] as? [Any],
                    let songsData = try? JSONSerialization.data(withJSONObject: songsDictionary),
                    let songs = try? JSONDecoder().decode([Song].self, from: songsData) else {
                        completeOnMain(nil, MusicError.jsonDecoding)
                        return
                }
                completeOnMain(songs, nil)
            }
            task.resume()
        }
    }
    
    static func search(forSongs search: [String], completion: @escaping ([Song], [Error]) -> Void) {
        var songs: [Song] = []
        var errors: [Error] = []
        
        let searchGroup = DispatchGroup()
        
        for string in search {
            searchGroup.enter()
            DispatchQueue.global(qos: .utility).async {
                Song.search(for: string, maxResults: 1, completion: { (results, error) in
                    if let results = results, results.count > 0, let song = results.first {
                        songs.append(song)
                        searchGroup.leave()
                    } else if let error = error {
                        errors.append(error)
                        searchGroup.leave()
                    } else {
                        print("~>No results or errors.")
                        searchGroup.leave()
                    }
                })
            }
        }
        
        searchGroup.notify(queue: .main) {
            print("~>Search complete.")
            completion(songs, errors)
        }
        
    }
    
    static func top40Songs(completion: @escaping ([Song]?, Error?) -> Void) {
        AuthorizationManager.withAPIData { developerToken, countryCode in
            guard let url = URL(string: "https://api.music.apple.com/v1/catalog/\(countryCode)/charts?types=songs&chart=most-played&limit=40") else {
                completion(nil, MusicError.invalidUrl)
                return
            }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(developerToken)", forHTTPHeaderField: "Authorization")
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
//                if let response = response as? HTTPURLResponse {
//                    print("~>Response code: \(response.statusCode)")
//                }
//                
                let completeOnMain: ([Song]?, Error?) -> Void = { songs, error in
                    DispatchQueue.main.async {
                        completion(songs, error)
                    }
                }
                
                if let error = error {
                    completeOnMain(nil, MusicError.networkError(innerError: error))
                    return
                }
                guard let data = data else {
                    completeOnMain(nil, MusicError.noData)
                    return
                }
                
                guard let jsonData = try? JSONSerialization.jsonObject(with: data),
                    let dataDictionary = jsonData as? [String: Any],
                    let results = dataDictionary["results"] as? [String:Any],
                    let songsArray = results["songs"] as? [[String: Any]],
                    let songsItem = songsArray.first,
                    let songsDictionary = songsItem["data"],
                    let songsData = try? JSONSerialization.data(withJSONObject: songsDictionary),
                    let songs = try? JSONDecoder().decode([Song].self, from: songsData) else {
                        completeOnMain(nil, MusicError.jsonDecoding)
                        return
                }
                completeOnMain(songs, nil)
            }
            task.resume()
        }
    }

}
