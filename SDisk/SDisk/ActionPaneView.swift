//
//  ActionPaneView.swift
//  SDisk
//
//  Created by Mayank Kumar on 1/28/19.
//  Copyright © 2019 Mayank Kumar. All rights reserved.
//

import Cocoa

/// Represents a simple action bar.
class ActionPaneView: NSView {
    
    override var wantsUpdateLayer: Bool {
        return true
    }
    
    override func updateLayer() {
        layer?.borderWidth = 1.0
        layer?.borderColor = NSColor.quaternaryLabelColor.cgColor
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }
    
}
