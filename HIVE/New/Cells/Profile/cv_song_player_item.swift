//
//  cv_song_player_item.swift
//  HIVE
//
//  Created by elitemobile on 12/17/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import UIKit

class cv_song_player_item: UIView {

    @IBOutlet weak var img_song: UIImageView!
    @IBOutlet weak var btn_play: UIButton!
    @IBOutlet weak var v_out: UIView!
    
    var opSongSelectedAction: (() -> Void)?
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initComponents()
    }
    
    func initComponents(){
        self.v_out.makeRoundView(r: 4)
    }
    
    func setupSong(song: FirebaseSong){
        img_song.loadImg(str: song.artworkUrl)
        updateButton(isPlaying: false)
    }
    
    @IBAction func opSelectSong(_ sender: Any) {
        self.opSongSelectedAction?()
    }
    
    func updateButton(isPlaying: Bool = false){
//        btn_play.setImage(UIImage(named: isPlaying ? "mic_music_pause" : "mic_music_play"), for: .normal)
    }
}
