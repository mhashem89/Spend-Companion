//
//  ArchivedCode.swift
//  Spend Companion
//
//  Created by Mohamed Hashem on 10/20/20.
//

import Foundation



//func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
//        if editingStyle == .delete {
//            let item = viewModel.recentItems[indexPath.row]
//            let itemYear = item.month?.year
//            itemDeletedFromRecentTable = true
//            recentItemsTable?.performBatchUpdates({
//                recentItemsTable?.deleteRows(at: [indexPath], with: .automatic)
//                viewModel.deleteItem(item: item, at: indexPath)
//            }, completion: { [unowned self] _ in
//                let selectedYearString = self.viewModel.yearFormatter.string(from: selectedYear)
//                if self.summaryView.segmentedControl.selectedSegmentIndex == 1, itemYear == selectedYearString {
//                    self.viewModel.calcYearTotals(year: selectedYearString)
//                    self.scaleFactor = self.calcScaleFactor()
//                    self.summaryView.barChart.reloadData()
//                }
//            })
//        }
//    }



//    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
//        let edit = UIContextualAction(style: .normal, title: "Edit") { [unowned self] (action, view, nil) in
//            let item = self.viewModel.recentItems[indexPath.row]
//            let categoryVC = CategoryViewController(month: item.month!, category: item.category)
//            if let itemIndex = categoryVC.viewModel?.items?.firstIndex(of: item) {
//                present(UINavigationController(rootViewController: categoryVC), animated: true) {
//                    let selectedIndexPath = IndexPath(item: itemIndex, section: 0)
//                    categoryVC.tableView.scrollToRow(at: selectedIndexPath, at: .none, animated: true)
//                    categoryVC.tableView.cellForRow(at: selectedIndexPath)?.isHighlighted = true
//                }
//            }
//        }
//        edit.backgroundColor = .systemBlue
//        let swipe = UISwipeActionsConfiguration(actions: [edit])
//        return swipe
//    }



//        } else if controller == remindersFetchedResultsController && !context.hasChanges, let item = anObject as? Item {
//            if type == .insert {
//                guard let period = item.recurringNum, let unit = item.recurringUnit, let reminderTime = item.reminderTime, let reminderUID = item.reminderUID else { return }
//                UNUserNotificationCenter.current().getPendingNotificationRequests { [weak self] (requests) in
//                    let requestIDs = requests.compactMap({ $0.identifier })
//                    if !requestIDs.contains(reminderUID) {
//                        let itemRecurrence = ItemRecurrence(period: Int(truncating: period), unit: RecurringUnit(rawValue: Int(truncating: unit))!, reminderTime: Int(truncating: reminderTime), endDate: item.recurringEndDate!)
//                        self?.scheduleReminder(for: item, with: itemRecurrence, createNew: false)
//                    }
//                }
//            } else if type == .delete {
//                if let reminderUID = item.reminderUID {
//                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderUID])
//                }
//            }



//{
//    /*
//     The persistent container for the application. This implementation
//     creates and returns a container, having loaded the store for the
//     application to it. This property is optional since there are legitimate
//     error conditions that could cause the creation of the store to fail.
//    */
//    var container: NSPersistentContainer!
//
//    if #available(iOS 13, *) {
//        container = iCloudKeyStore.bool(forKey: "iCloud sync") ? NSPersistentCloudKitContainer(name: "Spend_Companion") : NSPersistentContainer(name: "Spend_Companion")
//        container.viewContext.automaticallyMergesChangesFromParent = true
//    } else {
//        container = NSPersistentContainer(name: "Spend_Companion")
//    }
//
//    container.loadPersistentStores(completionHandler: { (storeDescription, error) in
//        if let error = error as NSError? {
//            // Replace this implementation with code to handle the error appropriately.
//            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//
//            /*
//             Typical reasons for an error here include:
//             * The parent directory does not exist, cannot be created, or disallows writing.
//             * The persistent store is not accessible, due to permissions or data protection when the device is locked.
//             * The device is out of space.
//             * The store could not be migrated to the current model version.
//             Check the error message to determine what the actual problem was.
//             */
//            fatalError("Unresolved error \(error), \(error.userInfo)")
//        }
//    })
//    return container
//}()



//        do {
//            try remindersFetchedResultsController.performFetch()
//            UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
//                let requestIDs = requests.map({ $0.identifier })
//                self.remindersFetchedResultsController.fetchedObjects?.forEach({ item in
//                    if !requestIDs.contains(item.reminderUID!), let itemRecurrence = self.createItemRecurrence(from: item) {
//                        self.scheduleReminder(for: item, with: itemRecurrence, createNew: false)
//                    }
//                })
//            }
//        } catch let err {
//            print(err.localizedDescription)
//        }



//let button = UITabBarItem(title: "Settings", image: nil, selectedImage: nil)
//button.setTitleTextAttributes([.font: UIFont.boldSystemFont(ofSize: 16)], for: .normal)
//button.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -8)
//navigationController?.tabBarItem = button

//
//
//class DateFormats {
//
//    static let fullDateWithLetters = "E, d, MMM yyyy"
//
//    static let fullDate = "MMM d, yyyy"
//
//    static let monthYear = "MMMM yyyy"
//
//    static let abbreviatedMonthYear = "MMM yyyy"
//
//    static let abbreviatedMonth = "MMM"
//
//    static let year = "yyyy"
//}
//
//
//@propertyWrapper
//struct FormattedDate {
//
//    private var dateFormatter = DateFormatter()
//
//    var wrappedValue: Date
//
//    var projectedValue: String? {
//        return dateFormatter.string(from: wrappedValue)
//    }
//
//    init(wrappedValue: Date, dateFormat: String) {
//        self.wrappedValue = wrappedValue
//        self.dateFormatter.dateFormat = dateFormat
//    }
//
//}
//
//
//@propertyWrapper
//struct FormattedDateString {
//
//    private var dateFormatter = DateFormatter()
//
//    var wrappedValue: String
//
//    var projectedValue: Date?
//
//    init(wrappedValue: String, dateFormat: String) {
//        self.wrappedValue = wrappedValue
//        self.dateFormatter.dateFormat = dateFormat
//    }
//}
