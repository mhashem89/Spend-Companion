//
//  SettingNames.swift
//  Spend Companion
//
//  Created by Mohamed Hashem on 1/12/21.
//

import Foundation
import UIKit


struct SettingNames {
    static let iCloudSync = "iCloud sync"
    static let enableBiometrics = "EnableBiometrics"
    static let barColor = "bar color"
    static let buttonColor = "button color"
    static let labelColor = "label color"
    static let currency = "currency"
    static let remindersPurchased = "remindersPurchased"
    static let iCloudSyncPurchased = "iCloudSync Purchased"
    static let contextIsActive = "contextIsActive"
    static let openedBefore = "openedBefore"
    static let feedbackRequested = "feedbackRequested"
    static let productURL = "https://apps.apple.com/us/app/spend-companion/id1536985369"
    static let currentMonthSpending = "currentMonthSpending"
    static let currentMonthIncome = "currentMonthIncome"
    static let scaleFactor = "scaleFactor"
}



extension UserDefaults {
    
  func colorForKey(key: String) -> UIColor? {
    var colorReturned: UIColor?
    if let colorData = data(forKey: key) {
      do {
        if let color = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? UIColor {
          colorReturned = color
        } else {
            colorReturned = nil
        }
      } catch {
        print("Error UserDefaults")
      }
    }
    return colorReturned
  }
  
  func setColor(color: UIColor?, forKey key: String) {
    var colorData: NSData?
    if let color = color {
      do {
        let data = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false) as NSData?
        colorData = data
      } catch {
        print("Error UserDefaults")
      }
    }
    set(colorData, forKey: key)
  }
    
    @objc dynamic var currentMonthIncome: Double {
        get {
            return double(forKey: SettingNames.currentMonthIncome)
        }
        set {
            setValue(newValue, forKey: SettingNames.currentMonthIncome)
        }
    }
    
}
