//
//  LockingView.swift
//  Spend Companion
//
//  Created by Mohamed Hashem on 10/24/20.
//

import UIKit


class LockingView: UIView {
    
    
    var loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .systemBlue
        let title = NSAttributedString(string: "Login", attributes: [.font: UIFont.boldSystemFont(ofSize: 26), .foregroundColor: UIColor.white])
        button.setAttributedTitle(title, for: .normal)
        button.isHidden = true
        button.layer.cornerRadius = 10
        return button
    }()
    
    
    func setupUI() {
        backgroundColor = CustomColors.systemBackground
        addSubview(loginButton)
        loginButton.anchor(centerX: centerXAnchor, centerY: centerYAnchor, centerYConstant: frame.height * 0.25, widthConstant: frame.width * 0.5, heightConstant: frame.height * 0.08)
    }
    
    
}
