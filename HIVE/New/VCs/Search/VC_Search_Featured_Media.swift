//
//  VC_Search_Featured_Media.swift
//  HIVE
//
//  Created by elitemobile on 10/12/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import UIKit
import XLPagerTabStrip
import CollectionKit
import Firebase

class VC_Search_Featured_Media: UIViewController{
    var itemInfo = IndicatorInfo(title: "Featured")
    
    @IBOutlet weak var collectionView: CollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initComponents()
    }
    
    var postsDataSource1: ArrayDataSource<Post>! = ArrayDataSource<Post>()
    var postsDataSource2: ArrayDataSource<Post>! = ArrayDataSource<Post>()
    var postsDataSource3: ArrayDataSource<Post>! = ArrayDataSource<Post>()
    var postsDataSource4: ArrayDataSource<Post>! = ArrayDataSource<Post>()
    var postsDataSource5: ArrayDataSource<Post>! = ArrayDataSource<Post>()
    
    var isLoadingMore: Bool = false
    var sectionProvider: ComposedProvider!
    var isRefreshing: Bool = false
    func initComponents(){
        collectionView.clipsToBounds = true
        collectionView.contentInset = UIEdgeInsets(top: 200, left: 0, bottom: 1000, right: 0)
        collectionView.removeGestureRecognizer(collectionView.tapGestureRecognizer)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        
        postsDataSource1.data = []
        postsDataSource2.data = []
        postsDataSource3.data = []
        postsDataSource4.data = []
        postsDataSource5.data = []
                
        let specialWidth = (UIScreen.main.bounds.width - 1) / 3 * 2 + 0.5
        let defaultWidth = (UIScreen.main.bounds.width - 1) / 3
        let specialSize: CGSize = CGSize(width: specialWidth, height: specialWidth)
        let defaultSize: CGSize = CGSize(width: defaultWidth, height: defaultWidth)
        let longSize: CGSize = CGSize(width: specialWidth, height: defaultWidth)
        
        sectionProvider = ComposedProvider(sections: [
            ComposedProvider(sections: [
                BasicProvider(
                    dataSource: postsDataSource1,
                    viewSource: ClosureViewSource(viewGenerator: { (post: Post, index: Int) -> cell_media_collection in
                        let v = Bundle.main.loadNibNamed("cell_media_collection", owner: self, options: nil)?[0] as! cell_media_collection
                        return v
                    }, viewUpdater: { (v: cell_media_collection, post: Post, index: Int) in
                        v.special = true
                        v.setPost(post: post)
                        v.setConstraint(top: true, bottom: true)
                        v.opChooseAction = { thumb in
                            self.openPost(post: post, thumb: thumb)
                        }
                    }),
                    sizeSource: { (index: Int, post: Post, size: CGSize) -> CGSize in
                        return self.postsDataSource1.data.count != 0 ? specialSize : CGSize.zero
                    }
                ),
                BasicProvider(
                    dataSource: postsDataSource2,
                    viewSource: ClosureViewSource(viewGenerator: { (post: Post, index: Int) -> cell_media_collection in
                        let v = Bundle.main.loadNibNamed("cell_media_collection", owner: self, options: nil)?[0] as! cell_media_collection
                        return v
                    }, viewUpdater: { (v: cell_media_collection, post: Post, index: Int) in
                        v.setPost(post: post)
                        v.setConstraint(top: true, left: true)
                        v.opChooseAction = { thumb in
                            self.openPost(post: post, thumb: thumb)
                        }
                    }),
                    sizeSource: { (index: Int, post: Post, size: CGSize) -> CGSize in
                        return self.postsDataSource2.data.count != 0 ? CGSize(width: defaultWidth + 0.5, height: defaultWidth) : CGSize.zero
                    },
                    layout: FlowLayout(spacing: 0).transposed()
                )
            ]),
            ComposedProvider(sections: [
                BasicProvider(
                    dataSource: postsDataSource3,
                    viewSource: ClosureViewSource(viewGenerator: { (post: Post, index: Int) -> cell_media_collection in
                        let v = Bundle.main.loadNibNamed("cell_media_collection", owner: self, options: nil)?[0] as! cell_media_collection
                        return v
                    }, viewUpdater: { (v: cell_media_collection, post: Post, index: Int) in
                        v.special = true
                        v.setPost(post: post)
                        v.setConstraint(bottom: true)
                        v.opChooseAction = { thumb in
                            self.openPost(post: post, thumb: thumb)
                        }
                    }),
                    sizeSource: { (index: Int, post: Post, size: CGSize) -> CGSize in
                        return self.postsDataSource3.data.count != 0 ? longSize : CGSize.zero
                    }
                ),
                BasicProvider(
                    dataSource: postsDataSource4,
                    viewSource: ClosureViewSource(viewGenerator: { (post: Post, index: Int) -> cell_media_collection in
                        let v = Bundle.main.loadNibNamed("cell_media_collection", owner: self, options: nil)?[0] as! cell_media_collection
                        return v
                    }, viewUpdater: { (v: cell_media_collection, post: Post, index: Int) in
                        v.setPost(post: post)
                        v.setConstraint(left: true, bottom: true)
                        v.opChooseAction = { thumb in
                            self.openPost(post: post, thumb: thumb)
                        }
                    }),
                    sizeSource: { (index: Int, post: Post, size: CGSize) -> CGSize in
                        return self.postsDataSource4.data.count != 0 ? CGSize(width: defaultWidth + 0.5, height: defaultWidth) : CGSize.zero
                    }
                )
            ]),
            BasicProvider(
                dataSource: postsDataSource5,
                viewSource: ClosureViewSource(viewGenerator: { (post: Post, index: Int) -> cell_media_collection in
                    let v = Bundle.main.loadNibNamed("cell_media_collection", owner: self, options: nil)?[0] as! cell_media_collection
                    return v
                }, viewUpdater: { (v: cell_media_collection, post: Post, index: Int) in
                    v.setPost(post: post)
                    v.opChooseAction = { thumb in
                        self.openPost(post: post, thumb: thumb)
                    }
                }),
                sizeSource: { (index: Int, post: Post, size: CGSize) -> CGSize in
                    return self.postsDataSource5.data.count != 0 ? defaultSize : CGSize.zero
                },
                layout: FlowLayout(spacing: 0.5)
            )
        ])
        
        collectionView.provider = sectionProvider
        
        collectionView.es.addPullToRefresh {
            print("reloading")
            if self.isLoadingMore{
                print("is in load more")
                DispatchQueue.main.async {
                    self.collectionView.es.stopPullToRefresh()
                }
                return
            }
            if self.isRefreshing{
                print("is in reloading")
                return
            }
            
            print("reloading started")
            self.isRefreshing = true
            
            self.postsDataSource1.data.removeAll()
            self.postsDataSource2.data.removeAll()
            self.postsDataSource3.data.removeAll()
            self.postsDataSource4.data.removeAll()
            self.postsDataSource5.data.removeAll()

            FeaturedPostsManager.shared.loadData()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                if self.isRefreshing{
                    print("finish reloading due to non-reply")
                    self.isRefreshing = false
                    self.collectionView.es.stopPullToRefresh()
                }
            }
        }
        
        self.isRefreshing = true
        FeaturedPostsManager.shared.loadData()
        FeaturedPostsManager.shared.delegate = self
    }
}

extension VC_Search_Featured_Media: IndicatorInfoProvider{
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return itemInfo
    }
}

extension VC_Search_Featured_Media: UIScrollViewDelegate{
    func scrollViewDidScroll(_ scrollView: UIScrollView){
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        let diff = maximumOffset - currentOffset
        if diff <= 300{
            if self.postsDataSource5.data.count == 0{
                return
            }

            if self.isRefreshing{
                return
            }
            if self.isLoadingMore{
                return
            }
            self.isLoadingMore = true
            
            FeaturedPostsManager.shared.loadMoreData()
        }
    }
}

extension VC_Search_Featured_Media: FeaturedPostsDelegate{
    func postsUpdated(posts: [Post]){
        self.postsDataSource1.data.removeAll()
        self.postsDataSource2.data.removeAll()
        self.postsDataSource3.data.removeAll()
        self.postsDataSource4.data.removeAll()
        self.postsDataSource5.data.removeAll()

        if self.isRefreshing{
            self.isRefreshing = false
            DispatchQueue.main.async {
                self.collectionView.es.stopPullToRefresh()
            }
        }
        if self.isLoadingMore{
            self.isLoadingMore = false
        }

        DispatchQueue.main.async {
            var index: Int = 0
            posts.forEach { (post) in
                switch(index){
                case 0:
                    self.postsDataSource1.data.append(post)
                    break
                case 1:
                    self.postsDataSource2.data.append(post)
                    break
                case 2:
                    self.postsDataSource2.data.append(post)
                    break
                case 3:
                    self.postsDataSource3.data.append(post)
                    break
                case 4:
                    self.postsDataSource4.data.append(post)
                    break
                default:
                    self.postsDataSource5.data.append(post)
                    break
                }
                index += 1
            }
        }
    }
    func postsLoadedMore(posts: [Post]){
        if self.isRefreshing{
            self.isRefreshing = false
        }
        if self.isLoadingMore{
            self.isLoadingMore = false
        }
        
        DispatchQueue.main.async {
            if posts.count > 0{
                self.postsDataSource5.data.append(contentsOf: posts)
            }
        }
    }
}
