//
//  CalendarHeader.swift
//  Spending App
//
//  Created by Mohamed Hashem on 10/4/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit



class CalendarHeader: UICollectionViewCell {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    weak var delegate: YearHeaderDelegate?
    
    let headerLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 24)
        label.textColor = CustomColors.label
        return label
    }()
    
    let nextButton: UIButton = {
        let button = UIButton(type: .system)
        if #available(iOS 13, *) {
            button.setImage(UIImage(systemName: "chevron.right.square"), for: .normal)
            button.tintColor = CustomColors.label
        } else {
            button.setAttributedTitle(NSAttributedString(string: "〉", attributes: [.font: UIFont.boldSystemFont(ofSize: 24), .foregroundColor: CustomColors.label]), for: .normal)
        }
        button.imageView?.contentMode = .scaleAspectFill
        return button
    }()
    
    let previousButton: UIButton = {
        let button = UIButton(type: .system)
        button.imageView?.contentMode = .scaleAspectFill
        if #available(iOS 13, *) {
            button.setImage(UIImage(systemName: "chevron.left.square"), for: .normal)
            button.tintColor = CustomColors.label
        } else {
            button.setAttributedTitle(NSAttributedString(string: "〈", attributes: [.font: UIFont.boldSystemFont(ofSize: 24), .foregroundColor: CustomColors.label]), for: .normal)
        }
        return button
    }()
    
    let segmentedControl = UISegmentedControl()
    
    func setupUI() {
        addSubviews([previousButton, headerLabel, nextButton])
        
        previousButton.anchor(centerX: centerXAnchor, centerXConstant: -frame.width * 0.25, centerY: centerYAnchor, centerYConstant: -frame.height * 0.2, widthConstant: 50, heightConstant: 50)
        headerLabel.anchor(centerX: centerXAnchor, centerY: centerYAnchor, centerYConstant: -frame.height * 0.2)
        nextButton.anchor(centerX: centerXAnchor, centerXConstant: frame.width * 0.25, centerY: centerYAnchor, centerYConstant: -frame.height * 0.2, widthConstant: 50, heightConstant: 50)
        
        previousButton.addTarget(self, action: #selector(previousYear), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextYear), for: .touchUpInside)
    }
    
    func addSegmentedControl() {
        addSubview(segmentedControl)
        segmentedControl.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: fontScale < 1 ? 15 : 15 * fontScale)], for: .normal)
        segmentedControl.setTitleTextAttributes([.font: UIFont.boldSystemFont(ofSize: fontScale < 1 ? 15 : 15 * fontScale)], for: .selected)
        segmentedControl.anchor(top: previousButton.bottomAnchor, topConstant: 5 * viewsHeightScale, leading: leadingAnchor, leadingConstant: 20 * viewsWidthScale, trailing: trailingAnchor, trailingConstant: 20 * viewsWidthScale)
    }
    
    @objc func nextYear() {
        guard let year = headerLabel.text, let yearNumber = Int(year) else { return }
        headerLabel.text = String(yearNumber + 1)
        delegate?.yearSelected(year: year)
    }
    
    @objc func previousYear() {
        guard let year = headerLabel.text, let yearNumber = Int(year) else { return }
        headerLabel.text = String(yearNumber - 1)
        delegate?.yearSelected(year: year)
    }

}


