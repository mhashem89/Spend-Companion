//
//  CalendarCell.swift
//  Spending App
//
//  Created by Mohamed Hashem on 10/6/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit


class CalendarCell: UICollectionViewCell {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    var monthLabel: UILabel = {
        let label = UILabel()
        label.textColor = CustomColors.label
        return label
    }()
    
    var incomeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = #colorLiteral(red: 0.1960784346, green: 0.3411764801, blue: 0.1019607857, alpha: 1)
        return label
    }()
    
    var spendingLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .systemRed
        return label
    }()
    
    var userCurrency: String? {
        return UserDefaults.standard.value(forKey: "currency") as? String
    }
    
    var currencySymbol: String {
        if let storedCurrency = userCurrency {
            return CurrencyViewController.extractSymbol(from: storedCurrency)
        } else {
            return "$"
        }
    }
    
    var stack = UIStackView()
    
    func setupUI() {
        layer.borderWidth = 0.8
        addSubview(stack)
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        stack.addArrangedSubview(monthLabel)
        stack.anchor(centerX: centerXAnchor, centerY: centerYAnchor, centerYConstant: 2)
    }
    
    func addTotalLabel(income: String, spending: String) {
        stack.insertArrangedSubview(incomeLabel, at: 1)
        stack.insertArrangedSubview(spendingLabel, at: 2)
        if let storedCurrency = userCurrency, let currencyPosition = CurrencyViewController.currenciesDict[storedCurrency] {
            incomeLabel.text = currencyPosition == .left ? "\(currencySymbol)\(income)" : "\(income) \(currencySymbol)"
            spendingLabel.text = currencyPosition == .left ? "\(currencySymbol)\(spending)" : "\(spending) \(currencySymbol)"
        } else {
            incomeLabel.text = "$\(income)"
            spendingLabel.text = "$\(spending)"
        }
    }
    
    func removeTotalLabel() {
        if stack.arrangedSubviews.contains(incomeLabel) {
            incomeLabel.removeFromSuperview()
        }
        if stack.arrangedSubviews.contains(spendingLabel) {
            spendingLabel.removeFromSuperview()
        }
    }
    
}

