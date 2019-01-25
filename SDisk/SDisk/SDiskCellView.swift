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
    
    weak var associatedDisk: Disk! = nil
    
    @IBAction func actionsOnMount(_ sender: Any) {
    }
    
    @IBAction func actionsPeriodically(_ sender: Any) {
        
    }
    
    @IBAction func actionsOnUnmount(_ sender: Any) {
        
    }
    
}
