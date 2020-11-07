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
    
    static let shared = CalendarViewModel()
    
    func calcCategoryTotal(category: Category) -> Double {
        return CoreDataManager.shared.calcCategoryTotal(category: category)
    }
    
    func calcCategoryTotalForMonth(_ monthString: String, for categoryName: String? = nil) -> Double? {
        return CoreDataManager.shared.calcCategoryTotalForMonth(monthString, for: categoryName)
    }
    
    
    func fetchFavorites() -> [String] {
        return CoreDataManager.shared.fetchFavorites()
    }
    
    
}
