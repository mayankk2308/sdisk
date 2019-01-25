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
    var currentDisks = [DADisk]()
    
    /// Holds list of configured disks.
    var configuredDisks = [Disk]()
    
    /// Maintains track of the number of disks to unmount.
    var totalDisksToUnmount = 0
    
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
        guard let registeredSession = session else { return }
        let volumes = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: [.volumeNameKey, .volumeAvailableCapacityKey, .volumeTotalCapacityKey, .volumeUUIDStringKey, .volumeIsInternalKey], options: [.skipHiddenVolumes])
        guard let allVolumes = volumes else { return }
        currentDisks.removeAll()
        for volume in allVolumes {
//                let volumeProperties = try volume.resourceValues(forKeys: [.volumeNameKey, .volumeAvailableCapacityKey, .volumeTotalCapacityKey, .volumeUUIDStringKey, .volumeIsInternalKey])
//                guard let volumeIsInternal = volumeProperties.volumeIsInternal, !volumeIsInternal else { continue }
//                guard let volumeName = volumeProperties.volumeName,
//                let volumeID = volumeProperties.volumeUUIDString,
//                let volumeTotalCapacity = volumeProperties.volumeTotalCapacity,
//                let volumeAvailableCapacity = volumeProperties.volumeAvailableCapacity else {
//                    success = false
//                    continue
//                }
            guard let disk = DADiskCreateFromVolumePath(kCFAllocatorDefault, registeredSession, volume as CFURL) else {
                success = false
                continue
            }
            currentDisks.append(disk)
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
    
    /// Handle disk unmounts.
    var diskDidUnmount: DADiskUnmountApprovalCallback = { disk, _ in
        DADiskManager.shared.performTask(withDisk: disk, withTaskType: .onUnmount)
        if !MenuManager.shared.preferencesViewController.updateQueued {
            MenuManager.shared.preferencesViewController.updateDisks()
        }
        return nil
    }
    
    /// Handle disk mounting.
    var diskDidMount: DADiskMountApprovalCallback = { disk, _ in
        DADiskManager.shared.performTask(withDisk: disk, withTaskType: .onMount)
        if !MenuManager.shared.preferencesViewController.updateQueued {
            MenuManager.shared.preferencesViewController.updateDisks()
        }
        return nil
    }
    
    /// Handles changes to disk information.
    var diskDidChange: DADiskDescriptionChangedCallback = { disk, _, _ in
        for aDisk in DADiskManager.shared.configuredDisks { aDisk.updateFrom(arbDisk: disk) }
    }
    
    /// Called after a disk successfully unmounts.
    var diskUnmountDone: DADiskUnmountCallback = { disk, _, _ in
        DADiskManager.shared.totalDisksToUnmount -= 1
        DispatchQueue.main.async {
            if DADiskManager.shared.totalDisksToUnmount == 0 {
                if !MenuManager.shared.preferencesViewController.updateQueued {
                    MenuManager.shared.preferencesViewController.refreshAllDisks(DADiskManager.shared)
                }
                MenuManager.shared.ejectAllDisksItem.title = "Eject All Disks"
                MenuManager.shared.ejectAllDisksItem.action = #selector(DADiskManager.shared.unmountAllDisks(_:))
            }
        }
    }
    
    /// Unmount all disks.
    ///
    /// - Parameter task: Runs designated task after all disks have been unmounted.
    @objc func unmountAllDisks(_ sender: Any) {
        MenuManager.shared.ejectAllDisksItem.title = "Ejecting..."
        MenuManager.shared.ejectAllDisksItem.action = nil
        MenuManager.shared.preferencesViewController.toggleUpdateMode()
        DispatchQueue.global(qos: .userInitiated).async {
            self.fetchExternalDisks()
            self.totalDisksToUnmount = self.currentDisks.count
            if self.totalDisksToUnmount == 0 {
                DispatchQueue.main.async {
                    MenuManager.shared.ejectAllDisksItem.title = "Eject All Disks"
                    MenuManager.shared.ejectAllDisksItem.action = #selector(DADiskManager.shared.unmountAllDisks(_:))
                    MenuManager.shared.preferencesViewController.toggleUpdateMode(enableItems: true)
                }
                return
            }
            for disk in self.currentDisks {
                DADiskUnmount(disk, DADiskUnmountOptions(kDADiskUnmountOptionDefault), self.diskUnmountDone, nil)
            }
        }
    }
    
    /// Generic disk task wrapper.
    ///
    /// - Parameter type: The type of task to perform.
    private func performTask(withDisk disk: DADisk, withTaskType type: TaskType) {
        guard let diskData = disk.diskData(),
            let diskUUID = disk.uniqueID(withDiskData: diskData) else { return }
        SDTaskManager.shared.performTasks(forDiskUUID: diskUUID, withTaskType: type, handler: SDTaskManager.shared.executeUIHandler)
    }
    
}
