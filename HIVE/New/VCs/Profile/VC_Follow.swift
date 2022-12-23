//
//  FollowLikeVC.swift
//  HIVEcopy
//
//  Created by Kassy Pop on 7/31/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import Foundation
import Firebase
import CollectionKit

class VC_Follow: UIViewController {
    @IBOutlet weak var lbl_title: UILabel!
    @IBOutlet weak var collectionView: CollectionView!
    
    var isLoadingMore: Bool = false
    var ltitle: String = ""
    var user: User!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initComponents()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.collectionView.reloadData()
    }
    
    func initComponents(){
        addSwipeRight()
        
        loadUsers()
    }
    
    var usersDataSource: ArrayDataSource<User>! = ArrayDataSource<User>()
    func loadUsers(){
        lbl_title.text = ltitle
        
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.clipsToBounds = true
        collectionView.contentInset = UIEdgeInsets(top: 200, left: 0, bottom: 1000, right: 0)
        collectionView.removeGestureRecognizer(collectionView.tapGestureRecognizer)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.provider = BasicProvider(
            dataSource: usersDataSource,
            viewSource: ClosureViewSource(viewGenerator: { (usr: User, index: Int) -> cell_follow in
                let v = Bundle.main.loadNibNamed("cell_follow", owner: self, options: nil)?[0] as! cell_follow
                return v
            }, viewUpdater: { (v: cell_follow, usr: User, index: Int) in
                v.setUser(usr: usr)
                v.opOpenAction = {
                    self.openUser(usr: usr)
                }
            }),
            sizeSource: { (index: Int, usr: User, size: CGSize) -> CGSize in
                return CGSize(width: size.width, height: 60)
            }
        )
        
        collectionView.es.addPullToRefresh {
            self.collectionView.reloadData()
            DispatchQueue.main.async {
                self.collectionView.es.stopPullToRefresh()
            }
        }
        
        loadData()
    }
    
    var lastUserDoc: QueryDocumentSnapshot? = nil
    var lastUsedUserDoc: QueryDocumentSnapshot? = nil
    
    func loadData(){
        self.lastUserDoc = nil
        self.lastUsedUserDoc = nil
        
        FUSER_REF
            .document(user.uid)
            .collection(ltitle == "Following" ? User.key_collection_following : User.key_collection_followers)
            .order(by: User.key_created, descending: true)
            .limit(to: LoadStepCount)
            .getDocuments { [unowned self] (doc, err) in
                if let error = err{
                    print(error.localizedDescription)
                    return
                }
                
                self.lastUserDoc = doc?.documents.last
                
                var users: [User] = []
                let taskGroup = DispatchGroup()
                doc?.documents.forEach({ (item) in
                    if self.user.uid == Me.uid{
                        if ltitle == "Following"{
                            MyFollowings[item.documentID] = FollowStatus(time: Utils.curTime, followType: .Following)
                        }
                        else{
                            MyFollowers[item.documentID] = true
                        }
                    }
                    
                    taskGroup.enter()
                    Utils.fetchUser(uid: item.documentID) { (rusr) in
                        guard let usr = rusr else {
                            taskGroup.leave()
                            return }
                        users.append(usr)
                        taskGroup.leave()
                    }
                })
                
                taskGroup.notify(queue: .main) {
                    self.usersDataSource.data = users
                }
            }
    }
    
    func loadMoreData(){
        DispatchQueue.global(qos: .background).async {
            if self.lastUserDoc == nil || (self.lastUserDoc?.documentID == self.lastUsedUserDoc?.documentID && self.lastUsedUserDoc != nil){
                self.isLoadingMore = false
                return
            }
            
            self.lastUsedUserDoc = self.lastUserDoc
            
            FUSER_REF
                .document(self.user.uid)
                .collection(self.ltitle == "Following" ? User.key_collection_following : User.key_collection_followers)
                .order(by: User.key_created, descending: true)
                .start(afterDocument: self.lastUserDoc!)
                .limit(to: LoadStepCount)
                .getDocuments { [unowned self](doc, err) in
                    if let error = err{
                        print(error.localizedDescription)
                        self.isLoadingMore = false
                        return
                    }
                    
                    self.lastUserDoc = doc?.documents.last
                    var users: [User] = []
                    let taskGroup = DispatchGroup()
                    doc?.documents.forEach({ (item) in
                        if self.user.uid == Me.uid{
                            if ltitle == "Following"{
                                MyFollowings[item.documentID] = FollowStatus(time: Utils.curTime, followType: .Following)
                            }
                            else{
                                MyFollowers[item.documentID] = true
                            }
                        }
                        
                        taskGroup.enter()
                        Utils.fetchUser(uid: item.documentID) { (rusr) in
                            guard let usr = rusr else {
                                taskGroup.leave()
                                return }
                            users.append(usr)
                            taskGroup.leave()
                        }
                    })
                    DispatchQueue.main.async {
                        if doc?.documents.count ?? 0 == 0{
                            self.collectionView.es.noticeNoMoreData()
                        }
                    }
                    taskGroup.notify(queue: .main) {
                        if users.count > 0{
                            self.usersDataSource.data.append(contentsOf: users)
                        }
                        self.isLoadingMore = false
                    }
                }
        }
    }
    
    @IBAction func opBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}

extension VC_Follow: UIScrollViewDelegate{
    func scrollViewDidScroll(_ scrollView: UIScrollView){
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        let diff = maximumOffset - currentOffset
        if diff <= 1000{
            if self.usersDataSource.data.count == 0{
                return
            }
            
            if self.isLoadingMore{
                return
            }
            self.isLoadingMore = true
            self.loadMoreData()
        }
    }
}
