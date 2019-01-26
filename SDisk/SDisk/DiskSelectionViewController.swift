//
//  DiskSelectionViewController.swift
//  SDisk
//
//  Created by Mayank Kumar on 1/25/19.
//  Copyright © 2019 Mayank Kumar. All rights reserved.
//

import Cocoa

/// Handles selection from available mounted drives.
class DiskSelectionViewController: NSViewController {

    @IBOutlet weak var mainScrollView: NSScrollView!
    @IBOutlet weak var availableVolumesLabel: NSTextField!
    @IBOutlet weak var selectionTableView: NSTableView!
    @IBOutlet weak var driveFetchIndicator: NSProgressIndicator!
    @IBOutlet weak var driveFetchLabel: NSTextField!
    @IBOutlet weak var dismissButton: NSButton!
    @IBOutlet weak var addButton: NSButton!
    
    var disks = [DADisk]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mainScrollView.isHidden = true
        availableVolumesLabel.isHidden = true
        dismissButton.isHidden = true
        addButton.isHidden = true
        driveFetchIndicator.startAnimation(self)
        driveFetchLabel.stringValue = "Retrieving drives..."
        selectionTableView.dataSource = self
        selectionTableView.delegate = self
        DADiskManager.shared.delegate = self
    }
    
    override func viewWillAppear() {
        mainScrollView.isHidden = true
        availableVolumesLabel.isHidden = true
        dismissButton.isHidden = true
        addButton.isHidden = true
        driveFetchIndicator.startAnimation(self)
        driveFetchLabel.isHidden = false
        driveFetchLabel.stringValue = "Retrieving drives..."
        DADiskManager.shared.fetchExternalDisks { success in
            self.disks = DADiskManager.shared.filteredDisks
            DispatchQueue.main.async {
                self.driveFetchIndicator.stopAnimation(self)
                if !success || self.disks.count == 0 {
                    self.driveFetchLabel.stringValue = "No External Drives Found"
                }
                else {
                    self.addButton.isHidden = false
                    self.mainScrollView.isHidden = false
                    self.availableVolumesLabel.isHidden = false
                    self.driveFetchLabel.isHidden = true
                    self.selectionTableView.reloadData()
                }
                self.dismissButton.isHidden = false
            }
        }
    }

    @IBAction func dismissView(_ sender: Any) {
        dismiss(self)
    }
}

// MARK: - Handle disk events.
extension DiskSelectionViewController: DADiskManagerDelegate {
    
//    func postDiskMount() {
//        print("mount")
//        disks = DADiskManager.shared.filteredDisks
//        selectionTableView.reloadData()
//    }
//    
//    func postDiskUnmount() {
//        print("unmount")
//        disks = DADiskManager.shared.filteredDisks
//        selectionTableView.reloadData()
//    }
    
    func postDiskDescriptionChanged() {
        print("description")
        disks = DADiskManager.shared.filteredDisks
        selectionTableView.reloadData()
    }
}

// MARK: - Handle tableview configuration.
extension DiskSelectionViewController: NSTableViewDelegate, NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return disks.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SDiskSelectCellView"), owner: self) as! SDiskSelectCellView
        populateCell(cell, row)
        return cell
    }
    
    /// Populates the table view cells.
    ///
    /// - Parameters:
    ///   - cell: Cell to populate.
    ///   - row: Row index.
    private func populateCell(_ cell: SDiskSelectCellView, _ row: Int) {
        let disk = disks[row]
        guard let data = disk.diskData(),
            let name = disk.name(withDiskData: data),
            let capacityData = disk.capacity(withDiskData: data),
            let capacityString = DADiskManager.shared.capacityString(availableCapacity: capacityData.available, totalCapacity: capacityData.total),
            let icon = disk.icon(withDiskData: data) else { return }
        cell.diskImageView.image = NSImage(data: icon)
        cell.diskNameLabel.stringValue = name
        cell.diskCapacityLabel.stringValue = capacityString
        cell.diskCapacityBar.normal = (capacityData.total - capacityData.available) / capacityData.total
        cell.diskCapacityBar.index = row
        cell.diskCapacityBar.drawLayer()
    }
}
