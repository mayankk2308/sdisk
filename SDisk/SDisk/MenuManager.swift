//
//  File.swift
//  SDisk
//
//  Created by Mayank Kumar on 1/17/19.
//  Copyright © 2019 Mayank Kumar. All rights reserved.
//

import Cocoa

/// Manages the macOS menubar item for the application.
class MenuManager {
    
    private static var instance: MenuManager?
    
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let statusMenuItem = NSMenuItem(title: "Status: Not Configured", action: nil, keyEquivalent: "")
    private let menu = NSMenu()
    
    /// Prepares the menu item.
    func prepare() {
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit(_:)), keyEquivalent: "q")
        quitItem.target = self
        let prefItem = NSMenuItem(title: "Preferences...", action: #selector(quit(_:)), keyEquivalent: ",")
        prefItem.target = self
        menu.addItem(statusMenuItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(prefItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(quitItem)
        statusItem.menu = menu
        if let button = statusItem.button {
            button.image = NSImage(named: "MenuIcon")
            button.target = self
        }
    }
    
    /// Updates menu item status.
    ///
    /// - Parameter status: Status description.
    func update(withStatus status: String) {
        statusMenuItem.title = "Status: " + status
    }
    
    /// Quits the application.
    ///
    /// - Parameter sender: The element responsible for the action.
    @objc func quit(_ sender: Any) {
        NSApplication.shared.terminate(sender)
    }
    
    /// Returns a shared instance of MenuManager.
    static var shared: MenuManager {
        guard let prevInstance = instance else {
            instance = MenuManager()
            return instance!
        }
        return prevInstance
    }
    
}
