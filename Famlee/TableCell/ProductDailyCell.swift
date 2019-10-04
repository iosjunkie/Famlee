//
//  ProductDailyCell.swift
//  Famlee
//
//  Created by Jules Lee on 29/09/2019.
//  Copyright © 2019 Jules Lee. All rights reserved.
//

import UIKit

class ProductDailyCell: UITableViewCell{
    @IBOutlet weak var item: PaddingLabel!
    @IBOutlet weak var price: PaddingLabel!
    @IBOutlet weak var quantity: PaddingLabel!
    @IBOutlet weak var tq: PaddingLabel!
    @IBOutlet weak var approve: UISwitch!
    @IBOutlet weak var delete: UIButton!
    // @IBOutlet weak var added: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}

func statusBarHeight() -> CGFloat {
    let statusBarSize = UIApplication.shared.statusBarFrame.size
    return min(statusBarSize.width, statusBarSize.height)
}
