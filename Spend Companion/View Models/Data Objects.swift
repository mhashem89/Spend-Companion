//
//  Protocols.swift
//  Spend Companion
//
//  Created by Mohamed Hashem on 10/21/20.
//

import Foundation


class CommonObjects {
    
    static let shared = CommonObjects()
    
    private init() {}
    
    var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.minusSign = ""
        return formatter
    }()
    
    var userCurrency: String? {
        return UserDefaults.standard.value(forKey: SettingNames.currency) as? String
    }
    
    var currencySymbol: (symbol: String?, position: CurrencyPosition) {
        if let storedCurrency = userCurrency {
            if let currencyPosition = CurrencyViewController.currenciesDict[storedCurrency] {
                return (CurrencyViewController.extractSymbol(from: storedCurrency), currencyPosition)
            } else if userCurrency == "Local currency" {
                return (Locale.current.currencySymbol, .left)
            } else if userCurrency == "None" {
                return (nil, .left)
            }
        }
        return ("$", .left)
    }
    
    func formattedCurrency(with amount: Double) -> String {
        let amountString = String(format: "%g", amount >= 0 ? amount : -amount)
        if let storedCurrency = userCurrency {
            if storedCurrency == "Local currency" {
                return numberFormatter.string(from: NSNumber(value: amount)) ?? amountString
            } else if let currencyPosition = CurrencyViewController.currenciesDict[storedCurrency] {
                return currencyPosition == .left ? "\(currencySymbol.symbol ?? "")\(amountString)" : "\(amountString) \(currencySymbol.symbol ?? "")"
            }
        }
        return amountString
    }
    
}


enum SortingOption {
    case date, amount, name
}

enum SortingDirection {
    case ascending, descending
}


enum ItemType: Int16 {
    case spending = 0
    case income = 1
}

struct ItemStruct {
    var amount: Double
    var type: ItemType
    var date: String
    var detail: String?
    var itemRecurrence: ItemRecurrence?
    var categoryName: String?
    
    static func itemStruct(from item: Item) -> ItemStruct {
        let date = DateFormatters.fullDateFormatter.string(from: item.date!)
        return ItemStruct(amount: item.amount, type: ItemType(rawValue: item.type)!, date: date, detail: item.detail, itemRecurrence: ItemRecurrence.createItemRecurrence(from: item), categoryName: item.category?.name)
    }
    
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
    
    static func createItemRecurrence(from item: Item) -> ItemRecurrence? {
        guard let period = item.recurringNum, let unit = item.recurringUnit, let endDate = item.recurringEndDate else { return nil }
        var reminderTime: Int?
        if let itemReminderTime = item.reminderTime {
            reminderTime = Int(truncating: itemReminderTime)
        }
        let itemRecurrence = ItemRecurrence(period: Int(truncating: period), unit: RecurringUnit(rawValue: Int(truncating: unit))!, reminderTime: reminderTime, endDate: endDate)
        return itemRecurrence
    }
}



class DateFormatters {
    
    /// "MMM d, yyyy"
    static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()
    
    /// "MMMM yyyy"
    static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    /// "MMM yyyy"
    static let abbreviatedMonthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }()
    
    /// "MMM"
    static let abbreviatedMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()
    
    /// "yyyy"
    static let yearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter
    }()
    
    /// "E, d, MMM yyyy"
    static let fullDateWithLetters: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, d, MMM yyyy"
        return formatter
    }()
    
    /// "MMM"
    static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()
}
