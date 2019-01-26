//
//  SDiskSelectCellView.swift
//  SDisk
//
//  Created by Mayank Kumar on 1/26/19.
//  Copyright © 2019 Mayank Kumar. All rights reserved.
//

import Cocoa

class SDiskSelectCellView: NSTableCellView {
    
    @IBOutlet weak var diskImageView: NSImageView!
    @IBOutlet weak var diskCapacityBar: DiskCapacityBarView!
    @IBOutlet weak var diskCapacityLabel: NSTextField!
    @IBOutlet weak var diskNameLabel: NSTextField!
    
}
