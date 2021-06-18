//
//  Spend_CompanionTests.swift
//  Spend CompanionTests
//
//  Created by Mohamed Hashem on 10/18/20.
//

import XCTest
import CoreData
@testable import Spend_Companion

class Spend_CompanionTests: XCTestCase {

    private var managedObjectContext: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        managedObjectContext = coreDataContext(modelName: "Spend_Companion")
        let todayItem = Item(context: managedObjectContext)
        todayItem.date = Date()
        todayItem.recurringNum = 2
        let pastItem = Item(context: managedObjectContext)
        pastItem.date = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        let futureItem = Item(context: managedObjectContext)
        futureItem.date = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        let veryFutureItem = Item(context: managedObjectContext)
        veryFutureItem.date = Calendar.current.date(byAdding: .day, value: 2, to: Date())
        [pastItem, futureItem, veryFutureItem].forEach { todayItem.addToSisterItems($0) }
        
        XCTAssertNotNil(todayItem.futureItems())
        XCTAssertTrue(todayItem.futureItems()!.contains(futureItem))
        XCTAssertTrue(todayItem.futureItems()!.contains(veryFutureItem))
        XCTAssertFalse(todayItem.futureItems()!.contains(pastItem))
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        
        managedObjectContext = nil
    }
//
//    func testExample() throws {
//        // This is an example of a functional test case.
//        // Use XCTAssert and related functions to verify your tests produce the correct results.
//    }
//
//    func testPerformanceExample() throws {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}


extension XCTestCase {
    
    func coreDataContext(modelName: String) -> NSManagedObjectContext {
        let modelUrl = Bundle.main.url(forResource: modelName, withExtension: "momd")!
        let model = NSManagedObjectModel(contentsOf: modelUrl)!
        let persistentCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        try! persistentCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = persistentCoordinator
        return context
    }
}
