//
//  ViewController+Appearance.swift
//  CommonUX
//
//  Created by 駿逸 陳 on 2016/4/15.
//  Copyright © 2016年 TUTK. All rights reserved.
//

import UIKit
import Dispatch.once

extension UIAlertController {
    class Appearance {
        
        private static let sharedInstance = Appearance()
        
        var tintColor: UIColor?
        
        private init() {
        }
        
        class func appearance() -> Appearance {
            return sharedInstance
        }
        
    }
    
    class func appearance() -> Appearance {
        return Appearance.appearance()
    }
    
    
    public override class func initialize() {
        struct Static {
            static var onceToken: Int = 0
        }

        // TODO: dispatch_once 在 swift3 失效
//        dispatch_once(&Static.onceToken) {
//            let originalSelector = #selector(UIViewController.viewWillLayoutSubviews)
//            let swizzledSelector = #selector(UIAlertController.swizzle_viewWillLayoutSubviews)
//            
//            let originalMethod = class_getInstanceMethod(self, originalSelector)
//            let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
//            
//            let didAddMethod = class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
//            if didAddMethod {
//                class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
//            } else {
//                method_exchangeImplementations(originalMethod, swizzledMethod);
//            }
//        }
    }
    
    func swizzle_viewWillLayoutSubviews() {
        swizzle_viewWillLayoutSubviews()
        
        let subview = self.view.subviews.first! as UIView
        let alertContentView = subview.subviews.first! as UIView
        self.view.isOpaque = false
        alertContentView.isOpaque = false
        alertContentView.backgroundColor = self.dynamicType.appearance().tintColor
        
//        self.view.tintColor = self.dynamicType.appearance().tintColor
//        self.view.backgroundColor = self.dynamicType.appearance().tintColor
    }
}
