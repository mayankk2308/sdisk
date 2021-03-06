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
    var currentDisks = Set<DADisk>()
    
    /// Holds list of configured disks.
    var configuredDisks = [Disk]()
    
    /// Convenience map between `DADisk`s and `Disk` object(s).
    var diskMap = SuperMap<DADisk, Disk>()
    
    var filteredDisks: [DADisk] {
        var tempDisks = Set<DADisk>()
        for disk in currentDisks {
            if diskMap[disk] == nil { tempDisks.insert(disk) }
        }
        return Array(tempDisks)
    }
    
    /// Maintains track of the number of disks to unmount.
    var totalDisksToUnmount = 0
    
    /// Maintains update queue state.
    var updateQueued = false
    
    /// Holds all delegates.
    private var delegates = [DADiskManagerDelegate]()
    
    /// Maintains state of disk arbitration.
    var ejectMode = false
    
    var delegate: DADiskManagerDelegate? {
        willSet {
            if let value = newValue { delegates.append(value) }
        }
    }
    
    /// Initializes a disk arbitration session and prepares disk approval callbacks.
    init() {
        session = DASessionCreate(kCFAllocatorDefault)
        guard let registeredSession = session else { return }
        DARegisterDiskUnmountApprovalCallback(registeredSession, kDADiskDescriptionMatchVolumeMountable.takeUnretainedValue(), diskDidUnmount, nil)
        DARegisterDiskMountApprovalCallback(registeredSession, kDADiskDescriptionMatchVolumeMountable.takeUnretainedValue(), diskDidMount, nil)
        DARegisterDiskDescriptionChangedCallback(registeredSession, kDADiskDescriptionMatchVolumeMountable.takeUnretainedValue(), nil, diskDidChange, nil)
        DARegisterDiskDisappearedCallback(registeredSession, kDADiskDescriptionMatchVolumeMountable.takeUnretainedValue(), diskDidDisappear, nil)
        DASessionScheduleWithRunLoop(registeredSession, RunLoop.main.getCFRunLoop(), RunLoop.Mode.default as CFString)
    }
    
    deinit {
        guard let registeredSession = session else { return }
        DASessionUnscheduleFromRunLoop(registeredSession, RunLoop.main.getCFRunLoop(), RunLoop.Mode.default as CFString)
    }
    
    /// Handle disk unmounts.
    var diskDidUnmount: DADiskUnmountApprovalCallback = { disk, _ in
        DADiskManager.shared.performTask(withDisk: disk, withTaskType: .onUnmount)
        DADiskManager.shared.diskMap[disk] = nil
        if let index = DADiskManager.shared.currentDisks.firstIndex(of: disk) {
            DADiskManager.shared.currentDisks.remove(at: index)
        }
        if !DADiskManager.shared.updateQueued && !DADiskManager.shared.ejectMode {
            DADiskManager.shared.updateQueued = true
            for delegate in DADiskManager.shared.delegates { delegate.postDiskUnmount(unmountedDisk: disk) }
            DADiskManager.shared.updateQueued = false
        }
        return nil
    }
    
    /// Handle disk mounting.
    var diskDidMount: DADiskMountApprovalCallback = { disk, _ in
        DADiskManager.shared.performTask(withDisk: disk, withTaskType: .onMount)
        DADiskManager.shared.currentDisks.insert(disk)
        for cDisk in DADiskManager.shared.configuredDisks {
            if disk == cDisk {
                DADiskManager.shared.diskMap[disk] = cDisk
                break
            }
        }
        if !DADiskManager.shared.updateQueued && !DADiskManager.shared.ejectMode {
            DADiskManager.shared.updateQueued = true
            for delegate in DADiskManager.shared.delegates { delegate.postDiskMount(mountedDisk: disk) }
            DADiskManager.shared.updateQueued = false
        }
        return nil
    }
    
    /// Handles changes to disk information.
    var diskDidChange: DADiskDescriptionChangedCallback = { disk, _, _ in
        if DADiskManager.shared.currentDisks.contains(disk) {
            DADiskManager.shared.currentDisks.remove(disk)
            DADiskManager.shared.currentDisks.insert(disk)
        }
        if let cDisk = DADiskManager.shared.diskMap[disk] {
            cDisk.updateFrom(arbDisk: disk)
        }
        if !DADiskManager.shared.updateQueued && !DADiskManager.shared.ejectMode {
            DADiskManager.shared.updateQueued = true
            for delegate in DADiskManager.shared.delegates { delegate.postDiskDescriptionChanged(changedDisk: disk) }
            DADiskManager.shared.updateQueued = false
        }
    }
    
    /// Called after a disk successfully unmounts.
    var diskUnmountDone: DADiskUnmountCallback = { disk, _, _ in
        DADiskManager.shared.totalDisksToUnmount -= 1
        if DADiskManager.shared.ejectMode && DADiskManager.shared.totalDisksToUnmount == 0 {
            DADiskManager.shared.ejectMode = false
            for delegate in DADiskManager.shared.delegates { delegate.postDiskUnmount(unmountedDisk: disk) }
        }
    }
    
    /// Called after a whole disk is ejected or a disk suddenly disappears.
    var diskDidDisappear: DADiskDisappearedCallback = { disk, _ in
        for delegate in DADiskManager.shared.delegates { delegate.postDiskDisappearence(disappearedDisk: disk) }
    }
}

// MARK: - Manages disk fetching, configuration, and more.
extension DADiskManager {
    
    /// Removes all configured disks.
    func removeAllConfiguredDisks(doUITask task: @escaping () -> Void) {
        DispatchQueue.global(qos: .default).async {
            for disk in self.configuredDisks {
                CDS.persistentContainer.viewContext.delete(disk)
            }
            CDS.saveContext {
                self.configuredDisks.removeAll()
                self.diskMap = SuperMap<DADisk, Disk>()
                DispatchQueue.main.async {
                    task()
                }
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
    
    /// Retrieves configured disks.
    func fetchConfiguredDisks(onCompletion handler: ((Bool) -> Void)? = nil) {
        var success = true
        diskMap = SuperMap<DADisk, Disk>()
        DispatchQueue.global(qos: .default).async {
            let fetchRequest = NSFetchRequest<Disk>(entityName: "Disk")
            do {
                self.configuredDisks = try CDS.persistentContainer.viewContext.fetch(fetchRequest)
                DispatchQueue.main.async {
                    MenuManager.shared.update(withStatus: "Volumes Configured: \(self.configuredDisks.count == 0 ? "None" : "\(self.configuredDisks.count)")")
                }
                for savedDisk in self.configuredDisks {
                    for disk in self.currentDisks {
                        guard let data = disk.diskData(),
                            let uniqueID = disk.uniqueID(withDiskData: data),
                            let savedUniqueID = savedDisk.uniqueID, uniqueID == savedUniqueID else { continue }
                        self.diskMap[disk] = savedDisk
                    }
                }
            } catch {
                success = false
            }
            guard let call = handler else { return }
            call(success)
        }
    }
    
    /// Remove specified disk.
    ///
    /// - Parameter disk: `Disk` to remove.
    func removeConfiguredDisk(_ disk: Disk) {
        guard let index = configuredDisks.firstIndex(of: disk) else { return }
        CDS.persistentContainer.viewContext.delete(configuredDisks[index])
        CDS.saveContext {
            self.configuredDisks.remove(at: index)
            self.diskMap[disk] = nil
            DispatchQueue.main.async {
                MenuManager.shared.update(withStatus: "Volumes Configured: \(self.configuredDisks.count == 0 ? "None" : "\(self.configuredDisks.count)")")
            }
        }
    }
    
    /// Fetches all available external disks.
    func fetchExternalDisks(completion: ((Bool) -> Void)? = nil) {
        var success = true
        guard let registeredSession = session else { return }
        DispatchQueue.global(qos: .default).async {
            let volumes = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: [.volumeIsInternalKey], options: [.skipHiddenVolumes])
            guard let allVolumes = volumes else { return }
            self.currentDisks.removeAll()
            for volume in allVolumes {
                do {
                    let properties = try volume.resourceValues(forKeys: [.volumeIsInternalKey])
                    guard let volumeIsInternal = properties.volumeIsInternal, !volumeIsInternal else { continue }
                    guard let disk = DADiskCreateFromVolumePath(kCFAllocatorDefault, registeredSession, volume as CFURL) else {
                        success = false
                        continue
                    }
                    self.currentDisks.insert(disk)
                } catch {
                    success = false
                    continue
                }
            }
            guard let handler = completion else { return }
            handler(success)
        }
    }
    
    /// Unmount all disks.
    ///
    /// - Parameter task: Runs designated task after all disks have been unmounted.
    func unmountAllDisks() {
        ejectMode = true
        for del in delegates { del.preDiskUnmount() }
        fetchExternalDisks { success in
            if !success {
                self.ejectMode = false
                return
            }
            self.totalDisksToUnmount = self.currentDisks.count
            if self.totalDisksToUnmount == 0 {
                DispatchQueue.main.async {
                    for delegate in self.delegates { delegate.postDiskUnmount(unmountedDisk: nil) }
                }
                self.ejectMode = false
                return
            }
            for disk in self.currentDisks {
                DADiskUnmount(disk, DADiskUnmountOptions(kDADiskUnmountOptionForce), self.diskUnmountDone, nil)
            }
        }
    }
}

// MARK: - Handles basic disk data.
extension DADiskManager {
    
    /// Computes appropriate displayable disk size and unit.
    ///
    /// - Parameter capacity: Disk capacity in bytes.
    /// - Returns: Tuple of calculated displayable size and unit.
    private func diskSizeComputeHelper(_ capacity: Double) -> (Double, String) {
        var capacity = capacity, tierCount = 0
        let tiers = ["bytes", "KB", "MB", "GB", "TB", "PB"]
        while capacity > 999 {
            capacity /= 1000
            tierCount += 1
            if tierCount > tiers.count - 1 { break }
        }
        return (capacity, tiers[tierCount])
    }
    
    /// Computes a capacity string representation for given statistics.
    ///
    /// - Parameters:
    ///   - available: Amount of disk capacity remaining.
    ///   - total: Total disk capacity.
    ///   - p: Decimal precision.
    /// - Returns: Built capacity string.
    func capacityString(availableCapacity available: Double, totalCapacity total: Double, withPrecision p: Double! = 10) -> String? {
        let availableDiskCapacityStringData = diskSizeComputeHelper(available)
        let totalDiskCapacityStringData = diskSizeComputeHelper(total)
        return "\(round(availableDiskCapacityStringData.0 * p) / p)\(availableDiskCapacityStringData.1 == totalDiskCapacityStringData.1 ? " of " : " \(availableDiskCapacityStringData.1) of ")\(round(totalDiskCapacityStringData.0 * p) / p) \(totalDiskCapacityStringData.1) free"
    }
}
