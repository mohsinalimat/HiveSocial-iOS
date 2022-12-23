//
//  NotificationsVC.swift
//  HIVEcopy
//
//  Created by Kassy Pop on 7/25/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import UIKit
import Firebase
import CollectionKit
import GradientLoadingBar

class VC_Alerts: UIViewController{
    @IBOutlet weak var v_noti: CollectionView!
    @IBOutlet weak var gradientBar: GradientActivityIndicatorView!

    // MARK: - Properties
    var timer: Timer?
    var notifications: [String: Noti] = [:]
    var refresher = UIRefreshControl()
    
    //notificationsListener
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initComponents()
        fetchNotifications()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            FNOTIFICATIONS_REF
                .document(Me.uid)
                .setData([
                    Noti.key_unread_count: 0
                ], merge: true)
            
            NotificationCenter.default.post(name: NSNotification.Name("hideNotificationBadge"), object: nil, userInfo: nil)
        }
    }
    
    deinit {
        notificationsListener?.remove()
        notificationsListener = nil
    }
    
    var notiDataSource: ArrayDataSource<Noti>! = ArrayDataSource<Noti>()
    func initComponents(){
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

        v_noti.contentInsetAdjustmentBehavior = .never
        v_noti.clipsToBounds = true
        v_noti.contentInset = UIEdgeInsets(top: 200, left: 0, bottom: 1000, right: 0)
        v_noti.removeGestureRecognizer(v_noti.tapGestureRecognizer)
        v_noti.showsVerticalScrollIndicator = false
        v_noti.showsHorizontalScrollIndicator = false
        
        v_noti.delegate = self
        
        let sections: [Provider] = [
            BasicProvider(
                dataSource: [1],
                viewSource: ClosureViewSource(viewGenerator: { (_, index: Int) -> cell_noti_header in
                    let v = Bundle.main.loadNibNamed("cell_noti_header", owner: self, options: nil)?[0] as! cell_noti_header
                    return v
                }, viewUpdater: { (v: cell_noti_header, _, index: Int) in
                    v.refreshNotificationsCount()
                }),
                sizeSource: { (index: Int, _, size: CGSize) -> CGSize in
                    return CGSize(width: size.width, height: 100) }
            ),
            BasicProvider(
                dataSource: notiDataSource,
                viewSource: ClosureViewSource(viewGenerator: { (noti: Noti, index: Int) -> UIView in
                    return UIView()
                }, viewUpdater: { (v: UIView, noti: Noti, index: Int) in
                    switch(noti.type){
                    case .Follow:
                        let v_item = Bundle.main.loadNibNamed("cell_noti_follow", owner: self, options: nil)?[0] as! cell_noti_follow
                        v_item.setNoti(noti: noti)
                        
                        v_item.opOpenUserAction = { (usr) in
                            self.openUser(usr: usr)
                        }
                        
                        v.addContentView(v: v_item)
                        break
                    case .Lock:
                        let v_item = Bundle.main.loadNibNamed("cell_notification_lock", owner: self, options: nil)?[0] as! cell_notification_lock
                        v_item.setNoti(noti: noti)
                        
                        v_item.opOpenUserAction = { (usr) in
                            self.openUser(usr: usr)
                        }
                        
                        v.addContentView(v: v_item)
                        break
                    case .ChatMessage:
                        let v_item = Bundle.main.loadNibNamed("cell_noti_post", owner: self, options: nil)?[0] as! cell_noti_post
                        v_item.setNoti(noti: noti)
                        v_item.opOpenUserAction = { (usr) in
                            self.openUser(usr: usr)
                        }
                        v_item.opOpenPostAction = { (pst) in
                            self.openPost(post: pst)
                        }
                        
                        v.addContentView(v: v_item)
                        break
                    default:
                        //.Like, .PostMention, .Comment, .CommentMention:
                        let v_item = Bundle.main.loadNibNamed("cell_noti_post", owner: self, options: nil)?[0] as! cell_noti_post
                        v_item.setNoti(noti: noti)
                        v_item.opOpenUserAction = { (usr) in
                            self.openUser(usr: usr)
                        }
                        v_item.opOpenPostAction = { (pst) in
                            self.openPost(post: pst)
                        }
                        
                        v.addContentView(v: v_item)
                        break
                    }
                }),
                sizeSource: { (index: Int, _, size: CGSize) -> CGSize in
                    return CGSize(width: size.width, height: 72) }
            )
            
        ]
        v_noti.provider = ComposedProvider(sections: sections)
        
        NotificationCenter.default.addObserver(self, selector: #selector(logoutAlert), name: NSNotification.Name(rawValue: "logoutAlert"), object: nil)
    }
    
    @objc func logoutAlert(){
        notificationsListener?.remove()
        notificationsListener = nil
    }

    var isLoadingMore: Bool = false
    var firstLoading: Bool = true
    var notificationsListener: ListenerRegistration? = nil
    func fetchNotifications() {
        guard let cuid = CUID else { return }
        notificationsListener = FNOTIFICATIONS_REF
            .document(cuid)
            .collection(Noti.key_collection_notifications)
            .order(by: Noti.key_created, descending: true)
            .limit(to: LoadStepCount)
            .addSnapshotListener({ (doc, err) in
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    DispatchQueue.main.async {
                        if !self.gradientBar.isHidden{
                            self.gradientBar.fadeOut()
                        }
                    }
                }
                
                if let error = err{
                    print("\(error.localizedDescription)")
                    return
                }

                doc?.documentChanges.forEach({ (item) in
                    let noti = Noti(id: item.document.documentID, dic: item.document.data())
                    let key = "\(noti.created)"
                    switch(item.type){
                        case .added:
                            self.notifications[key] = noti
                            break
                        case .modified:
                            self.notifications[key] = noti
                            break
                        case .removed:
                            if self.notifications.keys.contains(key){
                                self.notifications.removeValue(forKey: key)
                            }
                            break
                    }
                })
                
                self.notiDataSource.data = self.notifications.values.sorted(by: { (item1, item2) -> Bool in
                    return item1.created > item2.created
                })
                                
                self.firstLoading = false
            })
    }
    
    var lastKey: Double = 0
    func loadMoreData(){
        guard let cuid = CUID else {
            self.isLoadingMore = false
            return }
        guard let last = self.notiDataSource.data.last else {
            self.isLoadingMore = false
            return
        }
        
        if lastKey == last.created{
            self.isLoadingMore = false
            return
        }
        
        lastKey = last.created
        print("lastKey: \(lastKey)")
        FNOTIFICATIONS_REF
            .document(cuid)
            .collection(Noti.key_collection_notifications)
            .order(by: Noti.key_created, descending: true)
            .whereField(Noti.key_created, isLessThan: lastKey)
            .limit(to: 20)
            .getDocuments { (doc, err) in
                self.isLoadingMore = false

                if let error = err{
                    print("\(error.localizedDescription)")
                    return
                }
                doc?.documents.forEach({ (item) in
                    let noti = Noti(id: item.documentID, dic: item.data())
                    let key = "\(noti.created)"
                    self.notifications[key] = noti
                })
                
                self.notiDataSource.data = self.notifications.values.sorted(by: { (item1, item2) -> Bool in
                    return item1.created > item2.created
                })
            }
    }
}
extension VC_Alerts: UIScrollViewDelegate{
    func scrollViewDidScroll(_ scrollView: UIScrollView){
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height

        if maximumOffset - currentOffset <= 1000{
            if !self.isLoadingMore{
                self.isLoadingMore = true
                self.loadMoreData()
            }
        }
    }
}
