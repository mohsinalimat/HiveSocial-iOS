//
//  cell_search_tag.swift
//  HIVE
//
//  Created by elitemobile on 12/9/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import UIKit

class cell_search_tag: UITableViewCell {

    @IBOutlet weak var lbl_tag: UILabel!

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
