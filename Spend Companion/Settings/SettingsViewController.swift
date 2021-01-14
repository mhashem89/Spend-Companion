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
import MessageUI


protocol SettingsCellDelegate: class {
    
    func settingsTogglePressed(toggleIsON: Bool, in cell: SettingsCell)
    
    func purchaseButtonPressed()
    
}

@available(iOS 13, *)
class SettingsViewController: UITableViewController {
    
    
// MARK:- Properties
        
    var iCloudKeyStore = (UIApplication.shared.delegate as! AppDelegate).iCloudKeyStore
    
    let iCloudPurchaseProductID = PurchaseIds.iCloudSync.description
    let iCloudPurchased = SettingNames.iCloudSyncPurchased
    
    let reminderPurchaseProductId = PurchaseIds.reminders.description
    let remindersPurchased = SettingNames.remindersPurchased
    
    var settings: [Setting] {
        var settingsList: [Setting] = [.iCloudSync, .biometrics, .currency, .support, .feedback, .share, .export, .delete]
        if #available(iOS 14, *) {
            settingsList.insert(.appearance, at: 3)
        }
        return settingsList
    }
    
    var dimmingView = UIView().withBackgroundColor(color: UIColor.black.withAlphaComponent(0.5))
    var activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
    
// MARK:- Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(SettingsCell.self, forCellReuseIdentifier: SettingsCell.reuseIdentifier)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingsCell.reuseIdentifier, for: indexPath) as! SettingsCell
        cell.textLabel?.font = UIFont.systemFont(ofSize: 18 * fontScale)
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: fontScale < 1 ? 12 : 12 * fontScale)
        cell.setting = settings[indexPath.row]
        cell.setupUI()
        cell.delegate = self
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard let setting = (tableView.cellForRow(at: indexPath) as? SettingsCell)?.setting else { return }
        switch setting {
        case .currency:
            navigationController?.pushViewController(CurrencyViewController(), animated: true)
        case.appearance:
            if #available(iOS 14, *) { navigationController?.pushViewController(CustomizeAppearanceController(), animated: true) }
        case .support:
            if MFMailComposeViewController.canSendMail() {
                let mc = MFMailComposeViewController()
                mc.mailComposeDelegate = self
                mc.setToRecipients(["spendcompanion@gmail.com"])
                mc.setSubject("Support")
                present(mc, animated: true, completion: nil)
            } else {
                let alertController = UIAlertController(title: nil, message: "Please email spendcompanion@gmail.com with any support issues", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                present(alertController, animated: true, completion: nil)
            }
        case .feedback:
            guard let productURL = URL(string: SettingNames.productURL) else { return }
            var components = URLComponents(url: productURL, resolvingAgainstBaseURL: false)
            components?.queryItems = [URLQueryItem(name: "action", value: "write-review")]
            guard let writeReviewURL = components?.url else { return }
            UIApplication.shared.open(writeReviewURL)
        case .share:
            let activityViewController = UIActivityViewController(activityItems: [SettingNames.productURL], applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
            present(activityViewController, animated: true)
        case .export:
            dimBackground()
            do {
                try CoreDataManager.shared.generateCSV(completion: { [weak self] (fileURL) in
                    let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
                    self?.present(activityViewController, animated: true, completion: {
                        self?.dimmingView.removeFromSuperview()
                    })
                })
            } catch let err {
                activityIndicator.stopAnimating()
                presentError(error: err)
            }
        case .delete:
            let alertController = UIAlertController(title: "Delete all data?", message: "This will delete all stored spending and income data.\n\n Warning: if iCloud sync is turned on, this will delete data on all devices. If you'd like to delete data only on this device, try uninstalling the application", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] (_) in
                do {
                    try CoreDataManager.shared.deleteAllData()
                    InitialViewController.shared.updateData()
                } catch let err {
                    self?.presentError(error: err)
                }
            }))
            present(alertController, animated: true, completion: nil)
        default:
            break
        }
    }
    
// MARK:- Methods
    
    private func dimBackground() {
        navigationController?.view.addSubview(dimmingView)
        dimmingView.fillSuperView()
        dimmingView.addSubview(activityIndicator)
        activityIndicator.anchor(centerX: dimmingView.centerXAnchor, centerY: dimmingView.centerYAnchor)
        activityIndicator.startAnimating()
        activityIndicator.hidesWhenStopped = true
    }
    
    func buyiCloudSync() {
        let idiom = UIDevice.current.userInterfaceIdiom
        let alertController = UIAlertController(title: "Purchase iCloud sync", message: "backup and sync your transactions across all devices signed in to iCloud for a one-time payment of 0.99 USD (or equivalent in local currency)", preferredStyle: idiom == .pad ? .alert : .actionSheet)
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
    
    @objc func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}

// MARK:- Settings Cell Delegate

@available(iOS 13, *)
extension SettingsViewController: SettingsCellDelegate {
    
    func purchaseButtonPressed() {
        buyiCloudSync()
    }

    func settingsTogglePressed(toggleIsON: Bool, in cell: SettingsCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        switch (indexPath.row, toggleIsON) {
        case (0, true):
            CKContainer.default().accountStatus { [self] (status, error) in
                DispatchQueue.main.async {
                    if status == .available {
                        toggleiCloudSync(sync: toggleIsON)
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
                    tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                    queue.finishTransaction(transaction)
                }
            case .failed:
                guard transaction.payment.productIdentifier == iCloudPurchaseProductID else { return }
                queue.finishTransaction(transaction)
            case .restored:
                if transaction.original?.payment.productIdentifier == iCloudPurchaseProductID, iCloudKeyStore.bool(forKey: iCloudPurchased) == false {
                    iCloudKeyStore.set(true, forKey: iCloudPurchased)
                    tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                } else if transaction.original?.payment.productIdentifier == reminderPurchaseProductId, iCloudKeyStore.bool(forKey: remindersPurchased) == false {
                    iCloudKeyStore.set(true, forKey: remindersPurchased)
                }
            default: break
            }
        }
    }
}


// MARK:- MFMailComposer Delegate

@available(iOS 13, *)
extension SettingsViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true, completion: nil)
    }
    
}

// MARK:- Settings

enum Setting {
    case iCloudSync, biometrics, currency, appearance, support, feedback, share, export, delete
}
