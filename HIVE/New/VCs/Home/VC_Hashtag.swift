//
//  VC_Hashtag.swift
//  HIVEcopy
//
//  Created by Kassy Pop on 8/24/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import UIKit
import Firebase
import XLPagerTabStrip

class VC_Hashtag: BaseButtonBarPagerTabStripViewController<cell_youtube_icon> {
    @IBOutlet weak var lbl_title: UILabel!
    @IBOutlet weak var constraintScrollViewHeight: NSLayoutConstraint!

    var hashtag: String = ""
    var isLikedPosts: Bool = false
    var uid: String = ""
    // MARK: - Init
    
    override func viewDidLoad() {
        // change selected bar color
        buttonBarItemSpec = ButtonBarItemSpec.nibFile(nibName: "cell_youtube_icon", bundle: Bundle(for: cell_youtube_icon.self), width: { _ in
            return UIScreen.main.bounds.width / 2
        })
        
        // change selected bar color
        settings.style.buttonBarBackgroundColor = .clear
        settings.style.buttonBarItemBackgroundColor = .clear
        settings.style.selectedBarBackgroundColor = UIColor(named: isLikedPosts ? "col_btn_send_active" : "col_profile_selected")!
        settings.style.selectedBarHeight = 0.0
        settings.style.buttonBarMinimumLineSpacing = 0
        settings.style.buttonBarItemTitleColor = UIColor(named: isLikedPosts ? "col_btn_send_active" : "col_profile_selected")!
        settings.style.buttonBarItemsShouldFillAvailableWidth = false
        settings.style.buttonBarLeftContentInset = 0
        settings.style.buttonBarRightContentInset = 0
        
        var backConfirmed: Bool = false
        changeCurrentIndexProgressive = {(oldCell: cell_youtube_icon?, newCell: cell_youtube_icon?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) -> Void in
            if !backConfirmed &&
                self.currentIndex == 0 &&
                oldCell == nil &&
                ((progressPercentage > 0 && progressPercentage < 0.5) ||
                    (progressPercentage < 0 && progressPercentage > -0.5)){
                
                backConfirmed = true
                self.navigationController?.popViewController(animated: true)
                
                return
            }
            
            guard changeCurrentIndex == true else { return }
            oldCell?.iconImage.tintColor = .darkGray
            oldCell?.backgroundColor = .clear
            
            newCell?.iconImage.tintColor = .white
            newCell?.backgroundColor = UIColor(named: self.isLikedPosts ? "col_btn_send_active" : "col_profile_selected")!
            
            if animated{
                UIView.animate(withDuration: 0.1, animations: { () -> Void in
                    newCell?.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                    oldCell?.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                })
            }
            else{
                newCell?.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                oldCell?.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            }
        }
        
        super.viewDidLoad()
        initComponents()
        
        setupHUD()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { 
            DispatchQueue.main.async {
                self.hideHUD()
            }
        }
    }
    override func configure(cell: cell_youtube_icon, for indicatorInfo: IndicatorInfo) {
        cell.iconImage.image = indicatorInfo.image?.withRenderingMode(.alwaysTemplate)
        cell.iconImage.tintColor = .gray
    }
    
    override func updateIndicator(for viewController: PagerTabStripViewController, fromIndex: Int, toIndex: Int, withProgressPercentage progressPercentage: CGFloat, indexWasChanged: Bool) {
        super.updateIndicator(for: viewController, fromIndex: fromIndex, toIndex: toIndex, withProgressPercentage: progressPercentage, indexWasChanged: indexWasChanged)
        if indexWasChanged && toIndex > -1 && toIndex < viewControllers.count {
            let child = viewControllers[toIndex] as! IndicatorInfoProvider // swiftlint:disable:this force_cast
            UIView.performWithoutAnimation({ [weak self] () -> Void in
                guard let me = self else { return }
                me.navigationItem.leftBarButtonItem?.title =  child.indicatorInfo(for: me).title
            })
        }
    }
    
    // MARK: - View Lifecycle Functions
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?){
        super.traitCollectionDidChange(previousTraitCollection)
        settings.style.buttonBarBackgroundColor = .clear
        settings.style.buttonBarItemBackgroundColor = .clear
    }

    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let sb = UIStoryboard(name: "TB_CL", bundle: nil)

        let child1 = sb.instantiateViewController(withIdentifier: "VC_Hashtag_Discover") as! VC_Hashtag_Discover
        let child2 = sb.instantiateViewController(withIdentifier: "VC_Hashtag_Posts") as! VC_Hashtag_Posts

        if !self.hashtag.isEmpty{
            let manager = TagPostsManager()
            manager.hashTag = self.hashtag
            manager.searchTagData(tag: self.hashtag)
            child1.manager = manager
            child2.manager = manager
        }
        else if isLikedPosts{
            LikedPostsManager.shared.likedPostsUid = self.uid
            LikedPostsManager.shared.loadMyLikedPosts()
        }

        return [child1, child2]
    }

    func initComponents(){
        addSwipeRight()
        configureNavigationBar()
                
        UIView.animate(withDuration: 0.3) { 
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Handlers
    func configureNavigationBar() {
        if !hashtag.isEmpty{
            lbl_title.text = "#\(hashtag)"
        }
        else if isLikedPosts{
            lbl_title.text = "Liked Posts"
        }
    }

    @IBAction func opBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}
