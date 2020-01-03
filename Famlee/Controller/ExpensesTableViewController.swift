//
//  ExpensesTableViewController.swift
//  Famlee
//
//  Created by Jules Lee on 22/07/2019.
//  Copyright © 2019 Jules Lee. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD

class ExpensesTableViewController: UITableViewController {
    
    // lazies
    lazy var ref: DatabaseReference = {
        return Database.database().reference()
    }()
    lazy var refresher: UIRefreshControl = {
        let refresherControl = UIRefreshControl()
        refresherControl.tintColor = UIColor.black
        refresherControl.addTarget(self, action: #selector(loadExpenses), for: .valueChanged)
        return refresherControl
    }()
    lazy var house: String = {
        return UserDefaults.standard.string(forKey: "house")!
    }()
    
    var expenses = [NSDictionary]()
    var currentYear = ""
    var currentMonth = 0
    var currentDay = ""
    
    @IBOutlet weak var pickDate: UITextField!
    @IBOutlet weak var totalExpenses: UILabel!
    var total : Float = 0
    let datePicker = UIDatePicker()
    
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
        pickDate.text = dateFormatter.string(from: date)
        
        SVProgressHUD.show(withStatus: "Loading Expenses")
        loadExpenses()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return expenses.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        
        var createdAtString = String(describing: expenses[indexPath.row]["createdAt"]!)
        let createdAt = Constants.sharedInstance.dateToTime(date: &createdAtString)
        let cell = tableView.dequeueReusableCell(withIdentifier: "expenseDailyCell", for: indexPath) as! ExpenseDailyCell
        cell.number.text = String(describing: expenses[indexPath.row]["number"]!)
        cell.desc.text = String(describing: expenses[indexPath.row]["description"]!)
        cell.dateTime.text = createdAt
        cell.price.text = numberFormatter.string(from: NSNumber(value: Float(expenses[indexPath.row]["price"] as! String)!))
        cell.delete.tag = indexPath.row
        return cell
    }

    @objc func loadExpenses() {
        let selectedDate = currentYear + "-\(currentMonth)-" + currentDay
        ref.child("houses").child(house).child("daily").child("expenses").child(selectedDate).observeSingleEvent(of: .value, with: { (snapshot) in
            defer {
                self.stopLoading()
            }

            // Reset aray
            self.total = 0
            self.expenses.removeAll()
            
            // If there are no expenses
            if !snapshot.hasChildren() {
                self.stopLoading()
                return
            }
            // If everything is normal
            if let expenses = snapshot.value as? NSDictionary {
                for expense in expenses {
                    //do your logic and validation here
                    self.expenses.append(expense.value as! NSDictionary)
                    self.expenses.last?.setValue(expense.key as! String, forKey: "id")
                    self.expenses.last?.setValue(selectedDate, forKey: "date")
                    self.total += Float(self.expenses.last!["price"] as! String)!
                }
                self.expenses = self.expenses.sorted(by: {($0["number"] as! Int) > ($1["number"] as! Int)})
            }
        }) { (error) in
            print(error.localizedDescription)
            self.stopLoading()
        }
    }
    
    func stopLoading() {
        tableView.reloadData()
        self.refresher.endRefreshing()
        if SVProgressHUD.isVisible() { SVProgressHUD.dismiss() }
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        self.totalExpenses.text = numberFormatter.string(from: NSNumber(value:self.total))
    }
    
    // MARK: - Finish picking date
    @objc func dateChanged() {
        Constants.sharedInstance.getDateFromPicker(textF: pickDate, picker: datePicker)
    }
    
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
        loadExpenses()
    }
    
    @IBAction func deletePressed(_ sender: UIButton) {
        // 1
        let thisExpense = expenses[sender.tag]["description"]
        let thisKey = expenses[sender.tag]["id"] as! String
        let date = expenses[sender.tag]["date"] as! String
        let optionMenu = UIAlertController(title: nil, message: "Are you sure you want to delete \(thisExpense!)?", preferredStyle: .actionSheet)
        
        // 2
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { (alert: UIAlertAction!) -> Void in
            print(date)
            print(thisKey)
            self.ref.child("houses").child(self.house).child("daily").child("expenses").child(date).child(thisKey).setValue(nil)
            self.loadExpenses()
        })
        
        // 4
        optionMenu.addAction(deleteAction)
        
        // 5
        
        optionMenu.popoverPresentationController?.sourceView = sender
        self.present(optionMenu, animated: true, completion: nil)
    }
}

