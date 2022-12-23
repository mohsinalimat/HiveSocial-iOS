//
//  SearchViewController.swift
//  HIVE
//
//  Created by Daniel Pratt on 10/1/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import UIKit
import XLPagerTabStrip
import GradientLoadingBar
import CollectionKit

class VC_Search: ButtonBarPagerTabStripViewController {

    @IBOutlet weak var v_searchView: CollectionView!
    @IBOutlet weak var v_searchBar: UIView!
    @IBOutlet weak var gradientBar: GradientActivityIndicatorView!

    @IBOutlet weak var searchBar: UISearchBar!
    
    // MARK: - Properties
    let searchManager = SearchManager.shared
    var isTypingSearch = false
    
    // MARK: - View Lifecycle Functions
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?){
        super.traitCollectionDidChange(previousTraitCollection)
//        settings.style.buttonBarBackgroundColor = buttonBarColor
//        settings.style.buttonBarItemBackgroundColor = buttonBarColor
    }
    
    override func viewDidLoad() {
        setupBarButtonView()
        
        super.viewDidLoad()
        
        initComponents()
    }
    
    func setupBarButtonView(){
        // change selected bar color
        settings.style.buttonBarBackgroundColor = .clear
        settings.style.buttonBarItemBackgroundColor = .clear
        settings.style.selectedBarBackgroundColor = UIColor.brand()
        settings.style.buttonBarItemFont = UIFont.cFont_medium(size: 17)
        settings.style.selectedBarHeight = 2.0
        settings.style.buttonBarMinimumLineSpacing = 0
        settings.style.buttonBarMinimumInteritemSpacing = 0
        settings.style.buttonBarLeftContentInset = 0
        settings.style.buttonBarRightContentInset = 0
        
        if #available(iOS 13.0, *){
            settings.style.buttonBarItemTitleColor = .label
        }
        else{
            settings.style.buttonBarItemTitleColor = .black
        }
        
        settings.style.buttonBarItemsShouldFillAvailableWidth = true
        
        changeCurrentIndexProgressive = { (oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) -> Void in
            guard changeCurrentIndex == true else { return }

            oldCell?.label.textColor = UIColor(named: "ncol_contrast_grey_dark")!
            oldCell?.label.font = UIFont.cFont_regular(size: 18)

            newCell?.label.textColor = .label
            newCell?.label.font = UIFont.cFont_bold(size: 18)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        v_searchView.isHidden = true
        v_searchView.reloadData()
    }
    
    // MARK: - PagerTabStripDataSource
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let sb = UIStoryboard(name: "TB_CL", bundle: nil)
        
        let vc_featured = sb.instantiateViewController(withIdentifier: "VC_Search_Featured_Media") as! VC_Search_Featured_Media
        let vc_trending = sb.instantiateViewController(withIdentifier: "VC_Search_Trending_Cate") as! VC_Search_Trending_Cate
        let vc_browse = sb.instantiateViewController(withIdentifier: "VC_Search_Browse") as! VC_Search_Browse
        
        return [vc_featured, vc_trending, vc_browse]
    }
    
    func initComponents(){
        addSwipeRight()

        v_searchBar.makeRoundView(r: 4)
        searchBar.autocapitalizationType = .none
        searchBar.backgroundImage = UIImage()
        if let txtField = searchBar.value(forKey: "searchField") as? UITextField{
            txtField.font = UIFont.cFont_regular(size: 16)
            if let lView = txtField.leftView as? UIImageView{
                lView.image = UIImage(named: "mic_search_bar")
            }
            txtField.backgroundColor = UIColor.clear
        }
        searchBar.delegate = self
        
        gradientBar.progressAnimationDuration = 6
        gradientBar.gradientColors = [
            UIColor(named: "ncol_gradient_0")!,
            UIColor(named: "ncol_gradient_1")!,
            UIColor(named: "ncol_gradient_2")!,
            UIColor(named: "ncol_gradient_3")!,
            UIColor(named: "ncol_gradient_4")!,
            UIColor(named: "ncol_gradient_5")!,
        ]
        
        gradientBar.fadeIn()
        
        searchManager.delegateSearch = self
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            DispatchQueue.main.async {
                if !self.gradientBar.isHidden{
                    self.gradientBar.fadeOut()
                }
            }
        }
        
        initData()
    }
    
    var searchResultsData: ArrayDataSource<SuggestionResult>! = ArrayDataSource<SuggestionResult>()
    func initData(){
        v_searchView.contentInsetAdjustmentBehavior = .never
        v_searchView.clipsToBounds = true
        v_searchView.contentInset = UIEdgeInsets(top: -1, left: 0, bottom: 300, right: 0)
        v_searchView.removeGestureRecognizer(v_searchView.tapGestureRecognizer)
        v_searchView.showsVerticalScrollIndicator = false
        v_searchView.showsHorizontalScrollIndicator = false
        
        searchResultsData.data = searchManager.searchSuggestions
        
        v_searchView.provider = BasicProvider(
            dataSource: searchResultsData,
            viewSource: ClosureViewSource(viewGenerator: { (item: SuggestionResult, index: Int) -> UIView in
                if(!item.tag.isEmpty){
                    let v = Bundle.main.loadNibNamed("cell_search_tag", owner: self, options: nil)?[0] as! cell_search_tag
                    return v
                }
                else{
                    let v = Bundle.main.loadNibNamed("cell_search_user", owner: self, options: nil)?[0] as! cell_search_user
                    return v
                }
            }, viewUpdater: { (view: UIView, item: SuggestionResult, index: Int) in
                if(!item.tag.isEmpty){
                    guard let v = view as? cell_search_tag else { return }
                    v.lbl_tag.text = item.tag
                    v.opSelectAction = {
                        DispatchQueue.main.async{
                            self.searchBar.endEditing(true)
                            self.isTypingSearch = false
                            let sb = UIStoryboard(name: "TB_CL", bundle: nil)
                            let vc = sb.instantiateViewController(withIdentifier: "VC_Hashtag") as! VC_Hashtag
                            vc.hashtag = String(item.tag.dropFirst()).lowercased()
                            self.navigationController?.pushViewController(vc, animated: true)
                        }
                    }
                }
                else{
                    guard let v = view as? cell_search_user else { return }
                    guard let usr = item.user else { return }
                    v.lbl_username.text = usr.uname
                    v.img_Profile.loadImg(str: usr.thumb.isEmpty ? usr.avatar : usr.thumb, user: true)
                    v.img_Profile.makeCircleView()
                    v.opSelectAction = {
                        DispatchQueue.main.async{
                            self.searchBar.endEditing(true)
                            self.isTypingSearch = false
                            self.openUser(usr: usr)
                        }
                    }
                }
            }),
            sizeSource: { (index: Int, item: SuggestionResult, size: CGSize) -> CGSize in
                if(!item.tag.isEmpty){
                    return CGSize(width: size.width, height: 40)
                }
                else{
                    return CGSize(width: size.width, height: 50)
                }
            }
        )
    }
}

extension VC_Search: SearchManagerDelegate {
    func updateSearchResult() {
        searchResultsData.data = searchManager.searchSuggestions
    }
}

// MARK: - Search Delegate
extension VC_Search: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
        isTypingSearch = true
        searchResultsData.data = searchManager.searchSuggestions
        self.v_searchView.isHidden = false
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.isEmpty else { return }
        searchBar.resignFirstResponder()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        DispatchQueue.main.async{
            self.v_searchView.isHidden = true
        }
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
        searchBar.text = ""
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        print("~>Cancel button clicked")
        searchBar.endEditing(true)
        isTypingSearch = false
        DispatchQueue.main.async{
            self.v_searchView.isHidden = true
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard searchText.count >= 2 else {
            searchManager.searchSuggestions = []
            searchResultsData.data = searchManager.searchSuggestions
            return
        }
        
        guard !searchManager.isSearching else { return }
        
        searchManager.getSuggestions(for: searchText)
    }
}
