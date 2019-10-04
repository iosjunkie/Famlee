//
//  SalesTableViewController.swift
//  Famlee
//
//  Created by Jules Lee on 21/07/2019.
//  Copyright © 2019 Jules Lee. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD

class SalesTableViewController: UITableViewController {
    
    // lazies
    lazy var ref: DatabaseReference = {
        return Database.database().reference()
    }()
    lazy var refresher: UIRefreshControl = {
        let refresherControl = UIRefreshControl()
        refresherControl.tintColor = UIColor.black
        refresherControl.addTarget(self, action: #selector(loadSales), for: .valueChanged)
        return refresherControl
    }()
    lazy var house: String = {
        return UserDefaults.standard.string(forKey: "house")!
    }()
    
    var sales = [NSDictionary]()
    var currentYear = ""
    var currentMonth = 0
    var currentDay = ""
    
    @IBOutlet weak var pickDate: UITextField!
    let datePicker = UIDatePicker()
    
    // Summary
    @IBOutlet weak var totalMerchandise: UILabel!
    @IBOutlet weak var totalRooms: UILabel!
    @IBOutlet weak var totalSales: UILabel!
    var totalMerch : Float = 0
    var totalRoom : Float = 0
    var totalSale : Float = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.rowHeight = 55.0
        self.tableView.separatorStyle = .none
        self.tableView.refreshControl = refresher
        
        //init toolbar
        let toolbar:UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0,  width: self.view.frame.size.width, height: 30))
        //create left side empty space so that done button set on right side
        let flexSpace = UIBarButtonItem(barButtonSystemItem:    .flexibleSpace, target: nil, action: nil)
        let doneBtn: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonAction))
        toolbar.setItems([flexSpace, doneBtn], animated: false)
        toolbar.sizeToFit()
        
        pickDate.inputView = datePicker
        pickDate.inputAccessoryView = toolbar
        datePicker.datePickerMode = .date
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        currentYear = dateFormatter.string(from: date)
        dateFormatter.dateFormat = "M"
        currentMonth = Int(dateFormatter.string(from: date))!-1
        dateFormatter.dateFormat = "d"
        currentDay = dateFormatter.string(from: date)
        dateFormatter.dateFormat = "MMMM d, yyyy"
        pickDate.text = dateFormatter.string(from: datePicker.date)
        
        SVProgressHUD.show(withStatus: "Loading Sales")
        loadSales()
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sales.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var productLabel = ""
        if String(describing: sales[indexPath.row]["category"]!) == "product" {
            productLabel = String(describing: sales[indexPath.row]["product"]!)
        } else {
            productLabel = String(describing: sales[indexPath.row]["description"]!)
        }
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        
        var createdAtString = String(describing: sales[indexPath.row]["createdAt"]!)
        let createdAt = Constants.sharedInstance.dateToTime(date: &createdAtString)
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "saleDailyCell", for: indexPath) as! SaleDailyCell
        cell.number.text = String(describing: sales[indexPath.row]["number"]!)
        cell.product.text = productLabel
        cell.price.text = numberFormatter.string(from: NSNumber(value: sales[indexPath.row]["amount"] as? Float ?? sales[indexPath.row]["price"] as! Float))
        cell.quantity.text = String(describing: sales[indexPath.row]["quantity"]!)
        cell.dateTime.text = createdAt
        return cell
    }
    
    @objc func loadSales() {
        let selectedDate = currentYear + "-\(currentMonth)-" + currentDay

        ref.child("houses").child(house).child("daily").child("merchandises").child(selectedDate).observeSingleEvent(of: .value, with: { (snapshot1) in
            // Reset the array
            self.sales.removeAll()
            self.totalMerch = 0
            self.totalRoom = 0
            self.totalSale = 0
            // If no one has bought anything in yet
            if !snapshot1.hasChildren() {
                self.stopLoading()
                return
            }
            // If there are sales
            if let merchandises = snapshot1.value as? NSDictionary {
                for merchandise in merchandises {
                    //do your logic and validation here
                    self.sales.append(merchandise.value as! NSDictionary)
                    self.totalMerch += self.sales.last!["amount"] as? Float ?? self.sales.last!["price"] as! Float
                    self.totalSale += self.sales.last!["amount"] as? Float ?? self.sales.last!["price"] as! Float
                }
                self.ref.child("houses").child(self.house).child("daily").child("rooms").child(selectedDate).observeSingleEvent(of: .value, with: { (snapshot2) in
                    // If no one has checked in yet therefore, stop the laoding
                    if !snapshot2.hasChildren() {
                        self.stopLoading()
                        return
                    }
                    // Get user value
                    if let rooms = snapshot2.value as? NSDictionary {
                        for room in rooms {
                            //do your logic and validation here
                            self.sales.append(room.value as! NSDictionary)
                            self.totalRoom += self.sales.last!["amount"] as? Float ?? self.sales.last!["price"] as! Float
                            self.totalSale += self.sales.last!["amount"] as? Float ?? self.sales.last!["price"] as! Float
                        }
                        // Successfully appeneded rooms
                        self.sales = self.sales.sorted(by: {($0["number"] as? Int ?? 0) > ($1["number"] as? Int ?? 0)})
                        self.stopLoading()
                    }
                }) { (error) in
                    // If rooms cannot be loaded
                    print(error.localizedDescription)
                    self.sales = self.sales.sorted(by: {($0["number"] as! Int) > ($1["number"] as! Int)})
                    self.stopLoading()
                }
            } else {
                self.stopLoading()
            }
        }) { (error) in
            print(error.localizedDescription)
            self.stopLoading()
        }
    }
    
    func stopLoading() {
        self.tableView.reloadData()
        self.refresher.endRefreshing()
        if SVProgressHUD.isVisible() { SVProgressHUD.dismiss() }
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        totalSales.text = numberFormatter.string(from: NSNumber(value:totalSale))
        totalMerchandise.text = numberFormatter.string(from: NSNumber(value:totalMerch))
        totalRooms.text = numberFormatter.string(from: NSNumber(value:totalRoom))
    }
    
    @objc func dateChanged() {
        Constants.sharedInstance.getDateFromPicker(textF: pickDate, picker: datePicker)
    }
    
    // MARK: - Finish picking date
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        changeContentsAccdgToDate()
        view.endEditing(true)
    }
    
    @objc func doneButtonAction() {
        changeContentsAccdgToDate()
        self.view.endEditing(true)
    }
    
    func changeContentsAccdgToDate() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        currentYear = dateFormatter.string(from: datePicker.date)
        dateFormatter.dateFormat = "M"
        currentMonth = Int(dateFormatter.string(from: datePicker.date))!-1
        dateFormatter.dateFormat = "d"
        currentDay = dateFormatter.string(from: datePicker.date)
        
        SVProgressHUD.show(withStatus: "Loading Sales")
        loadSales()
    }
}
