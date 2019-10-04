//
//  RoomCell.swift
//  Famlee
//
//  Created by Jules Lee on 29/09/2019.
//  Copyright © 2019 Jules Lee. All rights reserved.
//

import UIKit

// MARK - Cell
class RoomsCell: UITableViewCell {
    @IBOutlet weak var roomNumber: PaddingLabel!
    @IBOutlet weak var desc: PaddingLabel!
    @IBOutlet weak var price: PaddingLabel!
    
    @IBOutlet weak var availability: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }

}
