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
    
    /// Create a new Item entitiy from an item struct and saves it. Does the same if the item has future similar items.
    func saveItem(itemStruct: ItemStruct) throws {
        let createdItem = try createNewItem(date: itemStruct.date, itemStruct: itemStruct)
        
        if itemStruct.itemRecurrence != nil {
            try createFutureItems(for: createdItem, shouldSave: true)
        }
    }
    /// Creates an Item entity for each future recurrence of the item, with the option to save them to the context
    func createFutureItems(for item: Item, shouldSave save: Bool) throws {
        guard var itemDate = item.date, let itemStruct = ItemStruct.itemStruct(from: item) else { return }
        if let itemRecurrence = itemStruct.itemRecurrence, itemRecurrence.endDate > itemDate {
            var items = [item]
            
            // Since the future end date will be saved as starting at hour 00.00, need to adjust it to account for the additional hours on the day the item is being saved
            let additionalHours = Calendar.current.dateComponents([.hour, .minute, .second, .nanosecond], from: Date())
            let adjustedEndDate = Calendar.current.date(byAdding: additionalHours, to: itemRecurrence.endDate)!
            
            var dateComponent = DateComponents()
            switch itemRecurrence.unit { // Set the recurring date component to either every X days, weeks or months
            case .day: dateComponent.day = itemRecurrence.period
            case .month: dateComponent.month = itemRecurrence.period
            case .week: dateComponent.weekOfYear = itemRecurrence.period
            }
            // Loop through the the period from start date to end date and create a new Item entity each time
            while Calendar.current.date(byAdding: dateComponent, to: itemDate)! <= adjustedEndDate {
                itemDate = Calendar.current.date(byAdding: dateComponent, to: itemDate)!
                let newItem = try createNewItem(date: itemDate, itemStruct: itemStruct, save: save)
                items.append(newItem)
            }
            if items.count > 1 {
                for item in items {
                    item.sisterItems = NSSet(array: items.filter({ $0 != item }))
                }
            }
            if save { try saveContext() }
        }
    }
    
    /// Create new Item entity from an item struct with the option to save it
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
                if save { try scheduleReminder(for: item, with: itemRecurrence) } // Create reminder notification
            }
            item.recurringEndDate = itemRecurrence.endDate
        }
        if save {
            try saveContext()
        }
        return item
    }
    
    /// Checks if a Category entity exists for a certain name and month, with the option to create a new one if nothing is found
    func checkCategory(categoryName: String, monthString: String, createNew: Bool = true) -> Category? {
        guard let month = checkMonth(monthString: monthString, createNew: true)  else { return nil }
        let fetchRequest = NSFetchRequest<Category>(entityName: "Category")
        fetchRequest.predicate = NSPredicate(format: "name = %@ AND month = %@", categoryName, month)
        guard let fetchedCategories = try? context.fetch(fetchRequest) else { return nil }
        if let fetchedCategory = fetchedCategories.first {
            if fetchedCategories.count > 1 { mergeCategories(fetchedCategories) }
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
    /// Checks if a Month entity exists, with the option to create a new one if nothing is found
    func checkMonth(monthString: String, createNew: Bool = false) -> Month? {
        let fetchRequest = NSFetchRequest<Month>(entityName: "Month")
        fetchRequest.predicate = NSPredicate(format: "date = %@", monthString)
        guard let fetchedMonths = try? context.fetch(fetchRequest) else { return nil }
        if let fetchedMonth = fetchedMonths.first {
            if fetchedMonths.count > 1 { mergeMonths(months: fetchedMonths) }
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
    /// If duplicate Month entities are found, then merges the categories and items of both months and deletes the duplicate entitity
    func mergeMonths(months: [Month]) {
        var filteredMonths = months
        let first = filteredMonths.removeFirst()
        filteredMonths.forEach { (month) in
            (month.categories?.allObjects as? [Category])?.forEach({ $0.month = first })
            (month.items?.allObjects as? [Item])?.forEach({ $0.month = first })
            context.delete(month)
        }
    }
    /// If duplicate Category entities are found, then merges the items of both categories and deletes the duplicate entity
    func mergeCategories(_ categories: [Category]) {
        var filteredCategories = categories
        let first = filteredCategories.removeFirst()
        filteredCategories.forEach { (category) in
            (category.items?.allObjects as? [Item])?.forEach({ $0.category = first })
            context.delete(category)
        }
    }
    /// Extracts the month and year from a full date string (e.g. Jan 24, 2020)
    func extractMonthString(from dayString: String) -> String {
        let segments = dayString.split(separator: " ")
        let month = String(segments[0])
        let year = String(segments[2])
        return "\(month) \(year)"
    }
    /// Fetches all the Month entities in a given year and then returns a struct that has total income per year, total spending per year, and the maximum amount of income/spending per month
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
    /// Returns a dictionary that has the total amount of income and spending in a given month
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
    /// Returns the total amount for a given category rounded to two decimals
    func calcCategoryTotal(category: Category) -> Double {
        var total: Double = 0
        if let items = category.items?.allObjects as? [Item] {
            for item in items {
                total += item.amount
            }
        }
        return total > 0 ? (total * 100).rounded() / 100 : 0
    }
    /// Returns the total amount for a given month, if no category is specified returns the total spending, otherwise returns the total for the specified category or nil if total is 0
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
    /// Returns an array of favorite category names
    func fetchFavorites() -> [String] {
        let fetchRequest = NSFetchRequest<Favorite>(entityName: "Favorite")
        if let favorites = try? context.fetch(fetchRequest) {
            return favorites.compactMap({ $0.name })
        } else {
            return [String]()
        }
    }
    /// Takes an item with its item recurrence struct and schedules a reminder remote notifcation at the specified time, with the option to create a new reminder UID and save it if needed
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
        if let oldReminderUID = item.reminderUID {
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
        }
    }
    
    /// Returns an array of the most common item names entered in the last 2 months, with max limit of 15.
    func getCommonItemNames() -> [String] {
        var commonItemNames = [String]()
        let fetchRequest = NSFetchRequest<Item>(entityName: "Item")
        let currentMonthString = DateFormatters.abbreviatedMonthYearFormatter.string(from: Date())
        let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date())
        let lastMonthString = DateFormatters.abbreviatedMonthYearFormatter.string(from: lastMonth!)
        fetchRequest.predicate = NSPredicate(format: "month.date = %@ OR month.date = %@", currentMonthString, lastMonthString)
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
    /// Returns the difference between average income and average spending in a given year
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
    /// Asks the context to delete and item with option to save it to context
    func deleteItem(item: Item, saveContext save: Bool) throws {
        context.delete(item)
        if save {
            try saveContext()
        }
    }
    /// Asks context to save changes if there are any
    func saveContext() throws {
        if context.hasChanges {
            try (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
        }
    }
    /// Returns an array of all the unique category names
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
    /// Returns the maximum spending in a given year or, if specified, the maximum income
    func calcMaxInYear(year: String, forIncome income: Bool = false) -> Double? {
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        var totals = [Double]()
        for month in months {
            let monthString = "\(month) \(year)"
            if let totalValue = calcCategoryTotalForMonth(monthString, for: income ? "Income" : nil) {
                totals.append(totalValue)
            }
        }
        return totals.max()
    }
    
    /// Returns a dictionary of all the spending category names in a given year or month with corresponding total amount. Exlcudes income
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
    
    func generateCSV(completion: @escaping ((URL) -> Void)) throws {
        let itemFetch = NSFetchRequest<Item>(entityName: "Item")
        let categoryFetch = NSFetchRequest<Category>(entityName: "Category")
        let favoriteFetch = NSFetchRequest<Favorite>(entityName: "Favorite")
        
        var csvString = ""
        
        if let items = try? context.fetch(itemFetch),
           let categories = try? context.fetch(categoryFetch),
           let favorites = try? context.fetch(favoriteFetch) {
            
            csvString = "ITEMS\n\nmonth,date,type,category,description,amount,every,recurringUnit,recurringEndDate,reminderTime\n"
            items.forEach { (item) in
                let month = item.month?.date ?? ""
                let date = item.date?.description ?? ""
                let type = item.type == 0 ? "Spending" : "Income"
                let category = item.category?.name ?? ""
                let description = item.detail ?? ""
                let amount = item.amount.description
                let recurringNum = item.recurringNum?.description ?? ""
                var recurringUnit: String {
                    switch item.recurringUnit {
                    case 0: return "day"
                    case 1: return "week"
                    case 2: return "month"
                    default: return ""
                    }
                }
                let recurringEndDate = item.recurringEndDate?.description ?? ""
                let reminderTime = item.reminderTime?.description ?? ""
                let content = "\(month),\(date),\(type),\(category),\(description),\(amount),\(recurringNum),\(recurringUnit),\(recurringEndDate),\(reminderTime)\n"
                csvString.append(content)
            }
            
            csvString.append("\n\nCATEGORIES\nname,month\n")
            
            categories.forEach { (category) in
                let content = "\(category.name ?? ""),\(category.month?.date ?? "")\n"
                csvString.append(content)
            }
            
            csvString.append("\n\nFAVORITES\nname\n")
            favorites.forEach { (favorite) in
                let content = "\(favorite.name ?? "")\n"
                csvString.append(content)
            }
            let directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = URL(fileURLWithPath: "Spend Companion Data", relativeTo: directoryURL).appendingPathExtension("csv")
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            completion(fileURL)
        } 
    }
    
    public func deleteAllData() throws {
        let categoryRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Category")
        let favoriteRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Favorite")
        let monthRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Month")
        let itemRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Item")
        
        let categoryDelete = NSBatchDeleteRequest(fetchRequest: categoryRequest)
        let favoriteDelete = NSBatchDeleteRequest(fetchRequest: favoriteRequest)
        let monthDelete = NSBatchDeleteRequest(fetchRequest: monthRequest)
        let itemDelete = NSBatchDeleteRequest(fetchRequest: itemRequest)
        
        try context.execute(categoryDelete)
        try context.execute(favoriteDelete)
        try context.execute(monthDelete)
        try context.execute(itemDelete)
    }
    
    func checkIfItemExists(name: String) -> (categoryName: String?, itemType: ItemType)? {
        let fetchRequest = NSFetchRequest<Item>(entityName: "Item")
        fetchRequest.predicate = NSPredicate(format: "detail = %@", name)
        if let results = try? context.fetch(fetchRequest) {
            var categoryNames = [String]()
            var itemTypes = [ItemType]()
            results.forEach { (item) in
                if let categoryName = item.category?.name, !categoryNames.contains(categoryName) { categoryNames.append(categoryName) }
                if let type = ItemType(rawValue: item.type), !itemTypes.contains(type) { itemTypes.append(type) }
            }
            if !itemTypes.isEmpty {
                return !categoryNames.isEmpty ? (categoryNames[0], itemTypes[0]) : (nil, itemTypes[0])
            }
        }
        return nil
    }
}
