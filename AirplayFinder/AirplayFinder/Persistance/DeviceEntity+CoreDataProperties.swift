//
//  DeviceEntity+CoreDataProperties.swift
//  AirplayFinder
//
//  Created by Mohammed Janish on 22/01/26.
//
//

public import Foundation
public import CoreData


public typealias DeviceEntityCoreDataPropertiesSet = NSSet

extension DeviceEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DeviceEntity> {
        return NSFetchRequest<DeviceEntity>(entityName: "DeviceEntity")
    }

    @NSManaged public var name: String?
    @NSManaged public var ipAddress: String?
    @NSManaged public var isReachable: Bool
    @NSManaged public var lastSeen: Date?

}

extension DeviceEntity : Identifiable {

}
