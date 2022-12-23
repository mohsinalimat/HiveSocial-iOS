//
//  GIPHY.swift
//  HIVE
//
//  Created by Daniel Pratt on 8/29/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import GiphyUISDK

protocol GIPHYMediaManagerDelegate {
    func got(media: GPHMedia)
}

class GIPHYModel {
    // delegate for sending media
    var delegate: GIPHYMediaManagerDelegate? = nil
    
    init() {
        Giphy.configure(apiKey: GIPHYConstant.apiKey)
    }
    
    func getGiphyVC() -> GiphyViewController {
        let giphy = GiphyViewController()
        giphy.mediaTypeConfig = [.gifs, .stickers, .text, .emoji]
        giphy.rating = .ratedPG
        giphy.shouldLocalizeSearch = true
        giphy.delegate = self
        
        return giphy
    }
}

extension GIPHYModel: GiphyDelegate {
    
    func didSelectMedia(giphyViewController: GiphyViewController, media: GPHMedia) {
        giphyViewController.dismiss(animated: true) {
            self.delegate?.got(media: media)
        }
    }
    
    func didDismiss(controller: GiphyViewController?) {
        print("~>Dismissed without selecting anything")
    }
}
