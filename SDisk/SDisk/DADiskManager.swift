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
    
    init() {
        session = DASessionCreate(kCFAllocatorDefault)
        guard let registeredSession = session else { return }
        DARegisterDiskUnmountApprovalCallback(registeredSession, kDADiskDescriptionMatchVolumeMountable.takeUnretainedValue(), diskDidUnmount, nil)
        DARegisterDiskMountApprovalCallback(registeredSession, kDADiskDescriptionMatchVolumeMountable.takeUnretainedValue(), diskDidMount, nil)
        DASessionScheduleWithRunLoop(registeredSession, RunLoop.main.getCFRunLoop(), RunLoop.Mode.default as CFString)
    }
    
    deinit {
        guard let registeredSession = session else { return }
        DASessionUnscheduleFromRunLoop(registeredSession, RunLoop.main.getCFRunLoop(), RunLoop.Mode.default as CFString)
    }
    
    /// Fetches all available external disks.
    func fetchExternalDisks() {
        let volumes = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: [.volumeNameKey, .volumeAvailableCapacityKey, .volumeTotalCapacityKey, .volumeUUIDStringKey, .volumeIsInternalKey], options: [.skipHiddenVolumes])
        guard let allVolumes = volumes else { return }
        for volume in allVolumes {
            do {
                let volumeProperties = try volume.resourceValues(forKeys: [.volumeNameKey, .volumeAvailableCapacityKey, .volumeTotalCapacityKey, .volumeUUIDStringKey, .volumeIsInternalKey])
                guard let volumeIsInternal = volumeProperties.volumeIsInternal, !volumeIsInternal else { continue }
                guard let volumeName = volumeProperties.volumeName else { continue }
                guard let volumeID = volumeProperties.volumeUUIDString else { continue }
                guard let volumeTotalCapacity = volumeProperties.volumeTotalCapacity else { continue }
                guard let volumeAvailableCapacity = volumeProperties.volumeAvailableCapacity else { continue }
                let volumeIcon = NSWorkspace.shared.icon(forFile: volume.path)
                let disk = AbstractDisk()
                disk.name = volumeName
                disk.volumeID = volumeID
                disk.totalCapacity = volumeTotalCapacity
                disk.availableCapacity = volumeAvailableCapacity
                disk.icon = volumeIcon
                currentDisks.append(disk)
            } catch {
                continue
            }
        }
    }
    
    /// Retrieves configured disks.
    private func fetchConfiguredDisks() {
        let fetchRequest = NSFetchRequest<Disk>(entityName: "Disk")
        do {
            configuredDisks = try CDS.persistentContainer.viewContext.fetch(fetchRequest)
        } catch {
            print("Disk fetch failed")
        }
    }
    
    /// Computes BSD disk name for given `DADisk`.
    ///
    /// - Parameter disk: Target disk.
    /// - Returns: BSD disk name.
    private func getBSDDiskName(disk: DADisk) -> String {
        guard let diskBSDNameData = DADiskGetBSDName(disk) else { return "unknown" }
        return String(cString: diskBSDNameData)
    }
    
    /// Handle disk unmounts.
    var diskDidUnmount: DADiskUnmountApprovalCallback = { disk, context in
        print("unmount")
        return nil
    }
    
    /// Handle disk mounting.
    var diskDidMount: DADiskMountApprovalCallback = { disk, context in
        print("mount")
        return nil
    }
    
}
