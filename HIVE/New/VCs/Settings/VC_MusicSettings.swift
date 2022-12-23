//
//  VC_MusicSettings.swift
//  HIVE
//
//  Created by elitemobile on 12/29/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import UIKit
import Firebase

class VC_MusicSettings: UIViewController {

    @IBOutlet weak var sw_music: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()

        initComponents()
    }
    
    func initComponents(){
        self.addSwipeRight()
        
        sw_music.isOn = Me.play_song
    }
    
    @IBAction func opChangeAutoPlay(_ sender: Any) {
        guard let cuid = CUID else { return }
        
        FUSER_REF
            .document(cuid)
            .updateData([
                User.key_play_song: sw_music.isOn
            ]) { (err) in
                if let error = err{
                    print(error.localizedDescription)
                    return
                }
                
                Me.play_song = self.sw_music.isOn
                Me.saveLocal()
            }
    }
    
    @IBAction func opBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func opSave(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}
