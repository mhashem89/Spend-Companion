//
//  CoreDataManager.swift
//  Spend Companion
//
//  Created by Mohamed Hashem on 11/7/20.
//

import CoreData
import UIKit


class CoreDataManager {
    
    static let shared = CoreDataManager()
    
    var context: NSManagedObjectContext {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }
    
    func saveItem(itemStruct: ItemStruct) throws {
        guard let itemDate = itemStruct.date == "Today" ? Date() : DateFormatters.fullDateFormatter.date(from: itemStruct.date) else { return }
        let createdItem = try createNewItem(date: itemDate, itemStruct: itemStruct)
        
        if itemStruct.itemRecurrence != nil {
            try createFutureItems(for: createdItem, shouldSave: true)
        }
    }
    
    func createFutureItems(for item: Item, shouldSave save: Bool) throws {
        guard var itemDate = item.date, let itemStruct = ItemStruct.itemStruct(from: item) else { return }
        if let itemRecurrence = itemStruct.itemRecurrence, itemRecurrence.endDate > itemDate {
            var items = [item]
            let additionalHours = Calendar.current.dateComponents([.hour, .minute, .second, .nanosecond], from: Date())
            let adjustedEndDate = Calendar.current.date(byAdding: additionalHours, to: itemRecurrence.endDate)!
            var dateComponent = DateComponents()
            switch itemRecurrence.unit {
            case .day: dateComponent.day = itemRecurrence.period
            case .month: dateComponent.month = itemRecurrence.period
            case .week: dateComponent.weekOfYear = itemRecurrence.period
            }
            
            repeat {
                itemDate = Calendar.current.date(byAdding: dateComponent, to: itemDate)!
                let newItem = try createNewItem(date: itemDate, itemStruct: itemStruct, save: save)
                items.append(newItem)
            } while Calendar.current.date(byAdding: dateComponent, to: itemDate)! <= adjustedEndDate
            
            if items.count > 1 {
                for item in items {
                    item.sisterItems = NSSet(array: items.filter({ $0 != item }))
                }
            }
            if save { try saveContext() }
        }
    }
    
    
    func createNewItem(date: Date, itemStruct: ItemStruct, save: Bool = true) throws -> Item {
        let dayString = DateFormatters.fullDateFormatter.string(from: date)
        let monthString = extractMonthString(from: dayString)
        let item = Item(context: context)
        item.date = date
        item.detail = itemStruct.detail == "Description" ? nil : itemStruct.detail
        item.type = itemStruct.type.rawValue
        item.amount = itemStruct.amount
        item.category = checkCategory(categoryName: itemStruct.categoryName ?? "Other", monthString: monthString)
        item.month = item.category?.month
        if let itemRecurrence = itemStruct.itemRecurrence {
            item.recurringNum = NSNumber(value: itemRecurrence.period)
            item.recurringUnit = NSNumber(value: itemRecurrence.unit.rawValue)
            if let reminderTime = itemRecurrence.reminderTime {
                item.reminderTime = NSNumber(value: reminderTime)
                if save { try scheduleReminder(for: item, with: itemRecurrence) }
            }
            item.recurringEndDate = itemRecurrence.endDate
        }
        if save {
            try saveContext()
        }
        return item
    }
    
    
    
    func checkCategory(categoryName: String, monthString: String, createNew: Bool = true) -> Category? {
        guard let month = checkMonth(monthString: monthString, createNew: true)  else { return nil }
        let fetchRequest = NSFetchRequest<Category>(entityName: "Category")
        fetchRequest.predicate = NSPredicate(format: "name = %@ AND month = %@", categoryName, month)
        if let fetchedCategory = try? context.fetch(fetchRequest).first {
            return fetchedCategory
        } else if createNew {
            let newCategory = Category(context: context)
            newCategory.month = month
            newCategory.name = categoryName
            return newCategory
        } else {
            return nil
        }
    }
    
    func checkMonth(monthString: String, createNew: Bool = false) -> Month? {
        let fetchRequest = NSFetchRequest<Month>(entityName: "Month")
        fetchRequest.predicate = NSPredicate(format: "date = %@", monthString)
        if let fetchedMonth = try? context.fetch(fetchRequest).first {
            return fetchedMonth
        } else if createNew {
            let newMonth = Month(context: context)
            newMonth.date = monthString
            newMonth.year = String(monthString.split(separator: " ").last!)
            return newMonth
        } else {
            return nil
        }
    }
    
    
    func extractMonthString(from dayString: String) -> String {
        let segments = dayString.split(separator: " ")
        let month = String(segments[0])
        let year = String(segments[2])
        return "\(month) \(year)"
    }
    
    func calcYearTotals(year: String) throws -> YearTotals {
        var yearTotalIncome: Double = 0
        var yearTotalSpending: Double = 0
        var maxMonthAmountInYear: Double = 0
        var maxAmountPerMonth = [Month: Double]()
        
        let fetchRequest  = NSFetchRequest<Month>(entityName: "Month")
        fetchRequest.predicate = NSPredicate(format: "year = %@", year)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        let fetchedMonths = try context.fetch(fetchRequest)
        for month in fetchedMonths {
            let totals = calcTotalsForMonth(month: month)
            yearTotalIncome += totals[.income] ?? 0
            yearTotalSpending += totals[.spending] ?? 0
            maxAmountPerMonth[month] = max(totals[.income] ?? 0, totals[.spending] ?? 0)
        }
        maxMonthAmountInYear = maxAmountPerMonth.values.max() ?? 0
        
        return YearTotals(totalSpending: yearTotalSpending, totalIncome: yearTotalIncome, maxAmountPerMonth: maxMonthAmountInYear)
    }
    
    
    func calcTotalsForMonth(month: Month) -> [ItemType: Double] {
        var result = [ItemType: Double]()
        guard let categories = month.categories?.allObjects as? [Category] else { return result }
        if let income = categories.filter({ $0.name == "Income" }).first {
            result[.income] = calcCategoryTotal(category: income)
        }
        let expenses = categories.filter({ $0.name != "Income" })
        var totalExpenses: Double = 0
        for category in expenses {
            totalExpenses += calcCategoryTotal(category: category)
        }
        result[.spending] = totalExpenses
        return result
    }
    
    func calcCategoryTotal(category: Category) -> Double {
        var total: Double = 0
        if let items = category.items?.allObjects as? [Item] {
            for item in items {
                total += item.amount
            }
        }
        return total > 0 ? (total * 100).rounded() / 100 : 0
    }
    
    func calcCategoryTotalForMonth(_ monthString: String, for categoryName: String? = nil) -> Double? {
        var total: Double = 0
        let fetchRequest = NSFetchRequest<Month>(entityName: "Month")
        fetchRequest.predicate = NSPredicate(format: "date = %@", monthString)
        if let fetchedMonth = try? context.fetch(fetchRequest).first {
            if let categories = fetchedMonth.categories?.allObjects as? [Category] {
                if categoryName == nil {
                    for category in categories.filter({ $0.name != "Income" }) {
                        let categoryTotal = calcCategoryTotal(category: category)
                        total += categoryTotal
                    }
                } else {
                    if let foundCategory = categories.filter({ $0.name == categoryName }).first {
                        let categoryTotal = calcCategoryTotal(category: foundCategory)
                        total += categoryTotal
                    }
                }
            }
        }
        if total > 0 {
            return total
        } else {
            return nil
        }
    }
    
    func fetchFavorites() -> [String] {
        let fetchRequest = NSFetchRequest<Favorite>(entityName: "Favorite")
        if let favorites = try? context.fetch(fetchRequest) {
            return favorites.compactMap({ $0.name })
        } else {
            return [String]()
        }
    }
    
    
    func scheduleReminder(for item: Item, with itemRecurrence: ItemRecurrence?, createNew new: Bool = true) throws {
        guard let itemDate = item.date, itemDate > Date(),
              let itemRecurrence = itemRecurrence
        else { return }
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (success, error) in
            if let err = error {
                print(err.localizedDescription)
                return
            }
        }
        if let oldReminderUID = item.reminderUID, new {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [oldReminderUID])
        }
        if let reminderTime = itemRecurrence.reminderTime {
            var reminderUID: String!
            
            if new {
                let newReminderUID = UUID().uuidString
                item.reminderUID = newReminderUID
                reminderUID = newReminderUID
            } else if let itemReminderUID = item.reminderUID {
                reminderUID = itemReminderUID
            }
            let content = UNMutableNotificationContent()
            content.title = item.detail ?? "Reminder"
            let period = itemRecurrence.period > 1 ? " \(itemRecurrence.period)" : ""
            content.body = "Every\(period) \(itemRecurrence.unit.description)"
            content.sound = .default
            if itemRecurrence.period > 1 { content.body.append("s") }
            
            let reminderDate = Calendar.current.date(byAdding: .day, value: -reminderTime, to: itemDate)
            let dateComponent = Calendar.current.dateComponents([.hour, .minute, .day, .month, .year], from: reminderDate!)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponent, repeats: false)
            let request = UNNotificationRequest(identifier: reminderUID, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { (error) in
                if let err = error {
                    print(err.localizedDescription)
                }
            }
            if new {
                try saveContext()
            }
        } else {
            item.reminderUID = nil
            return
        }
    }

    
    func getCommonItemNames() -> [String] {
        var commonItemNames = [String]()
        let fetchRequest = NSFetchRequest<Item>(entityName: "Item")
        let currentMonthString = DateFormatters.abbreviatedMonthYearFormatter.string(from: Date())
        let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date())
        let lastMonthString = DateFormatters.abbreviatedMonthYearFormatter.string(from: lastMonth!)
        fetchRequest.predicate = NSPredicate(format: "month.date = %@ OR month.date = %@", currentMonthString, lastMonthString)
        fetchRequest.fetchLimit = 15
        if let items = try? context.fetch(fetchRequest) {
            let itemNames = items.compactMap({ $0.detail })
            var itemCounts = [String: Int]()
            itemNames.forEach({ itemCounts[$0] = itemNames.countOf(element: $0) })
            commonItemNames = Array(itemCounts.keys).sorted(by: {
                guard let firstItemCount = itemCounts[$0],
                      let secondItemCount = itemCounts[$1]
                else { return false }
                return (firstItemCount, $1) > (secondItemCount, $0)
            })
        }
        return commonItemNames
    }
    
    
    func calcYearAverage(for year: String) throws -> Int? {
        let startDate = DateFormatters.yearFormatter.date(from: year)
        let endDate = DateFormatters.yearFormatter.string(from: Date()) == year ? Date() : Calendar.current.date(byAdding: .year, value: 1, to: startDate!)
        let dateComponent = Set(arrayLiteral: Calendar.Component.month)
        let number = Calendar.current.dateComponents(dateComponent, from: startDate!, to: endDate!).month
        guard let numberOfMonths = number, numberOfMonths > 1 else { return nil }
        let yearTotals = try calcYearTotals(year: year)
        let averageSpending = yearTotals.totalSpending / Double(numberOfMonths)
        let averageIncome = yearTotals.totalIncome / Double(numberOfMonths)
        if averageIncome > 0 && averageSpending > 0 {
            return Int(averageIncome - averageSpending)
        } else {
            return nil
        }
    }
    

    func deleteItem(item: Item, saveContext save: Bool) throws {
        if let reminuderUID = item.reminderUID {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminuderUID])
        }
        context.delete(item)
        if save {
            try saveContext()
        }
    }
    
    func saveContext() throws {
        if context.hasChanges {
            try context.save()
        }
    }
    
    
    func fetchUniqueCategoryNames(for year: String?) -> [String] {
        var names = [String]()
        let fetchRequest = NSFetchRequest<Category>(entityName: "Category")
        if year != nil { fetchRequest.predicate = NSPredicate(format: "month.year = %@", year!) }
        if let categories = try? context.fetch(fetchRequest) {
            for category in categories.filter({ $0.name != "Income" }) {
                if let name = category.name {
                    names.append(name)
                }
            }
        }
        return names.unique()
    }
    
    
    func calcMaxInYear(year: String, forIncome income: Bool = false) -> Double? {
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        var totals = [Double]()
        for month in months {
            let monthString = "\(month) \(year)"
            if let totalValue = CoreDataManager.shared.calcCategoryTotalForMonth(monthString, for: income ? "Income" : nil) {
                totals.append(totalValue)
            }
        }
        return totals.max()
    }
    
    
    func fetchCategoryTotals(for year: String, forMonth month: String? = nil) -> [String: Double] {
        var dict = [String: Double]()
        
        let categoryNames = CoreDataManager.shared.fetchUniqueCategoryNames(for: year)
        for name in categoryNames {
            var total: Double = 0
            let fetchRequest = NSFetchRequest<Category>(entityName: "Category")
            if let month = month {
                let monthYear = "\(month) \(year)"
                fetchRequest.predicate = NSPredicate(format: "name = %@ AND month.date = %@", name, monthYear)
            } else {
                fetchRequest.predicate = NSPredicate(format: "name = %@ AND month.year = %@", name, year)
            }
            if let fetchedCategories = try? context.fetch(fetchRequest) {
                for category in fetchedCategories.filter({ $0.name != "Income" }) {
                    for item in category.items?.allObjects as! [Item] {
                        total += item.amount
                    }
                }
            }
            dict[name] = (total * 100).rounded() / 100
        }
        return dict
    }
    
    
    
}
