//
//  CoreDataStack.swift
//  AirplayFinder
//
//  Created by Mohammed Janish on 22/01/26.
//

import Foundation
import CoreData

final class CoreDataStack {
    
    static let shared = CoreDataStack()
    
    private init() {}
    
    private let modelName = "AppModel"
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: modelName)
        container.loadPersistentStores { _ , error in
            if let error = error {
                fatalError("Core data store failed to load: \(error)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    func saveContext() {
        let ctx = context
        guard ctx.hasChanges else { return }
        do {
            try ctx.save()
        }
        catch {
            ctx.rollback()
            assertionFailure("Core data save failed: \(error)")
        }
    }
}
