//
//  ViewExtensions.swift
//  SDisk
//
//  Created by Mayank Kumar on 1/26/19.
//  Copyright © 2019 Mayank Kumar. All rights reserved.
//

import Cocoa

extension NSImageView {
    
    /// Creates a fade in/out transition from initial to final image.
    ///
    /// - Parameter img: Image to transition to.
    func transition(withImage img: NSImage?) {
        guard let image = img else { return }
        let transition = CATransition()
        transition.duration = 1.0
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        transition.type = .fade
        wantsLayer = true
        layer?.add(transition, forKey: kCATransition)
        self.image = image
    }
    
}

extension NSTextField {
    
    /// Animation system.
    ///
    /// - Parameters:
    ///   - change: UI changes to be executed as a block.
    ///   - interval: Animation duration.
    private func animate(change: @escaping () -> Void, interval: TimeInterval) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = interval / 2.0
            context.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
            animator().alphaValue = 0.0
        }, completionHandler: {
            change()
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = interval / 2.0
                context.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
                self.animator().alphaValue = 1.0
            }, completionHandler: {})
        })
    }
    
    /// Sets a new string with a fade-in/out effect.
    ///
    /// - Parameters:
    ///   - newValue: New string value to set to.
    ///   - animated: Whether to animate or not.
    ///   - interval: Animation time interval.
    func setStringValue(_ newValue: String, animated: Bool = true, interval: TimeInterval = 0.7) {
        guard stringValue != newValue else { return }
        if animated {
            animate(change: { self.stringValue = newValue }, interval: interval)
        } else {
            stringValue = newValue
        }
    }
    
}
