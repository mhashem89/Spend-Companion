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
        detailTextLabel?.font = UIFont.systemFont(ofSize: fontScale < 1 ? 11 : 11 * fontScale)
    }
    
    func configureCell(for item: Item) {
        guard let itemDate = item.date else { return }
        let todayDate = DateFormatters.fullDateFormatter.string(from: Date())
        let dayString = DateFormatters.fullDateFormatter.string(from: itemDate) == todayDate ? "Today" : DateFormatters.fullDateFormatter.string(from: itemDate)
        formatTitleLabel(itemName: item.detail, on: dayString)
        detailTextLabel?.text = item.category?.name
        let roundedAmount = (item.amount * 100).rounded() / 100
        formatAmountLabel(with: roundedAmount)
        if item.recurringNum != nil && item.recurringUnit != nil {
            addRecurrence()
        } else {
            recurringCircleButton.removeFromSuperview()
        }
    }
    
    func addRecurrence() {
        addSubview(recurringCircleButton)
        recurringCircleButton.anchor(leading: textLabel?.trailingAnchor, leadingConstant: 10, centerY: centerYAnchor)
    }
    
    func formatTitleLabel(itemName name: String?, on date: String) {
        let titleString = NSMutableAttributedString(string: name ?? "Item", attributes: [.font: UIFont.boldSystemFont(ofSize: fontScale < 1 ? 13 : 16 * fontScale), .foregroundColor: CustomColors.label])
        
        let formattedDayString = NSAttributedString(string: "   \(date)", attributes: [.font: UIFont.italicSystemFont(ofSize: fontScale < 1 ? 11 : 12 * fontScale), .foregroundColor: UIColor.systemGray])
        titleString.append(formattedDayString)
        
        textLabel?.attributedText = titleString
    }
    
    func formatAmountLabel(with amount: Double) {
        amountLabel.text = CommonObjects.shared.formattedCurrency(with: amount)
    }
    
    
    
    
}
