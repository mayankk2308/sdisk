//
//  PreferencesWindowController.swift
//  SDisk
//
//  Created by Mayank Kumar on 1/18/19.
//  Copyright © 2019 Mayank Kumar. All rights reserved.
//

import Cocoa

class PreferencesWindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
        print("windowcontroller")
    }
    
    override var windowNibName: NSNib.Name? {
        return "PreferencesWindowController"
    }
    
    override var owner: AnyObject? {
        return self
    }
    
}
