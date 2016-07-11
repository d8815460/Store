import UIKit
import MBProgressHUD
import ParseFacebookUtilsV4


class PAPLogInViewController: UIViewController, FBSDKLoginButtonDelegate {
    var delegate: PAPLogInViewControllerDelegate?
    var _facebookLoginView: FBSDKLoginButton?
    var hud: MBProgressHUD?

    // MARK:- UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // There is no documentation on how to handle assets with the taller iPhone 5 screen as of 9/13/2012
        if UIScreen.main().bounds.size.height > 480.0 {
            // for the iPhone 5
            // FIXME: We need 3x picture for iPhone 6
            let color = UIColor(patternImage: UIImage(named: "BackgroundLogin.png")!)
            self.view.backgroundColor = color
        } else {
            self.view.backgroundColor = UIColor(patternImage: UIImage(named: "BackgroundLogin.png")!)
        }
        
        //Position of the Facebook button
        var yPosition: CGFloat = 360.0
        if UIScreen.main().bounds.size.height > 480.0 {
            yPosition = 450.0
        }
        
        _facebookLoginView = FBSDKLoginButton()
        _facebookLoginView?.readPermissions = ["public_profile", "user_friends"/*, "email", "user_photos"*/]
        _facebookLoginView?.frame = CGRect(x: 36.0, y: yPosition, width: 244.0, height: 44.0)
        _facebookLoginView?.delegate = self
        _facebookLoginView?.tooltipBehavior = FBSDKLoginButtonTooltipBehavior.disable
        self.view.addSubview(_facebookLoginView!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func shouldAutorotate() -> Bool {
        let orientation: UIInterfaceOrientation = UIApplication.shared().statusBarOrientation
        
        return orientation == UIInterfaceOrientation.portrait
    }
    
    // FIXME: Just replaced with shouldAutorotate above? The one below is deprecated since ios6
//    override func shouldAutorotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation) -> Bool {
//        return toInterfaceOrientation == UIInterfaceOrientation.Portrait
//    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }


    // MARK:- FBLoginViewDelegate

    func loginViewShowingLoggedInUser(loginView: FBSDKLoginButton) {
        self.handleFacebookSession()
    }

    func loginView(loginView: FBSDKLoginButton, handleError error: NSError?) {
        self.handleLogInError(error: error)
    }

    func handleFacebookSession() {
        if PFUser.current() != nil {
            if self.delegate != nil && self.delegate!.responds(to: Selector(("logInViewControllerDidLogUserIn:"))) {
                self.delegate!.perform(Selector(("logInViewControllerDidLogUserIn:")), with: PFUser.current()!)
            }
            return
        }
        
        let permissionsArray = ["public_profile", "user_friends", "email"]
        self.hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        
        // public class func logInInBackground(withReadPermissions permissions: [String]?) -> BFTask<PFUser>
        // Login PFUser using Facebook
        PFFacebookUtils.logInInBackground(withReadPermissions: permissionsArray) { (user, error) in
            if user == nil {
                var errorMessage: String = ""
                if error == nil {
                    print("Uh oh. The user cancelled the Facebook login.")
                    errorMessage = NSLocalizedString("Uh oh. The user cancelled the Facebook login.", comment: "")
                } else {
                    print("Uh oh. An error occurred: %@", error)
                    errorMessage = error!.localizedDescription
                }
                let alertController = UIAlertController(title: NSLocalizedString("Log In Error", comment: ""), message: errorMessage, preferredStyle: UIAlertControllerStyle.alert)
                let alertAction = UIAlertAction(title: NSLocalizedString("Dismiss", comment: ""), style: UIAlertActionStyle.cancel, handler: nil)
                alertController.addAction(alertAction)
                self.present(alertController, animated: true, completion: nil)
            } else {
                if user!.isNew {
                    print("User with facebook signed up and logged in!")
                } else {
                    print("User with facebook logged in!")
                }
                
                if error == nil {
                    self.hud!.removeFromSuperview()
                    if self.delegate != nil {
                        if self.delegate!.responds(to: Selector(("logInViewControllerDidLogUserIn:"))) {
                            self.delegate!.perform(Selector(("logInViewControllerDidLogUserIn:")), with: user)
                        }
                    }
                } else {
                    self.cancelLogIn(error: error)
                }
            }
        }
    }
    
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        print("User Logged In")
        
        if error != nil {
            print("error\(error.description)")
        }
        else if result.isCancelled
        {
            // Handel cancellations
            print("cancelled")
        }
        else
        {
            // If you ask for multiple permissions at once, you
            // should check if specific permissions missing
            if result.grantedPermissions.contains("email")
            {
//                let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                // Do work
                print("logged in ")
//                FIRAuth.auth()?.signIn(with: credential, completion: { (user, error) in
//                    if (user != nil) {
//                        
//                        let uid = user?.uid as String!
//                        
//                        self.fetchProfile(uid!);
//                        
//                    }
//                })
            } else {
                // 登入之後 回到TabBar頁面
                self.dismiss(animated: true, completion: { 
                    
                })
            }
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("User logged Out")
    }

    // MARK:- ()

    func cancelLogIn(error: NSError?) {
        if error != nil {
            self.handleLogInError(error: error)
        }
        
        self.hud!.removeFromSuperview()
        /*
            You can just call this function to logout.
            LoginManager.getInstance().logout();
         
            This is the equivalent function for
            Session.getActiveSession().closeAndClearTokenInformation();
        */
//        FBSession.activeSession().closeAndClearTokenInformation()
        let loginManager = FBSDKLoginManager()
        loginManager.logOut()
        PFUser.logOut()
        (UIApplication.shared().delegate as! AppDelegate).presentLoginViewController(animated: false)
    }

    func handleLogInError(error: NSError?) {
        if error != nil {
            let reason = error!.userInfo["com.facebook.sdk:ErrorLoginFailedReason"] as? String
            print("Error: \(reason)")
            let title: String = NSLocalizedString("Login Error", comment: "Login error title in PAPLogInViewController")
            let message: String = NSLocalizedString("Something went wrong. Please try again.", comment: "Login error message in PAPLogInViewController")
            
            if reason == "com.facebook.sdk:UserLoginCancelled" {
                return
            }
            
            
            if error!.code == PFErrorCode.errorFacebookInvalidSession.rawValue {
                print("Invalid session, logging out.")
                let loginManager = FBSDKLoginManager()
                loginManager.logOut()
                return
            }
            
            if error!.code == PFErrorCode.errorConnectionFailed.rawValue {
                let ok = NSLocalizedString("OK", comment: "OK")
                let title = NSLocalizedString("Offline Error", comment: "Offline Error")
                let message = NSLocalizedString("Something went wrong. Please try again.", comment: "Offline message")
                let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
                let okAction = UIAlertAction(title: ok, style: .default, handler: nil)
                
                // Add Actions
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
                return
            }
            let ok = NSLocalizedString("OK", comment: "OK")
            let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: ok, style: .default, handler: nil)
            
            // Add Actions
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }

}

@objc protocol PAPLogInViewControllerDelegate: NSObjectProtocol {
    func logInViewControllerDidLogUserIn(logInViewController: PAPLogInViewController)
}
