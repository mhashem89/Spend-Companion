//
//  SettingsCell.swift
//  Spend Companion
//
//  Created by Mohamed Hashem on 11/17/20.
//

import UIKit
import LocalAuthentication


class SettingsCell: UITableViewCell {
    
    var iCloudKeyStore = (UIApplication.shared.delegate as! AppDelegate).iCloudKeyStore
    
    var settingsToggle = UISwitch()
    
    var purchaseButton = UIButton.purchaseButton(withFont: UIFont.boldSystemFont(ofSize: 14))
    
    weak var delegate: SettingsCellDelegate?
    
    var setting: Setting?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        guard let setting = setting else { return }
        switch setting {
        case .iCloudSync:
            if iCloudKeyStore.bool(forKey: SettingNames.iCloudSyncPurchased) {
                showSettingsToggle()
                settingsToggle.isOn = iCloudKeyStore.bool(forKey: SettingNames.iCloudSync)
            } else {
                showPurchaseButton()
            }
            textLabel?.text = "iCloud sync"
            detailTextLabel?.text = "set iCloud sync across all devices"
            selectionStyle = .none
        case .biometrics:
            showSettingsToggle()
            settingsToggle.isOn = UserDefaults.standard.bool(forKey: SettingNames.enableBiometrics)
            selectionStyle = .none
            if let biometry = biometricType() {
                switch biometry {
                case .faceID:
                    textLabel?.text = "Enable faceID"
                case .touchID:
                    textLabel?.text = "Enable touchID"
                case .none:
                    textLabel?.text = "Enable biometry"
                    settingsToggle.isEnabled = false
                default:
                    break
                }
            }
        case .reminder:
            textLabel?.text = "Daily reminder"
            showSettingsToggle()
            if let reminderTime = UserDefaults.standard.value(forKey: SettingNames.dailyReminderTime) as? String {
                detailTextLabel?.text = reminderTime
                settingsToggle.isOn = true
            }
            selectionStyle = .none
        case .currency:
            textLabel?.text = "Select currency"
            accessoryType = .disclosureIndicator
        case .appearance:
            if #available(iOS 14, *) {
                textLabel?.text = "Customize appearance"
                accessoryType = .disclosureIndicator
            }
        case .support:
            textLabel?.text = "Support"
        case .feedback:
            textLabel?.text = "Rate us"
        case .share:
            textLabel?.text = "Share with friends"
        case .export:
            textLabel?.text = "Export data"
            detailTextLabel?.text = "convert all data into CSV format"
        case .delete:
            textLabel?.text = "Delete all data"
            textLabel?.textColor = CustomColors.red
        }
    }
    
    func showPurchaseButton() {
        settingsToggle.removeFromSuperview()
        if !subviews.contains(purchaseButton) {
            addSubview(purchaseButton)
            purchaseButton.anchor(trailing: trailingAnchor, trailingConstant: 20, centerY: centerYAnchor, widthConstant: 75)
            purchaseButton.addTarget(self, action: #selector(purchaseButtonPressed), for: .touchUpInside)
        }
    }
    
    func showSettingsToggle() {
        purchaseButton.removeFromSuperview()
        if !subviews.contains(settingsToggle) {
            addSubview(settingsToggle)
            settingsToggle.anchor(trailing: trailingAnchor, trailingConstant: 20, centerY: centerYAnchor)
            settingsToggle.addTarget(self, action: #selector(settingsTogglePressed), for: .valueChanged)
        }
    }

    
    func biometricType() -> LABiometryType? {
        if LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) {
            return LAContext().biometryType
        } else {
            return nil
        }
    }
    
    @objc func settingsTogglePressed() {
        delegate?.settingsTogglePressed(toggleIsON: settingsToggle.isOn, in: self)
    }
    
    @objc func purchaseButtonPressed() {
        delegate?.purchaseButtonPressed()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        textLabel?.text = nil
        detailTextLabel?.text = nil
        accessoryType = .none
        textLabel?.textColor = CustomColors.label
        settingsToggle.removeFromSuperview()
        purchaseButton.removeFromSuperview()
    }
    
}


