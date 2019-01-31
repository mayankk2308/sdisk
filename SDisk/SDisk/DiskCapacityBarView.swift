//
//  DiskCapacityBarView.swift
//  SDisk
//
//  Created by Mayank Kumar on 1/24/19.
//  Copyright © 2019 Mayank Kumar. All rights reserved.
//

import Cocoa

/// Custom view to show disk capacity.
class DiskCapacityBarView: NSView {
    
    override var wantsUpdateLayer: Bool {
        return true
    }
    
    var normal: Double = 0
    var index: Int = 0
    private let availableColors: [NSColor] = [.systemBlue, .systemGreen, .systemPink, .systemOrange, .systemRed]
    
    /// Draws the layer, or updates if layer already drawn.
    func drawLayer() {
        if let oldGradient = layer as? CAGradientLayer {
            let colorAnimation = CABasicAnimation(keyPath: "colors")
            colorAnimation.duration = 1
            colorAnimation.toValue = [availableColors[index % availableColors.count].cgColor, availableColors[index % availableColors.count].withAlphaComponent(0.6).cgColor, NSColor.scrollBarColor.withAlphaComponent(0.2).cgColor, NSColor.scrollBarColor.withAlphaComponent(0.2).cgColor]
            colorAnimation.isRemovedOnCompletion = false
            colorAnimation.fillMode = .forwards
            let progressAnimation = CABasicAnimation(keyPath: "locations")
            progressAnimation.duration = 1
            progressAnimation.toValue = [0, normal, normal, 1] as [NSNumber]
            progressAnimation.isRemovedOnCompletion = false
            progressAnimation.fillMode = .forwards
            oldGradient.add(colorAnimation, forKey: "colors")
            oldGradient.add(progressAnimation, forKey: "locations")
        } else {
            let gradient = CAGradientLayer()
            gradient.cornerRadius = 3.5
            gradient.borderColor = NSColor.scrollBarColor.withAlphaComponent(0.3).cgColor
            gradient.borderWidth = 1.0
            gradient.colors = [availableColors[index % availableColors.count].cgColor, availableColors[index % availableColors.count].withAlphaComponent(0.6).cgColor, NSColor.scrollBarColor.withAlphaComponent(0.2).cgColor, NSColor.scrollBarColor.withAlphaComponent(0.2).cgColor]
            gradient.startPoint = CGPoint(x: 0, y: 0.5)
            gradient.endPoint = CGPoint(x: 1, y: 0.5)
            gradient.locations = [0, normal, normal, 1] as [NSNumber]
            layer = gradient
        }
    }
}
