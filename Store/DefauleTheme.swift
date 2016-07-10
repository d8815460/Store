//
//  DefauleTheme.swift
//  Mega
//
//  Created by 駿逸 陳 on 2016/4/8.
//  Copyright © 2016年 App Design Vault. All rights reserved.
//

import Foundation
import UIKit

public class DefauleTheme {
    
    public init() { }
    
    
    
    public class var getDeviceType : String {
        let screenSize : CGSize = UIScreen.main().bounds.size
        let screenWidth : CGFloat = screenSize.width
        let screenHeight : CGFloat = screenSize.height
        
        if screenWidth == 320 && screenHeight == 568{
            // iphone5
            return "iphone5"
        } else if screenWidth == 375 && screenHeight == 667 {
            // iphone6
            return "iphone6"
        } else if screenWidth == 414 && screenHeight == 736 {
            // iphone6plus
            return "iphone6plus"
        } else {
            // iphone4以下
            return "iphone4"
        }
    }
    
    public class var fontName : String {
        return "Avenir-Book"
    }
    
    public class var boldFontName : String {
        return "Avenir-Black"
    }
    
    public class var semiBoldFontName : String {
        return "Avenir-Heavy"
    }
    
    public class var lighterFontName : String {
        return "Avenir-Light"
    }
    
    public class var darkColor : UIColor {
        return UIColor.black()
    }
    
    public class var lightColor : UIColor {
        return UIColor(white: 0.6, alpha: 1.0)
    }
    
    public class var clearColor : UIColor {
        return UIColor.clear()
    }
    
    public class var whiteColor : UIColor {
        return UIColor.white()
    }
    
    public class var loginWhiteColor : UIColor {
        return UIColor(red: 225.0/255.0, green: 233.0/255.0, blue: 240.0/255.0, alpha: 1)
    }
    
    // TextField主要顏色
    public class var mainTextFieldColor : UIColor {
        return whiteColor
    }
    
    // Text 副色系
    public class var subTextColor : UIColor {
        return whiteColor
    }
    
    // TextFieldPlaceholder
    public class var textPlaceholderColor : UIColor {
        return ThirdColor
    }
    
    
    // 主要顏色（MainColor）
    public class var MainColor : UIColor {
        return Navy
    }
    
    // 次要顏色（SubColor）
    public class var SubColor : UIColor {
        return SteelBlue
    }
    
    // 第3顏色（ThirdColor）
    public class var ThirdColor : UIColor {
        return PowderBlue
    }
    
    
    
    // 海軍藍（Navy）
    public class var Navy : UIColor {
        return UIColor(red: 0.0, green: 66.0/255.0, blue: 130.0/255.0, alpha: 1)
    }
    
    // 鋼藍（SteelBlue）
    public class var SteelBlue : UIColor {
        return UIColor(red: 38.0/255.0, green: 141.0/255.0, blue: 205.0/255.0, alpha: 1)
    }
    
    // 粉藍（PowderBlue）
    public class var PowderBlue : UIColor {
        return UIColor(red: 104.0/255.0, green: 185.0/255.0, blue: 225.0/255.0, alpha: 1)
    }
    
    // 咖啡黑（BlackCoffee）
    public class var BlackCoffee : UIColor {
        return UIColor(red: 75.0/255.0, green: 71.0/255.0, blue: 67.0/255.0, alpha: 1)
    }
    
    // 按鈕主色
    public class var buttonMainColor : UIColor {
        return UIColor.white()
    }
    
    // 按鈕被壓住的顏色
    public class var buttonHighlightedColor : UIColor {
        return PowderBlue
    }
    
    // 按鈕被選擇的顏色
    public class var buttonSelectedColor : UIColor {
        return BlackCoffee
    }
    
    
    
    
    
    public func getImageWithColor(_ color: UIColor, size: CGSize) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    public func customizeAppAppearance() {
        let navAppearance = UINavigationBar.appearance()
        let backImage = UIImage( named: "back")
        
        // 設置導航欄，變得透明與否
        navAppearance.isTranslucent = false
        // 返回鍵
        navAppearance.backIndicatorImage = backImage
        navAppearance.backIndicatorTransitionMaskImage = backImage
        navAppearance.setBackgroundImage(getImageWithColor(DefauleTheme.MainColor, size: CGSize(width: 200, height: 200)), for: UIBarMetrics.default)
        navAppearance.tintColor = DefauleTheme.mainTextFieldColor
        
        
        // 設置ToorBar，變得透明與否
        let toolbarAppearance = UIToolbar.appearance()
        toolbarAppearance.isTranslucent = false
        toolbarAppearance.tintColor = DefauleTheme.mainTextFieldColor
        toolbarAppearance.setBackgroundImage(getImageWithColor(DefauleTheme.MainColor, size: CGSize(width: 200, height: 200)), forToolbarPosition: .any, barMetrics: UIBarMetrics.default)
        
        var textAttributes : [String : AnyObject] = [String : AnyObject]()
        textAttributes[NSForegroundColorAttributeName] = UIColor.white()
        textAttributes[NSFontAttributeName] = UIFont(name: DefauleTheme.fontName, size: 19)
        
        navAppearance.titleTextAttributes = textAttributes
        
        let barButtonAppearance = UIBarButtonItem.appearance()
        barButtonAppearance.setBackButtonTitlePositionAdjustment(UIOffsetMake(0, -60), for: .default)
        barButtonAppearance.setBackButtonTitlePositionAdjustment(UIOffsetMake(0, -60), for: .compact)
        
        
        let buttonAppearance = UIButton.appearance()
        buttonAppearance.setTitleColor(DefauleTheme.MainColor,        for: UIControlState())
        buttonAppearance.setTitleColor(DefauleTheme.buttonMainColor, for: UIControlState.highlighted)
        buttonAppearance.setTitleColor(DefauleTheme.BlackCoffee,    for: UIControlState.selected)
        
        buttonAppearance.setBackgroundImage(getImageWithColor(DefauleTheme.buttonMainColor, size: CGSize(width: 200, height: 200)), for: UIControlState())
        buttonAppearance.setBackgroundImage(getImageWithColor(DefauleTheme.buttonHighlightedColor, size: CGSize(width: 200, height: 200)), for: UIControlState.highlighted)
        buttonAppearance.setBackgroundImage(getImageWithColor(DefauleTheme.buttonSelectedColor, size: CGSize(width: 200, height: 200)), for: UIControlState.selected)
        
        // 不知道為什麼layer陰影不work，待查
        buttonAppearance.layer.shadowColor = UIColor.black().cgColor
        buttonAppearance.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        buttonAppearance.layer.masksToBounds = false
        buttonAppearance.layer.shadowRadius = 1.0
        buttonAppearance.layer.shadowOpacity = 0.5
        
        
        // TextField 
        let textfieldAppearance = UITextField.appearance()
        textfieldAppearance.textColor = DefauleTheme.mainTextFieldColor
        
        
        // AlertViewController
//        let alertViewController = UIAlertController.appearance()
//        alertViewController.tintColor = DefauleTheme.MainColor
        
    }
}
