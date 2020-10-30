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
    
    static var mediumGray: UIColor {
        if #available(iOS 13, *) {
            return .systemGray3
        } else {
            return .darkGray
        }
    }
    
    static var blue: UIColor {
        if #available(iOS 13, *) {
            return .systemBlue
        } else {
            return .blue
        }
    }
    
    static var green: UIColor {
        if #available(iOS 13, *) {
            return .systemGreen
        } else {
            return .green
        }
    }
    
    static var indigo: UIColor {
        if #available(iOS 13, *) {
            return .systemIndigo
        } else {
            return #colorLiteral(red: 0.3307441321, green: 0.210634785, blue: 0.5824837346, alpha: 1)
        }
    }
    
    static var orange: UIColor {
        if #available(iOS 13, *) {
            return .systemOrange
        } else {
            return .orange
        }
    }
    
    static var pink: UIColor {
        if #available(iOS 13, *) {
            return .systemPink
        } else {
            return #colorLiteral(red: 0.8549019694, green: 0.250980407, blue: 0.4784313738, alpha: 1)
        }
    }
    
    static var purple: UIColor {
        if #available(iOS 13, *) {
            return .systemPurple
        } else {
            return .purple
        }
    }
    
    static var red: UIColor {
        if #available(iOS 13, *) {
            return .systemRed
        } else {
            return .red
        }
    }
    
    static var teal: UIColor {
        if #available(iOS 13, *) {
            return .systemTeal
        } else {
            return #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        }
    }
    
    static var yellow: UIColor {
        if #available(iOS 13, *) {
            return .systemYellow
        } else {
            return .yellow
        }
    }
}





