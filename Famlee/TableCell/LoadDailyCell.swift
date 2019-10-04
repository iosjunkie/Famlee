//
//  LoadDailyCell.swift
//  Famlee
//
//  Created by Jules Lee on 29/09/2019.
//  Copyright © 2019 Jules Lee. All rights reserved.
//

import UIKit

// MARK: - LOAD TABLE VIEW CELL
class LoadDailyCell: UITableViewCell {
    @IBOutlet weak var number: PaddingLabel!
    @IBOutlet weak var phone: PaddingLabel!
    @IBOutlet weak var amount: PaddingLabel!
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
    @IBAction func deletePressed(_ sender: UIButton) {
    }
}
