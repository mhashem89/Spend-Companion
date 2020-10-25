//
//  CustomColors.swift
//  Spend Companion
//
//  Created by Mohamed Hashem on 10/21/20.
//

import UIKit


class CustomColors {
    
    
    static var systemBackground: UIColor {
        if #available(iOS 13, *) {
            return .systemBackground
        } else {
            return .white
        }
    }
    
    static var label: UIColor {
        if #available(iOS 13, *) {
            return .label
        } else {
            return .black
        }
    }
    
    static var lightGray: UIColor {
        if #available(iOS 13, *) {
            return .systemGray6
        } else {
            return .lightGray
        }
    }
    
    static var darkGray: UIColor {
        if #available(iOS 13, *) {
            return .systemGray
        } else {
            return .darkGray
        }
    }
    
    
}





