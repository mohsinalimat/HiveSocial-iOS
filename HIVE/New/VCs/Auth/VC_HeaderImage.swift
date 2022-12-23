//
//  VC_HeaderImage.swift
//  HIVE
//
//  Created by elitemobile on 10/15/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import UIKit
import YPImagePicker
import Firebase

class VC_HeaderImage: UIViewController {
    @IBOutlet weak var img_header: UIImageView!
    @IBOutlet weak var btn_next: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initComponents()
    }
    
    func initComponents(){
        img_header.makeRoundView(r: 5)
        btn_next.makeCircleView()
    }
    
    var imgSelected: Bool = false
    @IBAction func opAddHeaderImg(_ sender: Any) {
        let picker: YPImagePicker = self.openImagePicker(size: 500)
        
        picker.didFinishPicking { [unowned picker] items, cancelled in
            if cancelled{
                picker.dismiss(animated: true, completion: nil)
                return
            }
            for item in items{
                switch(item){
                case .photo(p: let img):
                    self.img_header.image = img.image
                    self.imgSelected = true
                    break
                case .video(v: _):
                    break
                }
                break
            }
            picker.dismiss(animated: true, completion: nil)
        }

    }
    
    @IBAction func opNext(_ sender: Any) {
        if !imgSelected{
            return
        }
        
        guard let profileImg = self.img_header.image else { return }
        guard let uploadData = profileImg.jpegData(compressionQuality: 0.3) else { return }
        guard let uid = CUID else { return }

        let filename = "banner_\(Utils.curTimeStr)"
        let storageRef = STORAGE_PROFILE_IMAGES_REF.child(uid).child(filename)
        setupHUD(msg: "Saving...")
        storageRef.putData(uploadData, metadata: nil, completion: { (metadata, error) in
            
            // handle error
            if let error = error {
                self.hideHUD()
                
                self.showError(title: "Uploading Error", msg: error.localizedDescription)
                print("Failed to upload image to Firebase Storage with error", error.localizedDescription)
                return
            }
            
            // retrieve download url
            storageRef.downloadURL(completion: { (downloadURL, error) in
                self.hideHUD()
                if let err = error{
                    self.showError(title: "Uploading Error", msg: err.localizedDescription)
                    return
                }
                guard let profileImageUrl = downloadURL?.absoluteString else {
                    self.showError(title: "Uploading Error", msg: "Try again later")
                    print("DEBUG: Profile image url is nil")
                    return
                }
                
                Me.banner = profileImageUrl
                
                let dic: [String: Any] = [
                    User.key_fname: Me.fname,
                    User.key_uname: Me.uname.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).filter{!" \n\t\r".contains($0)},
                    User.key_email: Me.email,
                    User.key_banner: Me.banner,
                    User.key_u_created: Utils.curTime
                ]
                
                // save user info to database
                self.setupHUD(msg: "Saving...")
                FUSER_REF
                    .document(uid)
                    .updateData(dic) { (err) in
                        self.hideHUD()
                        if let error = err{
                            print(error.localizedDescription)
                            return
                        }
                        
                        let sb = UIStoryboard(name: "Auth", bundle: nil)
                        let vc = sb.instantiateViewController(withIdentifier: "VC_SetupCategories") as! VC_SetupCategories
                        
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
            })
        })
    }
    
    @IBAction func opSkip(_ sender: Any) {
        let sb = UIStoryboard(name: "Auth", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "VC_SetupCategories") as! VC_SetupCategories
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
