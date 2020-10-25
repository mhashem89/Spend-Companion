//
//  SummaryView.swift
//  Spending App
//
//  Created by Mohamed Hashem on 10/7/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit


class SummaryView: UIView {
    
    var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = CustomColors.label
        label.font = UIFont.boldSystemFont(ofSize: fontScale < 1 ? 14 : 18 * fontScale)
        return label
    }()
    
    var segmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl()
        sc.insertSegment(withTitle: "Month", at: 0, animated: false)
        sc.insertSegment(withTitle: "Year", at: 1, animated: false)
        sc.selectedSegmentIndex = 0
        sc.setTitleTextAttributes([.font: UIFont.boldSystemFont(ofSize: 15 * fontScale)], for: .normal)
        return sc
    }()
    
    var summaryLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: fontScale < 1 ? 11.5 : 14 * fontScale)
        lbl.numberOfLines = 0
        lbl.layer.borderWidth = 0.5
        lbl.layer.borderColor = CustomColors.label.cgColor
        lbl.layer.cornerRadius = 5
        lbl.textAlignment = .center
        return lbl
    }()
    
    var barChart = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = CustomColors.systemBackground
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        addSubviews([segmentedControl, titleLabel, barChart, summaryLabel])
        (barChart.collectionViewLayout as? UICollectionViewFlowLayout)?.scrollDirection = .vertical
        titleLabel.anchor(top: safeAreaLayoutGuide.topAnchor, topConstant: 15 * viewsHeightScale, leading: safeAreaLayoutGuide.leadingAnchor, leadingConstant: 10 * viewsWidthScale)
        segmentedControl.anchor(trailing: safeAreaLayoutGuide.trailingAnchor, trailingConstant: 10 * viewsWidthScale, centerY: titleLabel.centerYAnchor, widthConstant: 117 * viewsWidthScale, heightConstant: 31 * viewsWidthScale)
        barChart.anchor(top: titleLabel.bottomAnchor, topConstant: 20 * viewsHeightScale, leading: safeAreaLayoutGuide.leadingAnchor, trailing: safeAreaLayoutGuide.trailingAnchor, heightConstant: frame.height * 0.4)
        barChart.backgroundColor = CustomColors.systemBackground
        (barChart.collectionViewLayout as? UICollectionViewFlowLayout)?.scrollDirection = .vertical
        barChart.showsHorizontalScrollIndicator = false
        barChart.showsVerticalScrollIndicator = false
        
        summaryLabel.anchor(top: barChart.bottomAnchor, topConstant: 15, centerX: centerXAnchor, widthConstant: frame.width * 0.9, heightConstant: frame.height * 0.17)
    }
    
    
}
