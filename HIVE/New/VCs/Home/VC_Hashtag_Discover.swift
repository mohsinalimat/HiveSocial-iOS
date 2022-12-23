//
//  VC_Hashtag_Discover.swift
//  HIVE
//
//  Created by elitemobile on 1/29/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import UIKit
import XLPagerTabStrip
import CollectionKit

class VC_Hashtag_Discover: UIViewController {
    var itemInfo = IndicatorInfo(title: "", image: UIImage(named: "nic_profile_media")!.withRenderingMode(.alwaysTemplate))
    
    @IBOutlet weak var collectionView: CollectionView!
    var updateScrollViewScrolls: ((CGFloat) -> Void)?

    var manager: TagPostsManager!{
        didSet{
            manager.delegateTagDiscover = self
        }
    }
    
    var dataSource: ArrayDataSource<Post>! = ArrayDataSource<Post>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        initComponents()
    }
    
    var isLoadingMore: Bool = false

    func initComponents(){
        if manager != nil{
            dataSource.data = manager.tagPostsMedia
        }
        else{
            dataSource.data = LikedPostsManager.shared.likedPostsMedia
            LikedPostsManager.shared.myLikedPostsDelegateMedia = self
        }
        
        collectionView.contentInset = UIEdgeInsets(top: 200, left: 0, bottom: 1000, right: 0)
        collectionView.clipsToBounds = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        
        let defaultWidth = (UIScreen.main.bounds.width - 1) / 3
        let defaultSize: CGSize = CGSize(width: defaultWidth, height: defaultWidth)

        collectionView.provider = BasicProvider(
            dataSource: dataSource,
            viewSource: ClosureViewSource(viewGenerator: { (data, index) -> cell_media_collection in
                let v = Bundle.main.loadNibNamed("cell_media_collection", owner: self, options: nil)?[0] as! cell_media_collection

                return v
            }) { (v: cell_media_collection, data, at: Int) in
                v.setPost(post: data)
                v.opChooseAction = { thumb in
                    self.openPost(post: data, thumb: thumb)
                }
            },
            sizeSource: { (index: Int, post: Post, size: CGSize) -> CGSize in
                return self.dataSource.data.count != 0 ? defaultSize : CGSize.zero
            },
            layout: FlowLayout(spacing: 0.5)
        )
    }
}

extension VC_Hashtag_Discover: TagPostsManagerDelegate{
    func postsUpdated() {
        if self.isLoadingMore{
            self.isLoadingMore = false
        }
        
        DispatchQueue.main.async {
            self.dataSource.data = self.manager.tagPostsMedia
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

extension VC_Hashtag_Discover: IndicatorInfoProvider{
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return itemInfo
    }
}

extension VC_Hashtag_Discover: MyLikedPostDelegate{
    func myLikedPostsUpdated() {
        if self.isLoadingMore{
            self.isLoadingMore = false
        }

        DispatchQueue.main.async {
            self.dataSource.data = LikedPostsManager.shared.likedPostsMedia
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

extension VC_Hashtag_Discover: UIScrollViewDelegate{
    func scrollViewDidScroll(_ scrollView: UIScrollView){
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height

        if maximumOffset - currentOffset <= 1000{
            if self.dataSource.data.count == 0 {
                return
            }
            if self.isLoadingMore{
                return
            }

            self.isLoadingMore = true

            if self.manager != nil{
                if !manager.hashTag.isEmpty{
                    self.manager.loadMoreTagData()
                }
                else{
                    self.manager.loadMore()
                }
            }
            else{
                LikedPostsManager.shared.loadMoreLikedPosts()
            }
        }
    }
}
