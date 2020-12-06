//
//  WelcomeViewController.swift
//  Spend Companion
//
//  Created by Mohamed Hashem on 12/5/20.
//

import UIKit


class WelcomeViewController: UIViewController {
    
    var welcomeLabel: UITextView = {
        let label = UITextView()
        label.font = UIFont.systemFont(ofSize: 16 * fontScale)
        label.textColor = CustomColors.label
        label.backgroundColor = CustomColors.systemBackground
        label.text = "Welcome! Start by entering transaction details here"
        label.textAlignment = .center
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(welcomeLabel)
        welcomeLabel.anchor(top: view.topAnchor, topConstant: -3 * windowHeightScale, leading: view.leadingAnchor, trailing: view.trailingAnchor, bottom: view.bottomAnchor)
    }
    
}
