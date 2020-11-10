//
//  TabBarController.swift
//  Spend Companion
//
//  Created by Mohamed Hashem on 11/9/20.
//

import UIKit



class CustomTabBarController: UITabBarController {
    
    lazy var lockingView: LockingView = {
        let view = LockingView()
        view.loginButton.addTarget(self, action: #selector(authenticate), for: .touchUpInside)
        return view
    }()
    
    let initialVC = UINavigationController(rootViewController: InitialViewController.shared)
    lazy var calendarVC = UINavigationController(rootViewController: CalenderViewController(collectionViewLayout: UICollectionViewFlowLayout()))
    lazy var chartVC = ChartViewController()
    var settingsVC: UINavigationController?
    
    let thirdBarItem: UITabBarItem = {
        if #available(iOS 14, *) {
            return UITabBarItem(title: "Chart", image: UIImage(systemName: "chart.bar.doc.horizontal"), tag: 2)
        } else if #available(iOS 13, *) {
            return UITabBarItem(title: "Chart", image: UIImage(systemName: "chart.bar.fill"), tag: 2)
        } else {
            let button = UITabBarItem(title: "Chart", image: nil, selectedImage: nil).setupForOldiOS()
            return button
        }
    }()

    lazy var tabBarItems: [UITabBarItem] = {
        if #available(iOS 13, *) {
            let firstBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house.fill"), tag: 0)
            let secondBarItem = UITabBarItem(title: "Calendar", image: UIImage(systemName: "calendar"), tag: 1)
            let fourthBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gear"), tag: 3)
            return [firstBarItem, secondBarItem, thirdBarItem, fourthBarItem]
        } else {
            let firstBarItem = UITabBarItem(title: "Home", image: nil, selectedImage: nil).setupForOldiOS()
            let secondBarItem = UITabBarItem(title: "Calendar", image: nil, selectedImage: nil).setupForOldiOS()
            let thirdBarItem = UITabBarItem(title: "Chart", image: nil, selectedImage: nil).setupForOldiOS()
            return [firstBarItem, secondBarItem, thirdBarItem]
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewControllers = [initialVC, calendarVC, chartVC]
        if #available(iOS 13, *) {
            settingsVC = UINavigationController(rootViewController: SettingsViewController(style: .plain))
            viewControllers?.append(settingsVC!)
        }
        initialVC.tabBarItem = tabBarItems[0]
        calendarVC.tabBarItem = tabBarItems[1]
        chartVC.tabBarItem = tabBarItems[2]
        settingsVC?.tabBarItem = tabBarItems[3]
    }
    
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




