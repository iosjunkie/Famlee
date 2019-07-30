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
import DropDownMenuKit
import ChameleonFramework

class RoomsTableViewController: UITableViewController, DropDownMenuDelegate {
    
    // lazies
    lazy var ref: DatabaseReference = {
        return Database.database().reference()
    }()
    lazy var house: String = {
        return UserDefaults.standard.string(forKey: "house")!
    }()
    lazy var refresher: UIRefreshControl = {
        let refresherControl = UIRefreshControl()
        refresherControl.tintColor = UIColor.black
        refresherControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return refresherControl
    }()
    // TextFields
    lazy var numberAdd:UITextField = {
        let numberAdd = UITextField(frame: CGRect(x: 20, y: 100, width: 300, height: 40))
        numberAdd.placeholder = "Number"
        numberAdd.keyboardType = .numberPad
        return numberAdd
    }()
    lazy var descAdd:UITextField = {
        let descAdd = UITextField(frame: CGRect(x: 20, y: 100, width: 300, height: 40))
        descAdd.placeholder = "Description"
        return descAdd
    }()
    lazy var costAdd:UITextField = {
        let costAdd = UITextField(frame: CGRect(x: 20, y: 100, width: 300, height: 40))
        costAdd.placeholder = "Cost"
        costAdd.keyboardType = .numberPad
        return costAdd
    }()
    
    var rooms = [NSDictionary]()
    var newDescription: UITextField?
    var newPrice: UITextField?
    
    var toolbarMenu: DropDownMenu!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.rowHeight = 55.0
        self.tableView.separatorStyle = .none
        self.tableView.refreshControl = refresher
        
        prepareToolbarMenu()
        toolbarMenu.container = view
        
        SVProgressHUD.show(withStatus: "Loading Rooms")
        refresh()
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return rooms.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        let cell = tableView.dequeueReusableCell(withIdentifier: "roomCell", for: indexPath) as! RoomsCell
        cell.roomNumber.text = (rooms[indexPath.row]["number"] as! String)
        cell.desc.text = (rooms[indexPath.row]["description"] as! String)
        cell.price.text = numberFormatter.string(from: NSNumber(value: Float(rooms[indexPath.row]["price"] as! String)!))!
        cell.availability.image = rooms[indexPath.row]["occupied"] as! String == "NO" ? UIImage(named: "vacant"): UIImage(named: "occupied")
        cell.desc.onClick = {
            self.roomPressed(row: indexPath.row, sender: cell.desc)
        }
        cell.price.onClick = {
            self.pricePressed(row: indexPath.row, sender: cell.price)
        }
        return cell
    }
    
    @IBAction func sortBy(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            self.rooms = self.rooms.sorted(by: {($1["number"] as! NSString).doubleValue > ($0["number"] as! NSString).doubleValue})
            self.tableView.reloadData()
        case 1:
            self.rooms = self.rooms.sorted(by: {($1["description"] as! NSString).doubleValue > ($0["description"] as! NSString).doubleValue})
            self.tableView.reloadData()
        case 2:
            self.rooms = self.rooms.sorted(by: {($0["price"] as! NSString).doubleValue > ($1["price"] as! NSString).doubleValue})
            self.tableView.reloadData()
        case 3:
            self.rooms = self.rooms.sorted(by: {availabilityToInt($0["occupied"]) > availabilityToInt($1["occupied"])})
            self.tableView.reloadData()
        default:
            return
        }
    }
    
    func roomPressed(row: Int, sender: PaddingLabel) {
        // 1
        let thisRoom = rooms[row]["description"]
        let thisKey = rooms[row]["id"] as! String
        let optionMenu = UIAlertController(title: "Edit", message: "Are you sure you want to change the description of \(thisRoom!)?", preferredStyle: .alert)
        
        // 2
        let saveAction = UIAlertAction(title: "Save", style: .default, handler: { (alert: UIAlertAction!) -> Void in
            self.ref.child("houses").child(self.house).child("rooms").child(thisKey).updateChildValues([
                "description": self.newDescription!.text!,
                "synced": false,
                "syncedAdmin": false
                ])
            self.refresh()
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        // 4
        optionMenu.addTextField(configurationHandler: newDescriptionTextField)
        newDescription?.text = String(describing: rooms[row]["description"]!)
        optionMenu.addAction(saveAction)
        optionMenu.addAction(cancelAction)
        
        // 5
        
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    func pricePressed(row: Int, sender: PaddingLabel) {
        // 1
        let thisRoom = rooms[row]["description"]
        let thisKey = rooms[row]["id"] as! String
        let optionMenu = UIAlertController(title: "Edit", message: "Are you sure you want to change the price of \(thisRoom!)?", preferredStyle: .alert)
        
        // 2
        let saveAction = UIAlertAction(title: "Save", style: .default, handler: { (alert: UIAlertAction!) -> Void in
            self.ref.child("houses").child(self.house).child("rooms").child(thisKey).updateChildValues([
                "price": self.newPrice!.text!,
                "synced": false,
                "syncedAdmin": false
                ])
            self.refresh()
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        // 4
        optionMenu.addTextField(configurationHandler: newPriceTextField)
        newPrice?.text = String(describing: rooms[row]["price"]!)
        newPrice?.keyboardType = .numberPad
        optionMenu.addAction(saveAction)
        optionMenu.addAction(cancelAction)
        
        // 5
        
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    func newDescriptionTextField(textField: UITextField) {
        newDescription = textField
    }
    
    func newPriceTextField(textField: UITextField) {
        newPrice = textField
    }
    
    func availabilityToInt(_ occupancy: Any?) -> Int {
        let occupiedString = occupancy as! String
        return occupiedString == "YES" ? 1 : 0
    }
    
    @objc func refresh() {
        ref.child("houses").child(house).child("rooms").observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            if let rooms = snapshot.value as? NSDictionary {
                self.rooms.removeAll()
                for room in rooms {
                    //do your logic and validation here
                    self.rooms.append(room.value as! NSDictionary)
                    self.rooms.last?.setValue(room.key as! String, forKey: "id")
                }
                self.rooms = self.rooms.sorted(by: {($1["number"] as! NSString).intValue > ($0["number"] as! NSString).intValue})
                self.tableView.reloadData()
            } else {
                print("no results")
            }
            // Whether the loading is successful or not, dimiss the loaders
            self.refresher.endRefreshing()
            if SVProgressHUD.isVisible() { SVProgressHUD.dismiss() }
            // ...
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            // 1
            let thisDesc = self.rooms[indexPath.row]["description"]
            let thisKey = self.rooms[indexPath.row]["id"]
            let optionMenu = UIAlertController(title: "Delete", message: "Are you sure you want to delete \(thisDesc!)?", preferredStyle: .actionSheet)
            
            // 2
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { (alert: UIAlertAction!) -> Void in
                self.ref.child("houses").child(self.house).child("rooms").child(self.rooms[indexPath.row]["id"] as! String).setValue(nil)
                self.refresh()
            })
            
            // 4
            optionMenu.addAction(deleteAction)
            
            // 5
            
            optionMenu.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
            self.present(optionMenu, animated: true, completion: nil)
            
        }
        return [deleteAction]
    }
    
    func prepareToolbarMenu() {
        toolbarMenu = DropDownMenu(frame: view.bounds)
        toolbarMenu.delegate = self
        
        let numberCell = DropDownMenuCell()
        numberCell.customView = numberAdd
        numberCell.imageView!.image = UIImage(named: "hashtag")
        numberCell.imageView!.tintColor = UIColor.flatBlue()
        
        let descCell = DropDownMenuCell()
        descCell.customView = descAdd
        descCell.imageView!.image = UIImage(named: "text")
        descCell.imageView!.tintColor = UIColor.flatBlue()
        
        let costCell = DropDownMenuCell()
        costCell.customView = costAdd
        costCell.imageView!.image = UIImage(named: "cost")
        costCell.imageView!.tintColor = UIColor.flatBlue()
        
        
        let buttonCell = DropDownMenuCell()
        buttonCell.textLabel!.text = "Save Room"
        buttonCell.textLabel?.textColor = UIColor.flatWhite()
        buttonCell.textLabel?.textAlignment = .center
        buttonCell.menuAction = Selector(("addNewRoom"))
        buttonCell.menuTarget = self
        buttonCell.backgroundColor = UIColor(hexString: "3379F7")
        buttonCell.selectionStyle = .none
        
        toolbarMenu.menuCells = [numberCell, descCell, costCell, buttonCell]
        toolbarMenu.direction = .down
        
        // For a simple gray overlay in background
        toolbarMenu.backgroundView = UIView(frame: toolbarMenu.bounds)
        toolbarMenu.backgroundView!.backgroundColor = UIColor.black
        toolbarMenu.backgroundAlpha = 0.7
    }
    
    
    @IBAction func showToolbarMenu() {
        toolbarMenu.show()
        numberAdd.becomeFirstResponder()
    }
    
    func didTapInDropDownMenuBackground(_ menu: DropDownMenu) {
        toolbarMenu.hide()
        resignFirstResponder()
    }
    
    @objc func addNewRoom() {
        if numberAdd.text!.isEmpty || descAdd.text!.isEmpty || costAdd.text!.isEmpty {print("unacceptable")} else {
            let newID = randomString(length: 17)
            ref.child("houses").child(house).child("rooms").child(newID).setValue([
                "number": numberAdd.text!,
                "description": descAdd.text!,
                "price": costAdd.text!,
                "guest": "",
                "synced": false,
                "occupied": "NO"])
            numberAdd.text = ""
            descAdd.text = ""
            costAdd.text = ""
            resignFirstResponder()
            toolbarMenu.hide()
            refresh()
        }
    }
    
    func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
}

// MARK - Cell 
class RoomsCell: UITableViewCell {
    @IBOutlet weak var roomNumber: PaddingLabel!
    @IBOutlet weak var desc: PaddingLabel!
    @IBOutlet weak var price: PaddingLabel!
    
    @IBOutlet weak var availability: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }

}

@IBDesignable public class PaddingLabel: UILabel {
    
    @IBInspectable var topInset: CGFloat = 5.0
    @IBInspectable var bottomInset: CGFloat = 5.0
    @IBInspectable var leftInset: CGFloat = 16.0
    @IBInspectable var rightInset: CGFloat = 16.0
    
    override public func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets.init(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawText(in: rect.inset(by: insets))
    }
    
    override public var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + leftInset + rightInset,
                      height: size.height + topInset + bottomInset)
    }
    
    var onClick: () -> Void = {}
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        onClick()
    }
}
