//
//  cell_media_collection.swift
//  HIVE
//
//  Created by elitemobile on 12/9/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage

class cell_media_collection: UICollectionViewCell {
    
    // MARK: - IBOutlets
    @IBOutlet weak var img_content: UIImageView!
    @IBOutlet weak var img_play: UIImageView!
    @IBOutlet weak var btn_select: UIButton!
    
    @IBOutlet weak var leadingConstant: NSLayoutConstraint!
    @IBOutlet weak var trailingConstant: NSLayoutConstraint!
    @IBOutlet weak var bottomConstant: NSLayoutConstraint!
    @IBOutlet weak var topConstant: NSLayoutConstraint!
    
    @IBOutlet weak var v_warning: UIView!
    //  MARK: - Properties
    var opChooseAction: ((UIImage?) -> Void)?
    var special: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initComponents()
    }
    
    func initComponents(){
        v_warning.isHidden = true
        v_warning.makeCircleView()
    }
    
    var post: Post!
    func setPost(post: Post){
        self.img_content.image = nil
        self.post = post
        if post.opid.isEmpty{
            setupMedia(pst: post)
        }
        else{
            if post.opost == nil{
                Utils.fetchPost(pid: post.opid) { (rpst) in
                    guard let pst = rpst else { return }
                    self.post.opost = pst
                    self.setupMedia(pst: pst)
                }
            }
            else{
                self.setupMedia(pst: self.post.opost!)
            }
        }
    }
    
    func setConstraint(top: Bool = false, right: Bool = false, left: Bool = false, bottom: Bool = false, sp: Bool = false){
        topConstant.constant = 0.0
        bottomConstant.constant = 0.0
        leadingConstant.constant = 0.0
        trailingConstant.constant = 0.0
        if top{
            topConstant.constant = 0.5
        }
        if bottom{
            bottomConstant.constant = 0.5
        }
        if left{
            leadingConstant.constant = 0.5
        }
        if right{
            trailingConstant.constant = sp ? -0.5 : 0.5
        }
    }
    
    func setupMedia(pst: Post){
        self.v_warning.isHidden = true
        switch pst.type {
            case .IMAGE:
                img_play.isHidden = true
                if let imgUrl = pst.media.first as? String, !imgUrl.isEmpty{
                    if let thumbUrl = pst.thumb.first as? String, !thumbUrl.isEmpty{
                        if Me.uid == vipUser{
                            img_content.loadImg(str: imgUrl)
                        }
                        else{
                            if special{
                                img_content.loadImg(str: imgUrl, thumb: thumbUrl)
                            }
                            else{
                                img_content.loadImg(str: thumbUrl)
                            }
                        }
                    }
                    else{
                        if Me.uid == vipUser || adminUser.contains(Me.uid){
                            self.v_warning.isHidden = false
                        }
                        
                        img_content.loadImg(str: imgUrl)
                    }
                }
                else{
                    if Me.uid == vipUser || adminUser.contains(Me.uid){
                        self.v_warning.isHidden = false
                    }
                    img_content.image = nil
                }
                break
            case .VIDEO:
                img_play.isHidden = false
                img_play.image = UIImage(named: "mic_video_play")
                if let vidUrl = pst.media.first as? [String: String], vidUrl.count > 0{
                    if let thumbUrl = pst.thumb.first as? String, !thumbUrl.isEmpty{
                        img_content.loadImg(str: thumbUrl)
                    }
                    else{
                        if Me.uid == vipUser || adminUser.contains(Me.uid){
                            self.v_warning.isHidden = false
                        }
                        img_content.loadImg(str: vidUrl.values.first!)
                    }
                }
                else{
                    if Me.uid == vipUser || adminUser.contains(Me.uid){
                        self.v_warning.isHidden = false
                    }
                    img_content.image = nil
                }
                break
            case .GIF:
                img_play.isHidden = false
                img_play.image = UIImage(named: "mic_gif")
                if let gifUrl = pst.media.first as? String, !gifUrl.isEmpty{
                    img_content.loadImg(str: gifUrl)
                }
                else{
                    img_content.image = nil
                }
                break
            default:
                print("This is Error - REAL ERROR _ COLLECTIONVIEW CELL")
                print(pst.pid)
                break
        }
    }
    
    @IBAction func opChoose(_ sender: Any) {
        opChooseAction?(self.img_content.image)
    }
}
