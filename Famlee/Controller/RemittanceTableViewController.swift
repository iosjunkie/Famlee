//
//  RemittanceTableViewController.swift
//  Famlee
//
//  Created by Jules Lee on 25/07/2019.
//  Copyright © 2019 Jules Lee. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD
import MonthYearPicker

class RemittanceTableViewController: UITableViewController {
    
    // Lazies
    lazy var ref: DatabaseReference = {
        return Database.database().reference()
    }()
    lazy var house: String = {
        return UserDefaults.standard.string(forKey: "house")!
    }()
    lazy var refresher: UIRefreshControl = {
        let refresherControl = UIRefreshControl()
        refresherControl.tintColor = UIColor.black
        refresherControl.addTarget(self, action: #selector(loadRemittances), for: .valueChanged)
        return refresherControl
    }()
    lazy var datePicker: MonthYearPickerView = {
        return MonthYearPickerView(frame: CGRect(x: 0, y: 0,  width: self.view.frame.size.width, height: 250))
    }()
    
    var remittances = [NSDictionary]()
    var currentYear = ""
    var currentMonth = 0
    var total : Float = 0
    
    @IBOutlet weak var pickMonthAndYear: UITextField!
    @IBOutlet weak var totalRemittances: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.rowHeight = 55.0
        self.tableView.refreshControl = refresher
        
        //init toolbar
        let toolbar:UIToolbar = {
            let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0,  width: self.view.frame.size.width, height: 30))
            //create left side empty space so that done button set on right side
            let flexSpace = UIBarButtonItem(barButtonSystemItem:    .flexibleSpace, target: nil, action: nil)
            let doneBtn: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonAction))
            toolbar.setItems([flexSpace, doneBtn], animated: false)
            toolbar.sizeToFit()
            return toolbar
        }()
        
        pickMonthAndYear.inputView = datePicker
        pickMonthAndYear.inputAccessoryView = toolbar
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        currentYear = dateFormatter.string(from: date)
        dateFormatter.dateFormat = "M"
        currentMonth = Int(dateFormatter.string(from: date))!-1
        dateFormatter.dateFormat = "MMMM yyyy"
        pickMonthAndYear.text = dateFormatter.string(from: date)
        
        loadRemittances()
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return remittances.count
    }
    

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        
        var createdAtString = String(describing: remittances[indexPath.row]["createdAt"]!)
        let createdAt = Constants.sharedInstance.dateToDay(date: &createdAtString)
        let cell = tableView.dequeueReusableCell(withIdentifier: "remittanceDailyCell", for: indexPath) as! RemittanceDailyCell
        cell.number.text = String(describing: remittances[indexPath.row]["number"]!)
        cell.dateTime.text = createdAt
        cell.amount.text = numberFormatter.string(from: NSNumber(value: remittances[indexPath.row]["amount"] as! Float))
        return cell
    }


    @objc func loadRemittances() {
        SVProgressHUD.show(withStatus: "Loading Remittances")

        let selectedYearAndMonth = "\(currentYear)-\(currentMonth)"
        for day in 1 ... daysInMonth() {
            DispatchQueue.global(qos: .background).async {
            self.ref.child("houses").child(self.house).child("daily").child("encash").child("\(selectedYearAndMonth)-\(day)").observeSingleEvent(of: .value, with: { (snapshot) in
                if day == 1 { // This is needed to prevent index out of range
                    self.total = 0
                    self.remittances.removeAll()
                }
                if let remits = snapshot.value as? NSDictionary {
                    for remit in remits {
                        //do your logic and validation here
                        self.remittances.append(remit.value as! NSDictionary)
                        self.remittances.last?.setValue(remit.key as! String, forKey: "id")
                        self.remittances.last?.setValue("\(selectedYearAndMonth)-\(day)", forKey: "date")
                        self.total += self.remittances.last!["amount"] as! Float
                    }
                }
                if day == self.daysInMonth(){
                    self.stopLoading()
                }
                    // ...
                }) { (error) in
                    print(error.localizedDescription)
                    self.stopLoading()
                }
            }
        }
    }
    
    func daysInMonth() -> Int {
        let dateComponents = DateComponents(year: Int(currentYear), month: currentMonth+1)
        let calendar = Calendar.current
        let date = calendar.date(from: dateComponents)!
        
        let range = calendar.range(of: .day, in: .month, for: date)!
        return range.count
    }
    
    func stopLoading() {
        DispatchQueue.main.async {
            self.remittances = self.remittances.sorted(by: {($0["number"] as! Int) > ($1["number"] as! Int)})
            self.tableView.reloadData()
            self.refresher.endRefreshing()
            if SVProgressHUD.isVisible() { SVProgressHUD.dismiss() }
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .currency
            self.totalRemittances.text = numberFormatter.string(from: NSNumber(value:self.total))
        }
    }
    
    // MARK: - Finish picking date
    @objc func dateChanged() {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        pickMonthAndYear.text = formatter.string(from: datePicker.date)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        changeContentsAccdgToDate()
        view.endEditing(true)
    }
    
    @objc func doneButtonAction() {
        changeContentsAccdgToDate()
        view.endEditing(true)
    }
    
    func changeContentsAccdgToDate() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        currentYear = dateFormatter.string(from: datePicker.date)
        dateFormatter.dateFormat = "M"
        currentMonth = Int(dateFormatter.string(from: datePicker.date))!-1
        
        loadRemittances()
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let id = remittances[indexPath.row]["id"]
        let date = remittances[indexPath.row]["date"] as! String
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            let optionMenu = UIAlertController(title: nil, message: "Are you sure you want to delete \(self.remittances[indexPath.row]["number"]!)?", preferredStyle: .actionSheet)
            
            // 2
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { (alert: UIAlertAction!) -> Void in
                self.ref.child("houses").child(self.house).child("daily").child("encash").child(date).child(id as! String).setValue(nil)
                self.remittances.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .right)
            })
            
            // 4
            optionMenu.addAction(deleteAction)
            
            // 5
            
            optionMenu.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
            self.present(optionMenu, animated: true, completion: nil)
        }
        
        return [delete]
    }
}

