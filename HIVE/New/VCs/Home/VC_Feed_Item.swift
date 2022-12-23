//
//  NewsFeedTableViewController.swift
//  HIVE
//
//  Created by Daniel Pratt on 9/4/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import UIKit
import CollectionKit

class VC_FeedItem: UIViewController{
    
    @IBOutlet weak var v_feed: CollectionView!
    var post: Post!
    var thumb: UIImage? = nil
    
    var isLoadingMore: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        initComponents()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.post.ouid == Me.uid{
            NotificationCenter.default.addObserver(self, selector: #selector(deleteCompletion), name: NSNotification.Name(rawValue: "deleteCompletion"), object: nil)
        }
        self.v_feed.reloadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if self.isMovingFromParent || self.isBeingDismissed{
            if self.post.ouid == Me.uid{
                NotificationCenter.default.removeObserver(self)
            }
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.v_feed.reloadData()
    }

    func initComponents(){
        addSwipeRight()
        initData()
    }
    
    func initData(){
        guard let pst = self.post else { return }

//        print("pid - \(pst.pid), uid - \(pst.ouid)")
        v_feed.contentInsetAdjustmentBehavior = .never
        v_feed.clipsToBounds = true
        v_feed.contentInset = UIEdgeInsets(top: -1, left: 0, bottom: 100, right: 0)
        v_feed.removeGestureRecognizer(v_feed.tapGestureRecognizer)
        v_feed.showsVerticalScrollIndicator = false
        v_feed.showsHorizontalScrollIndicator = false

        if pst.ouid == Me.uid{
            pst.oavatar = Me.thumb.isEmpty ? Me.avatar : Me.thumb
            pst.ouname = Me.uname
        }
//        print(pst.desc)
        v_feed.provider = BasicProvider(
            dataSource: [1],
            viewSource: ClosureViewSource(viewGenerator: { (_, index: Int) -> cell_media_table in
                let v = Bundle.main.loadNibNamed("cell_media_table", owner: self, options: nil)?[0] as! cell_media_table
                v.mustAutoPlay = true
                return v
            }, viewUpdater: { (v: cell_media_table, _, index: Int) in
                v.setPost(post: pst, thumb: self.thumb)
                self.setupPost(v: v, post: pst)
            }),
            sizeSource: { (index: Int, _, size: CGSize) -> CGSize in
                return CGSize(width: size.width, height: Utils.getCellHeight(post: self.post, cellWidth: size.width))
            }
        )
    }
    
    @objc func deleteCompletion(){
        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func opBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}
