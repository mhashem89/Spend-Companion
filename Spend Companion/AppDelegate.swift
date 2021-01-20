//
//  AppDelegate.swift
//  Spend Companion
//
//  Created by Mohamed Hashem on 10/18/20.
//

import UIKit
import CoreData
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var iCloudKeyStore = NSUbiquitousKeyValueStore.default

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        if #available(iOS 13, *) {
            
        } else {
            self.window = UIWindow()
            let tabBarController = CustomTabBarController()
            window?.rootViewController = tabBarController
            window?.makeKeyAndVisible()
            InitialViewController.shared.reloadRecentItems(withFetch: true)
        }
        
        UNUserNotificationCenter.current().delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(ubiquitousStoreDidChangeExternally), name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: NSUbiquitousKeyValueStore.default)
        iCloudKeyStore.synchronize()
        if UserDefaults.standard.value(forKey: SettingNames.currency) == nil {
            UserDefaults.standard.setValue("Local currency", forKey: SettingNames.currency)
        }
        return true
    }
    
    @objc func ubiquitousStoreDidChangeExternally() {
        CoreDataManager.shared.persistentContainer = CoreDataManager.shared.setupPersistentContainer()
        InitialViewController.shared.updateData()
    }
    
    // MARK: UISceneSession Lifecycle

    @available(iOS 13, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    @available(iOS 13, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}


extension AppDelegate: UNUserNotificationCenterDelegate {
    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        return completionHandler([.alert, .sound])
    }

}
