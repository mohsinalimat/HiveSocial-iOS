//
//  WebViewController.swift
//  HIVE
//
//  Created by Daniel Pratt on 10/3/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import UIKit
import WebKit

class VC_Web: UIViewController {
    
    @IBOutlet weak var webView: WKWebView!
    var urlToLoad: URL? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        initComponents()
    }
    
    func initComponents(){
        addSwipeRight()
        loadWebsite()
    }
    
    func loadWebsite() {
        guard let url = urlToLoad else {
            dismiss(animated: true, completion: nil)
            return
        }
        
        let request = URLRequest(url: url)
        webView.load(request)
    }

    @IBAction func opBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}
