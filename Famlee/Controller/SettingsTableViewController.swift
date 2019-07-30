//
//  SettingsTableViewController.swift
//  Famlee
//
//  Created by Jules Lee on 21/07/2019.
//  Copyright © 2019 Jules Lee. All rights reserved.
//

import UIKit
import Firebase

class SettingsTableViewController: UITableViewController {
    
    // lazies
    lazy var house: String = {
        return UserDefaults.standard.string(forKey: "house")!
    }()
    lazy var ref: DatabaseReference = {
        return Database.database().reference()
    }()
    
    var bedPrice: UITextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            extraBedPressed()
        case 1:
            switch indexPath.row {
            case 0:
                do {
                    try Auth.auth().signOut()
                } catch let signOutError as NSError {
                    print ("Error signing out: %@", signOutError)
                }
                performSegue(withIdentifier: "goToLogin", sender: self)
            default:
                return
            }
        default:
            return
        }
    }

    func extraBedPressed() {
        var currentBedPrice = 0
        ref.child("houses").child(house).child("extraBedPrice").observeSingleEvent(of: .value, with: { (snapshot) in
            currentBedPrice = Int(snapshot.value as! String)!
            self.bedPrice?.text = "\(currentBedPrice)"
        }) { (error) in
            return
        }
        // 1
        let optionMenu = UIAlertController(title: "Edit", message: "Are you sure you want to change the price of extra bed?", preferredStyle: .alert)
        
        // 2
        let saveAction = UIAlertAction(title: "Save", style: .default, handler: { (alert: UIAlertAction!) -> Void in
            self.ref.child("houses").child(self.house).updateChildValues([
                "extraBedPrice": self.bedPrice!.text!
                ])
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        // 4
        optionMenu.addTextField(configurationHandler: newBedPriceTextField)
        self.bedPrice?.keyboardType = .numberPad
        optionMenu.addAction(saveAction)
        optionMenu.addAction(cancelAction)
        
        // 5
        
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    func newBedPriceTextField(textField: UITextField) {
        bedPrice = textField
    }
}
