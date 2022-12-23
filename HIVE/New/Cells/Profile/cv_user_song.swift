//
//  cv_user_song.swift
//  HIVE
//
//  Created by elitemobile on 12/18/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import UIKit

class cv_user_song: UIView {
    @IBOutlet weak var v_out: UIView!
    @IBOutlet weak var img_song: UIImageView!
    @IBOutlet weak var btn_pause: UIButton!
    @IBOutlet weak var btn_play: UIButton!
    @IBOutlet weak var lbl_song_title: UILabel!
    @IBOutlet weak var v_song_shadow: UIView!
    
    var opPauseAction: (() -> Void)?
    var opPlayAction: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initComponents()
    }
    
    func initComponents(){
        img_song.makeRoundView(r: 4)
        self.btn_play.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.v_song_shadow.addShadow(circle: true, shadowCol: UIColor.black.cgColor, shadowRadius: 4)
        }
    }
    
    var isPlaying: Bool = false
    func setupSong(song: FirebaseSong, isPlaying: Bool = false){
        self.isPlaying = isPlaying
        
        let urlStr = song.artworkUrl.replacingOccurrences(of: "150x150", with: "1050x1050")
        img_song.loadImg(str: urlStr)
        
        if !song.title.isEmpty && !song.artist.isEmpty{
            let text = "\(song.title) - \(song.artist)"
            lbl_song_title.text = text
        }
        else if !song.artist.isEmpty{
            let text = "Song Title - \(song.artist)"
            lbl_song_title.text = text
        }
        else if !song.title.isEmpty{
            let text = "\(song.title)"
            lbl_song_title.text = text
        }
        else{
            lbl_song_title.text = "Song Title"
        }
        btn_play.setImage(UIImage(named: isPlaying ? "mic_music_pause" : "mic_music_play"), for: .normal)
    }
    
    @IBAction func opPlay(_ sender: Any) {
        if self.isPlaying{
            self.opPauseAction?()
        }
        else{
            self.opPlayAction?()
        }
        
        btn_play.setImage(UIImage(named: isPlaying ? "mic_music_pause" : "mic_music_play"), for: .normal)
    }
    
    @IBAction func opPause(_ sender: Any) {
        
    }
}
