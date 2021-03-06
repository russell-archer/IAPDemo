//
//  AppDelegate.swift
//  IAPDemo
//
//  Created by Russell Archer on 23/11/2020.
//

import UIKit
import IAPHelper

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    public var iapHelper: IAPHelper!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Make sure the IAPHelper is initialized early in the app's lifecycle to ensure we don't miss any App Store notifications
        iapHelper = IAPHelper.shared
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        iapHelper.removeFromPaymentQueue()
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

