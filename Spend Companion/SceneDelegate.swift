//
//  SceneDelegate.swift
//  Spend Companion
//
//  Created by Mohamed Hashem on 10/18/20.
//

import UIKit

@available(iOS 13, *)

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    var tabBar: CustomTabBarController!

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let scene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: scene)
        tabBar = CustomTabBarController()
        let initialVC = UINavigationController(rootViewController: InitialViewController.shared)
        let calendarVC = CalenderViewController(collectionViewLayout: UICollectionViewFlowLayout())
        let navVC = UINavigationController(rootViewController: calendarVC)
        let chartVC = ChartViewController()
        let settingsVC = UINavigationController(rootViewController: SettingsViewController(style: .plain))
        tabBar.viewControllers = [initialVC, navVC, chartVC, settingsVC]
        window?.rootViewController = tabBar
        window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        if UserDefaults.standard.bool(forKey: SettingNames.enableBiometrics), tabBar != nil {
            tabBar.authenticate()
        }
        (UIApplication.shared.delegate as? AppDelegate)?.iCloudKeyStore.synchronize()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }


}



class CustomTabBarController: UITabBarController {
    
    lazy var lockingView: LockingView = {
        let view = LockingView()
        view.loginButton.addTarget(self, action: #selector(authenticate), for: .touchUpInside)
        return view
    }()
    
    
    @objc func authenticate() {
        if !view.subviews.contains(lockingView) {
            view.addSubview(lockingView)
            lockingView.frame = view.bounds
            lockingView.setupUI()
        } else {
            lockingView.loginButton.isHidden = true
        }
        Authenticator.authenticate { [weak self] (success, error) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if success {
                    UIView.animate(withDuration: 0.3) {
                        self.lockingView.frame.origin.y = self.lockingView.frame.height
                    } completion: { (_) in
                        self.lockingView.removeFromSuperview()
                    }
                } else {
                    let ac = UIAlertController(title: "Authentication failed", message: "You could not be verified; please try again.", preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                        self.lockingView.loginButton.isHidden = false
                    }))
                    self.present(ac, animated: true)
                }
            }
        }
    }
}


