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
            let tabBarController = UITabBarController()
            let initialVC = UINavigationController(rootViewController: InitialViewController.shared)
            let navVC = UINavigationController(rootViewController: CalenderViewController(collectionViewLayout: UICollectionViewFlowLayout()))
            let button = UITabBarItem(title: "Calendar", image: nil, selectedImage: nil)
            button.setTitleTextAttributes([.font: UIFont.boldSystemFont(ofSize: 16)], for: .normal)
            button.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -8)
            navVC.tabBarItem = button
            let chartVC = ChartViewController()
            tabBarController.viewControllers = [initialVC, navVC, chartVC]
            window?.rootViewController = tabBarController
            window?.makeKeyAndVisible()
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
        persistentContainer = setupPersistentContainer()
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

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = setupPersistentContainer()
    
    
    func setupPersistentContainer() -> NSPersistentContainer {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        var container: NSPersistentContainer!
        
        if #available(iOS 13, *) {
            container = NSPersistentCloudKitContainer(name: "Spend_Companion")
            guard let description = container.persistentStoreDescriptions.first else {
                fatalError("###\(#function): Failed to retrieve a persistent store description.")
            }
            
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            if !iCloudKeyStore.bool(forKey: SettingNames.iCloudSync) {
                description.cloudKitContainerOptions = nil
            }
            
        } else {
            container = NSPersistentContainer(name: "Spend_Companion")
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
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
    }
    

    // MARK: - Core Data Saving support

    func saveContext () throws {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                throw SaveError.saveError
//                // Replace this implementation with code to handle the error appropriately.
//                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//                let nserror = error as NSError
//                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}


extension AppDelegate: UNUserNotificationCenterDelegate {
    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        return completionHandler([.alert, .sound])
    }

}


extension AppDelegate {
    
    
    public func clearDatabase() {
        guard let url = persistentContainer.persistentStoreDescriptions.first?.url else { return }
        
        let persistentStoreCoordinator = persistentContainer.persistentStoreCoordinator
        
        do {
            try persistentStoreCoordinator.destroyPersistentStore(at:url, ofType: NSSQLiteStoreType, options: nil)
            try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        } catch let error {
            print("Attempted to clear persistent store: " + error.localizedDescription)
        }
    }
    
}


enum SaveError: Error {
    case saveError
}
