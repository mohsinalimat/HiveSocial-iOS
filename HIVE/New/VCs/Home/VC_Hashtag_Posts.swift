//
//  VC_Hashtag_Posts.swift
//  HIVE
//
//  Created by elitemobile on 1/29/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import UIKit
import Firebase
import XLPagerTabStrip
import CollectionKit

class VC_Hashtag_Posts: UIViewController {
    var itemInfo = IndicatorInfo(title: "", image: UIImage(named: "nic_profile_status")!.withRenderingMode(.alwaysTemplate))
    
    @IBOutlet weak var collectionView: CollectionView!
    
    var manager: TagPostsManager!{
        didSet{
            manager.delegateTagPosts = self
        }
    }
    
    var dataSource: ArrayDataSource<Post>! = ArrayDataSource<Post>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initComponents()
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        self.collectionView.reloadData()
    }

    var isLoadingMore: Bool = false
    
    func initComponents(){
        if manager != nil{
            dataSource.data = manager.tagPostsState
        }
        else{
            dataSource.data = LikedPostsManager.shared.likedPostsStatus
            
            LikedPostsManager.shared.myLikedPostsDelegateStatus = self
        }
        
        collectionView.clipsToBounds = true
        collectionView.contentInset = UIEdgeInsets(top: 200, left: 0, bottom: 1000, right: 0)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.removeGestureRecognizer(collectionView.tapGestureRecognizer)
        
        collectionView.provider = BasicProvider(
            dataSource: dataSource,
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
    }
}

extension VC_Hashtag_Posts: TagPostsManagerDelegate{
    func postsUpdated() {
        if self.isLoadingMore{
            self.isLoadingMore = false
        }
        
        DispatchQueue.main.async {
            self.dataSource.data = self.manager.tagPostsState
        }
    }
    
    func postsLoadedMore(posts: [Post]) {
        if self.isLoadingMore{
            self.isLoadingMore = false
        }

        DispatchQueue.main.async {
            if posts.count > 0{
                self.dataSource.data.append(contentsOf: posts)
            }
        }
    }
}

extension VC_Hashtag_Posts: IndicatorInfoProvider{
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return itemInfo
    }
}

extension VC_Hashtag_Posts: MyLikedPostDelegate{
    func myLikedPostsUpdated() {
        if self.isLoadingMore{
            self.isLoadingMore = false
        }

        DispatchQueue.main.async {
            self.dataSource.data = LikedPostsManager.shared.likedPostsStatus
        }
    }
    
    func myLikedPostsLoadedMore(posts: [Post]) {
        if self.isLoadingMore{
            self.isLoadingMore = false
        }
        
        DispatchQueue.main.async {
            if posts.count > 0{
                self.dataSource.data.append(contentsOf: posts)
            }
        }
    }
}
