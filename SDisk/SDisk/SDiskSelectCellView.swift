//
//  SDiskSelectCellView.swift
//  SDisk
//
//  Created by Mayank Kumar on 1/26/19.
//  Copyright © 2019 Mayank Kumar. All rights reserved.
//

import Cocoa

/// Describes a cell view for available disks.
class SDiskSelectCellView: NSTableCellView {
    
    @IBOutlet weak var diskImageView: NSImageView!
    @IBOutlet weak var diskCapacityBar: DiskCapacityBarView!
    @IBOutlet weak var diskCapacityLabel: NSTextField!
    @IBOutlet weak var diskNameLabel: NSTextField!
    @IBOutlet weak var loadingView: NSView!
    
    func toggleView(hide hidden: Bool! = false) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.75
            diskImageView.alphaValue = hidden ? 0 : 1
            diskCapacityBar.alphaValue = hidden ? 0 : 1
            diskCapacityLabel.alphaValue = hidden ? 0 : 1
            diskNameLabel.alphaValue = hidden ? 0 : 1
            loadingView.alphaValue = hidden ? 1 : 0
        }
    }
    
    override func prepareForReuse() {
        for subview in loadingView.subviews {
            guard let waitView = subview as? CellWaitView else { continue }
            waitView.drawLayer()
        }
    }
    
}
