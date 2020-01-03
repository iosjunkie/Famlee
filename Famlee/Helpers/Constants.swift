//
//  Constants.swift
//  Famlee
//
//  Created by Jules Lee on 29/09/2019.
//  Copyright © 2019 Jules Lee. All rights reserved.
//

import UIKit
import Network
import SwiftMessages

class Constants {
    static var sharedInstance = Constants()
    
    func dateToTime(date: inout String) -> String {
        date.removeSubrange(date.range(of: "GMT")!.lowerBound ..< date.endIndex)
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "E MMM d yyyy HH:mm:ss"
        let formattedDate = dateFormatterGet.date(from: date)
        dateFormatterGet.dateFormat = "h:mm a"
        return dateFormatterGet.string(from: formattedDate!)
    }
    
    func dateToDay(date: inout String) -> String {
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
    
    func online(completion: @escaping (Bool) -> Void) {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue.global(qos: .background)
        monitor.start(queue: queue)
        monitor.pathUpdateHandler = { path in
          var err = true
          defer {
            DispatchQueue.main.async {
                completion(err)
            }
            monitor.cancel()
          }
          if path.status == .satisfied {
            err = false
          } else {
            err = true
          }
        }
    }
    
    func showError(message: String) {
        let error = MessageView.viewFromNib(layout: .statusLine)
        error.backgroundView.backgroundColor = UIColor.red
        error.bodyLabel?.textColor = UIColor.white
        error.configureContent(body: message)
        var status2Config = SwiftMessages.defaultConfig
        status2Config.presentationContext = .window(windowLevel: UIWindow.Level.normal)
        status2Config.preferredStatusBarStyle = .lightContent
        SwiftMessages.show(config: status2Config, view: error)
    }
    
    func showSuccess(message: String) {
        let success = MessageView.viewFromNib(layout: .statusLine)
        success.backgroundView.backgroundColor = UIColor.init(hexString: "56E491")
        success.bodyLabel?.textColor = UIColor.init(hexString: "128031")
        success.configureContent(body: message)
        var status2Config = SwiftMessages.defaultConfig
        status2Config.presentationContext = .window(windowLevel: UIWindow.Level.normal)
        status2Config.preferredStatusBarStyle = .lightContent
        SwiftMessages.show(config: status2Config, view: success)
    }
}
