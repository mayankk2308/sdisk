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
    func addAsConfigurableDisk() {
        let configuredDisk = Disk(context: CDS.persistentContainer.viewContext)
        configuredDisk.updateFrom(arbDisk: self)
        DADiskManager.shared.configuredDisks.append(configuredDisk)
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
        DADiskManager.shared.diskMap[self] = disk
        CDS.saveContext()
    }
    
    /// Mount state of the disk.
    var mounted: Bool {
        return DADiskManager.shared.diskMap[self] != nil
    }
    
}

/// Avails access to events such as disk mounting/unmounting for user interfaces.
protocol DADiskManagerDelegate {
    
    /// Notification for delegate after an unmount callback.
    func preDiskUnmount()
    
    /// Notification for delegate after an unmount callback
    ///
    /// - Parameter disk: Unmounted disk.
    func postDiskUnmount(unmountedDisk disk: DADisk?)
    
    /// Notification for delegate after a disk mount.
    ///
    /// - Parameter disk: Mounted disk.
    func postDiskMount(mountedDisk disk: DADisk)
    
    /// Notification for delegate after a disk description changes.
    ///
    /// - Parameter disk: Changed disk.
    func postDiskDescriptionChanged(changedDisk disk: DADisk?)
    
    /// Notification for delegate after a disk disappears.
    ///
    /// - Parameter disk: Disappearing disk.
    func postDiskDisappearence(disappearedDisk disk: DADisk)
    
}

// MARK: - Defaults for the delegate, making requirements optional.
extension DADiskManagerDelegate {
    
    func postDiskMount(mountedDisk disk: DADisk) { return }
    
    func postDiskDescriptionChanged(changedDisk disk: DADisk?) { return }
    
    func preDiskUnmount() { return }
    
    func postDiskUnmount(unmountedDisk disk: DADisk?) { return }
    
    func postDiskDisappearence(disappearedDisk disk: DADisk) { return }

}

// MARK: - Convenience conversions for CGFloat values.
extension CGFloat {
    
    init(_ bool: Bool) {
        self = bool ? 1.0 : 0.0
    }
    
}
