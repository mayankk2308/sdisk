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
class AbstractDisk {
    
    /// Disk name.
    var name: String! = nil
    
    /// Disk UUID.
    var volumeID: String! = nil
    
    /// Available space on disk in `GB`.
    var availableCapacity: Int! = nil
    
    /// Total capacity of disk in `GB`.
    var totalCapacity: Int! = nil
    
    /// Disk icon.
    var icon: NSImage! = nil
    
}
