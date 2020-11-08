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
    
    var recentItemsFetchedResultControl: NSFetchedResultsController<Item>!
    
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
    
    override init() {
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
            delegate?.presentError(error: err)
        }
    }
    
    
    func scheduleReminder(for item: Item, with itemRecurrence: ItemRecurrence, createNew new: Bool = true) {
        do {
            try CoreDataManager.shared.scheduleReminder(for: item, with: itemRecurrence, createNew: new)
        } catch let err {
            delegate?.presentError(error: err)
        }
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
        }
    }
    
    func fetchMonthTotals(forDate date: Date = Date()) {
        currentMonthTotalIncome =  0
        currentMonthTotalSpending = 0
        let dayString = DateFormatters.fullDateFormatter.string(from: date)
        let monthString = CoreDataManager.shared.extractMonthString(from: dayString)
        
        let fetchRequest = NSFetchRequest<Item>(entityName: "Item")
        fetchRequest.predicate = NSPredicate(format: "month.date = %@", monthString)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "amount", ascending: true)]
        monthTotalFetchedResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        monthTotalFetchedResultController.delegate = self
        try? monthTotalFetchedResultController.performFetch()
        
        if let currentMonth = CoreDataManager.shared.checkMonth(monthString: monthString, createNew: false) {
            let monthTotals = CoreDataManager.shared.calcTotalsForMonth(month: currentMonth)
            currentMonthTotalIncome = monthTotals[.income] ?? 0
            currentMonthTotalSpending = monthTotals[.spending] ?? 0
        }
    }

    
    func fetchRecentItems() {
        do {
            let weekAgo: Date = Date() - TimeInterval(60 * 60 * 24 * 7)
            let dayAfter: Date = Date() + TimeInterval(60 * 60 * 24)
            let fetchRequest = NSFetchRequest<Item>(entityName: "Item")
            fetchRequest.predicate = NSPredicate(format: "date > %@ AND date < %@", weekAgo as CVarArg, dayAfter as CVarArg)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            fetchRequest.fetchLimit = 15
            recentItemsFetchedResultControl = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            recentItemsFetchedResultControl.delegate = self
            try recentItemsFetchedResultControl.performFetch()
            recentItems = recentItemsFetchedResultControl.fetchedObjects ?? [Item]()
        } catch let err {
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
            let changedMonth = changedItem.month ?? CoreDataManager.shared.checkMonth(monthString: monthString, createNew: false)
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




