//
//  DADiskManager.swift
//  SDisk
//
//  Created by Mayank Kumar on 1/19/19.
//  Copyright © 2019 Mayank Kumar. All rights reserved.
//

import Foundation

import DiskArbitration
import CoreData
import Cocoa

/// Manages disk operations and sessions.
class DADiskManager {
    
    /// Holds singleton `DASession`.
    private let session: DASession?

    /// Singleton instance.
    static let shared = DADiskManager()
    
    /// Holds list of available disks.
    var currentDisks = [AbstractDisk]()
    
    /// Holds list of configured disks.
    var configuredDisks = [Disk]()
    
    /// Initializes a disk arbitration session and prepares disk approval callbacks.
    init() {
        session = DASessionCreate(kCFAllocatorDefault)
        guard let registeredSession = session else { return }
        DARegisterDiskUnmountApprovalCallback(registeredSession, kDADiskDescriptionMatchVolumeMountable.takeUnretainedValue(), diskDidUnmount, nil)
        DARegisterDiskMountApprovalCallback(registeredSession, kDADiskDescriptionMatchVolumeMountable.takeUnretainedValue(), diskDidMount, nil)
        DARegisterDiskDescriptionChangedCallback(registeredSession, kDADiskDescriptionMatchVolumeMountable.takeUnretainedValue(), nil, diskDidChange, nil)
        DASessionScheduleWithRunLoop(registeredSession, RunLoop.main.getCFRunLoop(), RunLoop.Mode.default as CFString)
    }
    
    deinit {
        guard let registeredSession = session else { return }
        DASessionUnscheduleFromRunLoop(registeredSession, RunLoop.main.getCFRunLoop(), RunLoop.Mode.default as CFString)
    }
        
    /// Fetches all available external disks.
    func fetchExternalDisks(completion: ((Bool) -> Void)? = nil) {
        var success = true
        currentDisks.removeAll()
        let volumes = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: [.volumeNameKey, .volumeAvailableCapacityKey, .volumeTotalCapacityKey, .volumeUUIDStringKey, .volumeIsInternalKey], options: [.skipHiddenVolumes])
        guard let allVolumes = volumes else { return }
        for volume in allVolumes {
            do {
                let volumeProperties = try volume.resourceValues(forKeys: [.volumeNameKey, .volumeAvailableCapacityKey, .volumeTotalCapacityKey, .volumeUUIDStringKey, .volumeIsInternalKey])
                guard let volumeIsInternal = volumeProperties.volumeIsInternal, !volumeIsInternal else { continue }
                guard let volumeName = volumeProperties.volumeName,
                let volumeID = volumeProperties.volumeUUIDString,
                let volumeTotalCapacity = volumeProperties.volumeTotalCapacity,
                let volumeAvailableCapacity = volumeProperties.volumeAvailableCapacity else {
                    success = false
                    continue
                }
                let disk = AbstractDisk()
                disk.name = volumeName
                disk.volumeID = UUID(uuidString: volumeID)
                disk.totalCapacity = Double(volumeTotalCapacity) / 10E8
                disk.availableCapacity = Double(volumeAvailableCapacity) / 10E8
                disk.icon = volume.path
                currentDisks.append(disk)
            } catch {
                success = false
                continue
            }
        }
        guard let handler = completion else { return }
        handler(success)
    }
    
    /// Retrieves configured disks.
    func fetchConfiguredDisks() {
        let fetchRequest = NSFetchRequest<Disk>(entityName: "Disk")
        do {
            configuredDisks = try CDS.persistentContainer.viewContext.fetch(fetchRequest)
            MenuManager.shared.update(withStatus: "Volumes Configured: \(self.configuredDisks.count == 0 ? "None" : "\(self.configuredDisks.count)")")
        } catch {
            print("Disk fetch failed")
        }
    }
    
    /// Remove specified disk.
    ///
    /// - Parameter disk: `Disk` to remove.
    func removeConfiguredDisk(_ disk: Disk) {
        guard let index = configuredDisks.index(of: disk) else { return }
        CDS.persistentContainer.viewContext.delete(configuredDisks[index])
        CDS.saveContext {
            self.configuredDisks.remove(at: index)
            MenuManager.shared.update(withStatus: "Volumes Configured: \(self.configuredDisks.count == 0 ? "None" : "\(self.configuredDisks.count)")")
        }
    }
    
    /// Removes all configured disks.
    func removeAllConfiguredDisks() {
        for disk in configuredDisks {
            CDS.persistentContainer.viewContext.delete(disk)
        }
        CDS.saveContext {
            self.configuredDisks.removeAll()
            MenuManager.shared.update(withStatus: "Volumes Configured: None")
        }
    }
    
    /// Retrieves the disk `UUID`.
    ///
    /// - Parameter disk: The `DADisk` object.
    /// - Returns: Disk UUID.
    private func getUUID(forDisk disk: DADisk) -> UUID? {
        guard let diskInfo = DADiskCopyDescription(disk) else { return nil }
        let data = diskInfo as NSDictionary
        let volumeID = CFUUIDCreateString(kCFAllocatorDefault, (data["DAVolumeUUID"] as! CFUUID)) as String
        return UUID(uuidString: volumeID)
    }
    
    /// Handle disk unmounts.
    var diskDidUnmount: DADiskUnmountApprovalCallback = { disk, _ in
        DADiskManager.shared.performTask(withDisk: disk, withTaskType: .onUnmount)
        return nil
    }
    
    /// Handle disk mounting.
    var diskDidMount: DADiskMountApprovalCallback = { disk, _ in
        DADiskManager.shared.performTask(withDisk: disk, withTaskType: .onMount)
        return nil
    }
    
    /// Handles changes to disk information.
    var diskDidChange: DADiskDescriptionChangedCallback = { disk, _, _ in
        for aDisk in DADiskManager.shared.configuredDisks { aDisk.updateFrom(arbDisk: disk) }
    }
    
    /// Generic disk task wrapper.
    ///
    /// - Parameter type: The type of task to perform.
    private func performTask(withDisk disk: DADisk, withTaskType type: TaskType) {
        guard let diskUUID = DADiskManager.shared.getUUID(forDisk: disk) else { return }
        SDTaskManager.shared.performTasks(forDiskUUID: diskUUID, withTaskType: type, handler: SDTaskManager.shared.executeUIHandler)
    }
    
}
