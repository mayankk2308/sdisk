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

    @IBOutlet weak var errorImageView: NSImageView!
    @IBOutlet weak var mainScrollView: NSScrollView!
    @IBOutlet weak var selectionTableView: NSTableView!
    @IBOutlet weak var driveFetchIndicator: NSProgressIndicator!
    @IBOutlet weak var driveFetchLabel: NSTextField!
    @IBOutlet weak var addButton: NSButton!
    @IBOutlet weak var actionPaneView: NSView!
    @IBOutlet weak var addProgressIndicator: NSProgressIndicator!
    @IBOutlet weak var exitButton: NSButton!
    @IBOutlet weak var reloadButton: NSButton!
    
    var disks = [DADisk]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selectionTableView.dataSource = self
        selectionTableView.delegate = self
    }
    
    private func reloadDisks() {
        actionPaneView.isHidden = true
        mainScrollView.isHidden = true
        errorImageView.isHidden = true
        driveFetchIndicator.startAnimation(self)
        driveFetchLabel.isHidden = false
        driveFetchLabel.stringValue = "Retrieving drives..."
        DADiskManager.shared.fetchExternalDisks { success in
            self.disks = DADiskManager.shared.filteredDisks
            DispatchQueue.main.async {
                self.driveFetchIndicator.stopAnimation(self)
                if !success || self.disks.count == 0 {
                    self.driveFetchLabel.stringValue = "No External Drives Found."
                    self.errorImageView.isHidden = false
                }
                else {
                    self.mainScrollView.isHidden = false
                    self.driveFetchLabel.isHidden = true
                    self.selectionTableView.reloadData()
                }
                self.actionPaneView.isHidden = false
            }
        }
    }
    
    override func viewDidDisappear() {
        disks.removeAll()
    }
    
    override func viewWillAppear() {
        reloadDisks()
    }
    
    @IBAction func addSelectedDisks(_ sender: Any) {
        let indexes = self.selectionTableView.selectedRowIndexes
        addProgressIndicator.startAnimation(self)
        addButton.isEnabled = false
        exitButton.isEnabled = false
        reloadButton.isEnabled = false
        DispatchQueue.global(qos: .userInitiated).async {
            for index in indexes {
                self.disks[index].addAsConfigurableDisk()
            }
            DispatchQueue.main.async {
                self.dismiss(self)
                self.addButton.isEnabled = true
                self.exitButton.isEnabled = true
                self.reloadButton.isEnabled = true
                self.addProgressIndicator.stopAnimation(self)
                MenuManager.shared.preferencesViewController.refreshAllDisks(self)
            }
        }
    }
    
    @IBAction func reloadDisks(_ sender: Any) {
        reloadDisks()
    }
    
    @IBAction func dismissView(_ sender: Any) {
        dismiss(self)
    }
}

// MARK: - Handle tableview configuration.
extension DiskSelectionViewController: NSTableViewDelegate, NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return disks.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "diskFetchCell"), owner: self) as! DiskCellView
        cell.update(fromDisk: disks[row], withRow: row)
        return cell
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        addButton.isEnabled = selectionTableView.selectedRowIndexes.count > 0
    }
}
