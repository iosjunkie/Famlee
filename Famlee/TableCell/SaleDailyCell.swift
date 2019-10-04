//
//  SaleDailyCell.swift
//  Famlee
//
//  Created by Jules Lee on 29/09/2019.
//  Copyright © 2019 Jules Lee. All rights reserved.
//

import UIKit

// MARK -  SaleDailyCell
class SaleDailyCell: UITableViewCell {
    @IBOutlet weak var number: PaddingLabel!
    @IBOutlet weak var product: PaddingLabel!
    @IBOutlet weak var dateTime: PaddingLabel!
    @IBOutlet weak var quantity: PaddingLabel!
    @IBOutlet weak var price: PaddingLabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
