//
//  CellWaitView.swift
//  SDisk
//
//  Created by Mayank Kumar on 1/28/19.
//  Copyright © 2019 Mayank Kumar. All rights reserved.
//

import Cocoa

class CellWaitView: NSView {
    
    override var wantsUpdateLayer: Bool {
        return true
    }
    
    override func updateLayer() {
        drawLayer()
    }
    
    func drawLayer() {
        let gradient = CAGradientLayer()
        gradient.cornerRadius = 2
        gradient.colors = [NSColor.quaternaryLabelColor.withAlphaComponent(0.2).cgColor, NSColor.windowBackgroundColor.withAlphaComponent(0.2).cgColor]
        gradient.locations = [0, 1]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        let animation = CABasicAnimation(keyPath: "colors")
        animation.duration = 1
        animation.repeatCount = .greatestFiniteMagnitude
        animation.autoreverses = true
        animation.toValue = [NSColor.windowBackgroundColor.withAlphaComponent(0.2).cgColor, NSColor.quaternaryLabelColor.withAlphaComponent(0.2).cgColor]
        gradient.add(animation, forKey: "locations")
        layer = gradient
    }
}
