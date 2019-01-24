//
//  MenuManager.swift
//  SDisk
//
//  Created by Mayank Kumar on 1/17/19.
//  Copyright © 2019 Mayank Kumar. All rights reserved.
//

import Cocoa
import Swipt

/// Manages the macOS menubar item for the application.
class MenuManager {
    
    static let shared = MenuManager()
    private let swiptManager = SwiptManager()
    private let preferencesWindowController = PreferencesWindowController()
    let preferencesViewController = PreferencesViewController()
    private let helpWindowController = HelpWindowController()
    
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let statusMenuItem = NSMenuItem(title: "Status: Not Configured", action: nil, keyEquivalent: "")
    private let aboutMenuItem = NSMenuItem(title: "SDisk Version: \(String(describing: Bundle.main.infoDictionary!["CFBundleShortVersionString"]!))", action: nil, keyEquivalent: "")
    private let menu = NSMenu()
    
    /// Prepares the menu item.
    func prepare() {
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit(_:)), keyEquivalent: "q")
        quitItem.target = self
        let prefItem = NSMenuItem(title: "Configure...", action: #selector(showPreferences(_:)), keyEquivalent: ",")
        let openAtLogin = NSMenuItem(title: "Launch At Login", action: #selector(toggleOpenAtLogin(_:)), keyEquivalent: "")
        let helpItem = NSMenuItem(title: "Help...", action: #selector(showHelp(_:)), keyEquivalent: "")
        let donateItem = NSMenuItem(title: "Donate...", action: #selector(openDonationPage(_:)), keyEquivalent: "")
        openAtLogin.target = self
        prefItem.target = self
        helpItem.target = self
        donateItem.target = self
        swiptManager.execute(appleScriptText: "tell application \"System Events\" to get login item \"SDisk\"") { error, _ in
            DispatchQueue.main.async {
                openAtLogin.state = error == nil ? .on : .off
            }
        }
        menu.addItem(aboutMenuItem)
        menu.addItem(statusMenuItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(openAtLogin)
        menu.addItem(prefItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(donateItem)
        menu.addItem(helpItem)
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
        statusMenuItem.title = status
    }
    
    /// Toggle open at login.
    ///
    /// - Parameter sender: The element responsible for the action.
    @objc func toggleOpenAtLogin(_ sender: Any) {
        guard let item = sender as? NSMenuItem else { return }
        let appPath = Bundle.main.bundlePath
        let alert = NSAlert()
        alert.messageText = "Permissions Required"
        alert.informativeText = "Unable to toggle permissions. Please allow SDisk to control System Events in System Preferences > Privacy > Automation."
        alert.addButton(withTitle: "Ok")
        alert.alertStyle = .critical
        if item.state == .off {
            swiptManager.execute(appleScriptText: "tell application \"System Events\" to make login item at end with properties {path:\"\(appPath)\", hidden:false}") { error, _ in
                DispatchQueue.main.async {
                    if error == nil {
                        item.state = .on
                    } else {
                        alert.runModal()
                    }
                }
            }
        } else {
            swiptManager.execute(appleScriptText: "tell application \"System Events\" to delete login item \"SDisk\"") { error, _ in
                DispatchQueue.main.async {
                    if error == nil {
                        item.state = .off
                    } else {
                        alert.runModal()
                    }
                }
            }
        }
        item.state = item.state == .on ? .off : .on
    }
    
    /// Quits the application.
    ///
    /// - Parameter sender: The element responsible for the action.
    @objc func quit(_ sender: Any) {
        NSApplication.shared.terminate(sender)
    }
    
    /// Show preference pane.
    ///
    /// - Parameter sender: The element responsible for the action.
    @objc func showPreferences(_ sender: Any) {
        preferencesWindowController.window?.center()
        preferencesViewController.window = preferencesWindowController.window
        preferencesWindowController.contentViewController = preferencesViewController
        preferencesWindowController.window?.makeKeyAndOrderFront(sender)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    /// Open donation website in Safari.
    ///
    /// - Parameter sender: The element responsible for the action.
    @objc func openDonationPage(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=mayankk2308@gmail.com&lc=US&item_name=Development%20of%20SDisk&no_note=0&currency_code=USD&bn=PP-DonationsBF:btn_donate_SM.gif:NonHostedGuest")!)
    }
    
    /// Show help view.
    ///
    /// - Parameter sender: The element responsible for the action.
    @objc func showHelp(_ sender: Any) {
        helpWindowController.window?.center()
        helpWindowController.window?.makeKeyAndOrderFront(sender)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
