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
    
    
    func search(name: String) {
        let fetchRequest = NSFetchRequest<Item>(entityName: "Item")
        fetchRequest.predicate = NSPredicate(format: "detail BEGINSWITH[c] %@", name)
        do {
            searchResults = try context.fetch(fetchRequest)
        } catch let err {
            print(err.localizedDescription)
        }
    
    }
    
    
    func deleteItem(item: Item, at indexPath: IndexPath) {
        if let reminuderUID = item.reminderUID {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminuderUID])
        }
        context.delete(item)
        searchResults.remove(at: indexPath.row)
        do {
            try context.save()
        } catch let err {
            print(err.localizedDescription)
        }
    }
    
    
}

