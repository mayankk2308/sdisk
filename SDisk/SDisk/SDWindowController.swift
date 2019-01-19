//
//  SDWindowController.swift
//  SDisk
//
//  Created by Mayank Kumar on 1/18/19.
//  Copyright © 2019 Mayank Kumar. All rights reserved.
//

import Cocoa

/// Base window configuration for the application.
class SDWindowController: NSWindowController {
    
    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == [.command] && event.characters == "w" {
            self.window?.performClose(self)
        }
        else if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == [.command] && event.characters == "m" {
            self.window?.miniaturize(self)
        }
        else if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == [.command] && event.characters == "q" {
            NSApplication.shared.terminate(self)
        }
    }
}
