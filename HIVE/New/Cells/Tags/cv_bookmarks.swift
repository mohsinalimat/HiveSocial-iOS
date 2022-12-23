//
//  cv_bookmarks.swift
//  HIVE
//
//  Created by elitemobile on 12/3/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import UIKit
import CollectionKit

class cv_bookmarks: UIView {
    @IBOutlet weak var collectionView: CollectionView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initComponents()
    }
    
    var opSelectedAction: ((Int) -> Void)?
    var categoriesDataSource: ArrayDataSource<Int>! = ArrayDataSource<Int>()
    func initComponents(){
        NotificationCenter.default.addObserver(self, selector: #selector(reloadFollowingCategories), name: NSNotification.Name(rawValue: "updateFollowingCategories"), object: nil)

        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        
        categoriesDataSource.data = Me.following_cate
        
        collectionView.provider = BasicProvider(
            dataSource: categoriesDataSource,
            viewSource: ClosureViewSource(viewGenerator: { (val: Int, index: Int) -> cv_mark in
                let v = Bundle.main.loadNibNamed("cv_mark", owner: self, options: nil)?[0] as! cv_mark
                return v
            }, viewUpdater: { (v: cv_mark, val: Int, index: Int) in
                v.setCategory(index: val)
                v.opSelectedAction = {
                    self.opSelectedAction?(val)
                }
            }),
            sizeSource: { (index: Int, _, size: CGSize) -> CGSize in
                return CGSize(width: 79, height: 112)
            },
            layout: FlowLayout(spacing: 8).transposed()
        )
    }
    
    @objc func reloadFollowingCategories(){
        categoriesDataSource.data = Me.following_cate
    }
}
