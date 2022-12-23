//
//  VC_Profile_State.swift
//  HIVE
//
//  Created by elitemobile on 12/11/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import UIKit
import XLPagerTabStrip
import CollectionKit

class VC_Profile_State: UIViewController{
    var itemInfo = IndicatorInfo(title: "", image: UIImage(named: "nic_profile_status")!.withRenderingMode(.alwaysTemplate))

    @IBOutlet weak var v_posts: CollectionView!
    var parentOffsetY: CGFloat = 0
    var isLoadingMore: Bool = false
    var noMoreData: Bool = false
    var parentDelegate: UIScrollViewDelegate?

    var manager: UserPostsManager!{
        didSet{
            manager.delegateState = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initComponents()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.v_posts.reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        postsDataSource.data.forEach { (pst) in
//            if pst.ouid == Me.uid{
//                pst.oavatar = Me.thumb.isEmpty ? Me.avatar : Me.thumb
//                pst.ouname = Me.uname
//            }
//        }
//        self.v_posts.reloadData()
    }

    var postsDataSource: ArrayDataSource<Post>! = ArrayDataSource<Post>()
    func initComponents(){
        v_posts.contentInsetAdjustmentBehavior = .never
        v_posts.clipsToBounds = true
        v_posts.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        v_posts.removeGestureRecognizer(v_posts.tapGestureRecognizer)
        v_posts.showsVerticalScrollIndicator = false
        v_posts.showsHorizontalScrollIndicator = false

        if self.manager != nil{
            postsDataSource.data = self.manager.userPostsStatus
        }

        v_posts.provider = BasicProvider(
            dataSource: postsDataSource,
            viewSource: ClosureViewSource(viewGenerator: { (_, index: Int) -> cell_media_table in
                let v = Bundle.main.loadNibNamed("cell_media_table", owner: self, options: nil)?[0] as! cell_media_table
                return v
            }, viewUpdater: { (v: cell_media_table, pst: Post, index: Int) in
                v.setPost(post: pst)
                self.setupPost(v: v, post: pst)
            }),
            sizeSource: { (index: Int, pst: Post, size: CGSize) -> CGSize in
                return CGSize(width: size.width, height: Utils.getCellHeight(post: pst))
            }
        )
        
        v_posts.delegate = self//.parentDelegate
//        v_posts.isScrollEnabled = false
//        v_posts.bounces = true
    }
}

extension VC_Profile_State: UserPostsManagerDelegate{
    func postsUpdated() {
        if self.isLoadingMore{
            self.isLoadingMore = false
        }
        
        DispatchQueue.main.async {
            self.postsDataSource.data = self.manager.userPostsStatus
        }
    }
    
    func postsLoadedMore(posts: [Post]) {
        if self.isLoadingMore{
            self.isLoadingMore = false
        }

        DispatchQueue.main.async {
            print("loaded more - \(posts.count)")
            
            if posts.count > 0{
                self.postsDataSource.data.append(contentsOf: posts)
            }
            else{
                self.noMoreData = true
            }
        }
    }
}

extension VC_Profile_State: IndicatorInfoProvider{
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return itemInfo
    }
}

extension VC_Profile_State: UIScrollViewDelegate{
    func scrollViewDidScroll(_ scrollView: UIScrollView){
//        if scrollView.contentOffset.y <= 0{
//            scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
//        }

        if self.noMoreData{
            return
        }
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height

        if maximumOffset - currentOffset <= 1000{
            if self.postsDataSource.data.count == 0 {
                return
            }
            if self.isLoadingMore{
                return
            }

            self.isLoadingMore = true

            if self.manager != nil{
                self.manager.loadMoreStatusPosts()
            }
            else{
                self.isLoadingMore = false
            }
        }
    }
}

