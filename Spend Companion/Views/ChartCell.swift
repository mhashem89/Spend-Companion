//
//  ChartCell.swift
//  Spending App
//
//  Created by Mohamed Hashem on 10/5/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit


class ChartCell: UICollectionViewCell {
    
    var barView: UIView = {
        let view = UIView()
        view.backgroundColor = UserDefaults.standard.colorForKey(key: SettingNames.barColor) ?? .systemRed
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
}
