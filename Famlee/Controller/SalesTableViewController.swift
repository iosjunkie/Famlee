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
    
    var done = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.rowHeight = 55.0
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(sortAndStopLoading(n:)), name: NSNotification.Name.init("done"), object: nil)
        loadSales()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.init("done"), object: nil)
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
        SVProgressHUD.show(withStatus: "Loading Sales")
        
        // Reset Array
        
        self.totalMerch = 0
        self.totalRoom = 0
        self.totalSale = 0
    
        let selectedDate = currentYear + "-\(currentMonth)-" + currentDay
        
        // Reset done
        downloadMerch(selectedDate: selectedDate) { (err) in
            guard err == false else {
                // Call done the 2nd time to stop it from loading
                NotificationCenter.default.post(name: NSNotification.Name.init("done"), object: nil)
                return
            }
            self.downloadRooms(selectedDate: selectedDate)
        }
    }
    
    @objc func sortAndStopLoading(n: NSNotification) {
        done += 1
        
        if done == 2 {
            self.sales = self.sales.sorted(by: {($0["number"] as! Int) > ($1["number"] as! Int)})
            DispatchQueue.main.async {
                self.stopLoading()
            }
        }
    }
    
    func downloadMerch(selectedDate: String, completion: @escaping (Bool) -> ()) {
        ref.child("houses").child(house).child("daily").child("merchandises").child(selectedDate).observeSingleEvent(of: .value, with: { (snapshot1) in
            var err = false
            defer {
                NotificationCenter.default.post(name: NSNotification.Name.init("done"), object: nil)
                completion(err)
            }
            self.sales.removeAll()
            // If there are buyers
            if snapshot1.hasChildren() {
                // If there are sales
                if let merchandises = snapshot1.value as? NSDictionary {
                    for merchandise in merchandises {
                        //do your logic and validation here
                        self.sales.append(merchandise.value as! NSDictionary)
                        self.totalMerch += self.sales.last!["amount"] as? Float ?? self.sales.last!["price"] as! Float
                        self.totalSale += self.sales.last!["amount"] as? Float ?? self.sales.last!["price"] as! Float
                    }
                    err = false
                } else { err = true }
            } else { err = false }
        }) { (error) in
            NotificationCenter.default.post(name: NSNotification.Name.init("done"), object: nil)
            print(error.localizedDescription)
            completion(true)
        }
    }
    
    func downloadRooms(selectedDate: String) {
        self.ref.child("houses").child(self.house).child("daily").child("rooms").child(selectedDate).observeSingleEvent(of: .value, with: { (snapshot2) in
            defer {
                NotificationCenter.default.post(name: NSNotification.Name.init("done"), object: nil)
            }
            // If there are checkins
            if snapshot2.hasChildren() {
                // Get user value
                if let rooms = snapshot2.value as? NSDictionary {
                    for room in rooms {
                        //do your logic and validation here
                        self.sales.append(room.value as! NSDictionary)
                        self.totalRoom += self.sales.last!["amount"] as? Float ?? self.sales.last!["price"] as! Float
                        self.totalSale += self.sales.last!["amount"] as? Float ?? self.sales.last!["price"] as! Float
                    }
                }
            }
        }) { (error) in
            NotificationCenter.default.post(name: NSNotification.Name.init("done"), object: nil)
            print(error.localizedDescription)
        }
    }
    
    func stopLoading() {
        if sales.count > 0 {
            self.tableView.reloadData()
        } else {
            Constants.sharedInstance.showError(message: "No records found!")
        }
        self.refresher.endRefreshing()
        if SVProgressHUD.isVisible() { SVProgressHUD.dismiss() }
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        totalSales.text = numberFormatter.string(from: NSNumber(value:totalSale))
        totalMerchandise.text = numberFormatter.string(from: NSNumber(value:totalMerch))
        totalRooms.text = numberFormatter.string(from: NSNumber(value:totalRoom))
        
        // reset done
        done = 0
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
