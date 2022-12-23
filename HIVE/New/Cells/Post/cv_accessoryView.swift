//
//  cv_accessoryView.swift
//  HIVE
//
//  Created by elitemobile on 11/16/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import Foundation
import UIKit
import CollectionKit
import YPImagePicker
import GiphyUISDK
import GradientLoadingBar

class cv_accessoryView: UIView{
    @IBOutlet weak var gradientView: GradientActivityIndicatorView!
    @IBOutlet weak var v_post: UIView!
    
    @IBOutlet weak var img_content: UIImageView!
    @IBOutlet weak var img_content_type: UIImageView!
    
    var opSelectMediaAction: ((Int) -> Void)?
    var opDeleteMediaAction: (() -> Void)?
    
    var selectedMedia: YPMediaItem? = nil
    var selectedGif: GPHMedia? = nil
    
    var post: Post!
    var isEdit: Bool = false
    var isRepost: Bool = false
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initComponents()
    }
    
    func initComponents(){
        gradientView.isHidden = true
        gradientView.progressAnimationDuration = 6
        gradientView.gradientColors = [
            UIColor(named: "ncol_gradient_0")!,
            UIColor(named: "ncol_gradient_1")!,
            UIColor(named: "ncol_gradient_2")!,
            UIColor(named: "ncol_gradient_3")!,
            UIColor(named: "ncol_gradient_4")!,
            UIColor(named: "ncol_gradient_5")!,
        ]
        
        v_post.makeRoundView(r: 14)
        v_post.isHidden = true
    }
    
    @IBAction func opSetMedia(_ sender: Any) {
        if self.isRepost || self.isEdit { return }
        if self.locked { return }

        self.opSelectMediaAction?(0)
    }
    
    @IBAction func opSetGif(_ sender: Any) {
        if self.isRepost || self.isEdit { return }
        if self.locked { return }

        self.opSelectMediaAction?(1)
    }
    
    @IBAction func opDeleteSelected(_ sender: Any) {
        if self.isRepost || self.isEdit { return }
        if self.locked { return }
        
        v_post.isHidden = true
        
        self.img_content_type.isHidden = true
        self.img_content.image = nil
        self.img_content_type.image = nil
        
        self.opDeleteMediaAction?()
    }
    
    func setMedia(media: YPMediaItem? = nil, gif: GPHMedia? = nil){
        self.selectedGif = gif
        self.selectedMedia = media
        
        self.v_post.isHidden = false
        self.img_content_type.isHidden = true
        
        if let gif = self.selectedGif{
            self.img_content.loadImg(str: gif.url(rendition: .fixedWidth, fileType: .gif)!)
            self.img_content_type.image = UIImage(named: "mic_gif")!
            self.img_content_type.isHidden = false
        }
        else if let media = self.selectedMedia{
            switch(media){
            case .photo(p: let img):
                self.img_content.image = img.image
                break
            case .video(v: let video):
                self.img_content.image = video.thumbnail
                self.img_content_type.image = UIImage(named: "mic_music_play")!
                self.img_content_type.isHidden = false
                break
            }
        }
    }
    
    func setPost(pst: Post, edit: Bool = false){
        self.post = pst
        self.isEdit = edit
        self.isRepost = !edit
        
        var type = post.type
        if let opst = post.opost{
            type = opst.type
        }

        switch(type){
        case .TEXT:
            self.v_post.isHidden = true
            break
        case .GIF:
            self.v_post.isHidden = false
            self.img_content_type.isHidden = false
            self.img_content_type.image = UIImage(named: "mic_gif")!
            self.img_content.isHidden = false
            
            if let opst = pst.opost{
                if let gifUrl = opst.media.first as? String, !gifUrl.isEmpty{
                    self.img_content.loadImg(str: gifUrl)
                }
            }
            else{
                if let gifUrl = pst.media.first as? String, !gifUrl.isEmpty{
                    self.img_content.loadImg(str: gifUrl)
                }
            }
            break
        case .IMAGE:
            self.v_post.isHidden = false
            self.img_content_type.isHidden = true
            self.img_content.isHidden = false
            
            if let opst = pst.opost{
                if let imgUrl = opst.media.first as? String, !imgUrl.isEmpty{
                    self.img_content.loadImg(str: imgUrl)
                }
            }
            else{
                if let imgUrl = pst.media.first as? String, !imgUrl.isEmpty{
                    self.img_content.loadImg(str: imgUrl)
                }
            }
            break
        case .VIDEO:
            self.v_post.isHidden = false
            self.img_content_type.isHidden = false
            self.img_content_type.image = UIImage(named: "mic_music_play")!
            self.img_content.isHidden = false
            
            if let opst = pst.opost{
                if let vidUrl = opst.media.first as? [String: String], vidUrl.count > 0{
                    self.img_content.loadImg(str: vidUrl.values.first!)
                }
            }
            else{
                if let vidUrl = pst.media.first as? [String: String], vidUrl.count > 0{
                    self.img_content.loadImg(str: vidUrl.values.first!)
                }
            }
            break
        }
    }
    
    func showGradientView(){
        gradientView.fadeIn()
    }
    func hideGradientView(){
        gradientView.fadeOut()
    }
    
    var locked: Bool = false
    func setLocked(locked: Bool){
        self.locked = locked
    }
}
