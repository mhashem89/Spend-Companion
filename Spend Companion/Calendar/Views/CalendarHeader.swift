//
//  CalendarHeader.swift
//  Spending App
//
//  Created by Mohamed Hashem on 10/4/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit

protocol CalendarHeaderDelegate: class {
    /// Passes the year selection to the delegate when the user goes to the previous or next year
    func yearSelected(year: String)
}

class CalendarHeader: UICollectionViewCell {
    
    weak var delegate: CalendarHeaderDelegate?
    
// MARK:- Subviews
    
    let headerLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 24)
        label.textColor = CustomColors.label
        return label
    }()
    
    private let nextButton: UIButton = {
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
    
    private let previousButton: UIButton = {
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
    
// MARK:- Methods
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        addSubviews([previousButton, headerLabel, nextButton])
        
        previousButton.anchor(centerX: centerXAnchor, centerXConstant: -frame.width * 0.25, centerY: centerYAnchor, centerYConstant: -frame.height * 0.2, widthConstant: 50, heightConstant: 50)
        headerLabel.anchor(centerX: centerXAnchor, centerY: centerYAnchor, centerYConstant: -frame.height * 0.2)
        nextButton.anchor(centerX: centerXAnchor, centerXConstant: frame.width * 0.25, centerY: centerYAnchor, centerYConstant: -frame.height * 0.2, widthConstant: 50, heightConstant: 50)
        
        previousButton.addTarget(self, action: #selector(previousYear), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextYear), for: .touchUpInside)
    }
    /// Used in the charts viewer to switch between Month/Category/Income
    func addSegmentedControl() {
        addSubview(segmentedControl)
        segmentedControl.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: fontScale < 1 ? 15 : 15 * fontScale)], for: .normal)
        segmentedControl.setTitleTextAttributes([.font: UIFont.boldSystemFont(ofSize: fontScale < 1 ? 15 : 15 * fontScale)], for: .selected)
        segmentedControl.anchor(top: previousButton.bottomAnchor, topConstant: 5 * windowHeightScale, leading: leadingAnchor, leadingConstant: 20 * windowWidthScale, trailing: trailingAnchor, trailingConstant: 20 * windowWidthScale)
    }
    /// Gets called when user pesses "next" arrow button. Adds one to the current year and passes it to the delegate
    @objc private func nextYear() {
        guard let year = headerLabel.text, let yearNumber = Int(year) else { return }
        let nextYear = String(yearNumber + 1)
        headerLabel.text = nextYear
        delegate?.yearSelected(year: nextYear)
    }
    /// Gets called when the user presses "previous" arrow button. Subtracts  one from the current year and passes it to the delegate
    @objc private func previousYear() {
        guard let year = headerLabel.text, let yearNumber = Int(year) else { return }
        let previousYear = String(yearNumber - 1)
        headerLabel.text = previousYear
        delegate?.yearSelected(year: previousYear)
    }
}


