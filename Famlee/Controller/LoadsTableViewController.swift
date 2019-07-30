//
//  LoadsTableViewController.swift
//  Famlee
//
//  Created by Jules Lee on 23/07/2019.
//  Copyright © 2019 Jules Lee. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD

class LoadsTableViewController: UITableViewController {

    // lazies
    lazy var ref: DatabaseReference = {
        return Database.database().reference()
    }()
    lazy var refresher: UIRefreshControl = {
        let refresherControl = UIRefreshControl()
        refresherControl.tintColor = UIColor.black
        refresherControl.addTarget(self, action: #selector(loadLoads), for: .valueChanged)
        return refresherControl
    }()
    lazy var house: String = {
        return UserDefaults.standard.string(forKey: "house")!
    }()
    
    var loads = [NSDictionary]()
    var currentYear = ""
    var currentMonth = 0
    var currentDay = ""
    
    @IBOutlet weak var totalLoad: UILabel!
    @IBOutlet weak var pickDate: UITextField!
    var total : Float = 0
    let datePicker = UIDatePicker()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.rowHeight = 55.0
        self.tableView.separatorStyle = .none
        self.tableView.refreshControl = refresher
        
        //init toolbar
        let toolbar:UIToolbar =  {
            let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0,  width: self.view.frame.size.width, height: 30))
            //create left side empty space so that done button set on right side
            let flexSpace = UIBarButtonItem(barButtonSystemItem:    .flexibleSpace, target: nil, action: nil)
            let doneBtn: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonAction))
            toolbar.setItems([flexSpace, doneBtn], animated: false)
            toolbar.sizeToFit()
            return toolbar
        }()
        
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
        
        SVProgressHUD.show(withStatus: "Loading Loads")
        loadLoads()
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return loads.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        
        var createdAtString = String(describing: loads[indexPath.row]["createdAt"]!)
        var createdAt = dateToTime(date: &createdAtString)
        let cell = tableView.dequeueReusableCell(withIdentifier: "loadDailyCell", for: indexPath) as! LoadDailyCell
        cell.number.text = String(describing: loads[indexPath.row]["number"]!)
        cell.phone.text = String(describing: loads[indexPath.row]["cell"]!)
        cell.dateTime.text = createdAt
        cell.amount.text = numberFormatter.string(from: NSNumber(value: Float(loads[indexPath.row]["amount"] as! String)!))
        cell.delete.tag = indexPath.row
        return cell
    }


    @objc func loadLoads() {
        let selectedDate = currentYear + "-\(currentMonth)-" + currentDay
        ref.child("houses").child(house).child("daily").child("loader").child(selectedDate).observeSingleEvent(of: .value, with: { (snapshot) in
            // Reset array
            self.total = 0
            self.loads.removeAll()
            // If there are no people buying load
            if !snapshot.hasChildren() {
                self.stopLoading()
                return
            }
            
            // If everything is normal
            if let loads = snapshot.value as? NSDictionary {
                for load in loads {
                    //do your logic and validation here
                    self.loads.append(load.value as! NSDictionary)
                    self.loads.last?.setValue(load.key as! String, forKey: "id")
                    self.loads.last?.setValue(selectedDate, forKey: "date")
                    self.total += Float(self.loads.last!["amount"] as! String)!
                }
                self.loads = self.loads.sorted(by: {($0["number"] as! Int) > ($1["number"] as! Int)})
                self.tableView.reloadData()
            } else {
                print("no results")
            }
            self.stopLoading()
            // ...
        }) { (error) in
            print(error.localizedDescription)
            self.stopLoading()
        }
    }
    
    func stopLoading() {
        self.refresher.endRefreshing()
        if SVProgressHUD.isVisible() { SVProgressHUD.dismiss() }
        tableView.reloadData()
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        self.totalLoad.text = numberFormatter.string(from: NSNumber(value:self.total))
    }
    
    // MARK: - Finish picking date
    @objc func dateChanged() {
        getDateFromPicker()
    }
    
    func getDateFromPicker() {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        pickDate.text = formatter.string(from: datePicker.date)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        changeContentsAccdgToDate()
        pickDate.resignFirstResponder()
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
        loadLoads()
    }
    
    @IBAction func deletePressed(_ sender: UIButton) {
        // 1
        let thisLoads = loads[sender.tag]["cell"]
        let thisKey = loads[sender.tag]["id"] as! String
        let date = loads[sender.tag]["date"] as! String
        let optionMenu = UIAlertController(title: nil, message: "Are you sure you want to delete \(thisLoads!)?", preferredStyle: .actionSheet)
        
        // 2
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { (alert: UIAlertAction!) -> Void in
            print(date)
            self.ref.child("houses").child(self.house).child("daily").child("loader").child(date).child(thisKey).setValue(nil)
            self.loadLoads()
        })
        
        // 4
        optionMenu.addAction(deleteAction)
        
        // 5
        
        optionMenu.popoverPresentationController?.sourceView = sender
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    func dateToTime(date: inout String) -> String {
        date.removeSubrange(date.range(of: "GMT")!.lowerBound ..< date.endIndex)
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "E MMM d yyyy HH:mm:ss"
        let formattedDate = dateFormatterGet.date(from: date)
        dateFormatterGet.dateFormat = "hh:mm a"
        return dateFormatterGet.string(from: formattedDate!)
    }
}

// MARK: - LOAD TABLE VIEW CELL
class LoadDailyCell: UITableViewCell {
    @IBOutlet weak var number: PaddingLabel!
    @IBOutlet weak var phone: PaddingLabel!
    @IBOutlet weak var amount: PaddingLabel!
    @IBOutlet weak var dateTime: PaddingLabel!
    @IBOutlet weak var delete: UIButton!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    @IBAction func deletePressed(_ sender: UIButton) {
    }
}
