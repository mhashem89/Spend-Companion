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
    
    lazy var dataFetcher: NSFetchedResultsController<Item> = {
        let fetchRequest = NSFetchRequest<Item>(entityName: "Item")
        fetchRequest.predicate = NSPredicate(format: "category = %@", category!)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest,
                                             managedObjectContext: context,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        return frc
    }()
    
    init(month: Month, category: Category? = nil) {
        self.month = month
        if let category = category {
            self.category = category
            checkIfFavorite()
            self.items = category.items?.allObjects as? [Item]
        }
    }
    
    func createNewCategory(name: String) {
        let newCategory = NSEntityDescription.insertNewObject(forEntityName: "Category", into: context) as! Category
        newCategory.month = month
        newCategory.name = name
        self.category = newCategory
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
    
    func updateItemRecurrence(for item: Item, with itemRecurrence: ItemRecurrence, sisterItems: [Item]? = nil) {
        item.recurringNum = NSNumber(value: itemRecurrence.period)
        item.recurringUnit = NSNumber(value: itemRecurrence.unit.rawValue)
        item.recurringEndDate = itemRecurrence.endDate
        
        switch (item.reminderTime, itemRecurrence.reminderTime) {
        case (nil, nil):
            break
        case (.some(_), nil):
            item.reminderTime = nil
            item.reminderUID = nil
        case (nil, .some(_)):
            item.reminderTime = NSNumber(value: itemRecurrence.reminderTime!)
        case (.some(_), .some(_)):
            if let itemReminderTime = item.reminderTime, let itemRecurrenceTime = itemRecurrence.reminderTime, Int(truncating: itemReminderTime) != itemRecurrenceTime {
                item.reminderTime = NSNumber(value: itemRecurrenceTime)
            }
        }
      
        if let sisterItems = sisterItems {
            sisterItems.forEach({
                if let reminderUID = $0.reminderUID {
                    reminderUIDsForDeletion.append(reminderUID)
                }
                context.delete($0)
            })
            guard var itemDate = item.date else { return }
            var items = [item]
            var dateComponent = DateComponents()
            switch itemRecurrence.unit {
            case .day: dateComponent.day = itemRecurrence.period
            case .month: dateComponent.month = itemRecurrence.period
            case .week: dateComponent.weekOfYear = itemRecurrence.period
            }
            
            repeat {
                itemDate = Calendar.current.date(byAdding: dateComponent, to: itemDate)!
                let newItem = InitialViewModel.shared.createNewItem(date: itemDate, description: item.detail ?? "", type: ItemType(rawValue: item.type)!, category: item.category?.name, amount: item.amount, itemRecurrence: itemRecurrence, save: false)
                items.append(newItem)
            } while Calendar.current.date(byAdding: dateComponent, to: itemDate)! <= itemRecurrence.endDate
            
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
