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
            do {
                try CoreDataManager.shared.saveContext()
            } catch let err {
                delegate?.presentError(error: err)
            }
        }
    }
    
    func fetchData() {
        guard let categories = month.categories?.allObjects as? [Category] else { return }
        fixedCategories = [String: Category]()
        fixedCategories["Income"] = categories.filter({
            guard let name = $0.name else { return false }
            return name == "Income"
        }).first
        otherExpenses = categories
            .filter({
                guard let name = $0.name else { return false }
                return name != "Income"
            })
            .sorted(by: {
                guard let name0 = $0.name, let name1 = $1.name else { return false }
                return name0 < name1
            })
    }
    
    func addCategory(name: String) {
        let newCategory = Category(context: context)
        newCategory.name = name
        newCategory.month = month
        do {
            try CoreDataManager.shared.saveContext()
        } catch let err {
            delegate?.presentError(error: err)
        }
    }
    
    func calcCategoryTotal(category: Category?) -> String {
        if let category = category {
            return String(format: "%g", CoreDataManager.shared.calcCategoryTotal(category: category))
        }
        return String(format: "%g", 0)
    }
    
    
    func deleteCategory(category: Category) {
        do {
            if let items = category.items?.allObjects as? [Item] {
                for item in items {
                    try CoreDataManager.shared.deleteItem(item: item, saveContext: true)
                }
            }
            context.delete(category)
            try CoreDataManager.shared.saveContext()
        } catch let err {
            delegate?.presentError(error: err)
        }
    }
    
    
    
    
}
