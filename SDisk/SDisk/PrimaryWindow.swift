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
    
    /// Custom window animation resize time.
    ///
    /// - Parameter newFrame: The new frame to animate to.
    /// - Returns: Time interval of the animation.
    override func animationResizeTime(_ newFrame: NSRect) -> TimeInterval {
        return 0.3
    }
    
}
