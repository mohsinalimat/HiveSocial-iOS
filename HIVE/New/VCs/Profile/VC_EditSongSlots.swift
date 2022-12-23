//
//  VC_EditSongSlots.swift
//  HIVE
//
//  Created by elitemobile on 11/26/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import UIKit
import StoreKit
import CollectionKit

class VC_EditSongSlots: UIViewController {
    @IBOutlet weak var collectionView: CollectionView!
    @IBOutlet weak var btn_restore: UIButton!
    
    var products: [SKProduct] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        initComponents()
    }
    
    func initComponents(){
        loadStoreProducts()
        initData()
    }
    
    func initData(){
        btn_restore.makeRoundView(r: 4)
        let btnTxt = "Restore Purchases"
        let attributedStr = NSMutableAttributedString(string: btnTxt)
        attributedStr.addAttribute(NSAttributedString.Key.underlineColor, value: UIColor.active(), range: NSRange(location: 0, length: btnTxt.count))
        attributedStr.addAttribute(NSAttributedString.Key.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: btnTxt.count))
        btn_restore.setAttributedTitle(attributedStr, for: .normal)
        
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.clipsToBounds = true

        collectionView.provider = BasicProvider(
            dataSource: [1, 2, 3, 4],
            viewSource: ClosureViewSource(viewGenerator: { (item: Any, index: Int) -> cv_song_slot in
                let v = Bundle.main.loadNibNamed("cv_song_slot", owner: self, options: nil)?[0] as! cv_song_slot
                return v
            }, viewUpdater: { (v: cv_song_slot, item: Any, index: Int) in
                if Me.songs.count > index{
                    v.setupSong(song: Me.songs[index], slotPurchased: true, index: index)
                    v.opSelectedAction = {
                        self.openMusicSearchView(slotPurchased: true, index: index)
                    }
                }
                else{
                    var pIdentifier = ""
                    switch(index){
                    case 1:
                        pIdentifier = HIVEProducts.PlaylistTwo
                        v.setupSong(song: nil, slotPurchased: HIVEProducts.store.isProductPurchased(pIdentifier), index: index)
                        break
                    case 2:
                        pIdentifier = HIVEProducts.PlaylistThree
                        break
                    case 3:
                        pIdentifier = HIVEProducts.PlaylistFour
                        break
                    default:
                        break
                    }
                    let slotPurchased = HIVEProducts.store.isProductPurchased(pIdentifier)
                    v.setupSong(song: nil, slotPurchased: slotPurchased, index: index)

                    v.opSelectedAction = {
                        self.openMusicSearchView(slotPurchased: index == 0 || (index != 0 && HIVEProducts.store.isProductPurchased(pIdentifier)), index: index)
                    }
                }
                
            }),
            sizeSource: { (index: Int, item: Any, size: CGSize) -> CGSize in
                return CGSize(width: size.width, height: 62)
            }
        )
    }
    
    func openSlotPurchased(slotPurchased: Bool, index: Int){
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "VC_SearchMusic") as! VC_SearchMusic
        vc.modalPresentationStyle = .pageSheet
        vc.slotPurchased = slotPurchased
        vc.slotIndex = index
        vc.opSelectedSong = { fSong in
            if Me.songs.count > index{
                Me.songs[index] = fSong
            }
            else{
                Me.songs.append(fSong)
            }
            
            Me.updateSong()
            Me.saveLocal()
            
            self.collectionView.reloadData()
        }
        
        self.present(vc, animated: true, completion: nil)
    }
    
    func openMusicSearchView(slotPurchased: Bool, index: Int){
        if slotPurchased{
            self.openSlotPurchased(slotPurchased: slotPurchased, index: index)
        }
        else{
            self.setupHUD()
            var found: Bool = false
            for product in products {
                switch(index){
                case 1:
                    if product.productIdentifier == HIVEProducts.PlaylistTwo{
                        found = true
                        
                        HIVEProducts.store.buyProduct(product)
                        NotificationCenter.default.addObserver(forName: .IAPHelperPurchaseNotification, object: nil, queue: .main) { [weak self] (notification) in
                            guard let self = self else { return }
                            // remove the observer
                            NotificationCenter.default.removeObserver(self, name: .IAPHelperPurchaseNotification, object: nil)
                            self.openSlotPurchased(slotPurchased: true, index: index)
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.hideHUD()
                        }
                    }
                    break
                case 2:
                    if product.productIdentifier == HIVEProducts.PlaylistThree{
                        found = true
                        
                        HIVEProducts.store.buyProduct(product)
                        NotificationCenter.default.addObserver(forName: .IAPHelperPurchaseNotification, object: nil, queue: .main) { [weak self] (notification) in
                            guard let self = self else { return }
                            // remove the observer
                            NotificationCenter.default.removeObserver(self, name: .IAPHelperPurchaseNotification, object: nil)
                            self.openSlotPurchased(slotPurchased: true, index: index)
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.hideHUD()
                        }
                    }
                    break
                case 3:
                    if product.productIdentifier == HIVEProducts.PlaylistFour{
                        found = true
                        
                        HIVEProducts.store.buyProduct(product)
                        NotificationCenter.default.addObserver(forName: .IAPHelperPurchaseNotification, object: nil, queue: .main) { [weak self] (notification) in
                            guard let self = self else { return }
                            // remove the observer
                            NotificationCenter.default.removeObserver(self, name: .IAPHelperPurchaseNotification, object: nil)
                            self.openSlotPurchased(slotPurchased: true, index: index)
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.hideHUD()
                        }
                    }
                    break
                default:
                    break
                }
            }
            
            if !found {
                self.hideHUD()
                self.loadStoreProducts()
            }
        }
    }

    @IBAction func opRestore(_ sender: Any) {
        HIVEProducts.store.restorePurchases()

        self.setupHUD(msg: "Restoring...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.hideHUD()
            
            self.collectionView.reloadData()
        }
    }
    
    func loadStoreProducts() {
        HIVEProducts.store.requestProducts { [weak self] (success, products) in
            guard let self = self else { return }
            if success, let loadedProducts = products {
                self.products = loadedProducts
                
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            }
        }
    }
}
