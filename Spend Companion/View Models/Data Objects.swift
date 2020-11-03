//
//  Protocols.swift
//  Spend Companion
//
//  Created by Mohamed Hashem on 10/21/20.
//

import Foundation



enum ItemType: Int16 {
    case spending = 0
    case income = 1
}


enum RecurringUnit: Int, CustomStringConvertible {
    case day = 0
    case week = 1
    case month = 2
    
    var description: String {
        switch self {
        case .day: return "day"
        case .week: return "week"
        case .month: return "month"
        }
    }
}


struct SettingNames {
    static let iCloudSync = "iCloud sync"
    static let enableBiometrics = "EnableBiometrics"
    static let barColor = "bar color"
    static let buttonColor = "button color"
    static let labelColor = "label color"
    static let currency = "currency"
    static let remindersPurchased = "remindersPurchased"
    static let iCloudSyncPurchased = "iCloudSync Purchased"
}


enum PurchaseIds: CustomStringConvertible {
    case reminders, iCloudSync
    
    var description: String {
        switch self {
        case .reminders: return "MohamedHashem.Spend_Companion.reminders_purchase"
        case .iCloudSync: return "MohamedHashem.Spend_Companion.iCloud_sync"
        }
    }
}


struct ItemRecurrence {
    var period: Int
    var unit: RecurringUnit
    var reminderTime: Int?
    var endDate: Date
    
//    init?(item: Item) {
//        guard let recurringNum = item.recurringNum, let recurringUnit = item.recurringUnit, let endDate = item.recurringEndDate else { return }
//        self.period = Int(truncating: recurringNum)
//        self.unit = RecurringUnit(rawValue: Int(truncating: recurringUnit))!
//        if let itemReminderTime = item.reminderTime { self.reminderTime = Int(truncating: itemReminderTime) }
//        self.endDate = endDate
//    }
}
