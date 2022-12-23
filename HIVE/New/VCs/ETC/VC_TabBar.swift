//
//  VC_TabBar.swift
//  HIVE
//
//  Created by elitemobile on 11/11/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import UIKit
import Firebase

class VC_TabBar: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initComponents()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    func initComponents(){
        UITabBar.appearance().layer.borderWidth = 0
        
        let cv = Bundle.main.loadNibNamed("cv_tabbar", owner: self, options: nil)?[0] as! cv_tabbar
        cv.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: self.tabBar.frame.height)
        cv.opSelectAction1 = {
            if self.selectedIndex != 0{
                self.selectedIndex = 0
            }
            else{
                if let nav: UINavigationController = self.selectedViewController as? UINavigationController{
                    nav.popToRootViewController(animated: true)
                }
            }
        }
        cv.opSelectAction2 = {
            if self.selectedIndex != 1{
                self.selectedIndex = 1
            }
            else{
                if let nav: UINavigationController = self.selectedViewController as? UINavigationController{
                    nav.popToRootViewController(animated: true)
                }
            }
        }
        cv.opSelectAction3 = {
            guard let cid = CUID else { return }
            if Me.uid != cid{
                self.showError(msg: "Please signin again.")
                return
            }
            if Me.uname.isEmpty{
                self.showError(msg: "Please add an username.")
                return
            }
            if Me.avatar.isEmpty{
                self.showError(msg: "Please add an avatar.")
                return
            }

            let sb = UIStoryboard(name: "Main", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "VC_Post") as! VC_Post

            let nav: UINavigationController = UINavigationController(rootViewController: vc)
            nav.isNavigationBarHidden = true
            nav.modalPresentationStyle = .overFullScreen
            nav.modalTransitionStyle = .coverVertical
            self.present(nav, animated: true, completion: nil)
        }
        cv.opSelectAction4 = {
            if self.selectedIndex != 3{
                self.selectedIndex = 3
            }
            else{
                if let nav: UINavigationController = self.selectedViewController as? UINavigationController{
                    nav.popToRootViewController(animated: true)
                }
            }
        }
        cv.opSelectAction5 = {
            if self.selectedIndex != 4{
                self.selectedIndex = 4
            }
            else{
                if let nav: UINavigationController = self.selectedViewController as? UINavigationController{
                    nav.popToRootViewController(animated: true)
                }
            }
        }

        self.tabBar.addSubview(cv)
    }
}
