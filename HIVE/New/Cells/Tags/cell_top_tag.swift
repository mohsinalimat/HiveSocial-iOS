//
//  cell_top_tag.swift
//  HIVE
//
//  Created by elitemobile on 1/7/20.
//  Copyright © 2020 Kassy Pop. All rights reserved.
//

import UIKit

class cell_top_tag: UITableViewCell {
    @IBOutlet weak var lbl_tag_name: UILabel!
    @IBOutlet weak var lbl_posts_count: UILabel!
    
    var opOpenAction: (() -> Void)?
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initComponents()
    }
    
    func initComponents(){
        
    }

    func setTrendingTag(tt: TrendingTag){
        lbl_tag_name.text = tt.tag
        self.lbl_posts_count.text = "\(tt.count) posts"
    }
    
    @IBAction func opOpen(_ sender: Any) {
        opOpenAction?()
    }
}
