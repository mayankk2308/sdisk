//
//  PreferencesViewController.swift
//  SDisk
//
//  Created by Mayank Kumar on 1/21/19.
//  Copyright © 2019 Mayank Kumar. All rights reserved.
//

import Cocoa

/// Defines the base preferences view.
class PreferencesViewController: NSViewController {
    
    @IBOutlet weak var addDiskButton: NSButton!
    @IBOutlet weak var indicator: NSProgressIndicator!
    @IBOutlet weak var statusLabel: NSTextField!
    var window: NSWindow! = nil
    
    @IBAction func addDisk(_ sender: Any) {
    }
    
    /// Changes current window size.
    ///
    /// - Parameter offset: Offset by which to change window size.
    private func changeWindowSize(byOffset offset: CGFloat) {
        guard let window = window else { return }
        var frame = window.frame
        frame.size = CGSize(width: window.frame.width, height: window.frame.height + offset)
        frame.origin.y -= offset
        var viewFrame = view.frame
        viewFrame.origin.y -= offset
        view.frame = viewFrame
        window.setFrame(frame, display: true, animate: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
