//
//  DropDownMenuCell.swift
//  Famlee
//
//  Created by Jules Lee on 29/09/2019.
//  Copyright © 2019 Jules Lee. All rights reserved.
//

import UIKit
import DropDownMenuKit

extension DropDownMenuCell {
    
    convenience init(image: String, textField: DropDownField) {
        self.init()
        
        customView = textField.uiTextF()
        imageView!.image = UIImage(named: image)
        imageView!.tintColor = UIColor.flatBlue()
    }
}
