//
//  ChartViewModel.swift
//  Spending App
//
//  Created by Mohamed Hashem on 10/2/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit
import CoreData

class ChartViewModel {
    
    
    var context: NSManagedObjectContext {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }
    
    var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    
    static let shared = ChartViewModel()
    
    
    func calcMaxInYear(year: String, forIncome income: Bool = false) -> Double? {
        var totals = [Double]()
        for month in months {
            let monthString = "\(month) \(year)"
            if let totalValue = CoreDataManager.shared.calcCategoryTotalForMonth(monthString, for: income ? "Income" : nil) {
                totals.append(totalValue)
            }
        }
        return totals.max()
    }
    
    func fetchUniqueCategoryNames(for year: String?) -> [String] {
        var names = [String]()
        let fetchRequest = NSFetchRequest<Category>(entityName: "Category")
        if year != nil { fetchRequest.predicate = NSPredicate(format: "month.year = %@", year!) }
        if let categories = try? context.fetch(fetchRequest) {
            for category in categories.filter({ $0.name != "Income" }) {
                if let name = category.name {
                    names.append(name)
                }
            }
        }
        return names.unique()
    }
    
    func fetchCategoryTotals(for year: String, forMonth month: String? = nil) -> [String: Double] {
        var dict = [String: Double]()
        
        let categoryNames = fetchUniqueCategoryNames(for: year)
        for name in categoryNames {
            var total: Double = 0
            let fetchRequest = NSFetchRequest<Category>(entityName: "Category")
            if let month = month {
                let monthYear = "\(month) \(year)"
                fetchRequest.predicate = NSPredicate(format: "name = %@ AND month.date = %@", name, monthYear)
            } else {
                fetchRequest.predicate = NSPredicate(format: "name = %@ AND month.year = %@", name, year)
            }
            if let fetchedCategories = try? context.fetch(fetchRequest) {
                for category in fetchedCategories.filter({ $0.name != "Income" }) {
                    for item in category.items?.allObjects as! [Item] {
                        total += item.amount
                    }
                }
            }
            dict[name] = (total * 100).rounded() / 100
        }
        return dict
    }
    
}



