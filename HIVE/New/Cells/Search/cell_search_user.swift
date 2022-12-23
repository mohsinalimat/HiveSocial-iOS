//
//  cell_search_user.swift
//  HIVE
//
//  Created by elitemobile on 12/9/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import UIKit

class cell_search_user: UITableViewCell {
    
    @IBOutlet weak var img_Profile: UIImageView!
    @IBOutlet weak var lbl_username: UILabel!
    
    var opSelectAction: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func opSelect(_ sender: Any) {
        opSelectAction?()
    }
}
