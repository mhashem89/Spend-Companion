//
//  WelcomeViewController.swift
//  Spend Companion
//
//  Created by Mohamed Hashem on 12/5/20.
//

import UIKit


class WelcomeViewController: UIViewController {
    
    var welcomeTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 16 * fontScale)
        textView.textColor = CustomColors.label
        textView.backgroundColor = CustomColors.systemBackground
        textView.text = "Welcome! Start by entering transaction details here"
        textView.textAlignment = .center
        return textView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(welcomeTextView)
        welcomeTextView.anchor(top: view.topAnchor, topConstant: -3 * windowHeightScale, leading: view.leadingAnchor, trailing: view.trailingAnchor, bottom: view.bottomAnchor)
    }
    
}
