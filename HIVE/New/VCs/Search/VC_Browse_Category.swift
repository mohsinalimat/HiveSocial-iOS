//
//  VC_Browse_Category.swift
//  HIVE
//
//  Created by elitemobile on 1/4/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import UIKit
import XLPagerTabStrip
import CollectionKit

class VC_Browse_Category: BaseButtonBarPagerTabStripViewController<cell_youtube_icon> {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var img_content: UIImageView!
    @IBOutlet weak var lbl_title: UILabel!
    @IBOutlet weak var v_tags: CollectionView!
    @IBOutlet weak var img_cate_follow: UIImageView!
    @IBOutlet weak var lbl_cate_follow: UILabel!
    @IBOutlet weak var contentViewHeightConstraint: NSLayoutConstraint!
    
    var manager: TagPostsManager = TagPostsManager()
    override func viewDidLoad() {		
        setupPagerHeaderViews()
        super.viewDidLoad()
        initComponents()
        
        manager.searchCateData()
        setupHUD()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { 
            DispatchQueue.main.async {
                self.hideHUD()
            }
        }
    }
    
    func setupPagerHeaderViews(){
        // change selected bar color
        buttonBarItemSpec = ButtonBarItemSpec.nibFile(nibName: "cell_youtube_icon", bundle: Bundle(for: cell_youtube_icon.self), width: { _ in
            return UIScreen.main.bounds.width / 2
        })
        
        // change selected bar color
        settings.style.buttonBarBackgroundColor = .clear
        settings.style.buttonBarItemBackgroundColor = .clear
        settings.style.selectedBarBackgroundColor = UIColor(named: "col_profile_selected")!
        settings.style.selectedBarHeight = 0.0
        settings.style.buttonBarMinimumLineSpacing = 0
        settings.style.buttonBarMinimumInteritemSpacing = 0
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
            newCell?.backgroundColor = UIColor(named: "col_1")!
            
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
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?){
        super.traitCollectionDidChange(previousTraitCollection)
        settings.style.buttonBarBackgroundColor = .clear
        settings.style.buttonBarItemBackgroundColor = .clear
    }
    
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let sb = UIStoryboard(name: "TB_CL", bundle: nil)
        
        let child1 = sb.instantiateViewController(withIdentifier: "VC_Hashtag_Discover") as! VC_Hashtag_Discover
        let child2 = sb.instantiateViewController(withIdentifier: "VC_Hashtag_Posts") as! VC_Hashtag_Posts
        child1.manager = manager
        child2.manager = manager
        return [child1, child2]
    }
    
//    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        let offsetY = scrollView.contentOffset.y
//        print(offsetY)
//    }
    func initComponents(){
        addSwipeRight()
        setupContentViewHeight()
        initTags()
        
        let cate = categories[selectedCategoryIndex]
        lbl_title.text = cate[0] as? String
        img_content.image = UIImage(named: cate[1] as! String)
        
//        scrollView.delegate = self
    }
    
    func setupContentViewHeight(){
        print(UIScreen.main.nativeBounds.height)
        switch UIScreen.main.nativeBounds.height{
        case 1136:
            //iphone 5_5s_5c_se
            contentViewHeightConstraint.constant = -124
            break
        case 1334:
            //iphone 6_6s_7_8
            contentViewHeightConstraint.constant = -124
            break
        case 1792:
            //iphone xr_11
            contentViewHeightConstraint.constant = -180
            break
        case 1920, 2208:
            //iphone 6plus_6splus_7plus_8plus
            contentViewHeightConstraint.constant = -124
            break
        case 2426:
            //iphone 11_pro
            contentViewHeightConstraint.constant = -180
            break
        case 2436:
            //iphone x_xs
            contentViewHeightConstraint.constant = -180
            break
        case 2688:
            //iphone xsmax_promax
            contentViewHeightConstraint.constant = -180
            break
        default:
            contentViewHeightConstraint.constant = -180
            break
        }
        print("ContentHeight \(contentViewHeightConstraint.constant)")
        self.view.layoutSubviews()
    }
    
    func initTags(){
        v_tags.clipsToBounds = true
        v_tags.contentInset = UIEdgeInsets(top: 0, left: 78, bottom: 0, right: 0)
        v_tags.removeGestureRecognizer(v_tags.tapGestureRecognizer)
        v_tags.showsVerticalScrollIndicator = false
        v_tags.showsHorizontalScrollIndicator = false
        
        var tags = categories[selectedCategoryIndex][3] as! [String]
        tags.insert("All", at: 0)
        
        v_tags.provider = BasicProvider(
            dataSource: tags,
            viewSource: ClosureViewSource(viewGenerator: { (tag: String, index: Int) -> cell_category_tag in
                let v = Bundle.main.loadNibNamed("cell_category_tag", owner: self, options: nil)?[0] as! cell_category_tag
                return v
            }, viewUpdater: { (v: cell_category_tag, tag: String, index: Int) in
                v.lbl_tag.text = tags[index]
                
                v.opSelectedAction = {
                    self.buttonBarView.reloadData()
                    
                    selectedTagIndex = index
                    
                    if index == 0{
                        print("search #All")
                        self.manager.searchCateData()
                    }
                    else if index > 0{
                        let tagSearch = tags[index]
                        print("search #\(tagSearch)")
                        self.manager.searchTagData(tag: tagSearch)
                    }
                    self.v_tags.reloadData()
                }
                
                if (index == selectedTagIndex){
                    v.v_tag.alpha = 1
                    v.lbl_tag.textColor = UIColor.black
                }
                else{
                    v.v_tag.alpha = 0.12
                    v.lbl_tag.textColor = UIColor.white
                }
                
            }),
            sizeSource: { (index: Int, tag: String, size: CGSize) -> CGSize in
                let width: CGFloat = (tag as NSString).size(withAttributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 15, weight: .black)]).width + 30
                
                return CGSize(width: width, height: size.height)
            },
            layout: FlowLayout(spacing: 6).transposed()
        )
        
        updateBookMarkButton()
    }
    
    @IBAction func opMarked(_ sender: Any) {
        if let index = Me.following_cate.firstIndex(of: selectedCategoryIndex){
            Me.following_cate.remove(at: index)
        }
        else{
            Me.following_cate.append(selectedCategoryIndex)
        }
        
        Me.following_cate.sort()
        
        updateBookMarkButton()
        
        self.setupHUD(msg: "Saving...")
        
        Me.updateFollowingCategories { (res) in
            self.hideHUD()
            if res{
                Me.saveLocal()
                
                self.showSuccess(title: "Success", msg: "Updated successfully")
            }
        }
    }
    
    func updateBookMarkButton(){
        lbl_cate_follow.isHidden = !Me.following_cate.contains(selectedCategoryIndex)
        img_cate_follow.isHighlighted = Me.following_cate.contains(selectedCategoryIndex)
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateFollowingCategories"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadFollowingCategoriesView"), object: nil)
    }
    
    @IBAction func opBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}
