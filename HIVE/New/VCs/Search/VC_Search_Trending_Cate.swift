//
//  VC_Search_Trending_Cate.swift
//  HIVE
//
//  Created by elitemobile on 10/12/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import UIKit
import XLPagerTabStrip
import CollectionKit

class VC_Search_Trending_Cate: UIViewController {
    @IBOutlet weak var collectionView: CollectionView!
    var itemInfo = IndicatorInfo(title: "Trending")
    
    //    var itemInfo = IndicatorInfo(title: "", image: UIImage(named: "nic_profile_status")!.withRenderingMode(.alwaysTemplate))
//    var manager: PostManager = PostManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initComponents()
    }
    
    var postsDataSource: ArrayDataSource<TrendingTag>! = ArrayDataSource<TrendingTag>()
    func initComponents(){
        collectionView.clipsToBounds = true
        collectionView.contentInset = UIEdgeInsets(top: -1, left: 0, bottom: 100, right: 0)
        collectionView.removeGestureRecognizer(collectionView.tapGestureRecognizer)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        
        collectionView.provider = BasicProvider(
            dataSource: postsDataSource,
            viewSource: ClosureViewSource(viewGenerator: { (_, index: Int) -> cell_top_tag in
                let v = Bundle.main.loadNibNamed("cell_top_tag", owner: self, options: nil)?[0] as! cell_top_tag
                return v
            }, viewUpdater: { (v: cell_top_tag, trendingTag: TrendingTag, index: Int) in
                v.setTrendingTag(tt: trendingTag)
                v.opOpenAction = {
                    self.openTag(tag: trendingTag.tag)
                }
            }),
            sizeSource: { (index: Int, _, size: CGSize) -> CGSize in
                return CGSize(width: size.width, height: 70)
            }
        )
        
        collectionView.es.addPullToRefresh {
            if self.isRefreshing{
                return
            }
            self.isRefreshing = true
            
            self.loadData()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                if self.isRefreshing{
                    self.isRefreshing = false
                    self.collectionView.es.stopPullToRefresh()
                }
            }
        }
        
        loadData()
    }
    
    var isRefreshing = false
    func loadData(){
        self.postsDataSource.data.removeAll()
        
        var query = FHASHTAG_POSTS_REF
            .order(by: HashTag.key_count, descending: false)
        if Me.uid == vipUser{
            query = query.limit(toLast: 50)
        }
        else{
            query = query.limit(toLast: 21)
        }
        query.getDocuments{ [unowned self](doc, err) in
            if self.isRefreshing{
                self.isRefreshing = false
                DispatchQueue.main.async {
                    self.collectionView.es.stopPullToRefresh()
                }
            }

            if let error = err{
                print(error.localizedDescription)
                return
            }
            doc?.documentChanges.forEach({ (item) in
                let data = item.document.data()
                guard let count = data[HashTag.key_count] as? Int, count > 0, let tag = data[HashTag.key_tag] as? String, let lastused = data[HashTag.key_last_used] as? Double else { return }
                
                let ttag = TrendingTag(tag: tag, count: count, lastUsed: lastused)
                self.postsDataSource.data.insert(ttag, at: 0)
            })
        }
    }
}

extension VC_Search_Trending_Cate: IndicatorInfoProvider{
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return itemInfo
    }
}
