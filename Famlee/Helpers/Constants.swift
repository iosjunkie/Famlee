//
//  Constants.swift
//  Famlee
//
//  Created by Jules Lee on 29/09/2019.
//  Copyright © 2019 Jules Lee. All rights reserved.
//

import UIKit

class Constants {
    static var sharedInstance = Constants()
    
    func dateToTime(date: inout String) -> String {
        date.removeSubrange(date.range(of: "GMT")!.lowerBound ..< date.endIndex)
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "E MMM d yyyy HH:mm:ss"
        let formattedDate = dateFormatterGet.date(from: date)
        dateFormatterGet.dateFormat = "MMM d"
        return dateFormatterGet.string(from: formattedDate!)
    }
    
    func getDateFromPicker(textF: UITextField, picker: UIDatePicker) {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        textF.text = formatter.string(from: picker.date)
    }
    
    func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
}
