//
//  RecentItemCell.swift
//  Spending App
//
//  Created by Mohamed Hashem on 10/11/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit


class RecentItemCell: UITableViewCell {
    
    
    var userCurrency: String? {
        return UserDefaults.standard.value(forKey: "currency") as? String
    }
    
    var currencySymbol: String? {
        if let storedCurrency = userCurrency {
            return CurrencyViewController.extractSymbol(from: storedCurrency)
        } else {
            return "$"
        }
    }
    
    var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    var amountLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = CustomColors.label
        lbl.font = UIFont.systemFont(ofSize: fontScale < 1 ? 14 : 16 * fontScale)
        return lbl
    }()
    
    var recurringCircleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setAttributedTitle(NSAttributedString(string: "⟳", attributes: [.font: UIFont.boldSystemFont(ofSize: 30 * fontScale)]), for: .normal)
        return button
    }()
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        addSubview(amountLabel)
        amountLabel.anchor(trailing: trailingAnchor, trailingConstant: 10, centerY: centerYAnchor)
    }
    
    func addRecurrence() {
        addSubview(recurringCircleButton)
        recurringCircleButton.anchor(leading: textLabel?.trailingAnchor, leadingConstant: 10, centerY: centerYAnchor)
    }
    
    func formatAmountLabel(with amount: Double) {
        let amountString = String(format: "%g", amount)
        if let storedCurrency = userCurrency {
            if storedCurrency == "Local currency" {
                amountLabel.text = numberFormatter.string(from: NSNumber(value: amount))
            } else if let currencyPosition = CurrencyViewController.currenciesDict[storedCurrency] {
                amountLabel.text = currencyPosition == .left ? "\(currencySymbol ?? "")\(amountString)" : "\(amountString) \(currencySymbol ?? "")"
            } else {
                amountLabel.text = amountString
            }
        }
    }
    
    
    
    
}
