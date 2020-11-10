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
import SwiftUI
import Combine


protocol SettingsCellDelegate: class {
    
    func settingsTogglePressed(toggleIsON: Bool, in cell: SettingsCell)
    
    
}

@available(iOS 13, *)
class SettingsViewController: UITableViewController {
    
    
// MARK:- Properties
    
    var cellId = "cellId"
    
    var iCloudKeyStore = (UIApplication.shared.delegate as! AppDelegate).iCloudKeyStore
    
    let iCloudPurchaseProductID = PurchaseIds.iCloudSync.description
    let iCloudPurchased = SettingNames.iCloudSyncPurchased
    
    let reminderPurchaseProductId = PurchaseIds.reminders.description
    let remindersPurchased = SettingNames.remindersPurchased
    
    var settings: [String] {
        var settingsList = ["iCloud sync"]
        if let biometricType = biometricType() {
            switch biometricType {
            case .faceID:
                settingsList.append("Enable faceID")
            case .touchID:
                settingsList.append("Enable touchID")
            default:
                break
            }
        } else {
            settingsList.append("Enable passcode")
        }
        settingsList.append("Select currency")
        if #available(iOS 14, *) {
            settingsList.append("Customize appearance")
        }
       return settingsList
    }
    
// MARK:- Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(SettingsCell.self, forCellReuseIdentifier: cellId)
        navigationController?.navigationBar.prefersLargeTitles = true
        title = "Settings"
        SKPaymentQueue.default().add(self)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Restore purchases", style: .plain, target: self, action: #selector(restorePurchases))
        tableView.tableFooterView = UIView()
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
        cell.textLabel?.font = UIFont.systemFont(ofSize: 18)
        
        switch indexPath.row {
        case 0:
            cell.settingsToggle.isOn = iCloudKeyStore.bool(forKey: "iCloud sync")
            cell.setupUI()
            cell.textLabel?.text = settings[indexPath.row]
            cell.detailTextLabel?.text = "sets iCloud sync across all devices"
            cell.selectionStyle = .none
        case 1:
            cell.settingsToggle.isOn = UserDefaults.standard.bool(forKey: SettingNames.enableBiometrics)
            cell.setupUI()
            cell.textLabel?.text = settings[indexPath.row]
            cell.selectionStyle = .none
        case 2:
            cell.textLabel?.text = settings[indexPath.row]
            cell.accessoryType = .disclosureIndicator
        case 3:
            if #available(iOS 14, *) {
                cell.textLabel?.text = settings[indexPath.row]
                cell.accessoryType = .disclosureIndicator
            }
        default:
            break
        }
        cell.delegate = self
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if indexPath.row == 2 {
            navigationController?.pushViewController(CurrencyViewController(), animated: true)
        }
        if indexPath.row == 3, #available(iOS 14, *) {
            navigationController?.pushViewController(CustomizeAppearanceController(), animated: true)
        }
    }
    
    
// MARK:- Methods
    
    func buyiCloudSync() {
        let alertController = UIAlertController(title: "Purchase iCloud sync", message: "for 1.99 USD (or equivalent in local currency) you can sync your transactions across all devices, syncing happens automatically!", preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Puchase", style: .default, handler: { [unowned self] (_) in
            if SKPaymentQueue.canMakePayments() {
                let paymentRequest = SKMutablePayment()
                paymentRequest.productIdentifier = iCloudPurchaseProductID
                SKPaymentQueue.default().add(paymentRequest)
            } else {
                print("User can't make payment")
            }
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { [unowned self] (_) in
            (tableView.cellForRow(at: IndexPath(item: 0, section: 0)) as? SettingsCell)?.settingsToggle.setOn(false, animated: true)
        }))
        present(alertController, animated: true)
    }
    
    func toggleiCloudSync(sync: Bool) {
        iCloudKeyStore.set(sync, forKey: SettingNames.iCloudSync)
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
    
    @objc func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
}

// MARK:- Settings Cell Delegate

@available(iOS 13, *)
extension SettingsViewController: SettingsCellDelegate {
    
    func settingsTogglePressed(toggleIsON: Bool, in cell: SettingsCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        switch (indexPath.row, toggleIsON) {
        case (0, true):
            CKContainer.default().accountStatus { [self] (status, error) in
                DispatchQueue.main.async {
                    if status == .available {
                        iCloudKeyStore.bool(forKey: iCloudPurchased) ? toggleiCloudSync(sync: toggleIsON) : buyiCloudSync()
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
            UserDefaults.standard.setValue(true, forKey: SettingNames.enableBiometrics)
        case (1, false):
            Authenticator.authenticate { (success, error) in
                if success {
                    UserDefaults.standard.setValue(false, forKey: SettingNames.enableBiometrics)
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

// MARK:- SKPayment Transaction Observer

@available(iOS 13, *)
extension SettingsViewController: SKPaymentTransactionObserver {
    
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                guard transaction.payment.productIdentifier == iCloudPurchaseProductID else { return }
                if iCloudKeyStore.bool(forKey: iCloudPurchased) == false {
                    iCloudKeyStore.set(true, forKey: iCloudPurchased)
                    let alertController = UIAlertController(title: "iCloud sync purchased!", message: "Now transactions will sync across all your devices", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Done", style: .default, handler: nil))
                    present(alertController, animated: true, completion: nil)
                    toggleiCloudSync(sync: true)
                    queue.finishTransaction(transaction)
                }
            case .failed:
                guard transaction.payment.productIdentifier == iCloudPurchaseProductID else { return }
                queue.finishTransaction(transaction)
                (tableView.cellForRow(at: IndexPath(item: 0, section: 0)) as? SettingsCell)?.settingsToggle.setOn(false, animated: true)
            case .restored:
                if transaction.original?.payment.productIdentifier == iCloudPurchaseProductID, iCloudKeyStore.bool(forKey: iCloudPurchased) == false {
                    iCloudKeyStore.set(true, forKey: iCloudPurchased)
                    toggleiCloudSync(sync: true)
                    (tableView.cellForRow(at: IndexPath(item: 0, section: 0)) as? SettingsCell)?.settingsToggle.setOn(true, animated: true)
                } else if transaction.original?.payment.productIdentifier == reminderPurchaseProductId, iCloudKeyStore.bool(forKey: remindersPurchased) == false {
                    iCloudKeyStore.set(true, forKey: remindersPurchased)
                }
            default: break
            }
        }
    }
    
}

// MARK:- Settings Cell

class SettingsCell: UITableViewCell {
    
    var settingsToggle = UISwitch()
    
    weak var delegate: SettingsCellDelegate?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        addSubview(settingsToggle)
        settingsToggle.anchor(trailing: trailingAnchor, trailingConstant: 20, centerY: centerYAnchor)
        settingsToggle.addTarget(self, action: #selector(settingsTogglePressed), for: .valueChanged)
    }
    
    @objc func settingsTogglePressed() {
        delegate?.settingsTogglePressed(toggleIsON: settingsToggle.isOn, in: self)
    }
    
    
}
