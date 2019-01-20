//
//  Disk.swift
//  SDisk
//
//  Created by Mayank Kumar on 1/19/19.
//  Copyright © 2019 Mayank Kumar. All rights reserved.
//

import Foundation
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
    var icon: String! = nil
    
    var configuredDisk: Disk! = nil
    
    var description: String {
        return "(Disk Name: \(String(describing: name!)), Disk ID: \(String(describing: volumeID!)), Space Available: \(String(describing: availableCapacity!)), Total Capacity: \(String(describing: totalCapacity!)))"
    }
    
    func addAsConfigurableDisk() {
        configuredDisk = Disk(context: CDS.persistentContainer.viewContext)
        configuredDisk.availableCapacity = availableCapacity
        configuredDisk.uniqueID = volumeID
        configuredDisk.totalCapacity = totalCapacity
        configuredDisk.name = name
        configuredDisk.icon = icon
        CDS.saveContext()
    }
    
}
