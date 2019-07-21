//
//  SalesTableViewController.swift
//  Famlee
//
//  Created by Jules Lee on 21/07/2019.
//  Copyright © 2019 Jules Lee. All rights reserved.
//

import UIKit
import Firebase

class RoomsTableViewController: UITableViewController {
    
    var ref: DatabaseReference!
    var house = ""
    var rooms = [NSDictionary]()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.rowHeight = 55.0
        self.tableView.separatorStyle = .none
        
        ref = Database.database().reference()
        if let house = UserDefaults.standard.string(forKey: "house") {
        ref.child("houses").child(house).child("rooms").observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            if let rooms = snapshot.value as? NSDictionary {
                for room in rooms {
                    //do your logic and validation here
                    self.rooms.append(room.value as! NSDictionary)
                }
                self.rooms = self.rooms.sorted(by: {($1["number"] as! NSString).doubleValue > ($0["number"] as! NSString).doubleValue})
                self.tableView.reloadData()
            } else {
                print("no results")
            }
            
            // ...
        }) { (error) in
            print(error.localizedDescription)
        }
        }
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return rooms.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "roomCell", for: indexPath) as! RoomsCell
        cell.roomNumber.text = (rooms[indexPath.row]["number"] as! String)
        cell.desc.text = (rooms[indexPath.row]["description"] as! String)
        cell.price.text = "₱"+(rooms[indexPath.row]["price"] as! String)
        cell.availability.image = rooms[indexPath.row]["occupied"] as! String == "NO" ? UIImage(named: "vacant"): UIImage(named: "occupied")
        return cell
    }
 
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
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

@IBDesignable class PaddingLabel: UILabel {
    
    @IBInspectable var topInset: CGFloat = 5.0
    @IBInspectable var bottomInset: CGFloat = 5.0
    @IBInspectable var leftInset: CGFloat = 16.0
    @IBInspectable var rightInset: CGFloat = 16.0
    
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets.init(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawText(in: rect.inset(by: insets))
    }
    
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + leftInset + rightInset,
                      height: size.height + topInset + bottomInset)
    }
}
