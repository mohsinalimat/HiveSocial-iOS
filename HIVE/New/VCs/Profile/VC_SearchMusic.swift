//
//  MusicSearchViewController.swift
//  HIVE
//
//  Created by Daniel Pratt on 9/24/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import UIKit
import StoreKit
import CollectionKit

class VC_SearchMusic: UIViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var v_searchBar: UIView!
    @IBOutlet weak var collectionView: CollectionView!
    @IBOutlet weak var btn_addSong: UIButton!
    // MARK: - IBOutlets
    
    // MARK: - Properties
    
    var isSearching: Bool = false
    var isShowingResults: Bool = false
    var searchHints: [String] = []
    var searchResults: [Song] = []
    
    var opSelectedSong: ((FirebaseSong) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initComponents()
    }
    
    var searchResultsData: ArrayDataSource<Any>! = ArrayDataSource<Any>()
    var selectedIndex = -1
    var selectedSong: Song!
    var slotPurchased: Bool = false
    var slotIndex: Int = -1
    func initComponents(){
        btn_addSong.setTitle(slotPurchased ? "Add Song": "Purchase Slot", for: .normal)
        
        btn_addSong.makeRoundView(r: 4)
        v_searchBar.makeRoundView(r: 4)
        searchBar.backgroundImage = UIImage()
        searchBar.autocapitalizationType = .none
        if let txtField = searchBar.value(forKey: "searchField") as? UITextField{
            txtField.font = UIFont.cFont_regular(size: 16)
            if let lView = txtField.leftView as? UIImageView{
                lView.image = UIImage(named: "mic_search_bar")
            }
            txtField.backgroundColor = UIColor.clear
        }
        searchBar.delegate = self

        collectionView.contentInset = UIEdgeInsets(top: -1, left: 0, bottom: 300, right: 0)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.clipsToBounds = true
        
        collectionView.provider = BasicProvider(
            dataSource: searchResultsData,
            viewSource: ClosureViewSource(viewGenerator: { (item: Any, index: Int) -> cv_new_chat_user in
                let v = Bundle.main.loadNibNamed("cv_new_chat_user", owner: self, options: nil)?[0] as! cv_new_chat_user
                return v
            }, viewUpdater: { (v: cv_new_chat_user, item: Any, index: Int) in
                if let song = item as? Song{
                    v.setSong(song: song)
                    
                    v.chk_checked.setOn(self.selectedIndex == index, animated: self.selectedIndex == index)
                    self.btn_addSong.backgroundColor = UIColor(named: self.selectedIndex != -1 ? "col_btn_send_active" : "mcol_song_picker_btn_inactive")
                    self.btn_addSong.setTitleColor(self.selectedIndex != -1 ? UIColor.white : UIColor(named: "mcol_song_picker_lbl_inactive"), for: .normal)
                    
                    v.opSelectedAction = {
                        if self.selectedIndex == index{
                            self.selectedIndex = -1
                            self.selectedSong = nil
                        }
                        else{
                            self.selectedSong = song
                            self.selectedIndex = index
                        }
                        self.collectionView.reloadData()
                    }
                }
                else{
                    self.selectedIndex = -1
                    self.selectedSong = nil
                    self.btn_addSong.backgroundColor = UIColor(named: self.selectedIndex != -1 ? "col_btn_send_active" : "mcol_song_picker_btn_inactive")
                    self.btn_addSong.setTitleColor(self.selectedIndex != -1 ? UIColor.white : UIColor(named: "mcol_song_picker_lbl_inactive"), for: .normal)

                    v.setCate(tag: item as! String)
                    v.opSelectedAction = {
                        self.view.endEditing(true)
                        self.search(for: item as! String)
                    }
                }
            }),
            sizeSource: { (index: Int, item: Any, size: CGSize) -> CGSize in
                if item is Song{
                    return CGSize(width: size.width, height: 62)
                }
                else{
                    return CGSize(width: size.width, height: 40)
                }
            }
        )
    }
    
    func updateData(){
        if isShowingResults{
            searchResultsData.data = Array(searchResults.prefix(10))
        }
        else{
            searchResultsData.data = searchHints
        }
    }
    
    @IBAction func opAddSong(_ sender: Any) {
        if self.btn_addSong.title(for: .normal) == "Add Song"{
            //set song
            if let song = self.selectedSong{
                if let tokens = MusicKitTokens.shared.getTokens(), !tokens.country.isEmpty {
                    set(song: song, withCountry: tokens.country)
                } else {
                    SKCloudServiceController().requestStorefrontIdentifier { (code, error) in
                        if let code = code {
                            self.set(song: song, withCountry: code)
                        } else {
                            self.set(song: song, withCountry: "us")
                        }
                    }
                }
            }
        }
        else{
            //purchase slot and set song
            self.showError(title: "Error", msg: "Please purchase song slot first.")
        }
    }
    
    func set(song: Song, withCountry country: String) {
        let fSong = FirebaseSong(title: song.title, artist: song.artist, id: song.id, artworkUrl: song.artworkUrl.absoluteString, country: country)
        self.opSelectedSong?(fSong)

        dismiss(animated: true, completion: nil)
    }
    
    func search(for text: String) {
        Song.search(for: text) { (songs, error) in
            if let error = error {
                print("~>Got an error: \(error)")
                self.searchResults = []
                self.isShowingResults = false
                self.updateData()
                return
            } else if let songs = songs {
                self.searchResults = songs
                self.isShowingResults = true
                self.updateData()
                return
            } else {
                self.searchResults = []
                self.isShowingResults = false
                self.updateData()
                return
            }
        }
    }
    
}

// MARK: - Handle Search Bar
extension VC_SearchMusic: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
        isShowingResults = false
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.isEmpty else { return }
        searchBar.resignFirstResponder()
        search(for: text)
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        print("~>Cancel button clicked")
        searchBar.endEditing(true)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard searchText.count >= 2 else {
            searchHints = []
            self.updateData()
            return
        }
        
        guard !isSearching else { return }
        
        Song.getSearchHint(for: searchText) { (hints, error) in
            if let error = error {
                print("~>There was an error searching: \(error)")
                self.isSearching = false
                return
            }
            
            DispatchQueue.main.async {
                self.searchHints = hints
                self.updateData()
                self.isSearching = false
                return
            }
        }
    }
}
