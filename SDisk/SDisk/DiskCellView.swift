//
//  DiskCellView.swift
//  SDisk
//
//  Created by Mayank Kumar on 1/29/19.
//  Copyright © 2019 Mayank Kumar. All rights reserved.
//

import Cocoa

/// Defines a generic table view cell for disks.
class DiskCellView: NSTableCellView {

    /// Displays the name of the disk.
    @IBOutlet weak var diskNameLabel: NSTextField?
    
    /// Displays amount of free space remaining.
    @IBOutlet weak var diskCapacityLabel: NSTextField?
    
    /// Shows disk mount status.
    @IBOutlet weak var diskMountLabel: NSTextField?
    
    /// Visualizes amount of disk space consumed.
    @IBOutlet weak var diskCapacityBar: DiskCapacityBarView?
    
    /// Shows the associated disk icon.
    @IBOutlet weak var diskImageView: NSImageView?
    
    /// Visualizes disk mount status.
    @IBOutlet weak var diskMountStatusView: NSImageView?
    
    /// Button to set up disk actions on mount.
    @IBOutlet weak var actionOnMountButton: NSButton?
    
    /// Button to set up disk actions on unmount.
    @IBOutlet weak var actionOnUnmountButton: NSButton?
    
    /// Button to set up disk actions periodically, as long as disk is mounted.
    @IBOutlet weak var actionPeriodicButton: NSButton?
    
    /// View shown while cell is updating.
    @IBOutlet weak var diskPreloadView: NSView?
    
    /// Stores a reference to a disk for which to determine actions.
    weak var actionableDisk: Disk?
    
}

// MARK: - Manage cell actions.
extension DiskCellView {
    
    @IBAction func actionsOnMount(_ sender: Any) {
    }
    
    @IBAction func actionsPeriodically(_ sender: Any) {
        
    }
    
    @IBAction func actionsOnUnmount(_ sender: Any) {
        
    }
    
}

// MARK: - Manage cell updates.
extension DiskCellView {
    
    /// Switches cell state between pre-load and post-load.
    ///
    /// - Parameter preload: State to set.
    func state(isPreloading preload: Bool) {
        let valueToSet = CGFloat(!preload)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.75
            if let nameLabel = diskNameLabel {
                nameLabel.alphaValue = valueToSet
            }
            if let capacityLabel = diskCapacityLabel {
                capacityLabel.alphaValue = valueToSet
            }
            if let mountLabel = diskMountLabel {
                mountLabel.alphaValue = valueToSet
            }
            if let capacityBar = diskCapacityBar {
                capacityBar.alphaValue = valueToSet
            }
            if let imageView = diskImageView {
                imageView.alphaValue = valueToSet
            }
            if let mountStatusView = diskMountStatusView {
                mountStatusView.alphaValue = valueToSet
            }
            if let onMountButton = actionOnMountButton {
                onMountButton.alphaValue = valueToSet
            }
            if let onUnmountButton = actionOnUnmountButton {
                onUnmountButton.alphaValue = valueToSet
            }
            if let periodicButton = actionPeriodicButton {
                periodicButton.alphaValue = valueToSet
            }
            if let preloadView = diskPreloadView {
                preloadView.alphaValue = CGFloat(preload)
            }
        }
    }
    
    /// Updates current cell with provided data.
    ///
    /// - Parameters:
    ///   - disk: Disk data to fetch.
    ///   - row: Current row in the table.
    func update(fromDisk disk: Disk, withRow row: Int) {
        state(isPreloading: true)
        DispatchQueue.global(qos: .userInitiated).async {
            guard let name = disk.name,
                let icon = disk.icon,
                let capacityString = DADiskManager.shared.capacityString(availableCapacity: disk.availableCapacity, totalCapacity: disk.totalCapacity) else { return }
            let mountStatus = disk.mounted
            DispatchQueue.main.async {
                self.state(isPreloading: false)
                if let nameLabel = self.diskNameLabel {
                    nameLabel.stringValue = name
                }
                if let capacityLabel = self.diskCapacityLabel {
                    capacityLabel.stringValue = capacityString
                }
                if let capacityBar = self.diskCapacityBar {
                    capacityBar.normal = (disk.totalCapacity - disk.availableCapacity) / disk.totalCapacity
                    capacityBar.index = row
                    capacityBar.drawLayer()
                }
                if let imageView = self.diskImageView {
                    imageView.transition(withImage: NSImage(data: icon) ?? NSImage(named: NSImage.Name("SDisk"))!)
                }
                if let mountLabel = self.diskMountLabel {
                    mountLabel.stringValue = mountStatus ? "Mounted" : "Not Mounted"
                }
                if let mountStatusView = self.diskMountStatusView {
                    mountStatusView.transition(withImage: NSImage(named: mountStatus ? NSImage.Name("NSStatusAvailable") : NSImage.Name("NSStatusUnavailable")))
                }
            }
        }
    }
    
    /// Updates current cell with provided data.
    ///
    /// - Parameters:
    ///   - disk: Disk data to fetch.
    ///   - row: Current row in the table.
    func update(fromDisk disk: DADisk, withRow row: Int) {
        state(isPreloading: true)
        DispatchQueue.global(qos: .userInitiated).async {
            guard let data = disk.diskData(),
                let name = disk.name(withDiskData: data),
                let capacityData = disk.capacity(withDiskData: data),
                let capacityString = DADiskManager.shared.capacityString(availableCapacity: capacityData.available, totalCapacity: capacityData.total),
                let icon = disk.icon(withDiskData: data) else { return }
            DispatchQueue.main.async {
                self.state(isPreloading: false)
                if let nameLabel = self.diskNameLabel {
                    nameLabel.stringValue = name
                }
                if let capacityLabel = self.diskCapacityLabel {
                    capacityLabel.stringValue = capacityString
                }
                if let capacityBar = self.diskCapacityBar {
                    capacityBar.normal = (capacityData.total - capacityData.available) / capacityData.total
                    capacityBar.index = row
                    capacityBar.drawLayer()
                }
                if let imageView = self.diskImageView {
                    imageView.transition(withImage: NSImage(data: icon) ?? NSImage(named: NSImage.Name("SDisk")))
                }
            }
        }
    }
    
    /// Redraws the preload view when a cell is re-used.
    override func prepareForReuse() {
        guard let preloadView = diskPreloadView else { return }
        for subview in preloadView.subviews {
            guard let waitView = subview as? CellWaitView else { continue }
            waitView.drawLayer()
        }
    }
    
}
