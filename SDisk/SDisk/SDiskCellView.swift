//
//  SDiskCellView.swift
//  SDisk
//
//  Created by Mayank Kumar on 1/21/19.
//  Copyright © 2019 Mayank Kumar. All rights reserved.
//

import Cocoa

/// Defines the configured disk cell view.
class SDiskCellView: NSTableCellView {

    @IBOutlet weak var diskImageView: NSImageView!
    @IBOutlet weak var diskNameLabel: NSTextField!
    @IBOutlet weak var diskCapacityLabel: NSTextField!
    @IBOutlet weak var diskAvailableImageView: NSImageView!
    @IBOutlet weak var diskCapacityBarView: DiskCapacityBarView!
    @IBOutlet weak var diskMountStatusLabel: NSTextField!
    @IBOutlet weak var actionMountButton: NSButton!
    @IBOutlet weak var actionPeriodicButton: NSButton!
    @IBOutlet weak var actionUnmountButton: NSButton!
    @IBOutlet weak var loadingView: NSView!
    
    weak var associatedDisk: Disk! = nil
    
    func toggleView(hide hidden: Bool! = false) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.75
            diskImageView.alphaValue = hidden ? 0 : 1
            diskAvailableImageView.alphaValue = hidden ? 0 : 1
            diskCapacityBarView.alphaValue = hidden ? 0 : 1
            diskCapacityLabel.alphaValue = hidden ? 0 : 1
            diskNameLabel.alphaValue = hidden ? 0 : 1
            diskMountStatusLabel.alphaValue = hidden ? 0 : 1
            actionMountButton.alphaValue = hidden ? 0 : 1
            actionUnmountButton.alphaValue = hidden ? 0 : 1
            actionPeriodicButton.alphaValue = hidden ? 0 : 1
            loadingView.alphaValue = hidden ? 1 : 0
        }
    }
    
    @IBAction func actionsOnMount(_ sender: Any) {
    }
    
    @IBAction func actionsPeriodically(_ sender: Any) {
        
    }
    
    @IBAction func actionsOnUnmount(_ sender: Any) {
        
    }
    
    override func prepareForReuse() {
        for subview in loadingView.subviews {
            guard let waitView = subview as? CellWaitView else { continue }
            waitView.drawLayer()
        }
    }
    
}
