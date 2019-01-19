//
//  HelpWindowController.swift
//  SDisk
//
//  Created by Mayank Kumar on 1/18/19.
//  Copyright © 2019 Mayank Kumar. All rights reserved.
//

import Cocoa

/// Shows help.
class HelpWindowController: SDWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
    }
 
    override var windowNibName: NSNib.Name? {
        return "HelpWindowController"
    }
    
    override var owner: AnyObject? {
        return self
    }
    
}
