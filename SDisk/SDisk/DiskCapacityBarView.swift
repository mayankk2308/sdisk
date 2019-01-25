//
//  DiskCapacityBarView.swift
//  SDisk
//
//  Created by Mayank Kumar on 1/24/19.
//  Copyright © 2019 Mayank Kumar. All rights reserved.
//

import Cocoa

class DiskCapacityBarView: NSView {

    var normal: Double = 1
    var index: Int = 0
    var subViewSet = false
    private var progressRect = NSView()
    private let availableColors: [NSColor] = [.systemBlue, .systemGreen, .systemRed, .systemPink, .systemOrange]
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        layer?.cornerRadius = 3.5
        layer?.borderColor = NSColor.separatorColor.cgColor
        layer?.borderWidth = 1.0
        NSColor.quaternaryLabelColor.setFill()
        dirtyRect.fill()
        progressRect.frame = dirtyRect
        progressRect.frame.size.width = CGFloat(normal) * progressRect.frame.size.width
        progressRect.layer?.backgroundColor = availableColors[index].withAlphaComponent(0.75).cgColor
        if !subViewSet { addSubview(progressRect) }
        subViewSet = true
    }
}
