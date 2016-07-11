//
//  StoreTableViewController.swift
//  Store
//
//  Created by 駿逸 陳 on 2016/7/11.
//  Copyright © 2016年 Ayi. All rights reserved.
//

import UIKit
import ParseUI
import Parse
import Synchronized
import ParseFacebookUtilsV4

let ROW_MARGIN = 6.0
let ROW_HEIGHT = 173.0
let PICKER_HEIGHT = 216.0
let SIZE_BUTTON_TAG_OFFSET = 1000

class StoreTableViewController: PFQueryTableViewController, PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate {

    private var _presentedLoginViewController: Bool = false
    private var _facebookResponseCount: Int = 0
    private var _expectedFacebookResponseCount: Int = 0
    private var _profilePicData: NSMutableData! = nil
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.parseClassName = "Item"
        self.tableView.register(PFProductTableViewCell.superclass(), forCellReuseIdentifier: "ParseProduct")
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.none
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.tableView.contentOffset = CGPoint(x: 0, y: 0)
        self.tableView.isScrollEnabled = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if PFUser.current() == nil {
            presentLoginViewController(animated: true)
            return
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier:String = "ParseProduct"
        var cell:PFProductTableViewCell! = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! PFProductTableViewCell
        
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: identifier) as! PFProductTableViewCell
        }
        
        self.tableView.separatorColor = UIColor.clear()
        
        let product: PFObject! = self.objects![indexPath.row]
        cell.configureProduct(product: product)
        
        
        return PFProductTableViewCell() as UITableViewCell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }

    
    // MARK: - 登入代理
    func presentLoginViewController(animated: Bool) {
        if _presentedLoginViewController {
            return
        }
        
        _presentedLoginViewController = true
        
        let signupViewController = PFSignUpViewController()
        signupViewController.delegate = self
        signupViewController.fields = [PFSignUpFields.default]
        
        let loginViewController = PFLogInViewController()
        loginViewController.delegate = self
        loginViewController.fields = [PFLogInFields.usernameAndPassword, PFLogInFields.facebook, PFLogInFields.signUpButton, PFLogInFields.dismissButton, PFLogInFields.passwordForgotten]
        loginViewController.signUpController = signupViewController
        loginViewController.facebookPermissions = [ "public_profile", "user_friends", "email", "user_photos"]
        
        
        present(loginViewController, animated: animated, completion: nil)
    }
    
    // MARK:- PFLoginViewControllerDelegate
    
    func log(_ logInController: PFLogInViewController, didLogIn user: PFUser) {
        if _presentedLoginViewController {
            _presentedLoginViewController = false
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func logInViewControllerDidCancelLog(in logInController: PFLogInViewController) {
        if _presentedLoginViewController {
            _presentedLoginViewController = false
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK:- PFSignUpViewControllerDelegate
    
    func signUpViewController(_ signUpController: PFSignUpViewController, didSignUp user: PFUser) {
        print("user signup")
        self.dismiss(animated: true) {
            
        }
    }
    
    func signUpViewControllerDidCancelSignUp(_ signUpController: PFSignUpViewController) {
        print("user canncel signup")
    }
    
    func signUpViewController(_ signUpController: PFSignUpViewController, didFailToSignUpWithError error: NSError?) {
        print("signup error:\(error?.description)")
    }
    
    func signUpViewController(_ signUpController: PFSignUpViewController, shouldBeginSignUp info: [String : String]) -> Bool {
        return true
    }
    
    // MARK:- ()
    
    func processedFacebookResponse() {
        // Once we handled all necessary facebook batch responses, save everything necessary and continue
        synchronized(self) {
            _facebookResponseCount += 1;
            if (_facebookResponseCount != _expectedFacebookResponseCount) {
                return
            }
        }
        _facebookResponseCount = 0;
        print("done processing all Facebook requests")
        
        PFUser.current()!.saveInBackground { (succeeded, error) in
            if !succeeded {
                print("Failed save in background of user, \(error)")
            } else {
                print("saved current parse user")
            }
        }
    }
    
    // MARK:- NSURLConnectionDataDelegate
    
    func connection(connection: NSURLConnection, didReceiveResponse response: URLResponse) {
        _profilePicData = NSMutableData()
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: Data) {
        _profilePicData!.append(data)
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        PAPUtility.processFacebookProfilePictureData(newProfilePictureData: _profilePicData!)
    }
    
    // MARK:- NSURLConnectionDelegate
    
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        print("Connection error downloading profile pic data: \(error)")
    }
    
    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
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
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
