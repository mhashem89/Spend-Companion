//
//  ItemTableHeader.swift
//  Spending App
//
//  Created by Mohamed Hashem on 10/5/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit

class ItemTableHeader: UIView {
    
    let titleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitleColor(CustomColors.label, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: fontScale < 1 ? 16 : 18 * fontScale)
        button.layer.borderWidth = 0.5
        button.layer.borderColor = CustomColors.label.cgColor
        button.clipsToBounds = true
        button.layer.cornerRadius = 5
        button.contentEdgeInsets = .init(top: 7, left: 7, bottom: 7, right: 7)
        return button
    }()
    
    let favoriteButton: UIButton = {
        let button = UIButton(type: .system)
        if #available(iOS 13, *) {
            button.setImage(UIImage(systemName: "heart"), for: .normal)
        } else {
            button.setAttributedTitle(NSAttributedString(string: "♡", attributes: [.font: UIFont.boldSystemFont(ofSize: 28)]), for: .normal)
        }
        button.layer.cornerRadius = fontScale < 1 ? 16 : 16 * fontScale
        button.clipsToBounds = true
        button.backgroundColor = #colorLiteral(red: 0.4549019608, green: 0.4549019608, blue: 0.5019607843, alpha: 0.08)
        button.anchor(widthConstant: fontScale < 1 ? 32 : 32 * fontScale, heightConstant: fontScale < 1 ? 32 : 32 * fontScale)
        button.isEnabled = false
        return button
    }()
    
    var plusButton: UIButton = {
        let button = UIButton(type: .system)
        if #available(iOS 13, *) {
            button.setImage(UIImage(systemName: "plus"), for: .normal)
        } else {
            button.setAttributedTitle(NSAttributedString(string: "+", attributes: [.font: UIFont.boldSystemFont(ofSize: 28)]), for: .normal)
        }
        button.layer.cornerRadius = fontScale < 1 ? 16 : 16 * fontScale
        button.clipsToBounds = true
        button.backgroundColor = #colorLiteral(red: 0.4549019608, green: 0.4549019608, blue: 0.5019607843, alpha: 0.08)
        button.anchor(widthConstant: fontScale < 1 ? 32 : 32 * fontScale, heightConstant: fontScale < 1 ? 32 : 32 * fontScale)
        button.isEnabled = false
        return button
    }()
    
    var sortButton: UIButton = {
        let button = UIButton(type: .system)
        if #available(iOS 13, *) {
            button.setImage(UIImage(systemName: "arrow.up.arrow.down"), for: .normal)
        } else {
            button.setAttributedTitle(NSAttributedString(string: "↑↓", attributes: [.font: UIFont.boldSystemFont(ofSize: 18)]), for: .normal)
        }
        button.layer.cornerRadius = fontScale < 1 ? 16 : 16 * fontScale
        button.anchor(widthConstant: fontScale < 1 ? 32 : 32 * fontScale, heightConstant: fontScale < 1 ? 32 : 32 * fontScale)
        button.backgroundColor = #colorLiteral(red: 0.4549019608, green: 0.4549019608, blue: 0.5019607843, alpha: 0.08)
        button.isEnabled = false
        return button
    }()
    
    let separatorView = UIView()
    
    
    func enableButtons(with viewModel: CategoryViewModel?) {
        guard let viewModel = viewModel else { return }
        plusButton.isEnabled = true
        favoriteButton.isEnabled = true
        if let items = viewModel.items, items.count > 1 {
            sortButton.isEnabled = true
        }
    }
    
    func toggleFavoriteButton(with viewModel: CategoryViewModel?) {
        guard let viewModel = viewModel else { return }
        switch viewModel.isFavorite {
        case true:
            if #available(iOS 13, *) {
                favoriteButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
            }
            favoriteButton.tintColor = .red
        case false:
            if #available(iOS 13, *) {
                favoriteButton.setImage(UIImage(systemName: "heart"), for: .normal)
            }
            favoriteButton.tintColor = .systemBlue
        }
    }
    
    func setupUI(with viewModel: CategoryViewModel?) {
        backgroundColor = CustomColors.systemBackground
        let buttonStack = UIStackView(arrangedSubviews: [favoriteButton, sortButton, plusButton])
        separatorView.backgroundColor = CustomColors.darkGray
        buttonStack.axis = .horizontal; buttonStack.spacing = 10 * viewsWidthScale
        addSubviews([titleButton, buttonStack, separatorView])
        
        titleButton.anchor(leading: leadingAnchor, leadingConstant: 20 * viewsWidthScale, centerY: centerYAnchor)
        buttonStack.anchor(trailing: trailingAnchor, trailingConstant: 20 * viewsWidthScale, centerY: centerYAnchor)
        separatorView.anchor(leading: leadingAnchor, trailing: trailingAnchor, bottom: bottomAnchor, heightConstant: 1)
        if let category = viewModel?.category {
            favoriteButton.isHidden = category.name == "Income"
            titleButton.isUserInteractionEnabled = category.name != "Income"
        }
    }
   
}
