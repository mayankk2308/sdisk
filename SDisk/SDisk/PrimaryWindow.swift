//
//  PrimaryWindow.swift
//  SDisk
//
//  Created by Mayank Kumar on 1/29/19.
//  Copyright © 2019 Mayank Kumar. All rights reserved.
//

import Cocoa

/// Declares the primary window for SDisk.
class PrimaryWindow: NSWindow {
    
    override func animationResizeTime(_ newFrame: NSRect) -> TimeInterval {
        return 0.3
    }
    
}
