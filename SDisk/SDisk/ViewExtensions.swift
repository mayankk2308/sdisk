//
//  ViewExtensions.swift
//  SDisk
//
//  Created by Mayank Kumar on 1/26/19.
//  Copyright © 2019 Mayank Kumar. All rights reserved.
//

import Cocoa

extension NSImageView {
    
    func transition(withImage image: NSImage) {
        let transition = CATransition()
        transition.duration = 1.0
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        transition.type = .fade
        wantsLayer = true
        layer?.add(transition, forKey: kCATransition)
        self.image = image
    }
    
}
