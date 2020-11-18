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
    
    var barView: UIView = {
        let view = UIView()
        view.backgroundColor = UserDefaults.standard.colorForKey(key: SettingNames.barColor) ?? #colorLiteral(red: 0.7254902124, green: 0.4784313738, blue: 0.09803921729, alpha: 1)
        return view
    }()
    
    var valueLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = CustomColors.darkGray
        lbl.font = UIFont.systemFont(ofSize: fontScale < 1 ? 13 : 13 * fontScale)
        return lbl
    }()
    
    var cellLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: fontScale < 1 ? 14 : 16 * fontScale)
        label.textColor = UserDefaults.standard.colorForKey(key: SettingNames.labelColor) ?? .systemBlue
        label.backgroundColor = CustomColors.systemBackground
        label.textAlignment = .right
        label.numberOfLines = 0
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func setupUI() {
        backgroundColor = CustomColors.systemBackground
        addSubviews([cellLabel, barView, valueLabel])
    }
    
    func formatValueLabel(with amount: Double, withPercentage percentage: Double? = nil) {
        guard amount > 0,
              let numberString = numberFormatter.string(from: NSNumber(value: amount))
        else { valueLabel.text = nil; return }
        if let percentage = percentage {
            valueLabel.text = "\(numberString) (\(Int(percentage))%)"
        } else {
            valueLabel.text = numberString
        }
        
    }
}
