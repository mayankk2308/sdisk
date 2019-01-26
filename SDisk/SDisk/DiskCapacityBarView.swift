//
//  DiskCapacityBarView.swift
//  SDisk
//
//  Created by Mayank Kumar on 1/24/19.
//  Copyright © 2019 Mayank Kumar. All rights reserved.
//

import Cocoa

class DiskCapacityBarView: NSView {
    
    override var wantsUpdateLayer: Bool {
        return true
    }
    
    var normal: Double = 0
    var index: Int = 0
    var subViewSet = false
    private var progressRect = NSView()
    private let availableColors: [NSColor] = [.systemBlue, .systemGreen, .systemPink, .systemOrange, .systemRed]
    
    func drawLayer() {
        let gradient = CAGradientLayer()
        gradient.cornerRadius = 3.5
        gradient.borderColor = NSColor.separatorColor.cgColor
        gradient.borderWidth = 1.0
        gradient.colors = [availableColors[index].cgColor, availableColors[index].withAlphaComponent(0.6).cgColor, NSColor.quaternaryLabelColor.cgColor, NSColor.quaternaryLabelColor.cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.locations = [0, normal, normal, 1] as [NSNumber]
        layer = gradient
    }
}
