//
//  PreferencesWindowController.swift
//  SDisk
//
//  Created by Mayank Kumar on 1/18/19.
//  Copyright © 2019 Mayank Kumar. All rights reserved.
//

import Cocoa

/// Allows disk access and script configuration.
class PreferencesWindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
    }
    
    override var windowNibName: NSNib.Name? {
        return "PreferencesWindowController"
    }
    
    override var owner: AnyObject? {
        return self
    }
    
    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == [.command] && event.characters == "w" {
            self.window?.performClose(self)
        }
        else if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == [.command] && event.characters == "m" {
            self.window?.miniaturize(self)
        }
    }
}
