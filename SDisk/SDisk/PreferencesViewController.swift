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
    
    private let maxCellsInView = 5
    
    var window: NSWindow! = nil
    
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
    private func changeWindowSize(byOffset offset: CGFloat) {
        guard let window = window else { return }
        var frame = window.frame
        frame.size = CGSize(width: window.frame.width, height: window.frame.height + offset)
        frame.origin.y -= offset
        var viewFrame = view.frame
        viewFrame.origin.y -= offset
        view.frame = viewFrame
        window.setFrame(frame, display: true, animate: true)
    }
    
    /// Updates the view.
    private func updateView() {
        indicator.isHidden = false
        indicator.startAnimation(self)
        instructionView.isHidden = false
        statusLabel.stringValue = "Updating..."
        DispatchQueue.global(qos: .background).async {
            DADiskManager.shared.fetchConfiguredDisks()
            DispatchQueue.main.async {
                self.indicator.isHidden = true
                self.indicator.stopAnimation(self)
                self.instructionView.isHidden = !DADiskManager.shared.configuredDisks.isEmpty
                self.statusLabel.stringValue = "Disks Configured: \(DADiskManager.shared.configuredDisks.isEmpty ? "None" : "\(DADiskManager.shared.configuredDisks.count)")"
                self.diskTableView.reloadData()
                if DADiskManager.shared.configuredDisks.count > self.maxCellsInView {
                    self.changeWindowSize(byOffset: CGFloat(self.maxCellsInView) * self.diskTableView.rowHeight)
                } else if DADiskManager.shared.configuredDisks.count > 1 {
                    self.changeWindowSize(byOffset: CGFloat(DADiskManager.shared.configuredDisks.count - 1) * self.diskTableView.rowHeight)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        diskTableView.dataSource = self
        diskTableView.delegate = self
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        updateView()
    }
}

extension PreferencesViewController: NSTableViewDelegate, NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return DADiskManager.shared.configuredDisks.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
//        let disk = DADiskManager.shared.configuredDisks[row]
        let cell = tableView.makeView(withIdentifier: .init("SDTableCellView"), owner: self)
        return cell
    }
}
