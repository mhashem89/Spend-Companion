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
        return CoreDataManager.shared.context
    }
    
    var month: Month!
    weak var delegate: MonthViewModelDelegate?
    var fixedCategories = [String: Category]()
    var otherExpenses = [Category]()
    
    init(monthString: String) {
        super.init()
        
        // Fetch the month and load it into the "month" variable, if not found then it creates a new "Month" entity
        self.month = CoreDataManager.shared.checkMonth(monthString: monthString, createNew: true)
        do {
            try CoreDataManager.shared.saveContext()
        } catch let err {
            delegate?.presentError(error: err)
        }
    }
    
    func fetchData() {
        guard let categories = month.categories?.allObjects as? [Category] else { return }
        fixedCategories = [String: Category]()
        
        // Filter the income category
        fixedCategories[ItemType.income.description] = categories.filter({
            guard let name = $0.name else { return false }
            return name == ItemType.income.description
        }).first
        
        // Filter the expenses and sort them by name
        otherExpenses = categories
            .filter({
                guard let name = $0.name else { return false }
                return name != ItemType.income.description
            })
            .sorted(by: {
                guard let name0 = $0.name, let name1 = $1.name else { return false }
                return name0 < name1
            })
    }
    
    /// Adds a new category and save the context
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
    
    /// Deletes the category and all associated items
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
