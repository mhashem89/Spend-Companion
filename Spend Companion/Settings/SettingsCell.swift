//
//  SettingsCell.swift
//  Spend Companion
//
//  Created by Mohamed Hashem on 11/17/20.
//

import UIKit


class SettingsCell: UITableViewCell {
    
    var settingsToggle = UISwitch()
    
    var purchaseButton = UIButton.purchaseButton(withFont: UIFont.boldSystemFont(ofSize: 14))
    
    weak var delegate: SettingsCellDelegate?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI(for setting: Setting, isPurchased purchased: Bool = true) {
        if setting == .iCloudSync, !purchased {
            settingsToggle.removeFromSuperview()
            addSubview(purchaseButton)
            purchaseButton.anchor(trailing: trailingAnchor, trailingConstant: 20, centerY: centerYAnchor, widthConstant: 75)
            purchaseButton.addTarget(self, action: #selector(purchaseButtonPressed), for: .touchUpInside)
        } else {
            purchaseButton.removeFromSuperview()
            addSubview(settingsToggle)
            settingsToggle.anchor(trailing: trailingAnchor, trailingConstant: 20, centerY: centerYAnchor)
            settingsToggle.addTarget(self, action: #selector(settingsTogglePressed), for: .valueChanged)
        }
    }
    
    @objc func settingsTogglePressed() {
        delegate?.settingsTogglePressed(toggleIsON: settingsToggle.isOn, in: self)
    }
    
    @objc func purchaseButtonPressed() {
        delegate?.purchaseButtonPressed()
    }
    
    
}


