//
//  VC_Search_Browse.swift
//  HIVE
//
//  Created by elitemobile on 12/14/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import UIKit
import Firebase
import CollectionKit

class VC_SetupCategories: UIViewController{
    @IBOutlet weak var collectionView: CollectionView!
    @IBOutlet weak var btn_finish: UIButton!
    @IBOutlet weak var btn_skip: UIButton!
    
    let dataManager: TagPostsManager = TagPostsManager.shared
    var userCate: [Int] = [0, 1, 2]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initComponents()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.collectionView.reloadData()
    }
    
    func initComponents(){
        addSwipeRight()
        
        btn_finish.makeCircleView()
        
        initData()
    }
    
    func initData(){
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.clipsToBounds = true
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 150, right: 0)
        collectionView.removeGestureRecognizer(collectionView.tapGestureRecognizer)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false

        collectionView.provider = BasicProvider(
            dataSource: categories,
            viewSource: ClosureViewSource(viewGenerator: { (_, index: Int) -> cell_category_item in
                let v = Bundle.main.loadNibNamed("cell_category_item", owner: self, options: nil)?[0] as! cell_category_item
                return v
            }, viewUpdater: { (v: cell_category_item, item: [Any], index: Int) in
                v.lbl_title.text = item[0] as? String
                v.img_category.image = UIImage(named: item[1] as! String)!
                
                if self.userCate.contains(index){
                    v.v_out.layer.borderWidth = 2
                }
                else{
                    v.v_out.layer.borderWidth = 0
                }
                
                v.opSelectAction = {
                    selectedCategoryIndex = index
                    if self.userCate.contains(index){
                        self.userCate.remove(at: self.userCate.firstIndex(of: index)!)
                        v.v_out.layer.borderWidth = 0
                    }
                    else{
                        self.userCate.append(index)
                        v.v_out.layer.borderWidth = 2
                    }
                }
            }),
            sizeSource: { (index: Int, _, size: CGSize) -> CGSize in
                let width = (self.collectionView.bounds.width - 20) / 3
                let height = width * 4 / 5
                let size:CGSize = CGSize(width: width, height: height)
                
                return size
            },
            layout: FlowLayout(spacing: 10)
        )
    }
    
    @IBAction func opDone(_ sender: Any) {
        guard let uid = CUID else { return }
        
        Me.following_cate = userCate
        
        // save user info to database
        setupHUD(msg: "Saving...")
        FUSER_REF
            .document(uid)
            .updateData([
                User.key_following_categories: userCate,
                User.key_u_created: Utils.curTime
            ]) { (err) in
                self.hideHUD()
                if let error = err{
                    Utils.logError(desc: "Save Categories", err: error)
                    return
                }
                
                let sb = UIStoryboard(name: "Main", bundle: nil)
                let nav_home = sb.instantiateViewController(withIdentifier: "nav_home") as! UINavigationController
                nav_home.modalPresentationStyle = .overFullScreen

                self.present(nav_home, animated: true, completion: nil)
            }
    }
    
    @IBAction func opSkip(_ sender: Any) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let nav_home = sb.instantiateViewController(withIdentifier: "nav_home") as! UINavigationController
        nav_home.modalPresentationStyle = .overFullScreen
        
        self.present(nav_home, animated: true, completion: nil)
    }
}
