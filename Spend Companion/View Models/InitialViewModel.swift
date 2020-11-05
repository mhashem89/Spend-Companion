//
//  QuickAddViewModel.swift
//  Spending App
//
//  Created by Mohamed Hashem on 10/8/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications

protocol InitialViewModelDelegate: class {
    func recentItemsChanged()
    func monthTotalChanged(forMonth: Month)
    func presentError(error: Error)
}


class InitialViewModel: NSObject {
    
    
// MARK:- Properties
    
    static let shared = InitialViewModel()
    
    var context: NSManagedObjectContext {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }
    
    weak var delegate: InitialViewModelDelegate?
    
    var recentItems = [Item]()
    
    var currentMonthTotalIncome: Double = 0
    var currentMonthTotalSpending: Double = 0
    var currentYearTotalSpending: Double = 0
    var currentYearTotalIncome: Double = 0
    var maxMonthSpendingInYear: Double = 0
    
// MARK:- Fetched Result Controllers
    
    var recentItemsFetchedResultControl: NSFetchedResultsController<Item>!
    
    lazy var remindersFetchedResultsController: NSFetchedResultsController<Item> = {
        let fetchRequest = NSFetchRequest<Item>(entityName: "Item")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "(reminderUID != nil) AND (date > %@)", Date() as CVarArg)
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        return frc
    }()
    
    var monthTotalFetchedResultController: NSFetchedResultsController<Item>!
    
    var yearTotalFetchedResultController: NSFetchedResultsController<Month>!
    
    
    
// MARK:- Methods
    
    private override init() {
        super.init()
        fetchMonthTotals()
        calcYearTotals(year: DateFormatters.yearFormatter.string(from: Date()))
        fetchRecentItems()
        remindersFetchedResultsController.delegate = self
        syncReminders()
    }

    
    func createItemRecurrence(from item: Item) -> ItemRecurrence? {
        guard let period = item.recurringNum, let unit = item.recurringUnit, let endDate = item.recurringEndDate else { return nil }
        var reminderTime: Int?
        if let itemReminderTime = item.reminderTime {
            reminderTime = Int(truncating: itemReminderTime)
        }
        let itemRecurrence = ItemRecurrence(period: Int(truncating: period), unit: RecurringUnit(rawValue: Int(truncating: unit))!, reminderTime: reminderTime, endDate: endDate)
        return itemRecurrence
    }
    
    func saveItem(itemStruct: ItemStruct) {
        guard var itemDate = itemStruct.date == "Today" ? Date() : DateFormatters.fullDateFormatter.date(from: itemStruct.date) else { return }
        let createdItem = createNewItem(date: itemDate, itemStruct: itemStruct)
        
        if let itemRecurrence = itemStruct.itemRecurrence, itemRecurrence.endDate > itemDate {
            var items = [createdItem]
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
                let newItem = createNewItem(date: itemDate, itemStruct: itemStruct)
                items.append(newItem)
            } while Calendar.current.date(byAdding: dateComponent, to: itemDate)! <= adjustedEndDate
            
            for item in items {
                item.sisterItems = NSSet(array: items.filter({ $0 != item }))
            }
            do {
                try context.save()
            } catch let err {
                print(err.localizedDescription)
                delegate?.presentError(error: err)
            }
        }
    }
    
    func createNewItem(date: Date, itemStruct: ItemStruct, save: Bool = true) -> Item {
        let dayString = DateFormatters.fullDateFormatter.string(from: date)
        let monthString = extractMonthString(from: dayString)
        let item = NSEntityDescription.insertNewObject(forEntityName: "Item", into: context) as! Item
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
                if save { scheduleReminder(for: item, with: itemRecurrence) }
            }
            item.recurringEndDate = itemRecurrence.endDate
        }
        if save {
            do {
                try context.save()
            } catch let err {
                print(err.localizedDescription)
                delegate?.presentError(error: err)
            }
        }
        return item
    }
    
    func scheduleReminder(for item: Item, with itemRecurrence: ItemRecurrence, createNew new: Bool = true) {
        guard item.date != nil, item.date! > Date()  else { return }
        
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
            } else if item.reminderUID != nil {
                reminderUID = item.reminderUID!
            }
            let content = UNMutableNotificationContent()
            content.title = item.detail ?? "Reminder"
            let period = itemRecurrence.period > 1 ? " \(itemRecurrence.period)" : ""
            content.body = "Every\(period) \(itemRecurrence.unit.description)"
            content.sound = .default
            if itemRecurrence.period > 1 { content.body.append("s") }
            
            let reminderDate = Calendar.current.date(byAdding: .day, value: -reminderTime, to: item.date!)
            
            let dateComponent = Calendar.current.dateComponents([.hour, .minute, .day, .month, .year], from: reminderDate!)
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponent, repeats: false)
            
            let request = UNNotificationRequest(identifier: reminderUID, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { (error) in
                if let err = error {
                    print(err.localizedDescription)
                }
            }
            if new {
                do {
                    try context.save()
                } catch let err {
                    print(err.localizedDescription)
                    delegate?.presentError(error: err)
                }
            }
        } else {
            item.reminderUID = nil
            return
        }
    }
    
    
    func checkCategory(categoryName: String, monthString: String) -> Category {
        let month = checkMonth(monthString: monthString, createNew: true)
        let fetchRequest = NSFetchRequest<Category>(entityName: "Category")
        fetchRequest.predicate = NSPredicate(format: "name = %@ AND month = %@", categoryName, month!)
        if let fetchedCategory = try? context.fetch(fetchRequest).first {
            return fetchedCategory
        } else {
            let newCategory = NSEntityDescription.insertNewObject(forEntityName: "Category", into: context) as! Category
            newCategory.month = month
            newCategory.name = categoryName
            return newCategory
        }
    }
    
    func checkMonth(monthString: String, createNew: Bool = false) -> Month? {
        let fetchRequest = NSFetchRequest<Month>(entityName: "Month")
        fetchRequest.predicate = NSPredicate(format: "date = %@", monthString)
        var fetchedMonth: Month?
        do {
            try fetchedMonth = context.fetch(fetchRequest).first
        } catch let err {
            print(err.localizedDescription)
            delegate?.presentError(error: err)
        }
        if let fetchedMonth = fetchedMonth {
            return fetchedMonth
        } else if createNew {
            let newMonth = NSEntityDescription.insertNewObject(forEntityName: "Month", into: context) as! Month
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
    
    func calcYearTotals(year: String) {
        currentYearTotalIncome = 0
        currentYearTotalSpending = 0
        var maxAmountPerMonth = [Month: Double]()
        
        let fetchRequest  = NSFetchRequest<Month>(entityName: "Month")
        fetchRequest.predicate = NSPredicate(format: "year = %@", year)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        yearTotalFetchedResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        yearTotalFetchedResultController.delegate = self
        
        do {
            try yearTotalFetchedResultController.performFetch()
            if let fetchedMonths = yearTotalFetchedResultController.fetchedObjects {
                for month in fetchedMonths {
                    let totals = calcTotalsForMonth(month: month)
                    currentYearTotalIncome += totals[.income] ?? 0
                    currentYearTotalSpending += totals[.spending] ?? 0
                    maxAmountPerMonth[month] = max(totals[.income] ?? 0, totals[.spending] ?? 0)
                }
            }
            maxMonthSpendingInYear = maxAmountPerMonth.values.max() ?? 0
        } catch let err {
            print(err.localizedDescription)
        }
        
    }
    
    func fetchMonthTotals(forDate date: Date = Date()) {
        let dayString = DateFormatters.fullDateFormatter.string(from: date)
        let monthString = extractMonthString(from: dayString)
        currentMonthTotalSpending = 0
        currentMonthTotalIncome = 0
        
        let fetchRequest = NSFetchRequest<Item>(entityName: "Item")
        fetchRequest.predicate = NSPredicate(format: "month.date = %@", monthString)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "amount", ascending: true)]
        monthTotalFetchedResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        monthTotalFetchedResultController.delegate = self
        try? monthTotalFetchedResultController.performFetch()
        
        if let currentMonth = checkMonth(monthString: monthString, createNew: false) {
            let totals = calcTotalsForMonth(month: currentMonth)
            self.currentMonthTotalIncome = totals[.income] ?? 0
            self.currentMonthTotalSpending = totals[.spending] ?? 0
        }
    }
    
    func calcTotalsForMonth(month: Month) -> [ItemType: Double] {
        var result = [ItemType: Double]()
        guard let categories = month.categories?.allObjects as? [Category] else { return result }
        if let income = categories.filter({ $0.name == "Income" }).first {
            result[.income] = CalendarViewModel.shared.calcCategoryTotal(category: income)
        }
        let expenses = categories.filter({ $0.name != "Income" })
        var totalExpenses: Double = 0
        for category in expenses {
            totalExpenses += CalendarViewModel.shared.calcCategoryTotal(category: category)
        }
        result[.spending] = totalExpenses
        return result
    }
    
    
    func fetchRecentItems() {
        do {
            let weekAgo: Date = Date() - TimeInterval(60 * 60 * 24 * 7)
            let dayAfter: Date = Date() + TimeInterval(60 * 60 * 24)
            let fetchRequest = NSFetchRequest<Item>(entityName: "Item")
            fetchRequest.predicate = NSPredicate(format: "date > %@ AND date < %@", weekAgo as CVarArg, dayAfter as CVarArg)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            recentItemsFetchedResultControl = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            recentItemsFetchedResultControl.delegate = self
            try recentItemsFetchedResultControl.performFetch()
            let fetchedResults = recentItemsFetchedResultControl.fetchedObjects ?? [Item]()
            if fetchedResults.count > 14 {
                recentItems = Array(fetchedResults[0...14])
            } else {
                recentItems = fetchedResults
            }
        } catch let err {
            print(err.localizedDescription)
            delegate?.presentError(error: err)
        }
    }
    
    
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
            commonItemNames = Array(itemCounts.keys).sorted(by: { itemCounts[$0]! > itemCounts[$1]! })
        }
        return commonItemNames.count > 14 ? Array(commonItemNames[0...14]) : commonItemNames
    }
    
    
    func calcAverage(for year: String) -> Int? {
        let startDate = DateFormatters.yearFormatter.date(from: year)
        let endDate = DateFormatters.yearFormatter.string(from: Date()) == year ? Date() : Calendar.current.date(byAdding: .year, value: 1, to: startDate!)
        let dateComponent = Set(arrayLiteral: Calendar.Component.month)
        let number = Calendar.current.dateComponents(dateComponent, from: startDate!, to: endDate!).month
        guard let numberOfMonths = number, numberOfMonths > 1 else { return nil }
        calcYearTotals(year: year)
        let averageSpending = currentYearTotalSpending / Double(numberOfMonths)
        let averageIncome = currentYearTotalIncome / Double(numberOfMonths)
        if averageIncome > 0 && averageSpending > 0 {
            return Int(averageIncome - averageSpending)
        } else {
            return nil
        }
    }
    
    func syncReminders() {
        guard NSUbiquitousKeyValueStore.default.bool(forKey: SettingNames.iCloudSync) else { return }
        do {
            try remindersFetchedResultsController.performFetch()
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            if let fetchedItems = remindersFetchedResultsController.fetchedObjects {
                for item in fetchedItems {
                    if let itemRecurrence = createItemRecurrence(from: item) {
                        scheduleReminder(for: item, with: itemRecurrence, createNew: false)
                    }
                }
            }
        } catch let err {
            print(err.localizedDescription)
            delegate?.presentError(error: err)
        }
    }
}


extension InitialViewModel: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if controller == recentItemsFetchedResultControl {
            delegate?.recentItemsChanged()
        } else if controller == monthTotalFetchedResultController {
            guard let changedItem = anObject as? Item, changedItem.date != nil else { return }
            let monthString = DateFormatters.abbreviatedMonthYearFormatter.string(from: changedItem.date!)
            let changedMonth = changedItem.month ?? checkMonth(monthString: monthString, createNew: false)
            if let changedMonth = changedMonth {
                delegate?.monthTotalChanged(forMonth: changedMonth)
            }
        } else if controller == remindersFetchedResultsController, let item = anObject as? Item {
            switch type {
            case .update, .insert:
                if let itemRecurrence = createItemRecurrence(from: item) {
                    scheduleReminder(for: item, with: itemRecurrence, createNew: false)
                }
            case .delete:
                if let itemReminderUID = item.reminderUID {
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [itemReminderUID])
                }
            default:
                break
            }
        }
    }
}


extension Array where Element: Equatable {
    
    func countOf(element: Element) -> Int {
        return filter({ $0 == element }).count
    }
    
}

