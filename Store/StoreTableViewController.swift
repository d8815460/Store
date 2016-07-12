//
//  StoreTableViewController.swift
//  Store
//
//  Created by 駿逸 陳 on 2016/7/12.
//  Copyright © 2016年 Ayi. All rights reserved.
//

import UIKit
import ParseUI
import Parse
import Synchronized
import ParseFacebookUtilsV4


class StoreTableViewController: PFQueryTableViewController, PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate {

    private var _presentedLoginViewController: Bool = false
    private var _facebookResponseCount: Int = 0
    private var _expectedFacebookResponseCount: Int = 0
    private var _profilePicData: NSMutableData! = nil
    
    override init(style: UITableViewStyle, className: String?) {
        super.init(style: style, className: className)
    }
    
    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
        super.init(coder: aDecoder)
        
        //Use the Parse built-in user class
        self.parseClassName = "Item"
        
        //This is a custom column in the user class.
        self.pullToRefreshEnabled = true
        self.paginationEnabled = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
    
    override func queryForTable() -> PFQuery<PFObject> {
        let query = PFQuery(className: self.parseClassName!)
        
        query.limit = 1000
        
        //It's very important to sort the query.  Otherwise you'll end up with unexpected results
        query.order(byAscending: "createdAt")
        
        
        query.cachePolicy = PFCachePolicy.cacheThenNetwork
        
        return query
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, object: PFObject?) -> PFTableViewCell? {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ParseProduct",  for: indexPath) as! PFProductTableViewCell
        
        //These two columns are custom fields.  You'll need to add them to the Parse _User class manually.
        let product: PFObject! = self.objects![indexPath.row]
        cell.configureProduct(product: product)

        
        
        return cell
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
        let image:UIImageView = UIImageView.init(image: UIImage.init(named: "ic_add_ok"))
        loginViewController.logInView?.logo = image
        
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
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
