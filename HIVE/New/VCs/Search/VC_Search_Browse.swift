//
//  VC_Search_Browse.swift
//  HIVE
//
//  Created by elitemobile on 10/12/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import UIKit
import CollectionKit
import XLPagerTabStrip

class VC_Search_Browse: UIViewController {
    var itemInfo = IndicatorInfo(title: "Browse")
    
    @IBOutlet weak var collectionView: CollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initComponents()
    }
    
    func initComponents(){
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.clipsToBounds = true
        collectionView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 100, right: 0)
        collectionView.removeGestureRecognizer(collectionView.tapGestureRecognizer)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadFollowingCategories), name: NSNotification.Name(rawValue: "reloadFollowingCategoriesView"), object: nil)

        collectionView.provider = ComposedProvider(layout: FlowLayout(spacing: 24), sections: [
            BasicProvider(
                dataSource: [1],
                viewSource: ClosureViewSource(viewGenerator: { (_, index: Int) -> cv_bookmarks in
                    let v = Bundle.main.loadNibNamed("cv_bookmarks", owner: self, options: nil)?[0] as! cv_bookmarks
                    return v
                }, viewUpdater: { (v: cv_bookmarks, _, index: Int) in
                    v.opSelectedAction = { (val) in
                        selectedCategoryIndex = val
                        selectedTagIndex = 0
                        
                        let sb = UIStoryboard(name: "TB_CL", bundle: nil)
                        let vc = sb.instantiateViewController(withIdentifier: "VC_Browse_Category") as! VC_Browse_Category
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                }),
                sizeSource: { (index: Int, _, size: CGSize) -> CGSize in
                    return CGSize(width: size.width, height: Me.following_cate.count == 0 ? 0 : 144)
                },
                layout: FlowLayout(spacing: 6).transposed()
            ),
            BasicProvider(
                dataSource: categories,
                viewSource: ClosureViewSource(viewGenerator: { (cate, index) -> cv_browse_cate in
                    let v = Bundle.main.loadNibNamed("cv_browse_cate", owner: self, options: nil)?[0] as! cv_browse_cate
                    return v
                }) { (v: cv_browse_cate, _, index: Int) in
                    let cate = categories[index]
                    v.img_bg.image = UIImage(named: cate[1] as! String)!
                    v.lbl_name.text = cate[0] as? String
                    v.lbl_desc.text = cate[2] as? String
                    
                    v.opOpenCategory = {
                        selectedCategoryIndex = index
                        selectedTagIndex = 0
                        
                        let sb = UIStoryboard(name: "TB_CL", bundle: nil)
                        let vc = sb.instantiateViewController(withIdentifier: "VC_Browse_Category") as! VC_Browse_Category
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                },
                sizeSource: { (index, data, size) in
                    return CGSize(width: size.width, height: size.width * 179 / 366)
                },
                layout: FlowLayout(spacing: 24)
            )
        ]
        )
    }
    
    @objc func reloadFollowingCategories(){
        collectionView.reloadData()
    }
}

extension VC_Search_Browse: IndicatorInfoProvider{
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return itemInfo
    }
}

