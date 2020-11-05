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
    var month: Month!
    var items: [Item]?
    var isFavorite: Bool = false
    var reminderUIDsForDeletion = [String]()

    
    init(month: Month, category: Category? = nil) {
        self.month = month
        if let category = category {
            self.category = category
            checkIfFavorite()
            self.items = category.items?.allObjects as? [Item]
        }
    }
    
    
    func createNewItem() {
        let newItem = NSEntityDescription.insertNewObject(forEntityName: "Item", into: context) as! Item
        newItem.category = category
        newItem.month = month
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
            let favoriteCategory = NSEntityDescription.insertNewObject(forEntityName: "Favorite", into: context) as! Favorite
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
        guard context.hasChanges else { print("WTF"); return }
        if reminderUIDsForDeletion.count > 0 {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: reminderUIDsForDeletion)
        }
        try context.save()
    }
    
    func cancel() {
        context.rollback()
    }
    
    func deleteItem(item: Item, at indexPath: IndexPath) {
        if let reminderUID = item.reminderUID {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderUID])
        }
        context.delete(item)
        items?.remove(at: indexPath.row)
    }
    
    func updateItemRecurrence(for item: Item, with newRecurrence: ItemRecurrence, sisterItems: [Item]? = nil) {
        item.recurringNum = NSNumber(value: newRecurrence.period)
        item.recurringUnit = NSNumber(value: newRecurrence.unit.rawValue)
        item.recurringEndDate = newRecurrence.endDate
        
        switch (item.reminderTime, newRecurrence.reminderTime) {
        case (nil, nil):
            break
        case (.some(_), nil):
            item.reminderTime = nil
            item.reminderUID = nil
        case (nil, .some(_)):
            item.reminderTime = NSNumber(value: newRecurrence.reminderTime!)
        case (.some(_), .some(_)):
            if let itemReminderTime = item.reminderTime, let itemRecurrenceTime = newRecurrence.reminderTime, Int(truncating: itemReminderTime) != itemRecurrenceTime {
                item.reminderTime = NSNumber(value: itemRecurrenceTime)
            }
        }
      
        if let futureSisterItems = sisterItems?.filter({ $0.date! > item.date! }) {
            futureSisterItems.forEach({
                if let reminderUID = $0.reminderUID {
                    reminderUIDsForDeletion.append(reminderUID)
                }
                context.delete($0)
            })
            guard var itemDate = item.date else { return }
            var items = [item]
            var dateComponent = DateComponents()
            switch newRecurrence.unit {
            case .day: dateComponent.day = newRecurrence.period
            case .month: dateComponent.month = newRecurrence.period
            case .week: dateComponent.weekOfYear = newRecurrence.period
            }
            
            repeat {
                itemDate = Calendar.current.date(byAdding: dateComponent, to: itemDate)!
                let itemStruct = ItemStruct.itemStruct(from: item)
                let newItem = InitialViewModel.shared.createNewItem(date: itemDate, itemStruct: itemStruct, save: false)
                items.append(newItem)
            } while Calendar.current.date(byAdding: dateComponent, to: itemDate)! <= newRecurrence.endDate
            
            for item in items {
                item.sisterItems = NSSet(array: items.filter({ $0 != item }))
            }
        }
    }
    
    
    func reloadData() {
        self.items = category?.items?.allObjects as? [Item]
    }
    
    func moveItem(item: Item, to categoryName: String, sisterItems: [Item]?) {
        guard let categories = month.categories?.allObjects as? [Category] else { return }
        guard let newCategory = categories.filter({ $0.name == categoryName }).first else { return }
        item.category = newCategory
        reloadData()
        if let sisterItems = sisterItems {
            sisterItems.forEach({
                if let categoryName = newCategory.name, let itemMonthString = $0.month?.date {
                    $0.category = InitialViewModel.shared.checkCategory(categoryName: categoryName, monthString: itemMonthString)
                }
            })
        }
    }
    
}
