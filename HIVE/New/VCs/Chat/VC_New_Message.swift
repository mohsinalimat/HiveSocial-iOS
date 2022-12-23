//
//  VC_New_Message.swift
//  HIVE
//
//  Created by elitemobile on 11/11/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import UIKit
import CollectionKit
import Firebase

class VC_New_Message: UIViewController {

    @IBOutlet weak var collectionView: CollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var btn_send: UIButton!
    @IBOutlet weak var v_searchBar: UIView!
    
    var isTypingSearch: Bool = false
    var isSearching: Bool = false
    
    var opSendMessageAction: ((User, String) -> Void)?
    var selectedUser: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initComponents()
    }
    
    func initComponents(){
        btn_send.makeRoundView(r: 4)
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
        
        loadUsers()
    }
    
    var usersDataSource: ArrayDataSource<User>! = ArrayDataSource<User>()
    var selectedIndex = -1
    func loadUsers(){
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.clipsToBounds = true
        collectionView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        collectionView.removeGestureRecognizer(collectionView.tapGestureRecognizer)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        
        collectionView.provider = BasicProvider(
            dataSource: usersDataSource,
            viewSource: ClosureViewSource(viewGenerator: { (usr: User, index: Int) -> cv_new_chat_user in
                let v = Bundle.main.loadNibNamed("cv_new_chat_user", owner: self, options: nil)?[0] as! cv_new_chat_user
                return v
            }, viewUpdater: { (v: cv_new_chat_user, usr: User, index: Int) in
                v.setUser(usr: usr)
                v.chk_checked.setOn(self.selectedIndex == index, animated: self.selectedIndex == index)
                self.btn_send.backgroundColor = UIColor(named: self.selectedIndex != -1 ? "col_btn_send_active" : "col_btn_send")
                
                v.opSelectedAction = {
                    self.selectedUser = usr
                    self.selectedIndex = index
                    self.collectionView.reloadData()
                }
            }),
            sizeSource: { (index: Int, usr: User, size: CGSize) -> CGSize in
                return CGSize(width: size.width, height: 53)
            },
            layout: FlowLayout(spacing: 4)
        )
        
        collectionView.es.addPullToRefresh {
            self.collectionView.reloadData()
            DispatchQueue.main.async {
                self.collectionView.es.stopPullToRefresh()
            }
        }
        loadData()
    }

    var users: [User] = []
    var stepCount: Int = 20
    func loadData(){
        guard let uid = CUID else { return }
        FUSER_REF
            .document(uid)
            .collection(User.key_collection_following)
            .order(by: User.key_uid, descending: false)
            .limit(to: stepCount)
            .getDocuments { (doc, err) in
                if let error = err{
                    print(error.localizedDescription)
                    return
                }
                
                doc?.documentChanges.forEach({ (item) in
                    switch(item.type){
                        case .added:
                            Utils.fetchUser(uid: item.document.documentID) { (rusr) in
                                guard let usr = rusr else { return }

                                self.users.append(usr)
                                self.updateList()
                            }
                            break
                        case .modified:
                            break
                        case .removed:
                            break
                    }
                })
                
                self.collectionView.es.addInfiniteScrolling {
                    if !self.isLoadingMore && !self.isTypingSearch{
                        self.isLoadingMore = true
                        self.loadMoreData()
                    }
                }
            }
    }
    
    var isLoadingMore: Bool = false
    var lastKey: String = ""
    func loadMoreData(){
        guard let uid = CUID else { return }
        guard let lKey = self.users.sorted(by: { (u1, u2) -> Bool in
            u1.uid < u2.uid
        }).last?.uid else {
            self.isLoadingMore = false
            self.collectionView.es.stopLoadingMore()
            return
        }
        
        if lastKey == lKey{
            self.isLoadingMore = false
            self.collectionView.es.stopLoadingMore()
            return
        }
        
        lastKey = lKey
        
        FUSER_REF
            .document(uid)
            .collection(User.key_collection_following)
            .order(by: User.key_uid, descending: false)
            .whereField(User.key_uid, isGreaterThan: lKey)
            .limit(to: stepCount)
            .getDocuments { (doc, err) in
                if let error = err{
                    print(error.localizedDescription)
                    self.isLoadingMore = false
                    self.collectionView.es.stopLoadingMore()
                    return
                }
                
                doc?.documentChanges.forEach({ (item) in
                    switch(item.type){
                        case .added:
                            Utils.fetchUser(uid: item.document.documentID) { (rusr) in
                                guard let usr = rusr else { return }
                                self.users.append(usr)
                                self.updateList()
                            }
                            break
                        case .modified:
                            break
                        case .removed:
                            break
                    }
                })
                DispatchQueue.main.async {
                    self.isLoadingMore = false
                    self.collectionView.es.stopLoadingMore()
                    
                    if doc?.documents.count ?? 0 == 0{
                        self.collectionView.es.noticeNoMoreData()
                    }
                }
            }
    }
    
    func updateList(){
        self.usersDataSource.data = self.users
    }

    @IBAction func opSendMessage(_ sender: Any) {
        guard let usr = selectedUser else { return }
        let msg: String = ""//txt_msg.text!
        
        self.opSendMessageAction?(usr, msg)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func opBack(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    var searchedUsers: [User] = []
    func searchUsers(text: String){
        if isSearching{
            return
        }
        isSearching = true
        let endTxt: String = text + "\u{f8ff}"

        FUSER_REF
            .whereField(User.key_uname, isGreaterThanOrEqualTo: text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))
            .whereField(User.key_uname, isLessThanOrEqualTo: endTxt.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))
            .getDocuments { (doc, err) in
                if let error = err{
                    self.isSearching = false
                    print(error.localizedDescription)
                    return
                }

                self.searchedUsers.removeAll()
                doc?.documents.forEach({ (item) in
                    let usr = User(uid: item.documentID, data: item.data())
                    self.searchedUsers.append(usr)
                })
                
                self.usersDataSource.data = self.searchedUsers
                self.isSearching = false
            }
    }
}

extension VC_New_Message: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
        isTypingSearch = true
        
        self.usersDataSource.data = self.users
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.isEmpty else { return }
        searchBar.resignFirstResponder()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
        isTypingSearch = false
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        print("~>Cancel button clicked")
        searchBar.endEditing(true)
        isTypingSearch = false
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard searchText.count >= 2 else {
            self.usersDataSource.data = self.users
            return
        }
        
        self.searchUsers(text: searchText)
    }
}
