//
//  CalendarCell.swift
//  Spending App
//
//  Created by Mohamed Hashem on 10/6/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit


class CalendarCell: UICollectionViewCell {
    
// MARK:- Subviews
    
    var monthLabel: UILabel = {
        let label = UILabel()
        label.textColor = CustomColors.label
        return label
    }()
    
    var incomeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = #colorLiteral(red: 0.303809394, green: 0.5380075372, blue: 0.1605153434, alpha: 1)
        return label
    }()
    
    var spendingLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = CustomColors.red
        return label
    }()
    
    var stack = UIStackView()
    
// MARK:- Methods
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        layer.borderWidth = 0.8
        addSubview(stack)
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        stack.addArrangedSubview(monthLabel)
        stack.anchor(centerX: centerXAnchor, centerY: centerYAnchor, centerYConstant: 2)
        monthLabel.font = UIFont.boldSystemFont(ofSize: 22 * fontScale)
        incomeLabel.font = UIFont.systemFont(ofSize: 13 * fontScale)
        spendingLabel.font = UIFont.systemFont(ofSize: 13 * fontScale)
    }
    
    func addTotalLabel(income: String, spending: String) {
        stack.insertArrangedSubview(incomeLabel, at: 1)
        stack.insertArrangedSubview(spendingLabel, at: 2)
        incomeLabel.text = "\(income)"
        spendingLabel.text = "\(spending)"
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

