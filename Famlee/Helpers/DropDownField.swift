//
//  DropDownField.swift
//  Famlee
//
//  Created by Jules Lee on 29/09/2019.
//  Copyright © 2019 Jules Lee. All rights reserved.
//

import UIKit

struct DropDownField {
    var x: Int = 20
    var y: Int = 100
    var width: Int = 300
    var height: Int = 40
    var placeholder: String = ""
    var text: String = ""
    var num: Bool = false
    
    func uiTextF() -> UITextField {
        let tf = UITextField(frame: CGRect(x: x, y: y, width: width, height: height))
        tf.keyboardType = num ? .numberPad : .default
        tf.text = text
        return tf
    }
}
