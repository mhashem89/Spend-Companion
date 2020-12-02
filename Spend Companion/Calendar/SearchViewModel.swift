//
//  SearchViewModel.swift
//  Spending App
//
//  Created by Mohamed Hashem on 10/15/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit
import CoreData


class SearchViewModel {
    
    var context: NSManagedObjectContext {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }
    
    var searchResults = [Item]()
    
    func search(name: String) throws {
        let fetchRequest = NSFetchRequest<Item>(entityName: "Item")
        fetchRequest.predicate = NSPredicate(format: "detail BEGINSWITH[c] %@", name)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        searchResults = try context.fetch(fetchRequest)
    }
    
    func deleteItem(item: Item, at indexPath: IndexPath) throws {
        searchResults.remove(at: indexPath.row)
        try CoreDataManager.shared.deleteItem(item: item, saveContext: true)
    }
}

