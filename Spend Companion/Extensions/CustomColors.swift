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
            return #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        }
    }
    
    static var darkGray: UIColor {
        return .systemGray
    }
    
    static var mediumGray: UIColor {
        if #available(iOS 13, *) {
            return .systemGray3
        } else {
            return .darkGray
        }
    }
    
    static var blue: UIColor {
        return .systemBlue
    }
    
    static var green: UIColor {
        return .systemGreen
    }
    
    static var indigo: UIColor {
        if #available(iOS 13, *) {
            return .systemIndigo
        } else {
            return #colorLiteral(red: 0.3307441321, green: 0.210634785, blue: 0.5824837346, alpha: 1)
        }
    }
    
    static var orange: UIColor {
        return .systemOrange
    }
    
    static var pink: UIColor {
        return .systemPink
    }
    
    static var purple: UIColor {
        return .systemPurple
    }
    
    static var red: UIColor {
        return .systemRed
    }
    
    static var teal: UIColor {
        return .systemTeal
    }
    
    static var yellow: UIColor {
        return .systemYellow
    }
}





