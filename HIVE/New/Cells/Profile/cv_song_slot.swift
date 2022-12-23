//
//  cv_song_slot.swift
//  HIVE
//
//  Created by elitemobile on 11/26/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import UIKit
import BEMCheckBox

class cv_song_slot: UITableViewCell {
    @IBOutlet weak var img_song: UIImageView!
    @IBOutlet weak var lbl_title: UILabel!
    @IBOutlet weak var lbl_artist: UILabel!
    
    @IBOutlet weak var lbl_slotStatus: UILabel!
    @IBOutlet weak var v_chk: BEMCheckBox!
    @IBOutlet weak var v_arrow: UIView!
    @IBOutlet weak var v_songExist: UIView!

    @IBOutlet weak var lbl_price: UILabel!
    @IBOutlet weak var v_needPurchase: UIView!
    
    var opSelectedAction: (() -> Void)?
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initComponents()
    }

    func initComponents(){
        img_song.makeRoundView(r: 4)
        lbl_slotStatus.makeRoundView(r: 4)
        lbl_slotStatus.layer.borderWidth = 1.5
    }
    
    func setupSong(song: FirebaseSong? = nil, slotPurchased: Bool = false, index: Int){
        img_song.image = nil
        lbl_title.text = "Song Title"
        lbl_artist.text = "Artist"
        if let sng = song{
            img_song.loadImg(str: sng.artworkUrl)
            lbl_title.text = sng.title
            lbl_artist.text = sng.artist
            v_chk.setOn(true, animated: false)
            v_chk.isHidden = false
            v_arrow.isHidden = true
        }
        else{
            v_chk.setOn(false, animated: false)
            v_chk.isHidden = true
            v_arrow.isHidden = false
        }

        if slotPurchased{
            v_needPurchase.isHidden = true
            v_songExist.isHidden = false
        }
        else{
            v_needPurchase.isHidden = index == 0
            v_songExist.isHidden = index != 0
        }

        lbl_slotStatus.text = index == 0 ? "Free Slot" : "Purchased"
        lbl_slotStatus.layer.borderColor = index == 0 ? UIColor.active().cgColor : UIColor.success().cgColor
        lbl_slotStatus.textColor = index == 0 ? UIColor.active() : UIColor.success()
        
        switch(index){
        case 1:
            lbl_price.text = "$0.99"
            break
        case 2:
            lbl_price.text = "$1.99"
            break
        case 3:
            lbl_price.text = "$1.99"
            break
        default:
            lbl_price.text = ""
            break
        }
    }
    
    @IBAction func opSelected(_ sender: Any) {
        self.opSelectedAction?()
    }
}
