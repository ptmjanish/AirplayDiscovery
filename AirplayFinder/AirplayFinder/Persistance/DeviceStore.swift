//
//  DeviceStore.swift
//  AirplayFinder
//
//  Created by Mohammed Janish on 22/01/26.
//

import Foundation
import CoreData

final class DeviceStore {
    
    private let stack: CoreDataStack
    
    init(stack: CoreDataStack = .shared) {
        self.stack = stack
    }
    
    func fetchAll() -> [DeviceEntity] {
        let request: NSFetchRequest<DeviceEntity> = DeviceEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        do {
            return try stack.context.fetch(request)
        }
        catch {
            print("Fetch failed: \(error)")
            return []
        }
    }
    
    
    func upsert(name: String, ipAddress: String, isReachable: Bool, lastSeen: Date? = nil) {
        let request: NSFetchRequest<DeviceEntity> = DeviceEntity.fetchRequest()
        request.predicate = NSPredicate(format: "ipAddress == %@", ipAddress)
        request.fetchLimit = 1
        
        let existing = (try? stack.context.fetch(request))?.first
        let device = existing ?? DeviceEntity(context: stack.context)
        
        device.name = name
        device.ipAddress = ipAddress
        device.isReachable = isReachable
        device.lastSeen = lastSeen
        
        stack.saveContext()
    }
    
    func deleteAll() {
        let request: NSFetchRequest<NSFetchRequestResult> = DeviceEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try stack.persistentContainer.persistentStoreCoordinator.execute(deleteRequest, with: stack.context)
        }
        catch {
            print("Delete failed: \(error)")
        }
    }
}

