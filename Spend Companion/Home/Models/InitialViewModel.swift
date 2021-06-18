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
    /// Tells the delegate that one of the recent items has changed
    func recentItemsChanged()
    /// Tells the delegate that either the total income or the total spending for a month has changed
    func monthTotalChanged(forMonth: Month)
    /// Passes an error to the delegate to be presented as an action alert
    func presentError(error: Error)
}

class InitialViewModel: NSObject {
    
// MARK:- Properties
    
    private var context: NSManagedObjectContext {
        return CoreDataManager.shared.context
    }
    weak var delegate: InitialViewModelDelegate?
    private(set) var recentItems = [Item]()  // Displayed by the recent items table
    
    // These variables are to keep track of the income and spending
    private(set) var currentMonthTotalIncome: Double = 0
    private(set) var currentMonthTotalSpending: Double = 0
    private(set) var currentYearTotalSpending: Double = 0
    private(set) var currentYearTotalIncome: Double = 0
    private(set) var maxMonthAmountInYear: Double = 0
    
// MARK:- Fetched Result Controllers
    
    var recentItemsFetchedResultControl: NSFetchedResultsController<Item>?
    
    private lazy var remindersFetchedResultsController: NSFetchedResultsController<Item> = {
        let fetchRequest = NSFetchRequest<Item>(entityName: "Item")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "(reminderTime != nil) AND (date > %@)", Date() as CVarArg)
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        return frc
    }()
    
    private var monthTotalFetchedResultController: NSFetchedResultsController<Item>?
    
// MARK:- Methods
    
    override init() {
        super.init()
        fetchMonthTotals()
        calcYearTotals(year: DateFormatters.yearFormatter.string(from: Date()))
        remindersFetchedResultsController.delegate = self
        
        // In case reminders had changed from another iCloud device, they get synced once when the app loads
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.syncReminders()
        }
    }

    func saveItem(itemStruct: ItemStruct, completion: @escaping (Bool) -> Void) {
        do {
            try CoreDataManager.shared.saveItem(itemStruct: itemStruct)
            completion(true)
        } catch let err {
            delegate?.presentError(error: err)
        }
    }
    /// Calculates the total income and spending in a given year and the highest spending amount per month in the given year in order to calculate width of the bar chart
    func calcYearTotals(year: String) {
        currentYearTotalIncome = 0
        currentYearTotalSpending = 0
        do {
            let yearTotals = try CoreDataManager.shared.calcYearTotals(year: year)
            currentYearTotalIncome = yearTotals.totalIncome
            currentYearTotalSpending = yearTotals.totalSpending
            maxMonthAmountInYear = yearTotals.maxAmountPerMonth
        } catch let err {
            delegate?.presentError(error: err)
        }
    }
    /// Performs a fetch request from the context  to fetch all the items in a given month then calculates total income and total spending
    func fetchMonthTotals(forDate date: Date = Date()) {
        currentMonthTotalIncome =  0
        currentMonthTotalSpending = 0
        
        // Fetch request for any item whos month corresponds to the given month then constructs the fetched result controller
        let monthString = DateFormatters.abbreviatedMonthYearFormatter.string(from: date)
        let fetchRequest = NSFetchRequest<Item>(entityName: "Item")
        fetchRequest.predicate = NSPredicate(format: "month.date = %@", monthString)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "amount", ascending: true)]
        monthTotalFetchedResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        monthTotalFetchedResultController?.delegate = self
        try? monthTotalFetchedResultController?.performFetch()
        
        // Calculate the total income and spending
        if let currentMonth = CoreDataManager.shared.checkMonth(monthString: monthString, createNew: false) {
            let monthTotals = CoreDataManager.shared.calcTotalsForMonth(month: currentMonth)
            currentMonthTotalIncome = monthTotals[.income] ?? 0
            currentMonthTotalSpending = monthTotals[.spending] ?? 0
        }
    }
    /// Fetch request for the most recent 15 transactions
    func fetchRecentItems() {
        guard let dayAfter: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date().zeroHour()) else { return }
        do {
            let fetchRequest = NSFetchRequest<Item>(entityName: "Item")
            fetchRequest.predicate = NSPredicate(format: "date < %@", dayAfter as CVarArg)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            fetchRequest.fetchLimit = 15
            recentItemsFetchedResultControl = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            recentItemsFetchedResultControl?.delegate = self
            try recentItemsFetchedResultControl?.performFetch()
            recentItems = recentItemsFetchedResultControl?.fetchedObjects ?? [Item]()
        } catch let err {
            delegate?.presentError(error: err)
        }
    }
    /// Gets called when the user swipes to delete a recent item
    func deleteRecentItem(at indexPath: IndexPath) {
        let item = recentItems.remove(at: indexPath.row)
        do {
            try CoreDataManager.shared.deleteItem(item: item, saveContext: true)
        } catch let err {
            delegate?.presentError(error: err)
        }
    }
    
    /// Syncs reminders after loading the app in case they were changed by another iCloud device. All the future notifications are reset after performing a fetch request.
    private func syncReminders() {
        guard NSUbiquitousKeyValueStore.default.bool(forKey: SettingNames.iCloudSync),
              NSUbiquitousKeyValueStore.default.bool(forKey: SettingNames.remindersPurchased)
              else { return }
        do {
            try remindersFetchedResultsController.performFetch()
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            if let timeString = UserDefaults.standard.value(forKey: SettingNames.dailyReminderTime) as? String, let reminderTime = DateFormatters.hourFormatter.date(from: timeString) {
                scheduleDailyReminder(at: reminderTime)
            }
            if let fetchedItems = remindersFetchedResultsController.fetchedObjects {
                for item in fetchedItems {
                    if let itemRecurrence = ItemRecurrence.createItemRecurrence(from: item) {
                        try CoreDataManager.shared.scheduleReminder(for: item, with: itemRecurrence, createNew: false)
                    }
                }
            }
        } catch let err {
            delegate?.presentError(error: err)
        }
    }
    
    func scheduleDailyReminder(at date: Date) {
        let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let content = UNMutableNotificationContent()
        content.body = "Daily Reminder"
        content.sound = .default
        let request = UNNotificationRequest(identifier: SettingNames.dailyReminderID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { (error) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
}

// MARK:- Recent Items Table Data Source

extension InitialViewModel: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recentItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RecentItemCell.reuseIdentifier, for: indexPath) as! RecentItemCell
        let item = recentItems[indexPath.row]
        cell.configureCell(for: item)
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.performBatchUpdates({
                tableView.deleteRows(at: [indexPath], with: .automatic)
                deleteRecentItem(at: indexPath)
            }, completion: nil)
        }
    }
}

// MARK:- Fetched Results Controller Delegate

extension InitialViewModel: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard let changedItem = anObject as? Item else { return }
        
        if controller == recentItemsFetchedResultControl {
            
            // Validation to make sure the item deletion did not occur in the recent items table
            if type == .delete, !recentItems.contains(changedItem) { return }
            
            // Update recent items and ask the delegate to reload the recent items table
            recentItems = recentItemsFetchedResultControl?.fetchedObjects ?? [Item]()
            delegate?.recentItemsChanged()
            
        } else if controller == monthTotalFetchedResultController {
            guard let itemDate = changedItem.date else { return }
            let monthString = DateFormatters.abbreviatedMonthYearFormatter.string(from: itemDate)
            
            // Unwrap the item's month and if successful then pass it to the delegate to reload bar chart
            let changedMonth = changedItem.month ?? CoreDataManager.shared.checkMonth(monthString: monthString, createNew: false)
            if let changedMonth = changedMonth {
                delegate?.monthTotalChanged(forMonth: changedMonth)
            }
        } else if controller == remindersFetchedResultsController {
            
            // If a reminder is setup, validate that it came from a different device
            guard !UserDefaults.standard.bool(forKey: SettingNames.contextIsActive) else { return }
            switch type {
            
            // Use the existing reminder UID to create/edit or delete a reminder, this is done in order to keep the same UID for a given item across all devices
            case .update, .insert:
                if let itemRecurrence = ItemRecurrence.createItemRecurrence(from: changedItem) {
                    try? CoreDataManager.shared.scheduleReminder(for: changedItem, with: itemRecurrence, createNew: false)
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




