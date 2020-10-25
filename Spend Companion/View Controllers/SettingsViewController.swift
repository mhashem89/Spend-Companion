//
//  SettingsViewController.swift
//  Spend Companion
//
//  Created by Mohamed Hashem on 10/19/20.
//

import UIKit
import StoreKit
import CloudKit
import LocalAuthentication


protocol SettingsCellDelegate: class {
    
    func settingsTogglePressed(toggleIsON: Bool, in cell: SettingsCell)
    
    
}

class SettingsViewController: UITableViewController {
    
    
    // MARK:- Properties
    
    var cellId = "cellId"
    
    var iCloudKeyStore = (UIApplication.shared.delegate as! AppDelegate).iCloudKeyStore
    
    let iCloudPurchaseProductID = "MohamedHashem.Spend_Companion.iCloud_sync"
    
    var settings: [String] {
        var settingsList = ["iCloudSync"]
        if let biometricType = biometricType() {
            switch biometricType {
            case .faceID:
                settingsList.append("Enable faceID")
            case .touchID:
                settingsList.append("Enable touchID")
            default:
                break
            }
        }
       return settingsList
    }
    
    // MARK:- Lifecycle Methods
    
    override init(style: UITableView.Style) {
        super.init(style: style)
        if #available(iOS 13, *) {
            tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gear"), tag: 3)
        } else {
            let button = UITabBarItem(title: "Settings", image: nil, selectedImage: nil)
            button.setTitleTextAttributes([.font: UIFont.boldSystemFont(ofSize: 16)], for: .normal)
            button.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -8)
            navigationController?.tabBarItem = button
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(SettingsCell.self, forCellReuseIdentifier: cellId)
        navigationController?.navigationBar.prefersLargeTitles = true
        title = "Settings"
        tableView.allowsSelection = false
        SKPaymentQueue.default().add(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // MARK:- Table View Methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! SettingsCell
        cell.textLabel?.text = settings[indexPath.row]
        cell.textLabel?.font = UIFont.systemFont(ofSize: 18)
        cell.setupUI()
        switch indexPath.row {
        case 0:
            cell.settingsToggle.isOn = iCloudKeyStore.bool(forKey: "iCloud sync")
        case 1:
            cell.settingsToggle.isOn = UserDefaults.standard.bool(forKey: "EnableBiometrics")
        default:
            break
        }
       
        cell.delegate = self
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func buyiCloudSync() {
        if SKPaymentQueue.canMakePayments() {
            let paymentRequest = SKMutablePayment()
            paymentRequest.productIdentifier = iCloudPurchaseProductID
            SKPaymentQueue.default().add(paymentRequest)
        } else {
            print("User can't make payment")
        }
    }
    
    func toggleiCloudSync(sync: Bool) {
        iCloudKeyStore.set(sync, forKey: "iCloud sync")
        iCloudKeyStore.synchronize()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.persistentContainer = appDelegate.setupPersistentContainer()
        InitialViewController.shared.updateData()
    }
    
    func biometricType() -> LABiometryType? {
        if LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            return LAContext().biometryType
        } else {
            return nil
        }
    }
    

}


extension SettingsViewController: SettingsCellDelegate {
    
    
    func settingsTogglePressed(toggleIsON: Bool, in cell: SettingsCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        switch (indexPath.row, toggleIsON) {
        case (0, true):
            CKContainer.default().accountStatus { [self] (status, error) in
                DispatchQueue.main.async {
                    if status == .available {
                        toggleiCloudSync(sync: toggleIsON)
                        buyiCloudSync()
                    } else {
                        let alertController = UIAlertController(title: "Error: iCloud not available", message: "Please sign in to your iCloud account and make sure it is enabled for Spend Companion", preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "Done", style: .default, handler: { (action) in
                            cell.settingsToggle.setOn(false, animated: true)
                        }))
                        present(alertController, animated: true)
                    }
                }
            }
        case (0, false):
            toggleiCloudSync(sync: toggleIsON)
        case (1, true):
            UserDefaults.standard.setValue(true, forKey: "EnableBiometrics")
        case (1, false):
            Authenticator.authenticate { (success, error) in
                if success {
                    UserDefaults.standard.setValue(false, forKey: "EnableBiometrics")
                } else {
                    let ac = UIAlertController(title: "Authentication failed", message: "You could not be verified; please try again.", preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                        cell.settingsToggle.setOn(true, animated: true)
                    }))
                    self.present(ac, animated: true)
                }
            }
        default:
            break
        }
    }
    
}


extension SettingsViewController: SKPaymentTransactionObserver {
    
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            
            switch transaction.transactionState {
            case .purchasing: print("WTF 1")
            case .purchased: print("WTF 2")
            case .failed: print("WTF 3"); queue.finishTransaction(transaction)
            case .deferred: print("WTF 4")
            default: break
            }
        }
    }
    
}



class SettingsCell: UITableViewCell {
    
    var settingsToggle = UISwitch()
    
    weak var delegate: SettingsCellDelegate?
    
    func setupUI() {
        addSubview(settingsToggle)
        settingsToggle.anchor(trailing: trailingAnchor, trailingConstant: 20, centerY: centerYAnchor)
        settingsToggle.addTarget(self, action: #selector(settingsTogglePressed), for: .valueChanged)
    }
    
    @objc func settingsTogglePressed() {
        delegate?.settingsTogglePressed(toggleIsON: settingsToggle.isOn, in: self)
    }
    
    
}
