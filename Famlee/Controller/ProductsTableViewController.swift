//
//  ProductsTableViewController.swift
//  Famlee
//
//  Created by Jules Lee on 24/07/2019.
//  Copyright © 2019 Jules Lee. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD
import DropDownMenuKit
import ChameleonFramework

class ProductsTableViewController: UITableViewController, DropDownMenuDelegate {
    
    // lazier
    lazy var ref: DatabaseReference = {
        return Database.database().reference()
    }()
    lazy var refresher: UIRefreshControl = {
        let refresherControl = UIRefreshControl()
        refresherControl.tintColor = UIColor.black
        refresherControl.addTarget(self, action: #selector(loadProducts), for: .valueChanged)
        return refresherControl
    }()
    lazy var house: String = {
        return UserDefaults.standard.string(forKey: "house")!
    }()
    lazy var newPrice: UITextField = {
        let newPrice = UITextField()
        return newPrice
    }()
    lazy var newQuantity: UITextField = {
        let newQuantity = UITextField()
        return newQuantity
    }()
    // TextFields
    var itemAdd:DropDownField?
    var quantityAdd:DropDownField?
    var costAdd:DropDownField?
    
    var products = [NSDictionary]()
    var currentYear = ""
    var currentMonth = 0
    var currentDay = ""
    var toolbarMenu: DropDownMenu!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.rowHeight = 55.0
        self.tableView.separatorStyle = .none
        
        // Start DropDownMenuItem
        
        prepareToolbarMenu()
        toolbarMenu.container = view
        
        //
        
            }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        SVProgressHUD.show(withStatus: "Loading Products")
        loadProducts()

    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        let cell = tableView.dequeueReusableCell(withIdentifier: "productDailyCell", for: indexPath) as! ProductDailyCell
        cell.item.text = String(describing: products[indexPath.row]["product"]!)
        cell.price.text = numberFormatter.string(from: NSNumber(value: Float(products[indexPath.row]["price"] as! String)!))
        cell.quantity.text = String(describing: products[indexPath.row]["quantity"] ?? "0")
        cell.tq.text = String(describing: products[indexPath.row]["tentative"]!)
        if cell.tq.text! == "0" {
            cell.tq.text = ""
        }
        cell.approve.isOn = false
        if cell.tq.text! == "" || String(describing: products[indexPath.row]["quantity"]) == String(describing: products[indexPath.row]["tentative"]) {
            cell.approve.isEnabled = false
            cell.tq.text = ""
        } else {
            cell.approve.isEnabled = true
        }
        
        // Tags
        cell.approve.tag = indexPath.row
        cell.delete.tag = indexPath.row
        
        cell.price.onClick = {
            self.pricePressed(row: indexPath.row, sender: cell.price)
        }
        
        cell.quantity.onClick = {
            self.quantityPressed(row: indexPath.row, sender: cell.quantity)
        }
        return cell
    }
    
    @IBAction func deletePressed(_ sender: UIButton) {
        // 1
        let thisProduct = products[sender.tag]["product"]
        let thisKey = products[sender.tag]["id"]
        let optionMenu = UIAlertController(title: nil, message: "Are you sure you want to delete \(thisProduct!)?", preferredStyle: .actionSheet)
        
        // 2
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { (alert: UIAlertAction!) -> Void in
            self.ref.child("houses").child(self.house).child("remove").child("items").child(thisKey as! String).setValue(thisKey as! String)
            self.ref.child("houses").child(self.house).child("items").child(thisKey as! String).setValue(nil)
            self.loadProducts()
        })
        
        // 4
        optionMenu.addAction(deleteAction)
        
        // 5
        
        optionMenu.popoverPresentationController?.sourceView = sender
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    func pricePressed(row: Int, sender: PaddingLabel) {
        // 1
        let thisProduct = products[row]["product"]
        let thisKey = products[row]["id"]
        let optionMenu = UIAlertController(title: "Edit", message: "Are you sure you want to change the price of \(thisProduct!)?", preferredStyle: .alert)
        
        // 2
        let saveAction = UIAlertAction(title: "Save", style: .default, handler: { (alert: UIAlertAction!) -> Void in
            self.ref.child("houses").child(self.house).child("items").child(thisKey as! String).updateChildValues([
                "price": self.newPrice.text!,
                "tentative": "0",
                "synced": false,
                "syncedAdmin": false
                ])
            self.loadProducts()
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        // 4
        optionMenu.addTextField(configurationHandler: newPriceTextField)
        newPrice.text = String(describing: products[row]["price"] ?? "0")
        newPrice.keyboardType = .numberPad
        optionMenu.addAction(saveAction)
        optionMenu.addAction(cancelAction)
        
        // 5
        
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    func quantityPressed(row: Int, sender: PaddingLabel) {
        // 1
        let thisProduct = products[row]["product"]
        let thisKey = products[row]["id"]
        let optionMenu = UIAlertController(title: "Edit", message: "Are you sure you want to change the quantity of \(thisProduct!)?", preferredStyle: .alert)
        
        // 2
        let saveAction = UIAlertAction(title: "Save", style: .default, handler: { (alert: UIAlertAction!) -> Void in
            self.ref.child("houses").child(self.house).child("items").child(thisKey as! String).updateChildValues([
                "quantity": self.newQuantity.text!,
                "tentative": "0",
                "synced": false,
                "syncedAdmin": false
                ])
            self.loadProducts()
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        // 4
        optionMenu.addTextField(configurationHandler: newQuantityTextField)
        newQuantity.text = String(describing: products[row]["quantity"] ?? "0")
        newQuantity.keyboardType = .numberPad
        optionMenu.addAction(saveAction)
        optionMenu.addAction(cancelAction)
        
        // 5
        
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    func newPriceTextField(textField: UITextField) {
        newPrice = textField
    }
    
    func newQuantityTextField(textField: UITextField) {
        newQuantity = textField
    }
    
    @objc func loadProducts() {
        products = [NSDictionary]()
        ref.child("houses").child(house).child("items").observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            if let products = snapshot.value as? NSDictionary {
                for product in products {
                    //do your logic and validation here
                    self.products.append(product.value as! NSDictionary)
                    self.products.last?.setValue(product.key as! String, forKey: "id")
                }
                self.products = self.products.sorted(by: {($1["product"] as! String) > ($0["product"] as! String)})
                self.tableView.reloadData()
            } else {
                print("no results")
            }
            self.refresher.endRefreshing()
            if SVProgressHUD.isVisible() { SVProgressHUD.dismiss() }
            // ...
        }) { (error) in
            print(error.localizedDescription)
            self.refresher.endRefreshing()
            if SVProgressHUD.isVisible() { SVProgressHUD.dismiss() }
        }
    }

    @IBAction func sortBy(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            self.products = self.products.sorted(by: {$1["product"] as! String > $0["product"] as! String})
            self.tableView.reloadData()
        case 1:
            self.products = self.products.sorted(by: {($1["price"] as! NSString).doubleValue > ($0["price"] as! NSString).doubleValue})
            self.tableView.reloadData()
        case 2:
            self.products = self.products.sorted(by: {($0["quantity"] as? Int) ?? 0 > ($1["quantity"] as? Int) ?? 0})
            self.tableView.reloadData()
        case 3:
            self.products = self.products.sorted(by: {($0["tentative"] as? Int) ?? 0 > ($1["tentative"] as? Int) ?? 0})
            self.tableView.reloadData()
        default:
            return
        }
    }
    
    func prepareToolbarMenu() {
        toolbarMenu = DropDownMenu(frame: view.bounds)
        toolbarMenu.delegate = self

        let itemCell = DropDownMenuCell(image: "item", textField: DropDownField(placeholder: "Item"))
        let quantityCell = DropDownMenuCell(image: "quantity", textField: DropDownField(placeholder: "Quantity", num: true))
        let costCell = DropDownMenuCell(image: "cost", textField: DropDownField(placeholder: "Cost", num: true))
        
        let buttonCell = DropDownMenuCell()
        buttonCell.textLabel!.text = "Save Item"
        buttonCell.textLabel?.textColor = UIColor.flatWhite()
        buttonCell.textLabel?.textAlignment = .center
        buttonCell.menuAction = Selector(("addNewItem"))
        buttonCell.menuTarget = self
        buttonCell.backgroundColor = UIColor(hexString: "3379F7")
        buttonCell.selectionStyle = .none
        
        toolbarMenu.menuCells = [itemCell, quantityCell, costCell, buttonCell]
        toolbarMenu.direction = .down
        
        // For a simple gray overlay in background
        toolbarMenu.backgroundView = UIView(frame: toolbarMenu.bounds)
        toolbarMenu.backgroundView!.backgroundColor = UIColor.black
        toolbarMenu.backgroundAlpha = 0.7
    }
    
    
    @IBAction func showToolbarMenu() {
        toolbarMenu.show()
        itemAdd?.uiTextF().becomeFirstResponder()
    }
    
    func didTapInDropDownMenuBackground(_ menu: DropDownMenu) {
        toolbarMenu.hide()
        view.endEditing(true)
    }
    
    @objc func addNewItem() {
        if (itemAdd?.text.isEmpty)! || (quantityAdd?.text.isEmpty)! || (costAdd?.text.isEmpty)! { return } else {
            let newID = Constants.sharedInstance.randomString(length: 17)
            ref.child("houses").child(house).child("items").child(newID).setValue([
                "product": itemAdd!.text,
                "quantity": quantityAdd!.text,
                "price": costAdd!.text,
                "tentative": "0",
                "synced": false,
                "syncedAdmin": false])
            itemAdd?.text = ""
            quantityAdd?.text = ""
            costAdd?.text = ""
            view.endEditing(true)
            toolbarMenu.hide()
            loadProducts()
        }
    }
    
    @IBAction func approvePressed(_ sender: UISwitch) {
        if !products.isEmpty {
            SVProgressHUD.show(withStatus: "Loading Products")
            let thisKey = products[sender.tag]["id"] as! String
            
            let newQuantity = (products[sender.tag]["quantity"] as! Int) + Int("\(products[sender.tag]["tentative"] ?? 0)")!
            print(thisKey)
            print(newQuantity)
            self.ref.child("houses").child(self.house).child("items").child(thisKey).updateChildValues([
                "quantity": newQuantity,
                "tentative": "0",
                "synced": false,
                "syncedAdmin": false
                ])
            self.loadProducts()
        }
    }
}

