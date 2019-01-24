//
//  Disk.swift
//  SDisk
//
//  Created by Mayank Kumar on 1/19/19.
//  Copyright © 2019 Mayank Kumar. All rights reserved.
//

import Foundation
import DiskArbitration
import Cocoa

/// Defines an external disk.
class AbstractDisk: CustomStringConvertible {
    
    /// Disk name.
    var name: String! = nil
    
    /// Disk UUID.
    var volumeID: UUID! = nil
    
    /// Available space on disk in `GB`.
    var availableCapacity: Double! = nil
    
    /// Total capacity of disk in `GB`.
    var totalCapacity: Double! = nil
    
    /// Disk icon.
    var icon: Data! = nil
    
    var description: String {
        return "(Disk Name: \(String(describing: name!)), Disk ID: \(String(describing: volumeID!)), Space Available: \(String(describing: availableCapacity!)), Total Capacity: \(String(describing: totalCapacity!)))"
    }
    
    /// Converts an abstract disk to a saved, configurable disk.
    func addAsConfigurableDisk() -> Disk {
        let configuredDisk = Disk(context: CDS.persistentContainer.viewContext)
        configuredDisk.availableCapacity = availableCapacity
        configuredDisk.uniqueID = volumeID
        configuredDisk.totalCapacity = totalCapacity
        configuredDisk.name = name
        configuredDisk.icon = icon
        CDS.saveContext()
        return configuredDisk
    }
}

extension Disk {
    
    /// Updates configured disk values from provided `DADisk`, as long as current object is initialized and has same UUID.
    ///
    /// - Parameter disk: A `DADisk`.
    func updateFrom(arbDisk disk: DADisk) {
        guard let diskInfo = DADiskCopyDescription(disk) else { return }
        let data = diskInfo as NSDictionary
        guard let volumeUUID = CFUUIDCreateString(kCFAllocatorDefault, (data[kDADiskDescriptionVolumeUUIDKey] as! CFUUID)) as String? else { return }
        let arbDiskUUID = UUID(uuidString: volumeUUID)
        guard let volumeID = uniqueID else { return }
        if arbDiskUUID != volumeID { return }
        name = data[kDADiskDescriptionVolumeNameKey] as? String
        totalCapacity = (data[kDADiskDescriptionMediaSizeKey] as! Double) / 10E8
        let path = data[kDADiskDescriptionVolumePathKey] as! String
        icon = NSWorkspace.shared.icon(forFile: path).tiffRepresentation
    }
    
}
