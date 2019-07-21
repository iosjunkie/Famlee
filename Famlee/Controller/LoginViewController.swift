//
//  LoginViewController.swift
//  Famlee
//
//  Created by Jules Lee on 21/07/2019.
//  Copyright © 2019 Jules Lee. All rights reserved.
//

import UIKit
import Alamofire
import Firebase
import ChameleonFramework

class LoginViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var housePick: UIPickerView!
    @IBOutlet weak var scrollView: UIScrollView!
    var ref: DatabaseReference!
    var houses: [String] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        
        housePick.delegate = self
        housePick.dataSource = self
    
        
        // If there is internet
        if NetworkReachabilityManager()!.isReachable {
            ref.child("houses").observeSingleEvent(of: .value, with: { (snapshot) in
                // Get user value
                if let value = snapshot.value as? NSDictionary {
                    self.houses = (value.allKeys as! [String])
                    self.housePick.reloadComponent(0)
                    self.loginButton.isEnabled = true
                }
            }) { (error) in
                print(error.localizedDescription)
            }
        }
        
    }
    
    // Disable horizontal scrolling
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if scrollView.contentOffset.x>0 {
            scrollView.contentOffset.x = 0
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if Auth.auth().currentUser == nil {
            // Do any additional setup after loading the view.
            password.delegate = self
            password.becomeFirstResponder()
        } else {
            performSegue(withIdentifier: "goToDash", sender: self)
        }
        
        for i in [1, 2] {
            housePick.subviews[i].isHidden = true
        }
        
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        scrollView.contentOffset = password.frame.origin
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return houses.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return houses[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel = view as! UILabel?
        if view == nil {  //if no label there yet
            pickerLabel = UILabel()
        }
        let titleData = houses[row]
        let myTitle = NSAttributedString(string: titleData, attributes: [NSAttributedString.Key.font:UIFont(name: "Didot", size: 40.0)!,NSAttributedString.Key.foregroundColor:UIColor(hexString: "D2A75F") as Any])
        pickerLabel!.attributedText = myTitle
        pickerLabel!.textAlignment = .left
        
        return pickerLabel!
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 80.0
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        attemptLogin()
        return false
    }

    @IBAction func loginPressed(_ sender: UIButton) {
        attemptLogin()
    }
    
    func attemptLogin () {
        if houses.count != 0 {
            password.resignFirstResponder()
            Auth.auth().signIn(withEmail: "thefosterblue@me.com", password: password.text ?? "") { [weak self] user, error in
                guard let strongSelf = self else {
                    print("Failed Self")
                    self?.password.becomeFirstResponder()
                    return
                }
                if error != nil {
                    print("Failed")
                    self?.password.becomeFirstResponder()
                    return
                }
                UserDefaults.standard.set(self!.houses[self!.housePick.selectedRow(inComponent: 0)], forKey: "house")
                
                self!.performSegue(withIdentifier: "goToDash", sender: self)
                // ...
            }
        }
    }
}