//
//  ExpenseDailyCell.swift
//  Famlee
//
//  Created by Jules Lee on 29/09/2019.
//  Copyright © 2019 Jules Lee. All rights reserved.
//

import UIKit

// MARK -  ExpenseDailyCell
class ExpenseDailyCell: UITableViewCell {
    @IBOutlet weak var number: PaddingLabel!
    @IBOutlet weak var desc: PaddingLabel!
    @IBOutlet weak var price: PaddingLabel!
    @IBOutlet weak var dateTime: PaddingLabel!
    @IBOutlet weak var delete: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}

