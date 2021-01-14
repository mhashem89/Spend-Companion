//
//  ChartCell.swift
//  Spending App
//
//  Created by Mohamed Hashem on 10/5/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit


class ChartCell: UICollectionViewCell {
    
    var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.minusSign = ""
        formatter.currencySymbol = ""
        return formatter
    }()
    
    var barView = UIView()
    
    var valueLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = CustomColors.label
        lbl.font = UIFont.systemFont(ofSize: fontScale < 1 ? 13 : 13 * fontScale)
        return lbl
    }()
    
    var cellLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: fontScale < 1 ? 14 : 16 * fontScale)
        label.textColor =  CustomColors.label
//        label.backgroundColor = CustomColors.systemBackground
        label.textAlignment = .right
//        label.numberOfLines = 0
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubviews([cellLabel, barView, valueLabel])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI(withLabelWidth maxWidth: CGFloat) {
//        backgroundColor = CustomColors.systemBackground
        barView.backgroundColor = UserDefaults.standard.colorForKey(key: SettingNames.barColor) ?? #colorLiteral(red: 0.7254902124, green: 0.4784313738, blue: 0.09803921729, alpha: 1)
        barView.layer.cornerRadius = 10
        barView.clipsToBounds = true
        cellLabel.frame = .init(x: 0, y: 0, width: maxWidth, height: frame.height)
//        cellLabel.textColor = UserDefaults.standard.colorForKey(key: SettingNames.labelColor) ?? .systemBlue
    }
    
    func formatValueLabel(with amount: Double, withPercentage percentage: Double? = nil) {
        guard amount > 0,
              let numberString = numberFormatter.string(from: NSNumber(value: amount))
        else { valueLabel.text = "0"; return }
        if let percentage = percentage {
            valueLabel.text = "\(numberString) (\(Int(percentage))%)"
        } else {
            valueLabel.text = numberString
        }
    }
}
