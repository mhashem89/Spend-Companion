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
            if let currencyPosition = Currencies.currenciesDict[storedCurrency] {
                return (Currencies.extractSymbol(from: storedCurrency), currencyPosition)
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
            } else if let currencyPosition = Currencies.currenciesDict[storedCurrency] {
                return currencyPosition == .left ? "\(currencySymbol.symbol ?? "")\(amountString)" : "\(amountString) \(currencySymbol.symbol ?? "")"
            }
        }
        return amountString
    }
    
}

struct Currencies {
    
    static let currenciesDict : [String: CurrencyPosition] = ["USD ($)": .left, "EUR (€)": .left, "JPY (¥)": .left, "GBP (£)": .left, "AUD ($)": .left, "CAD ($)": .left, "CHF (fr.)": .left, "CNY (¥)": .left, "HKD ($)": .left, "NZD ($)": .left, "SEK (kr)": .left, "KRW (₩)": .left, "SGD ($)": .left, "NOK (kr)": .left, "MXN ($)": .left, "INR (₹)": .left, "RUB (₽)": .right, "ZAR (R)": .left, "TRY (₺)": .right, "BRL (R$)": .left, "TWD ($)": .left, "DKK (kr)": .left, "PLN (zł)": .right, "THB (฿)": .right, "IDR (Rp)": .left, "HUF (Ft)": .right, "CZK (Kč)": .right, "ILS (₪)": .left, "CLP ($)": .left, "PHP (₱)": .left, "AED (د.إ)": .right, "COP ($)": .left, "SAR (﷼)": .right, "MYR (RM)": .left, "RON (L)": .left]
    
    
    static func extractSymbol(from currency: String) -> String? {
        if currency == "Local currency" {
            return Locale.current.currencySymbol
        } else if currency == "None" {
            return nil
        } else {
            let symbol = currency.split(separator: "(").last?.split(separator: ")").first
            return String(symbol!)
        }
    }
}

enum SortingOption {
    case date, amount, name
}

enum SortingDirection {
    case ascending, descending
}

enum ItemChangeType {
    case edit, delete
}


enum ItemType: Int16, CustomStringConvertible {
    case spending = 0
    case income = 1
    
    var description: String {
        switch self {
        case .spending:
            return "Spending"
        case .income:
            return "Income"
        }
    }
}

struct YearTotals {
    var totalSpending: Double
    var totalIncome: Double
    var maxAmountPerMonth: Double
}


struct ItemStruct {
    var amount: Double
    var type: ItemType
    var date: Date
    var detail: String?
    var itemRecurrence: ItemRecurrence?
    var categoryName: String?
    var sisterItems: [Item]?
    
    static func itemStruct(from item: Item) -> ItemStruct? {
        guard let itemDate = item.date else { return nil }
        return ItemStruct(amount: item.amount, type: ItemType(rawValue: item.type)!, date: itemDate, detail: item.detail, itemRecurrence: ItemRecurrence.createItemRecurrence(from: item), categoryName: item.category?.name, sisterItems: item.sisterItems?.allObjects as? [Item])
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

enum PurchaseIds: CustomStringConvertible {
    case reminders, iCloudSync
    
    var description: String {
        switch self {
        case .reminders: return "MohamedHashem.Spend_Companion.reminders_purchase"
        case .iCloudSync: return "MohamedHashem.Spend_Companion.iCloud_sync"
        }
    }
}

enum ItemRecurrenceCase {
    case period, unit, reminderTime, endDate
}

struct ItemRecurrence: Equatable {
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
    
    static let hourFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
}



enum SaveError: Error {
    case saveError
}
