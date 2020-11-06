//
//  MonthViewModel.swift
//  Spending App
//
//  Created by Mohamed Hashem on 9/18/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit
import CoreData

protocol MonthViewModelDelegate: class {
    
    func presentError(error: Error)
    
}

class MonthViewModel: NSObject, NSFetchedResultsControllerDelegate {
   
    
    var context: NSManagedObjectContext {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }
    
    var month: Month!
    
    weak var delegate: MonthViewModelDelegate?
    
    var fixedCategories = [String: Category]()
    var otherExpenses = [Category]()
    

    lazy var dataFetcher: NSFetchedResultsController<Category> = {
        let fetchRequest = NSFetchRequest<Category>(entityName: "Category")
        fetchRequest.predicate = NSPredicate(format: "month = %@", month)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest,
                                             managedObjectContext: context,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        frc.delegate = self
        return frc
    }()
    
    init(monthString: String) {
        super.init()
        let fetchRequest = NSFetchRequest<Month>(entityName: "Month")
        fetchRequest.predicate = NSPredicate(format: "date = %@", monthString)
        if let fetchedMonth = try? context.fetch(fetchRequest).first {
            self.month = fetchedMonth
        } else {
            let newMonth = Month(context: context)
            newMonth.date = monthString
            if let year = monthString.split(separator: " ").last {
                newMonth.year = String(year)
            }
            self.month = newMonth
        }
    }
    
    func fetchData() {
        fixedCategories = [String: Category]()
        do {
            try dataFetcher.performFetch()
            if let fetchedObjects = dataFetcher.fetchedObjects {
                if let incomeCategory = fetchedObjects.filter({ $0.name == "Income" }).first {
                    self.fixedCategories["Income"] = incomeCategory
                }
                let otherExpenseCategories = fetchedObjects.filter({ $0.name != "Income" })
                self.otherExpenses = otherExpenseCategories
            }
        } catch let err {
            print("WTF", err.localizedDescription)
            delegate?.presentError(error: err)
        }
    }
    
    func addCategory(name: String) {
        let newCategory = Category(context: context)
        newCategory.name = name
        newCategory.month = month
        do {
            try context.save()
        } catch let err {
            print(err.localizedDescription)
            delegate?.presentError(error: err)
        }
    }
    
    func calcCategoryTotal(category: Category?) -> String {
        var total: Double = 0
        if let items = category?.items?.allObjects as? [Item] {
            for item in items {
                total += item.amount
            }
        }
        if total > 0 { total = (total * 100).rounded() / 100 }
        return String(format: "%g", total)
    }
    
    
    func deleteCategory(category: Category) {
        if let items = category.items?.allObjects as? [Item] {
            for item in items {
                if let reminderUID = item.reminderUID {
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderUID])
                }
                context.delete(item)
            }
        }
        context.delete(category)
        do {
            try context.save()
        } catch let err {
            print(err.localizedDescription)
            delegate?.presentError(error: err)
        }
    }
    
    
}
