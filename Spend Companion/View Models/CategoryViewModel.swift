//
//  CategoryViewModel.swift
//  Spending App
//
//  Created by Mohamed Hashem on 9/18/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit
import CoreData


class CategoryViewModel {
    
    var context: NSManagedObjectContext {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }
    
    var category: Category? {
        didSet {
            checkIfFavorite()
        }
    }
    var month: Month
    var items: [Item]?
    var isFavorite: Bool = false
    var reminderUIDsForDeletion = [String]()
    var currentSortingSelection: (option: SortingOption, direction: SortingDirection) = (.date, .ascending) {
        didSet {
            sortItems(option: currentSortingSelection.option, direction: currentSortingSelection.direction)
        }
    }
    
    
    init(month: Month, category: Category? = nil) {
        self.month = month
        UserDefaults.standard.setValue(true, forKey: SettingNames.contextIsActive)
        if let category = category {
            self.category = category
            checkIfFavorite()
            if let categoryItems = category.items?.allObjects as? [Item] {
                self.items = categoryItems
                sortItems(option: .date, direction: .ascending)
            }
        }
    }
    
    func calcDaysRange(month: Month) -> [String] {
        guard let monthDate = month.date,
              let firstDay = DateFormatters.monthYearFormatter.date(from: monthDate)
        else { return [] }
        let calendar = Calendar.current
        let dayOfMonth = calendar.component(.day, from: firstDay)
        let monthDays = calendar.range(of: .day, in: .month, for: firstDay)!
        let days = (monthDays.lowerBound..<monthDays.upperBound)
            .compactMap( { calendar.date(byAdding: .day, value: $0 - dayOfMonth, to: firstDay) } )
        let dayStrings = days.compactMap({ DateFormatters.fullDateWithLetters.string(from: $0) })
        return dayStrings
    }
    
    
    func createEmptyItem() {
        let newItem = Item(context: context)
        newItem.category = category
        newItem.month = month
        newItem.date = Date()
        if self.items == nil {
            self.items = [newItem]
        } else {
            self.items?.append(newItem)
        }
    }
    
    func favoriteCategory() {
        switch isFavorite {
        case true:
            guard let categoryName = category?.name else { return }
            let fetchRequest = NSFetchRequest<Favorite>(entityName: "Favorite")
            fetchRequest.predicate = NSPredicate(format: "name = %@", categoryName)
            if let favorite = try? context.fetch(fetchRequest).first {
                context.delete(favorite)
                isFavorite = false
            }
        case false:
            let favoriteCategory = Favorite(context: context)
            favoriteCategory.name = category?.name
            isFavorite = true
        }
        
    }
    
    func checkIfFavorite() {
        if let categoryName = category?.name {
            let fetchRequest = NSFetchRequest<Favorite>(entityName: "Favorite")
            fetchRequest.predicate = NSPredicate(format: "name = %@", categoryName)
            if (try? context.fetch(fetchRequest).first) != nil {
                self.isFavorite = true
            } else {
                self.isFavorite = false
            }
        }
    }
    
    
    func editCategoryName(name: String) {
        category?.name = name
        checkIfFavorite()
    }
    
    func save() throws {
        if reminderUIDsForDeletion.count > 0 {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: reminderUIDsForDeletion)
        }
        try CoreDataManager.shared.saveContext()
    }
    
    func cancel() {
        context.rollback()
    }
    
    func deleteItem(item: Item, at index: Int) {
        if let itemReminder = item.reminderUID { reminderUIDsForDeletion.append(itemReminder) }
        try? CoreDataManager.shared.deleteItem(item: item, saveContext: false)
        items?.remove(at: index)
    }
    
    func editFutureItems(for item: Item?, amount: Double?, detail: String?) {
        if let futureItems = item?.futureItems() {
            for item in futureItems {
                if let amount = amount { item.amount = amount }
                if let detail = detail { item.detail = detail }
            }
            reloadData()
        }
    }
    
    func updateItemRecurrence(for item: Item, with newRecurrence: ItemRecurrence, isNew: Bool, dataChanged: [ItemRecurrenceCase]) throws {
        
        if dataChanged.contains(.reminderTime) {
            if let newReminderTime = newRecurrence.reminderTime {
                item.reminderTime = NSNumber(value: newReminderTime)
                item.futureItems()?.forEach({ $0.reminderTime = item.reminderTime })
            } else {
                item.reminderTime = nil
                item.futureItems()?.forEach({ $0.reminderTime = nil })
            }
        }
        
        if dataChanged.count > 1 {
            item.recurringNum = NSNumber(value: newRecurrence.period)
            item.recurringUnit = NSNumber(value: newRecurrence.unit.rawValue)
            item.recurringEndDate = newRecurrence.endDate

            try item.futureItems()?.forEach({ (item) in
                try CoreDataManager.shared.deleteItem(item: item, saveContext: false)
            })
            try CoreDataManager.shared.createFutureItems(for: item, shouldSave: false)
        }
    }
    
    
    func reloadData() {
        self.items = category?.items?.allObjects as? [Item]
        sortItems(option: currentSortingSelection.option, direction: currentSortingSelection.direction)
    }
    
    func moveItem(item: Item, to categoryName: String, sisterItems: [Item]?) {
        guard let categories = month.categories?.allObjects as? [Category] else { return }
        guard let newCategory = categories.filter({ $0.name == categoryName }).first else { return }
        item.category = newCategory
        if let sisterItems = sisterItems {
            sisterItems.forEach({
                if let categoryName = newCategory.name, let itemMonthString = $0.month?.date {
                    $0.category = CoreDataManager.shared.checkCategory(categoryName: categoryName, monthString: itemMonthString)
                }
            })
        }
        reloadData()
    }
    
    func sortItems(option: SortingOption, direction: SortingDirection) {
        guard let viewModelItems = items else { return }
        switch option {
        case .date:
            items = viewModelItems.sorted(by: {
                guard let date0 = $0.date, let date1 = $1.date else { return false }
                return direction == .ascending ? date0 < date1 : date0 > date1
            })
        case .name:
            items = viewModelItems.sorted(by: {
                guard let name0 = $0.detail, let name1 = $1.detail else { return false }
                return direction == .ascending ? name0 < name1 : name0 > name1
            })
        case .amount:
            items = viewModelItems.sorted(by: {
                direction == .ascending ? $0.amount < $1.amount : $0.amount > $1.amount
            })
        }
    }
    
}
