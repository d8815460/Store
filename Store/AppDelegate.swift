//
//  AppDelegate.swift
//  Store
//
//  Created by Ayi on 2016/7/9.
//  Copyright © 2016年 Ayi. All rights reserved.
//

import UIKit
import CoreData
import Fabric
import Crashlytics
import Stripe
import Parse
import ParseCrashReporting
import ParseFacebookUtilsV4
import MBProgressHUD

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var networkStatus: Reachability.NetworkStatus?
    
    private var firstLaunch: Bool = true

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        // 設定Fabric
        Fabric.with([STPAPIClient.self, Crashlytics.self])
        
        // 設定Parse
        // ****************************************************************************
        // Parse initialization
        ParseCrashReporting.enable()
        Parse.setApplicationId("YiaRp86pvUzXygYbTh601Pq1BENz0S2GJogDSdBf", clientKey: "kncdDkcJQNZRqUpw2TioNsv9c3fyJa0Frw7DY7zl")
        // 設定FacebookUtilsV4
        PFFacebookUtils.initializeFacebook(applicationLaunchOptions: launchOptions)
        // TODO: PFFacebookUtils.initialize()
        // ****************************************************************************
        
        // 追蹤 app open.
        PFAnalytics.trackAppOpened(launchOptions: launchOptions)
        
        if (PFUser.current() != nil) {
            let defaultACL = PFACL()
            // If you would like all objects to be private by default, remove this line.
            defaultACL.setReadAccess(true, for: PFUser.current()!)
            PFACL.setDefault(defaultACL, withAccessForCurrentUser: true)
        }
        
        if (application.applicationState != UIApplicationState.background) {
            // Track an app open here if we launch with a push, unless
            // "content_available" was used to trigger a background push (introduced in iOS 7).
            // In that case, we skip tracking here to avoid double counting the app-open.
            
        }
        
        // Badge歸零
        if application.applicationIconBadgeNumber != 0 {
            application.applicationIconBadgeNumber = 0
            PFInstallation.current().saveInBackground()
        }
        
        let defaultACL: PFACL = PFACL()
        // Enable public read access by default, with any newly created PFObjects belonging to the current user
        defaultACL.getPublicReadAccess = true
        PFACL.setDefault(defaultACL, withAccessForCurrentUser: true)
        
        // 設定Theme
        // Set up our app's global UIAppearance
        self.setupAppearance()
        
        // Use Reachability to monitor connectivity
        self.monitorReachability()
        
        self.handlePush(launchOptions: launchOptions)
        
        // Register for Push Notitications （不一定要在這裡實作） iOS9 的做法
        let userNotificationTypes: UIUserNotificationType = [UIUserNotificationType.alert, UIUserNotificationType.badge, UIUserNotificationType.sound]
        let settings: UIUserNotificationSettings = UIUserNotificationSettings(types: userNotificationTypes, categories: nil)
        UIApplication.shared().registerUserNotificationSettings(settings)
        UIApplication.shared().registerForRemoteNotifications()
        
        return true
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        if (application.applicationIconBadgeNumber != 0) {
            application.applicationIconBadgeNumber = 0
        }
        
        let currentInstallation = PFInstallation.current()
        currentInstallation.setDeviceTokenFrom(deviceToken)
        currentInstallation.saveInBackground()
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        if error.code != 3010 { // 3010 is for the iPhone Simulator
            print("Application failed to register for push notifications: \(error)")
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        NotificationCenter.default().post(name: NSNotification.Name(rawValue: PAPAppDelegateApplicationDidReceiveRemoteNotification), object: nil, userInfo: userInfo)
        
        if UIApplication.shared().applicationState != UIApplicationState.active {
            // Track app opens due to a push notification being acknowledged while the app wasn't active.
            PFAnalytics.trackAppOpened(withRemoteNotificationPayload: userInfo)
        }
        
        if PFUser.current() != nil {
            // FIXME: Looks so lengthy, any better way?
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        // Clear badge and update installation, required for auto-incrementing badges.
        if application.applicationIconBadgeNumber != 0 {
            application.applicationIconBadgeNumber = 0
            PFInstallation.current().saveInBackground()
        }
        
        // Clears out all notifications from Notification Center.
        UIApplication.shared().cancelAllLocalNotifications()
        application.applicationIconBadgeNumber = 1
        application.applicationIconBadgeNumber = 0
        
        FBSDKAppEvents.activateApp()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK:- AppDelegate
    
    func isParseReachable() -> Bool {
        return self.networkStatus != .NotReachable
    }
    
    // 跳出登入畫面
    func presentLoginViewController(animated: Bool = true) {
//        self.welcomeViewController!.presentLoginViewController(animated)
    }
    
    // 跳出首頁Tabbar頁面
    internal func presentTabBarController() {
        
    }
    
    func logOut() {
        // clear cache
        PAPCache.sharedCache.clear()
        
        // clear NSUserDefaults
        UserDefaults.standard().removeObject(forKey: kPAPUserDefaultsCacheFacebookFriendsKey)
        UserDefaults.standard().removeObject(forKey: kPAPUserDefaultsActivityFeedViewControllerLastRefreshKey)
        UserDefaults.standard().synchronize()
        
        // Unsubscribe from push notifications by removing the user association from the current installation.
        PFInstallation.current().remove(forKey: kPAPInstallationUserKey)
        PFInstallation.current().saveInBackground()
        
        // Clear all caches
        PFQuery.clearAllCachedResults()
        
        // Log out
        PFUser.logOut()
//        FBSession.setActiveSession(nil)
        _ = FBSDKAccessToken.current().tokenString
        
        // clear out cached data, view controllers, etc
        
        presentLoginViewController()
    }
    
    
    // MARK: - 其他
    
    // Set up appearance parameters to achieve Anypic's custom look and feel
    func setupAppearance() {
        UIApplication.shared().statusBarStyle = UIStatusBarStyle.lightContent
        
        UINavigationBar.appearance().tintColor = UIColor(red: 254.0/255.0, green: 149.0/255.0, blue: 50.0/255.0, alpha: 1.0)
        UINavigationBar.appearance().barTintColor = UIColor(red: 0.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: 1.0)
        
        UINavigationBar.appearance().titleTextAttributes = [ NSForegroundColorAttributeName: UIColor.white() ]
        
//        UIButton.appearanceWhenContainedInInstancesOfClasses([UINavigationBar.self]).setTitleColor(UIColor(red: 254.0/255.0, green: 149.0/255.0, blue: 50.0/255.0, alpha: 1.0), forState: [])
        
        UIBarButtonItem.appearance().setTitleTextAttributes([ NSForegroundColorAttributeName: UIColor(red: 254.0/255.0, green: 149.0/255.0, blue: 50.0/255.0, alpha: 1.0) ], for: [])
        
        UISearchBar.appearance().tintColor = UIColor(red: 254.0/255.0, green: 149.0/255.0, blue: 50.0/255.0, alpha: 1.0)
    }
    
    func monitorReachability() {
        guard let reachability = Reachability(hostname: "api.parse.com") else {
            return
        }
        
        reachability.whenReachable = { (reach: Reachability) in
            self.networkStatus = reach.currentReachabilityStatus
            if self.isParseReachable() && PFUser.current() != nil {
                // Refresh home timeline on network restoration. Takes care of a freshly installed app that failed to load the main timeline under bad network conditions.
                // In this case, they'd see the empty timeline placeholder and have no way of refreshing the timeline unless they followed someone.
            }
        }
        reachability.whenUnreachable = { (reach: Reachability) in
            self.networkStatus = reach.currentReachabilityStatus
        }
        
        _ = reachability.startNotifier()
    }
    
    func handlePush(launchOptions: [NSObject: AnyObject]?) {
        // If the app was launched in response to a push notification, we'll handle the payload here
        guard let remoteNotificationPayload = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] as? [NSObject : AnyObject] else { return }
        
        NotificationCenter.default().post(name: NSNotification.Name(rawValue: PAPAppDelegateApplicationDidReceiveRemoteNotification), object: nil, userInfo: remoteNotificationPayload)
        
        if PFUser.current() == nil {
            return
        }
        
        // If the push notification payload references a photo, we will attempt to push this view controller into view
        if let photoObjectId = remoteNotificationPayload[kPAPPushPayloadPhotoObjectIdKey] as? String where photoObjectId.characters.count > 0 {
//            shouldNavigateToPhoto(PFObject(outDataWithObjectId: photoObjectId))
            return
        }
        
        // If the push notification payload references a user, we will attempt to push their profile into view
        guard let fromObjectId = remoteNotificationPayload[kPAPPushPayloadFromUserObjectIdKey] as? String where fromObjectId.characters.count > 0 else { return }
        
        let query: PFQuery? = PFUser.query()
        query!.cachePolicy = PFCachePolicy.cacheElseNetwork
        query!.getObjectInBackground(withId: fromObjectId, block: { (user, error) in
            if error == nil {
//                let homeNavigationController = self.tabBarController!.viewControllers![PAPTabBarControllerViewControllerIndex.HomeTabBarItemIndex.rawValue] as? UINavigationController
//                self.tabBarController!.selectedViewController = homeNavigationController
//                
//                let accountViewController = PAPAccountViewController(user: user as! PFUser)
//                print("Presenting account view controller with user: \(user!)")
//                homeNavigationController!.pushViewController(accountViewController, animated: true)
            }
        })
    }
    
    func autoFollowTimerFired(aTimer: Timer) {
//        MBProgressHUD.hideHUDForView(navController!.presentedViewController!.view, animated: true)
//        MBProgressHUD.hideHUDForView(homeViewController!.view, animated: true)
//        self.homeViewController!.loadObjects()
    }
    
    func shouldProceedToMainInterface(user: PFUser)-> Bool{
//        MBProgressHUD.hideHUDForView(navController!.presentedViewController!.view, animated: true)
        self.presentTabBarController()
        
//        self.navController!.dismissViewControllerAnimated(true, completion: nil)
        return true
    }
    
    func handleActionURL(url: NSURL) -> Bool {
        if url.host == kPAPLaunchURLHostTakePicture {
            if PFUser.current() != nil {
//                return tabBarController!.shouldPresentPhotoCaptureController()
            }
        } else {
            // FIXME: Is it working?           if ([[url fragment] rangeOfString:@"^pic/[A-Za-z0-9]{10}$" options:NSRegularExpressionSearch].location != NSNotFound) {
//            if url.fragment!.rangeOfString("^pic/[A-Za-z0-9]{10}$" , options: [.RegularExpressionSearch]) != nil {
//                let photoObjectId: String = url.fragment!.subString(4, length: 10)
//                if photoObjectId.length > 0 {
//                    print("WOOP: %@", photoObjectId)
//                    shouldNavigateToPhoto(PFObject(outDataWithObjectId: photoObjectId))
//                    return true
//                }
//            }
        }
        
        return false
    }
    
    func autoFollowUsers() {
        firstLaunch = true
        PFCloud.callFunction(inBackground: "autoFollowUsers", withParameters: nil, block: { (_, error) in
            if error != nil {
                print("Error auto following users: \(error)")
            }
//            MBProgressHUD.hideHUDForView(self.navController!.presentedViewController!.view, animated:false)
//            self.homeViewController!.loadObjects()
        })
    }
    
    
    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "Store")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

