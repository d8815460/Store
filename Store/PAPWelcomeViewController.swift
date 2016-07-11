import UIKit
import Synchronized
import ParseFacebookUtilsV4
import ParseUI
import Parse

class PAPWelcomeViewController: UIViewController, PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate {
    
    private var _presentedLoginViewController: Bool = false
    private var _facebookResponseCount: Int = 0
    private var _expectedFacebookResponseCount: Int = 0
    private var _profilePicData: NSMutableData? = nil

    // MARK:- UIViewController
    override func loadView() {
        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if PFUser.current() == nil {
            presentLoginViewController(animated: true)
            return
        }

        // Present Anypic UI
//        (UIApplication.shared().delegate as! AppDelegate).presentTabBarController()
        
        // Refresh current user with server side data -- checks if user is still valid and so on
        _facebookResponseCount = 0
        /*
        PFUser.current()?.fetchInBackground({ (refreshedObject, error) in
            // This fetches the most recent data from FB, and syncs up all data with the server including profile pic and friends list from FB.
            
            // A kPFErrorObjectNotFound error on currentUser refresh signals a deleted user
            if error != nil && error!.code == PFErrorCode.errorObjectNotFound.rawValue {
                print("User does not exist.")
//                (UIApplication.shared().delegate as! AppDelegate!).logOut()
                return
            }
            
            // TODO: 不知道怎麼處理
//            let session: FBSDKsession = PFFacebookUtils.session()!
//            if !session.isOpen {
//                print("FB Session does not exist, logout")
//                (UIApplication.shared().delegate as! AppDelegate).logOut()
//                return
//            }
            
            if FBSDKAccessToken.current().userID == nil {
                print("userID on FB Session does not exist, logout")
//                (UIApplication.shared().delegate as! AppDelegate).logOut()
                return
            }
            
            guard let currentParseUser: PFUser = PFUser.current() else {
                print("Current Parse user does not exist, logout")
//                (UIApplication.shared().delegate as! AppDelegate).logOut()
                return
            }
            
            let facebookId = currentParseUser.object(forKey: kPAPUserFacebookIDKey) as? String
            if facebookId == nil || facebookId?.characters.count == 0 {
                // set the parse user's FBID
                currentParseUser.setObject(FBSDKAccessToken.current().userID, forKey: kPAPUserFacebookIDKey)
            }
            
            if PAPUtility.userHasValidFacebookData(user: currentParseUser) == false {
                print("User does not have valid facebook ID. PFUser's FBID: \(currentParseUser.object(forKey: kPAPUserFacebookIDKey)), FBSessions FBID: \(FBSDKAccessToken.current().userID). logout")
//                (UIApplication.shared().delegate as! AppDelegate).logOut()
                return
            }
            
            // Finished checking for invalid stuff
            // Refresh FB Session (When we link up the FB access token with the parse user, information other than the access token string is dropped
            // By going through a refresh, we populate useful parameters on FBAccessTokenData such as permissions.
            
            // TODO: 完全不知道怎麼辦
            PFFacebookUtils.session()!.refreshPermissionsWithCompletionHandler { (session, error) in
                if (error != nil) {
                    print("Failed refresh of FB Session, logging out: \(error)")
                    (UIApplication.sharedApplication().delegate as! AppDelegate).logOut()
                    return
                }
                // refreshed
                print("refreshed permissions: \(session)")
                
                
                self._expectedFacebookResponseCount = 0
                let permissions: NSArray = session.accessTokenData.permissions
                // FIXME: How to use "contains" in Swift Array? Replace the NSArray with Swift array
                if permissions.containsObject("public_profile") {
                    // Logged in with FB
                    // Create batch request for all the stuff
                    let connection = FBRequestConnection()
                    self._expectedFacebookResponseCount++
                    connection.addRequest(FBRequest.requestForMe(), completionHandler: { (connection, result, error) in
                        if error != nil {
                            // Failed to fetch me data.. logout to be safe
                            print("couldn't fetch facebook /me data: \(error), logout")
                            (UIApplication.sharedApplication().delegate as! AppDelegate).logOut()
                            return
                        }
                        
                        if let facebookName = result["name"] as? String where facebookName.length > 0 {
                            currentParseUser.setObject(facebookName, forKey: kPAPUserDisplayNameKey)
                        }
                        
                        self.processedFacebookResponse()
                    })
                    
                    // profile pic request
                    self._expectedFacebookResponseCount++
                    connection.addRequest(FBRequest(graphPath: "me", parameters: ["fields": "picture.width(500).height(500)"], HTTPMethod: "GET"), completionHandler: { (connection, result, error) in
                        if error == nil {
                            // result is a dictionary with the user's Facebook data
                            // FIXME: Really need to be this ugly???
                            //                        let userData = result as? [String : [String : [String : String]]]
                            //                        let profilePictureURL = NSURL(string: userData!["picture"]!["data"]!["url"]!)
                            //                        // Now add the data to the UI elements
                            //                        let profilePictureURLRequest: NSURLRequest = NSURLRequest(URL: profilePictureURL!, cachePolicy: NSURLRequestCachePolicy.UseProtocolCachePolicy, timeoutInterval: 10.0) // Facebook profile picture cache policy: Expires in 2 weeks
                            //                        NSURLConnection(request: profilePictureURLRequest, delegate: self)
                            if let userData = result as? [NSObject: AnyObject] {
                                if let picture = userData["picture"] as? [NSObject: AnyObject] {
                                    if let data = picture["data"] as? [NSObject: AnyObject] {
                                        if let profilePictureURL = data["url"] as? String {
                                            // Now add the data to the UI elements
                                            let profilePictureURLRequest: NSURLRequest = NSURLRequest(URL: NSURL(string: profilePictureURL)!, cachePolicy: NSURLRequestCachePolicy.UseProtocolCachePolicy, timeoutInterval: 10.0) // Facebook profile picture cache policy: Expires in 2 weeks
                                            NSURLConnection(request: profilePictureURLRequest, delegate: self)
                                        }
                                    }
                                }
                                
                            }
                        } else {
                            print("Error getting profile pic url, setting as default avatar: \(error)")
                            let profilePictureData: NSData = UIImagePNGRepresentation(UIImage(named: "AvatarPlaceholder.png")!)!
                            PAPUtility.processFacebookProfilePictureData(profilePictureData)
                        }
                        self.processedFacebookResponse()
                    })
                    if permissions.containsObject("user_friends") {
                        // Fetch FB Friends + me
                        self._expectedFacebookResponseCount++
                        connection.addRequest(FBRequest.requestForMyFriends(), completionHandler: { (connection, result, error) in
                            print("processing Facebook friends")
                            if error != nil {
                                // just clear the FB friend cache
                                PAPCache.sharedCache.clear()
                            } else {
                                let data = result.objectForKey("data") as? NSArray
                                let facebookIds: NSMutableArray = NSMutableArray(capacity: data!.count)
                                for friendData in data! {
                                    if let facebookId = friendData["id"] {
                                        facebookIds.addObject(facebookId!)
                                    }
                                }
                                // cache friend data
                                PAPCache.sharedCache.setFacebookFriends(facebookIds)
                                
                                if currentParseUser.objectForKey(kPAPUserFacebookFriendsKey) != nil {
                                    currentParseUser.removeObjectForKey(kPAPUserFacebookFriendsKey)
                                }
                                if currentParseUser.objectForKey(kPAPUserAlreadyAutoFollowedFacebookFriendsKey) != nil {
                                    (UIApplication.sharedApplication().delegate as! AppDelegate).autoFollowUsers()
                                }
                            }
                            self.processedFacebookResponse()
                        })
                    }
                    connection.start()
                } else {
                    let profilePictureData: NSData = UIImagePNGRepresentation(UIImage(named: "AvatarPlaceholder.png")!)!
                    PAPUtility.processFacebookProfilePictureData(profilePictureData)
                    
                    PAPCache.sharedCache.clear()
                    currentParseUser.setObject("Someone", forKey: kPAPUserDisplayNameKey)
                    self._expectedFacebookResponseCount++
                    self.processedFacebookResponse()
                }
            }
        })*/
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK:- PAPWelcomeViewController

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
}
