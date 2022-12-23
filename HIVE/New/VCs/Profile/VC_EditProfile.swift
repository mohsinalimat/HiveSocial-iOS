//
//  EditProfileViewController.swift
//  HIVE
//
//  Created by Daniel Pratt on 9/24/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import UIKit
import Firebase
import YPImagePicker

class VC_EditProfile: UIViewController {
    @IBOutlet weak var img_banner: UIImageView!
    @IBOutlet weak var img_avatar: UIImageView!
    @IBOutlet weak var v_avatar_mask: UIView!
    @IBOutlet weak var txt_fname: UITextField!
    @IBOutlet weak var txt_bio: UITextView!
    @IBOutlet weak var txt_bio_placeholder: UITextField!
    @IBOutlet weak var txt_website: UITextField!
    @IBOutlet weak var btn_save: UIButton!
    
    @IBOutlet weak var v_fname: UIView!
    @IBOutlet weak var v_bio: UIView!
    @IBOutlet weak var v_website: UIView!
    @IBOutlet weak var v_music: UIView!
    
    var nameChanged: Bool = false
    var websiteChanged: Bool = false
    var bioChanged: Bool = false
    var imgAvatar: UIImage? = nil
    var imgBanner: UIImage? = nil
    
    var opUpdateProfile: (() -> Void)?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initComponents()
        loadStoreProducts()
    }
    
    func loadStoreProducts(){
        HIVEProducts.store.requestProducts { (success, products) in
        }
    }
    
    func initComponents(){
        addSwipeRight()
        
        img_avatar.makeCircleView()
        v_avatar_mask.makeCircleView()
        img_avatar.layer.borderWidth = 2
        img_avatar.layer.borderColor = UIColor.white.cgColor
        
        v_fname.makeRoundView(r: 2)
        v_bio.makeRoundView(r: 2)
        v_website.makeRoundView(r: 2)
        v_music.makeRoundView(r: 2)
        
        loadData()
        updateSaveButton()
        
        txt_bio.delegate = self
        txt_fname.delegate = self
        txt_website.delegate = self
        
        nameChanged = false
        websiteChanged = false
        bioChanged = false
    }
    
    func loadData(){
        img_avatar.loadImg(str: Me.avatar, user: true)
        img_banner.loadImg(str: Me.banner)
        txt_fname.text = Me.fname
        
        txt_bio.text = Me.bio
        txt_bio.textColor = UIColor.label
        txt_bio_placeholder.isHidden = !Me.bio.isEmpty
        
        txt_website.text = Me.website
    }
    
    func updateSaveButton(){
        if imgAvatar != nil || imgBanner != nil || nameChanged || websiteChanged || bioChanged{
            btn_save.setTitleColor(UIColor.active(), for: .normal)
        }
        else{
            btn_save.setTitleColor(UIColor.secondaryLabel, for: .normal)
        }
    }
    
    @IBAction func opEditBanner(_ sender: Any) {
        let picker: YPImagePicker = self.openImagePicker(size: 500)
        picker.didFinishPicking { [unowned picker] items, cancelled in
            if cancelled{
                picker.dismiss(animated: true, completion: nil)
                return
            }
            for item in items{
                switch(item){
                case .photo(p: let img):
                    self.imgBanner = img.image
                    self.img_banner.image = img.image
                    self.updateSaveButton()
                    break
                case .video(v: _):
                    break
                }
                break
            }
            picker.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func opEditAvatar(_ sender: Any) {
        let picker: YPImagePicker = self.openImagePicker(size: 500)
        picker.didFinishPicking { [unowned picker] items, cancelled in
            if cancelled{
                picker.dismiss(animated: true, completion: nil)
                return
            }
            for item in items{
                switch(item){
                case .photo(p: let img):
                    self.imgAvatar = img.image
                    self.img_avatar.image = img.image
                    self.updateSaveButton()
                    break
                case .video(v: _):
                    break
                }
                break
            }
            picker.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func opEditSong(_ sender: Any) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "VC_EditSongSlots") as! VC_EditSongSlots
        vc.modalPresentationStyle = .pageSheet
        
        self.present(vc, animated: true, completion: nil)
    }
    
    var isSaving: Bool = false
    @IBAction func opSave(_ sender: Any) {
        guard let cid = CUID else { return }
        if btn_save.titleColor(for: .normal) == UIColor.secondaryLabel{
            return
        }
        if isSaving{
            return
        }
        isSaving = true
        
        let fname = txt_fname.text!
        let bio = txt_bio.text!
        let website = txt_website.text!
        var bannerUrl = Me.banner
        var avatarUrl = Me.avatar
        var thumbUrl = Me.thumb
        
        self.setupHUD(msg: "Saving...")
        let searchGroup = DispatchGroup()
        if let bannerImg = imgBanner{
            guard let uploadData = bannerImg.jpegData(compressionQuality: 0.3) else {
                self.hideHUD()
                self.showError(msg: "Error in saving banner. Try again!")
                self.isSaving = false
                return
            }
            searchGroup.enter()
            self.uploadImage(imgData: uploadData, fname: User.key_banner) { (url) in
                bannerUrl = url
                searchGroup.leave()
            }
        }
        if let avatarImg = imgAvatar{
            guard let avatarData = avatarImg.jpegData(compressionQuality: 0.3) else {
                self.hideHUD()
                self.showError(msg: "Error in saving avatar. Try again!")
                self.isSaving = false
                return
            }
            guard let resizedData = avatarImg.resized100().jpegData(compressionQuality: 0.3) else{
                self.hideHUD()
                self.showError(msg: "Error in saving avatar. Try again!")
                self.isSaving = false
                return
            }
            searchGroup.enter()
            self.uploadImage(imgData: avatarData, fname: User.key_avatar) { (url) in
                avatarUrl = url
                searchGroup.leave()
            }
            searchGroup.enter()
            self.uploadImage(imgData: resizedData, fname: User.key_thumb) { (url) in
                thumbUrl = url
                searchGroup.leave()
            }
        }
        
        if nameChanged || bioChanged || websiteChanged{
            searchGroup.enter()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                searchGroup.leave()
            }
        }
        
        searchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            if self.imgAvatar != nil && (avatarUrl.isEmpty || thumbUrl.isEmpty){
                self.hideHUD()
                self.showError(msg: "Error in saving avatar. Try again!")
                self.isSaving = false
                return
            }
            if self.imgBanner != nil && bannerUrl.isEmpty{
                self.hideHUD()
                self.showError(msg: "Error in saving banner. Try again!")
                self.isSaving = false
                return
            }
            let dic: [String: Any] = [
                User.key_avatar: avatarUrl,
                User.key_banner: bannerUrl,
                User.key_thumb: thumbUrl,
                User.key_fname: fname,
                User.key_bio: bio,
                User.key_website: website
            ]
            FUSER_REF
                .document(cid)
                .updateData(dic) { (err) in
                    if err != nil{
                        self.hideHUD()
                        self.showError(title: "Error", msg: "Error Saving Profile Changes")
                        return
                    }
                    Me.fname = fname
                    Me.bio = bio
                    Me.website = website
                    Me.avatar = avatarUrl
                    Me.banner = bannerUrl
                    Me.thumb = thumbUrl
                    Me.saveLocal()
                    
                    if self.imgAvatar != nil{
                        Me.updateUserPostsInfo()
                    }
                    
                    self.imgAvatar = nil
                    self.imgBanner = nil
                    self.nameChanged = false
                    self.bioChanged = false
                    self.websiteChanged = false

                    self.updateSaveButton()
                    self.isSaving = false

                    self.opUpdateProfile?()
                    NotificationCenter.default.post(name: NSNotification.Name("updateAvatar"), object: nil)
                    
                    self.hideHUD()
                    self.showSuccess(title: "Success", msg: "Successfully Updated")
                    DispatchQueue.main.async {
                        self.navigationController?.popViewController(animated: true)
                    }
                }
        }
    }
    
    @IBAction func opCancel(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func uploadImage(imgData: Data, fname: String, completion: @escaping(String) -> Void){
        guard let cuid = CUID else { return }

        let storageRef = STORAGE_PROFILE_IMAGES_REF.child(cuid).child(fname)
        storageRef.putData(imgData, metadata: nil, completion: { (metadata, error) in
            if let error = error {
                print(error.localizedDescription)
                completion("")
                return
            }
            storageRef.downloadURL(completion: { (downloadURL, error) in
                if let error = error{
                    print(error.localizedDescription)
                    completion("")
                    return
                }
                guard let imgUrl = downloadURL?.absoluteString else {
                    completion("")
                    return
                }
                completion(imgUrl)
            })
        })
    }
}

extension VC_EditProfile: UITextViewDelegate {
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return true
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        self.txt_bio_placeholder.isHidden = !textView.text.isEmpty
        self.bioChanged = textView.text != Me.bio
        self.updateSaveButton()
        return true
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        self.txt_bio_placeholder.isHidden = !textView.text.isEmpty
        self.bioChanged = textView.text != Me.bio
        self.updateSaveButton()
    }
}

extension VC_EditProfile: UITextFieldDelegate{
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        switch(textField){
        case txt_fname:
            self.nameChanged = textField.text != Me.fname
            break
        case txt_website:
            self.websiteChanged = textField.text != Me.website
            break
        default:
            break
        }
        self.updateSaveButton()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        switch(textField){
        case txt_fname:
            self.nameChanged = textField.text != Me.fname
            break
        case txt_website:
            self.websiteChanged = textField.text != Me.website
            break
        default:
            break
        }
        self.updateSaveButton()
        return true
    }
}
