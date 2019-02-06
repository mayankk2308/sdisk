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
    
    var requested = false
    
    let selectionViewController = DiskSelectionViewController()
    
    /// Refreshes list of configured disks.
    ///
    /// - Parameter sender: The element responsible for the action.
    @IBAction func refreshAllDisks(_ sender: Any) {
        toggleUpdateMode()
        refreshDisks()
    }
    
    /// Ejects all disks.
    ///
    /// - Parameter sender: The element responsible for the action.
    @IBAction func ejectAllDisks(_ sender: Any) {
        let originalStatus = statusLabel.stringValue
        statusLabel.setStringValue("All disk eject initiated.")
        DADiskManager.shared.unmountAllDisks()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [unowned self] in
            self.statusLabel.setStringValue(originalStatus)
        }
    }
    
    /// Removes all configured disks.
    ///
    /// - Parameter sender: The element responsible for the action.
    @IBAction func removeAllDisks(_ sender: Any) {
        toggleUpdateMode()
        DADiskManager.shared.removeAllConfiguredDisks {
            MenuManager.shared.update(withStatus: "Volumes Configured: None")
            self.refreshDisks()
        }
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
    
    /// Requests tableview updates.
    private func requestUpdates() {
        if !requested {
            requested = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [unowned self] in
                self.diskTableView.reloadData()
                self.requested = false
            }
        }
    }
    
    /// Manage tableview for mounted disks.
    ///
    /// - Parameter disk: The mounted disk.
    func postDiskMount(mountedDisk disk: DADisk) {
        requestUpdates()
    }
    
    /// Manage tableview for unmounted disks.
    ///
    /// - Parameter disk: The unmounted disk.
    func postDiskUnmount(unmountedDisk disk: DADisk?) {
        requestUpdates()
    }
    
    /// Manage tableview for changed disk.
    ///
    /// - Parameter disk: The changed disk.
    func postDiskDescriptionChanged(changedDisk disk: DADisk?) {
        requestUpdates()
    }
    
    /// Manage tableview for suddenly disappearing disks.
    ///
    /// - Parameter disk: The disappearing whole disk.
    func postDiskDisappearence(disappearedDisk disk: DADisk) {
        if !requested {
            requested = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [unowned self] in
                self.diskTableView.isEnabled = false
                DADiskManager.shared.fetchExternalDisks()
                DADiskManager.shared.fetchConfiguredDisks()
                self.diskTableView.reloadData()
                self.diskTableView.isEnabled = true
                self.requested = false
            }
        }
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
            changeWindowHeight(toHeight: CGFloat(count) * diskTableView.rowHeight + viewDelta)
        } else {
            instructionView.isHidden = true
            removeAllDisksButton.isEnabled = true
            statusLabel.stringValue = "Volumes Configured: \(count)"
            changeWindowHeight(toHeight: CGFloat(count > maxCellsInView ? maxCellsInView : count) * diskTableView.rowHeight + viewDelta)
        }
    }
    
}

// MARK: - Handle disk updates.
extension PreferencesViewController {
    
    /// Refreshes all disks.
    func refreshDisks() {
        DispatchQueue.global(qos: .default).async {
            DADiskManager.shared.fetchExternalDisks { _ in
                DADiskManager.shared.fetchConfiguredDisks { _ in
                    DispatchQueue.main.async {
                        self.toggleUpdateMode(enableItems: true)
                        self.diskTableView.reloadData()
                        self.manageWindow()
                    }
                }
            }
        }
    }
    
}

// MARK: - Handle table view configuration.
extension PreferencesViewController: NSTableViewDelegate, NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return DADiskManager.shared.configuredDisks.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SDiskCellView"), owner: self) as! DiskCellView
        cell.update(fromDisk: DADiskManager.shared.configuredDisks[row], withRow: row)
        return cell
    }
    
    func tableView(_ tableView: NSTableView, rowActionsForRow row: Int, edge: NSTableView.RowActionEdge) -> [NSTableViewRowAction] {
        if edge == .trailing {
            let deleteAction = NSTableViewRowAction(style: .destructive, title: "") { action, index in
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.3
                    tableView.removeRows(at: IndexSet(integer: index), withAnimation: NSTableView.AnimationOptions.slideUp)
                }
                DADiskManager.shared.removeConfiguredDisk(DADiskManager.shared.configuredDisks[index])
                self.manageWindow()
                var windowFrame = self.window.frame
                windowFrame.size.height -= self.viewDelta
                tableView.setFrameSize(windowFrame.size)
            }
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
