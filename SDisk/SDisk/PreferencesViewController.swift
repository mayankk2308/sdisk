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
    @IBOutlet weak var removeDiskButton: NSButton!
    @IBOutlet weak var addDiskButton: NSButton!
    @IBOutlet weak var indicator: NSProgressIndicator!
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var removeAllDisksButton: NSButton!
    @IBOutlet weak var refreshAllDisksButton: NSButton!
    
    private let maxCellsInView = 5
    private let viewDelta: CGFloat = 48
    
    var window: NSWindow! = nil
    
    /// Refreshes list of configured disks.
    ///
    /// - Parameter sender: The element responsible for the action.
    @IBAction func refreshAllDisks(_ sender: Any) {
        toggleUpdateMode()
        DispatchQueue.global(qos: .background).async {
            DADiskManager.shared.fetchConfiguredDisks()
            DispatchQueue.main.async {
                self.toggleUpdateMode()
                self.diskTableView.reloadData()
                self.manageWindow()
            }
        }
    }
    
    /// Removes all configured disks.
    ///
    /// - Parameter sender: The element responsible for the action.
    @IBAction func removeAllDisks(_ sender: Any) {
    }
    
    /// Removes a configured disk.
    ///
    /// - Parameter sender: The element responsible for the action.
    @IBAction func removeDisk(_ sender: Any) {
    }
    
    /// Adds an available disk.
    ///
    /// - Parameter sender: The element responsible for the action.
    @IBAction func addDisk(_ sender: Any) {
    }
    
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
    
    private func toggleUpdateMode() {
        statusLabel.stringValue = "Updating..."
        refreshAllDisksButton.isEnabled = !refreshAllDisksButton.isEnabled
        removeAllDisksButton.isEnabled = !removeAllDisksButton.isEnabled
        removeDiskButton.isEnabled = !removeDiskButton.isEnabled
        addDiskButton.isEnabled = !addDiskButton.isEnabled
        indicator.isHidden = !indicator.isHidden
        if indicator.isHidden {
            indicator.stopAnimation(self)
        } else  {
            indicator.startAnimation(self)
        }
    }
    
    /// Manages the window.
    private func manageWindow() {
        var count = DADiskManager.shared.configuredDisks.count
        if count == 0 {
            instructionView.isHidden = false
            removeDiskButton.isEnabled = false
            removeAllDisksButton.isEnabled = false
            statusLabel.stringValue = "Volumes Configured: None"
            count += 1
        } else {
            removeAllDisksButton.isEnabled = true
            statusLabel.stringValue = "Volumes Configured: \(count)"
            changeWindowHeight(toHeight: CGFloat(count > maxCellsInView ? maxCellsInView : count) * diskTableView.rowHeight + viewDelta)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        diskTableView.dataSource = self
        diskTableView.delegate = self
        indicator.isHidden = true
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        manageWindow()
    }
}

extension PreferencesViewController: NSTableViewDelegate, NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return DADiskManager.shared.configuredDisks.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let disk = DADiskManager.shared.configuredDisks[row]
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SDiskCellView"), owner: self) as! SDiskCellView
        if let diskName = disk.name,
            let diskIcon = disk.icon {
            cell.diskNameLabel.stringValue = diskName
            cell.diskImageView.image = NSImage(data: diskIcon)
        }
        cell.diskCapacityLabel.stringValue = DADiskManager.shared.computeDiskSizeString(fromDiskCapacity: disk.totalCapacity, withAvailableDiskCapacity: disk.availableCapacity, withPrecision: 10)
        cell.diskCapacityBar.doubleValue = ((disk.totalCapacity - disk.availableCapacity) / disk.totalCapacity) * 100
        cell.associatedDisk = disk
        return cell
    }
}
