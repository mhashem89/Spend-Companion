//
//  RecentItemCell.swift
//  Spending App
//
//  Created by Mohamed Hashem on 10/11/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit


class RecentItemCell: UITableViewCell {
    
    
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
        amountLabel.text = CommonObjects.shared.formattedCurrency(with: amount)
    }
    
    
    
    
}
