//
//  DiskExtensions.swift
//  SDisk
//
//  Created by Mayank Kumar on 1/19/19.
//  Copyright © 2019 Mayank Kumar. All rights reserved.
//

import Foundation
import DiskArbitration
import Cocoa

extension DADisk {
    
    /// Retrieves disk information dictionary for the disk.
    ///
    /// - Returns: Information dictionary.
    func diskData() -> NSDictionary? {
        guard let data = DADiskCopyDescription(self) else { return nil }
        return data as NSDictionary
    }
    
    /// Computes disk name from given `DADisk` description.
    ///
    /// - Parameter data: Retrieved `DADisk` data.
    /// - Returns: Disk name.
    func name(withDiskData data: NSDictionary) -> String? {
        guard let diskName = data[kDADiskDescriptionVolumeNameKey] as? String else { return nil }
        return diskName
    }
    
    /// Computes disk UUID from given `DADisk` description.
    ///
    /// - Parameter data: Retrieved `DADisk` data.
    /// - Returns: Disk UUID.
    func uniqueID(withDiskData data: NSDictionary) -> UUID? {
        guard let diskUUIDData = data[kDADiskDescriptionVolumeUUIDKey] else { return nil }
        let diskCFUUID = diskUUIDData as! CFUUID
        guard let diskCFUUIDString = CFUUIDCreateString(kCFAllocatorDefault, diskCFUUID) as String?,
        let diskUUID = UUID(uuidString: diskCFUUIDString) else { return nil }
        return diskUUID
    }
    
    /// Retrieves disk icon from given `DADisk` description.
    ///
    /// - Parameter data: Retrieved `DADisk` data.
    /// - Returns: Disk image as `Data`.
    func icon(withDiskData data: NSDictionary) -> Data? {
        guard let diskPath = data[kDADiskDescriptionVolumePathKey] as? URL else { return nil }
        return NSWorkspace.shared.icon(forFile: diskPath.path).tiffRepresentation
    }
    
    /// Retrieves given disk data's available and total capacity.
    ///
    /// - Parameter data: Retrieved `DADisk` data.
    /// - Returns: Available and total capacity.
    func capacity(withDiskData data: NSDictionary) -> (available: Double, total: Double)? {
        guard let volumePathData = data[kDADiskDescriptionVolumePathKey] else { return nil }
        guard let volumePath = volumePathData as? URL else { return nil }
        do {
            let results = try volumePath.resourceValues(forKeys: [.volumeAvailableCapacityKey, .volumeTotalCapacityKey])
            guard let availableCapacity = results.volumeAvailableCapacity else { return nil }
            guard let totalCapacity = results.volumeTotalCapacity else { return nil }
            return (Double(availableCapacity), Double(totalCapacity))
        } catch { return nil }
    }
    
    /// Adds `DADisk` as configurable `Disk` to current CoreData context.
    ///
    /// - Returns: Added object.
    func addAsConfigurableDisk(withDiskData data: NSDictionary) -> Disk? {
        guard let capacityData = capacity(withDiskData: data),
            let diskName = name(withDiskData: data),
            let diskUUID = uniqueID(withDiskData: data),
            let image = icon(withDiskData: data) else { return nil }
        let configuredDisk = Disk(context: CDS.persistentContainer.viewContext)
        configuredDisk.availableCapacity = capacityData.available
        configuredDisk.totalCapacity = capacityData.total
        configuredDisk.uniqueID = diskUUID
        configuredDisk.name = diskName
        configuredDisk.icon = image
        CDS.saveContext()
        DADiskManager.shared.diskMap[self] = configuredDisk
        return configuredDisk
    }
    
}

extension Disk {
    
    static func == (lhs: DADisk, rhs: Disk) -> Bool {
        guard let data = lhs.diskData() else { return false }
        return rhs.uniqueID == lhs.uniqueID(withDiskData: data)
    }
    
    /// Updates configured disk values from provided `DADisk`, as long as current object is initialized and has same UUID.
    ///
    /// - Parameter disk: A `DADisk`.
    func updateFrom(arbDisk disk: DADisk) {
        guard let diskInfo = DADiskCopyDescription(disk) else { return }
        let data = diskInfo as NSDictionary
        guard let capacityData = disk.capacity(withDiskData: data),
            let diskName = disk.name(withDiskData: data),
            let diskUUID = disk.uniqueID(withDiskData: data),
            let image = disk.icon(withDiskData: data) else { return }
        name = diskName
        uniqueID = diskUUID
        icon = image
        availableCapacity = capacityData.available
        totalCapacity = capacityData.total
        DADiskManager.shared.diskMap[disk] = self
    }
    
    var mounted: Bool {
        return DADiskManager.shared.diskMap[self] != nil
    }
    
}

/// Avails access to events such as disk mounting/unmounting for user interfaces.
protocol DADiskManagerDelegate {
    
    /// Notification for delegate after an unmount callback.
    func preDiskUnmount()
    
    /// Notification for delegate after an unmount callback.
    func postDiskUnmount(unmountedDisk disk: DADisk?)
    
    /// Notification for delegate after a disk mount.
    func postDiskMount(mountedDisk disk: DADisk)
    
    /// Notification for delegate after a disk description changes.
    func postDiskDescriptionChanged(changedDisk disk: DADisk?)
    
}

// MARK: - Defaults for the delegate.
extension DADiskManagerDelegate {
    
    func postDiskMount(mountedDisk disk: DADisk) {}
    
    func postDiskDescriptionChanged(changedDisk disk: DADisk?) {}
    
    func preDiskUnmount() {}
    
    func postDiskUnmount(unmountedDisk disk: DADisk?) {}

}

extension CGFloat {
    
    init(_ bool: Bool) {
        self = bool ? 1.0 : 0.0
    }
    
}
