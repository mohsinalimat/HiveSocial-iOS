//
//  NewsFeedContainerViewController.swift
//  HIVE
//
//  Created by Daniel Pratt on 9/17/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import UIKit
import Firebase
import XLPagerTabStrip
import CollectionKit
import GradientLoadingBar
import ESPullToRefresh

public var buttonBarColor: UIColor = {
    if #available(iOS 13.0, *){
        return UIColor{ (UITraitCollection: UITraitCollection) -> UIColor in
            if UITraitCollection.userInterfaceStyle == .dark{
                return UIColor.black
            }
            else{
                return UIColor.white
            }
        }
    }
    else{
        return UIColor.white
    }
}()

class VC_Home: UIViewController {
    @IBOutlet weak var v_feed: CollectionView!
    @IBOutlet weak var v_newPostsOut: UIView!
    @IBOutlet weak var v_newPosts: UIView!
    @IBOutlet weak var gradientBar: GradientActivityIndicatorView!
    var isLoadingMore: Bool = false
    var isReloading: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.selectedIndex = 4

        initComponents()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        self.v_feed.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.v_feed.reloadData()
    }

    var first: Bool = true
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if first{
            return
        }
        DispatchQueue.main.async {
            self.checkNewPosts()
        }
    }
    
    func checkNewPosts(){
        if self.v_newPostsOut.isHidden == false{
            return
        }
        guard let cid = CUID else { return }
        if self.isReloading || self.isLoadingMore { return }
        
        FUSER_REF
            .document(cid)
            .collection(User.key_collection_feed)
            .whereField(Post.key_created, isLessThan: Utils.curTime)
            .order(by: Post.key_created, descending: true)
            .limit(to: 1)
            .getDocuments { (doc, _) in
                doc?.documents.forEach({ (item) in
                    print("new posts!!!")
                    print(item.documentID)
                    if FeedPostsManager.shared.myFeedPosts.count == 0{
                        self.v_newPostsOut.isHidden = true
                        self.isReloading = true

                        FeedPostsManager.shared.loadUserFeed()
                    }
                    else if !FeedPostsManager.shared.postIds.contains(item.documentID){
                        self.v_newPostsOut.isHidden = false
                    }
                    return
                })
            }
    }
    
    var notificationsListener: ListenerRegistration? = nil
    var blockedListener: ListenerRegistration? = nil
    deinit {
        logoutHome()
    }
    
    func initComponents(){
        checkVersion()
//        checkBlocked()
        observeNotifications()
        gradientBar.progressAnimationDuration = 6
        gradientBar.gradientColors = [
            UIColor(named: "ncol_gradient_0")!,
            UIColor(named: "ncol_gradient_1")!,
            UIColor(named: "ncol_gradient_2")!,
            UIColor(named: "ncol_gradient_3")!,
            UIColor(named: "ncol_gradient_4")!,
            UIColor(named: "ncol_gradient_5")!,
        ]
        gradientBar.fadeIn()
        
        initFeed()
//        DB_Management.updateHashTagCount()
//        DB_Management.convertOldChatToNew()
//        DB_Management.updatePostIds()
//        DB_Management.updateFollowers()
//        DB_Management.updatePostIds()
//        DB_Management.deleteOldPostIds()
        
        NotificationCenter.default.addObserver(self, selector: #selector(logoutHome), name: NSNotification.Name(rawValue: "logoutHome"), object: nil)
    }
    
    @objc func logoutHome(){
        notificationsListener?.remove()
        notificationsListener = nil
        
        blockedListener?.remove()
        blockedListener = nil
    }
    
    @objc func deleteCompletion(){
        DispatchQueue.main.async {
            self.v_feed.reloadData()
        }
    }
    
    var postsDataSource: ArrayDataSource<Post>! = ArrayDataSource<Post>()
    func initFeed(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            DispatchQueue.main.async {
                if !self.gradientBar.isHidden{
                    self.gradientBar.fadeOut()
                }
                self.first = false
            }
        }

        v_newPosts.makeRoundView(r: 5)
        v_newPostsOut.addShadow()
        v_newPostsOut.isHidden = true
        
        v_feed.contentInsetAdjustmentBehavior = .never
        v_feed.clipsToBounds = true
        v_feed.contentInset = UIEdgeInsets(top: 200, left: 0, bottom: 1000, right: 0)
        v_feed.removeGestureRecognizer(v_feed.tapGestureRecognizer)
        v_feed.showsVerticalScrollIndicator = false
        v_feed.showsHorizontalScrollIndicator = false
        v_feed.delegate = self
        
        v_feed.provider = BasicProvider(
            dataSource: postsDataSource,
            viewSource: ClosureViewSource(viewGenerator: { (post: Post, index: Int) -> cell_media_table in
                let v = Bundle.main.loadNibNamed("cell_media_table", owner: self, options: nil)?[0] as! cell_media_table
                return v
            }, viewUpdater: { (v: cell_media_table, post: Post, index: Int) in
                v.setPost(post: post)
                self.setupPost(v: v, post: post)
            }),
            sizeSource: { (index: Int, post: Post, size: CGSize) -> CGSize in
                return CGSize(width: UIScreen.main.bounds.width - 8, height: Utils.getCellHeight(post: post))
            }
        )
        
        v_feed.es.addPullToRefresh {
            print("Reload")
            if self.isLoadingMore{
                print("is in loading more already")
                return
            }
            if self.isReloading{
                print("is in reloading already")
                return
            }
            print("reloading started")
            self.isReloading = true
            self.postsDataSource.data.removeAll()
            FeedPostsManager.shared.loadUserFeed()
            self.v_newPostsOut.isHidden = true
        }

        self.isReloading = true
        FeedPostsManager.shared.loadUserFeed()
        FeedPostsManager.shared.delegate = self
        self.v_newPostsOut.isHidden = true
    }
    
    @IBAction func opTakeCamera(_ sender: Any) {
    }
    
    @IBAction func opSendMessage(_ sender: Any) {
        self.openChat()
    }
    
    @IBAction func opNewPost(_ sender: Any) {
        v_newPostsOut.isHidden = true
        self.isReloading = true

        self.postsDataSource.data.removeAll()
        FeedPostsManager.shared.loadUserFeed()
    }
    
    func observeNotifications() {
        guard let uid = CUID else { return }
        notificationsListener = FNOTIFICATIONS_REF
            .document(uid)
            .addSnapshotListener { (doc, err) in
                if let error = err{
                    print(error.localizedDescription)
                    return
                }
                
                if let data = doc?.data(), let count = data[Noti.key_unread_count] as? Int{
                    if count > 0{
                        NotificationCenter.default.post(name: NSNotification.Name("showNotificationBadge"), object: nil, userInfo: nil)
                    }
                    else{
                        NotificationCenter.default.post(name: NSNotification.Name("hideNotificationBadge"), object: nil, userInfo: nil)
                    }
                }
                else{
                    NotificationCenter.default.post(name: NSNotification.Name("hideNotificationBadge"), object: nil, userInfo: nil)
                }
            }
    }
}

extension VC_Home: FeedPostsDelegate {
    func postsUpdated() {
        if self.isReloading{
            print("reloading finished")
            self.isReloading = false
            DispatchQueue.main.async{
                self.v_feed.es.stopPullToRefresh()
            }
        }
        if self.isLoadingMore{
            print("loading more finished")
            self.isLoadingMore = false
        }

        DispatchQueue.main.async{
            self.postsDataSource.data = FeedPostsManager.shared.myFeedPosts.values.sorted(by: { (item1, item2) -> Bool in
                item1.created > item2.created
            })
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            DispatchQueue.main.async {
                if !self.gradientBar.isHidden{
                    self.gradientBar.fadeOut()
                }
            }
        }
    }
}

extension VC_Home: UIScrollViewDelegate{
    func scrollViewDidScroll(_ scrollView: UIScrollView){
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        let diff = maximumOffset - currentOffset
        if diff <= 300{
            if self.postsDataSource.data.count == 0{
                return
            }
            if self.isReloading{
                return
            }
            if self.isLoadingMore{
                return
            }
            DispatchQueue.main.async {
                self.isLoadingMore = true
                FeedPostsManager.shared.loadMoreUserFeed()
            }
        }
    }
}

//Check App Version & DO Logout!
extension VC_Home{
    func checkVersion(){
        FVERSION_REF
            .document("version")
            .getDocument { (val, err) in
                if let error = err{
                    print(error.localizedDescription)
                    return
                }

                if let data = val?.data(), let version = data["version"] as? Double{
                    guard let localVersionStr = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, let localAppVersion = Double(localVersionStr), localAppVersion > 0 else { return }
                    
                    print("app store version - \(version)")
                    print("local app version - \(localAppVersion)")
                    
                    if version > localAppVersion{
//                        self.logout()
                        self.showError(title: "Please update your Hive Social App", msg: "You are using an older version of Hive. To take advantage of the latest updates and bug fixes you will need to update your Hive App!")
                        return
                    }
                }
            }
    }
    
    func logout() {
        do {
            FeedPostsManager.shared.logout()
            FeaturedPostsManager.shared.logout()
            SearchManager.shared.logout()
            TagPostsManager.shared.logout()
            ChatManager.shared.logout()
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "logoutProfile"), object: nil)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "logoutHome"), object: nil)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "logoutAlert"), object: nil)

            try Auth.auth().signOut()
                
            Me = User()
            Me.saveLocal()
        } catch let error {
            print("~>There was an error logging out: \(error)")
            return
        }
        
        checkIfUserIsLoggedIn()
    }

    func checkIfUserIsLoggedIn() {
        if Auth.auth().currentUser == nil {
            DispatchQueue.main.async {
                let sb = UIStoryboard(name: "Auth", bundle: nil)
                let nav_auth = sb.instantiateViewController(withIdentifier: "nav_auth") as! UINavigationController
                
                nav_auth.modalPresentationStyle = .overFullScreen
                self.present(nav_auth, animated: true) {
                }
            }
            return
        }
    }
}

//Check Blocked Status from Admin
extension VC_Home{
    func checkBlocked(){
        if blockedListener != nil{
            blockedListener?.remove()
            blockedListener = nil
        }
        
        blockedListener = FBLOCKED_REF
            .document(Me.uid)
            .addSnapshotListener({ (val, err) in
                if let error = err{
                    print(error.localizedDescription)
                    return
                }

                if let data = val?.data(), let blocked = data["blocked"] as? Bool, blocked{
                    print("You are blocked from Admin")
                    Me.blocked = true

                    FUSER_REF
                        .document(Me.uid)
                        .collection(User.key_collection_posts)
                        .getDocuments { (doc, err) in
                            let taskGroup = DispatchGroup()

                            doc?.documents.forEach({ (docItem) in
                                taskGroup.enter()
                                Utils.fetchPost(pid: docItem.documentID) { (rpst) in
                                    guard let pst = rpst else {
                                        taskGroup.leave()
                                        return }
                                    pst.deletePost()

                                    taskGroup.leave()
                                }
                            })

                            taskGroup.notify(queue: .main) { [weak self] in
                                guard let self = self else { return }

                                DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                                    self.logout()
                                    self.showError(title: "You have been blocked from using Hive", msg: "We have found your account to be in violation of our Terms & Conditions.  At this moment, access to your account has been blocked.  If you wish to appeal this matter please email us at appeals@hivesocial.app with your username.")
                                }
                            }
                        }
                }
                else{
                    print("You are not blocked! Yeah!!! Everything is on the way! :)")
                }
            })
    }
}
