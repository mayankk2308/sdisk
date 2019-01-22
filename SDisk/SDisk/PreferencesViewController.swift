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
    private let viewDelta: CGFloat = 48
    
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
    private func changeWindowHeight(toHeight height: CGFloat) {
        guard let window = window else { return }
        var frame = window.frame
        let oldHeight = frame.height
        print(oldHeight, height)
        frame.size = CGSize(width: frame.width, height: height)
        frame.origin.y -= (height - oldHeight)
        var viewFrame = view.frame
        viewFrame.origin.y -= (height - oldHeight)
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
                var count = DADiskManager.shared.configuredDisks.count
                if count == 0 {
                    count += 1
                } else if count > self.maxCellsInView {
                    count = self.maxCellsInView
                }
                self.changeWindowHeight(toHeight: CGFloat(count) * self.diskTableView.rowHeight + self.viewDelta)
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
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SDiskCellView"), owner: self) as! SDiskCellView
        return cell
    }
}
