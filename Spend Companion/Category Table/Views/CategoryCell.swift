//
//  CategoryCell.swift
//  Spending App
//
//  Created by Mohamed Hashem on 8/26/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit


class CategoryCell: UICollectionViewCell {
    
    
    // MARK:- Properties
    
    var nameLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: fontScale < 1 ? 18 : 18 * fontScale)
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    var totalLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: fontScale < 1 ? 18 : 18 * fontScale)
        return label
    }()
    
    var checkMark = UIButton()
    
    var editingEnabled: Bool = false
    
    // MARK:- Lifecycle Methods
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 10
        clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK:- Selectors
    
    
    // MARK:- UI Methods
    
    func setupSubviews() {
        let stack = UIStackView(arrangedSubviews: [nameLabel, totalLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 10
        nameLabel.anchor(widthConstant: frame.width)
        
        addSubview(stack)
        stack.anchor(centerX: centerXAnchor, centerY: centerYAnchor)
        checkMark.tintColor = .white
        if editingEnabled {
            if #available(iOS 13, *) {
                checkMark.setImage(UIImage(systemName: "circle"), for: .normal) 
            } else {
                checkMark.setTitle("☐", for: .normal)
            }
            addSubview(checkMark)
            checkMark.anchor(trailing: trailingAnchor, trailingConstant: 4, bottom: bottomAnchor, bottomConstant: 4)
        } else {
            checkMark.removeFromSuperview()
        }
    }
    
    func toggleCheckMark() {
        if #available(iOS 13, *) {
            if checkMark.image(for: .normal) == UIImage(systemName: "circle") {
                checkMark.setImage(UIImage(systemName: "checkmark.circle"), for: .normal)
            } else {
                checkMark.setImage(UIImage(systemName: "circle"), for: .normal)
            }
        } else {
            if checkMark.title(for: .normal) == "☐" {
                checkMark.setTitle("☑", for: .normal)
            }
        }
    }
    
    
}

