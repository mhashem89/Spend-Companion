//
//  CalendarViewModel.swift
//  Spending App
//
//  Created by Mohamed Hashem on 9/30/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import Foundation
import UIKit
import CoreData


class CalendarViewModel {
    
    var context: NSManagedObjectContext {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }
    
    static let shared = CalendarViewModel()
    
    func calcCategoryTotal(category: Category) -> Double {
        var total: Double = 0
        if let items = category.items?.allObjects as? [Item] {
            for item in items {
                total += item.amount
            }
        }
        return (total * 100).rounded() / 100
    }
    
    func calcMonthTotal(_ monthString: String, for categoryName: String? = nil) -> Double? {
        var total: Double = 0
        let fetchRequest = NSFetchRequest<Month>(entityName: "Month")
        fetchRequest.predicate = NSPredicate(format: "date = %@", monthString)
        if let fetchedMonth = try? context.fetch(fetchRequest).first {
            if let categories = fetchedMonth.categories?.allObjects as? [Category] {
                if categoryName == nil {
                    for category in categories.filter({ $0.name != "Income" }) {
                        let categoryTotal = calcCategoryTotal(category: category)
                        total += categoryTotal
                    }
                } else {
                    if let foundCategory = categories.filter({ $0.name == categoryName }).first {
                        let categoryTotal = calcCategoryTotal(category: foundCategory)
                        total += categoryTotal
                    }
                }
            }
        }
        if total > 0 {
            return (total * 100).rounded() / 100
        } else {
            return nil
        }
    }
    
    
    func fetchFavorites() -> [String] {
        let fetchRequest = NSFetchRequest<Favorite>(entityName: "Favorite")
        if let favorites = try? context.fetch(fetchRequest) {
            return favorites.map({ $0.name! })
        } else {
            return [String]()
        }
    }
    
    
}
