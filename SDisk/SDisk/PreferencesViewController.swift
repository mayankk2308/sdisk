//
//  PreferencesViewController.swift
//  SDisk
//
//  Created by Mayank Kumar on 1/21/19.
//  Copyright © 2019 Mayank Kumar. All rights reserved.
//

import Cocoa

/// Defines the base preferences view.
class PreferencesViewController: NSViewController {
    
    @IBOutlet weak var diskTableView: NSTableView!
    @IBOutlet weak var instructionView: NSView!
    @IBOutlet weak var addDiskButton: NSButton!
    @IBOutlet weak var indicator: NSProgressIndicator!
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var removeAllDisksButton: NSButton!
    @IBOutlet weak var refreshAllDisksButton: NSButton!
    @IBOutlet weak var ejectAllDisksButton: NSButton!
    
    private let maxCellsInView = 5
    private let viewDelta: CGFloat = 48
    private var viewWasLoaded = false
    
    var window: NSWindow! = nil
    
    let selectionViewController = DiskSelectionViewController()
    
    /// Refreshes list of configured disks.
    ///
    /// - Parameter sender: The element responsible for the action.
    @IBAction func refreshAllDisks(_ sender: Any) {
        toggleUpdateMode()
        DispatchQueue.global(qos: .default).async {
            DADiskManager.shared.fetchExternalDisks()
            DADiskManager.shared.fetchConfiguredDisks()
            DispatchQueue.main.async {
                self.toggleUpdateMode(enableItems: true)
                self.diskTableView.reloadData()
                self.manageWindow()
            }
        }
    }
    
    /// Ejects all disks.
    ///
    /// - Parameter sender: The element responsible for the action.
    @IBAction func ejectAllDisks(_ sender: Any) {
        DADiskManager.shared.unmountAllDisks()
    }
    
    /// Removes all configured disks.
    ///
    /// - Parameter sender: The element responsible for the action.
    @IBAction func removeAllDisks(_ sender: Any) {
    }
    
    /// Adds an available disk.
    ///
    /// - Parameter sender: The element responsible for the action.
    @IBAction func addDisk(_ sender: Any) {
        presentAsSheet(selectionViewController)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        diskTableView.dataSource = self
        diskTableView.delegate = self
        viewWasLoaded = true
        DADiskManager.shared.delegate = self
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        manageWindow()
    }
}

// MARK: - Handle disk events.
extension PreferencesViewController: DADiskManagerDelegate {
    
    func preDiskUnmount() {
        toggleUpdateMode()
    }
    
    func postDiskUnmount() {
        toggleUpdateMode(enableItems: true)
        diskTableView.reloadData()
    }
    
    func postDiskDescriptionChanged() {
        diskTableView.reloadData()
    }
    
}

// MARK: - Handle user interface updates.
extension PreferencesViewController {
    
    /// Changes current window size.
    ///
    /// - Parameter offset: Offset by which to change window size.
    private func changeWindowHeight(toHeight height: CGFloat) {
        guard let window = window else { return }
        var frame = window.frame
        let oldHeight = frame.height
        frame.size = CGSize(width: frame.width, height: height)
        frame.origin.y -= (height - oldHeight)
        var viewFrame = view.frame
        viewFrame.origin.y -= (height - oldHeight)
        view.frame = viewFrame
        window.setFrame(frame, display: true, animate: true)
    }
    
    /// Toggles view into update mode.
    func toggleUpdateMode(enableItems enable: Bool! = false) {
        if !viewWasLoaded { return }
        statusLabel.stringValue = enable ? "Volumes Configured: \(DADiskManager.shared.configuredDisks.count)" : "Updating..."
        ejectAllDisksButton.isEnabled = enable
        refreshAllDisksButton.isEnabled = enable
        removeAllDisksButton.isEnabled = enable
        addDiskButton.isEnabled = enable
        indicator.isHidden = enable
        diskTableView.isEnabled = enable
        if !enable {
            indicator.isHidden = false
            indicator.startAnimation(self)
        } else {
            indicator.isHidden = true
            indicator.stopAnimation(self)
        }
    }
    
    /// Manages the window.
    private func manageWindow() {
        if !viewWasLoaded { return }
        var count = DADiskManager.shared.configuredDisks.count
        if count == 0 {
            instructionView.isHidden = false
            removeAllDisksButton.isEnabled = false
            statusLabel.stringValue = "Volumes Configured: None"
            count += 1
        } else {
            removeAllDisksButton.isEnabled = true
            statusLabel.stringValue = "Volumes Configured: \(count)"
            changeWindowHeight(toHeight: CGFloat(count > maxCellsInView ? maxCellsInView : count) * diskTableView.rowHeight + viewDelta)
        }
    }
    
}

// MARK: - Handle table view configuration.
extension PreferencesViewController: NSTableViewDelegate, NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return DADiskManager.shared.configuredDisks.count
    }
    
    /// Populates the table view cells.
    ///
    /// - Parameters:
    ///   - cell: Cell to populate.
    ///   - row: Row index.
    private func populateCell(_ cell: SDiskCellView, _ row: Int) {
        let disk = DADiskManager.shared.configuredDisks[row]
        guard let diskName = disk.name,
            let diskIcon = disk.icon,
            let diskCapacityString = DADiskManager.shared.capacityString(availableCapacity: disk.availableCapacity, totalCapacity: disk.totalCapacity) else { return }
        cell.diskNameLabel.stringValue = diskName
        cell.diskImageView.image = NSImage(data: diskIcon)
        cell.diskCapacityLabel.stringValue = diskCapacityString
        cell.diskCapacityBarView.index = row
        cell.diskCapacityBarView.normal = (disk.totalCapacity - disk.availableCapacity) / disk.totalCapacity
        cell.associatedDisk = disk
        cell.diskCapacityBarView.drawLayer()
        DispatchQueue.global(qos: .background).async {
            DispatchQueue.main.async {
                let mountStatus = disk.mounted
                cell.diskAvailableImageView.image = NSImage(named: mountStatus ? NSImage.Name("NSStatusAvailable") : NSImage.Name("NSStatusUnavailable"))
                cell.diskMountStatusLabel.stringValue = mountStatus ? "Mounted" : "Not Mounted"
            }
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SDiskCellView"), owner: self) as! SDiskCellView
        populateCell(cell, row)
        return cell
    }
    
    func tableView(_ tableView: NSTableView, rowActionsForRow row: Int, edge: NSTableView.RowActionEdge) -> [NSTableViewRowAction] {
        if edge == .trailing {
            let deleteAction = NSTableViewRowAction(style: .destructive, title: "") { _, _ in }
            deleteAction.image = NSImage(named: NSImage.Name("NSStopProgressFreestandingTemplate"))
            deleteAction.backgroundColor = NSColor.systemRed.withAlphaComponent(0.9)
            let resetAction = NSTableViewRowAction(style: .regular, title: "") { _, _ in
                
            }
            resetAction.image = NSImage(named: NSImage.Name("NSRefreshFreestandingTemplate"))
            resetAction.backgroundColor = NSColor.systemOrange.withAlphaComponent(0.9)
            return [resetAction, deleteAction]
        }
        return []
    }
}
