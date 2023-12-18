//
//  AppDelegate.swift
//  ShadowsInAR
//
//  Created by Dmitry Bakcheev on 12/10/23.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
 
        window = UIWindow()
        window?.makeKeyAndVisible()
        
        let mainViewController = ViewController()
        window?.rootViewController = mainViewController
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        return true
    }


}

