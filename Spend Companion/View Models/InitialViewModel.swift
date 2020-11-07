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
    
    private var context: NSManagedObjectContext {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }
    
    weak var delegate: InitialViewModelDelegate?
    
    private(set) var recentItems = [Item]()
    
    private(set) var currentMonthTotalIncome: Double = 0
    private(set) var currentMonthTotalSpending: Double = 0
    private(set) var currentYearTotalSpending: Double = 0
    private(set) var currentYearTotalIncome: Double = 0
    private(set) var maxMonthSpendingInYear: Double = 0
    
// MARK:- Fetched Result Controllers
    
    private var recentItemsFetchedResultControl: NSFetchedResultsController<Item>!
    
    private lazy var remindersFetchedResultsController: NSFetchedResultsController<Item> = {
        let fetchRequest = NSFetchRequest<Item>(entityName: "Item")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "(reminderUID != nil) AND (date > %@)", Date() as CVarArg)
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        return frc
    }()
    
    private var monthTotalFetchedResultController: NSFetchedResultsController<Item>!
    
    private var yearTotalFetchedResultController: NSFetchedResultsController<Month>!
    
    
    
// MARK:- Methods
    
    private override init() {
        super.init()
        fetchMonthTotals()
        calcYearTotals(year: DateFormatters.yearFormatter.string(from: Date()))
        fetchRecentItems()
        remindersFetchedResultsController.delegate = self
        syncReminders()
    }

    func saveItem(itemStruct: ItemStruct) {
        do {
            try CoreDataManager.shared.saveItem(itemStruct: itemStruct)
        } catch let err {
            print(err.localizedDescription)
            delegate?.presentError(error: err)
        }
    }
    
    
    func scheduleReminder(for item: Item, with itemRecurrence: ItemRecurrence, createNew new: Bool = true) {
        do {
            try CoreDataManager.shared.scheduleReminder(for: item, with: itemRecurrence, createNew: new)
        } catch let err {
            delegate?.presentError(error: err)
            print(err.localizedDescription)
        }
    }
    
    
    func checkCategory(categoryName: String, monthString: String, createNew: Bool = true) -> Category? {
        return CoreDataManager.shared.checkCategory(categoryName: categoryName, monthString: monthString, createNew: createNew)
    }
    
    private func checkMonth(monthString: String, createNew: Bool = false) -> Month? {
        return CoreDataManager.shared.checkMonth(monthString: monthString, createNew: createNew)
    }

    func calcYearTotals(year: String) {
        currentYearTotalIncome = 0
        currentYearTotalSpending = 0
        do {
            let yearTotals = try CoreDataManager.shared.calcYearTotals(year: year)
            currentYearTotalIncome = yearTotals.totalIncome
            currentYearTotalSpending = yearTotals.totalSpending
            maxMonthSpendingInYear = yearTotals.maxAmountPerMonth
        } catch let err {
            delegate?.presentError(error: err)
            print(err.localizedDescription)
        }
    }
    
    func fetchMonthTotals(forDate date: Date = Date()) {
        let monthTotals = CoreDataManager.shared.fetchMonthTotals(forDate: date, with: &monthTotalFetchedResultController)
        monthTotalFetchedResultController.delegate = self
        currentMonthTotalIncome = monthTotals[.income] ?? 0
        currentMonthTotalSpending = monthTotals[.spending] ?? 0
    }

    
    func fetchRecentItems() {
        do {
            recentItems = try CoreDataManager.shared.fetchRecentItems(with: &recentItemsFetchedResultControl)
            recentItemsFetchedResultControl.delegate = self
        } catch let err {
            print(err.localizedDescription)
            delegate?.presentError(error: err)
        }
    }
    
    func deleteRecentItem(at indexPath: IndexPath) {
        let item = recentItems[indexPath.row]
        do {
            try CoreDataManager.shared.deleteItem(item: item, saveContext: true)
        } catch let err {
            delegate?.presentError(error: err)
        }
    }
    
    
    func getCommonItemNames() -> [String] {
        return CoreDataManager.shared.getCommonItemNames()
    }
    
    
    func calcYearAverage(for year: String) -> Int? {
        return try? CoreDataManager.shared.calcYearAverage(for: year)
    }
    
    private func syncReminders() {
        guard NSUbiquitousKeyValueStore.default.bool(forKey: SettingNames.iCloudSync) else { return }
        do {
            try remindersFetchedResultsController.performFetch()
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            if let fetchedItems = remindersFetchedResultsController.fetchedObjects {
                for item in fetchedItems {
                    if let itemRecurrence = ItemRecurrence.createItemRecurrence(from: item) {
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
        guard let changedItem = anObject as? Item else { return }
        
        if controller == recentItemsFetchedResultControl {
            if type == .delete, !recentItems.contains(changedItem) { return }
            delegate?.recentItemsChanged()
        } else if controller == monthTotalFetchedResultController {
            guard changedItem.date != nil else { return }
            let monthString = DateFormatters.abbreviatedMonthYearFormatter.string(from: changedItem.date!)
            let changedMonth = changedItem.month ?? checkMonth(monthString: monthString, createNew: false)
            if let changedMonth = changedMonth {
                delegate?.monthTotalChanged(forMonth: changedMonth)
            }
        } else if controller == remindersFetchedResultsController {
            switch type {
            case .update, .insert:
                if let itemRecurrence = ItemRecurrence.createItemRecurrence(from: changedItem) {
                    scheduleReminder(for: changedItem, with: itemRecurrence, createNew: false)
                }
            case .delete:
                if let itemReminderUID = changedItem.reminderUID {
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [itemReminderUID])
                }
            default:
                break
            }
        }
    }
}




