//
//  VC_Blocked.swift
//  HIVE
//
//  Created by elitemobile on 1/26/21.
//  Copyright © 2021 Kassy Pop. All rights reserved.
//

import UIKit
import Foundation
import Firebase
import CollectionKit

class VC_Blocked: UIViewController {
    @IBOutlet weak var lbl_title: UILabel!
    @IBOutlet weak var collectionView: CollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initComponents()
    }
    
    var usersDataSource: ArrayDataSource<User>! = ArrayDataSource<User>()
    func initComponents(){
        addSwipeRight()
        
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.clipsToBounds = true
        collectionView.contentInset = UIEdgeInsets(top: -1, left: 0, bottom: 0, right: 0)
        collectionView.removeGestureRecognizer(collectionView.tapGestureRecognizer)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        
        collectionView.provider = BasicProvider(
            dataSource: usersDataSource,
            viewSource: ClosureViewSource(viewGenerator: { (usr: User, index: Int) -> cell_blocked in
                let v = Bundle.main.loadNibNamed("cell_blocked", owner: self, options: nil)?[0] as! cell_blocked
                return v
            }, viewUpdater: { (v: cell_blocked, usr: User, index: Int) in
                v.setUser(usr: usr)
                v.opOpenAction = {
                    self.openUser(usr: usr)
                }
            }),
            sizeSource: { (index: Int, usr: User, size: CGSize) -> CGSize in
                return CGSize(width: size.width, height: 70)
            }
        )
        
        loadData()
    }

    func loadData(){
        MyBlocks.keys.forEach { (uid) in
            Utils.fetchUser(uid: uid) { (rusr) in
                guard let usr = rusr else { return }
                
                self.usersDataSource.data.append(usr)
            }
        }
    }
    
    @IBAction func opBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}
