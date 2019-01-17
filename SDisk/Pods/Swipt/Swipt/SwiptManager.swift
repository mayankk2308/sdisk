//
//  Swipt.swift
//  Swipt
//
//  Created by Mayank Kumar on 4/8/18.
//  Copyright © 2018 Mayank Kumar. All rights reserved.
//

import Foundation

/// Primary scripting interface.
public class SwiptManager {
    
    /// Swift Core Service object for script processing and management.
    private let core = SwiptCore()
    
    public init() {}
    /// Executes a string representation of unix commands.
    ///
    /// - Parameters:
    ///   - scriptText: Any `unix` command
    ///   - privilegeLevel: Required privilege level (default = `user`)
    ///   - completionHandler: Handles script completion
    /// - Note: Take caution when using unix scripts directly as strings, as problems with symbol escaping may prevent AppleScript from correctly executing it.
    public func execute(unixScriptText scriptText: String, withPrivilegeLevel privilegeLevel: Privileges? = .user, completionHandler: RequestHandler? = nil) {
        core.execute(unixScriptText: scriptText, withPrivilegeLevel: privilegeLevel, completionHandler: completionHandler)
    }
    
    /// Execute AppleScript as text directly.
    ///
    /// - Parameters:
    ///   - scriptText: AppleScript text
    ///   - completionHandler: Handles script completion
    public func execute(appleScriptText scriptText: String, completionHandler: RequestHandler? = nil) {
        core.execute(appleScriptText: scriptText, completionHandler: completionHandler)
    }
    
    /// Executes a string representation of unix commands asynchronously and concurrently.
    ///
    /// - Parameters:
    ///   - scriptText: Any `unix` command
    ///   - privilegeLevel: Required privilege level (default = `user`)
    ///   - completionHandler: Handles script completion
    /// - Note: Take caution when using unix scripts directly as strings, as problems with symbol escaping may prevent AppleScript from correctly executing it.
    public func asyncExecute(unixScriptText scriptText: String, withPrivilegeLevel privilegeLevel: Privileges? = .user, completionHandler: RequestHandler? = nil) {
        core.asyncExecute(unixScriptText: scriptText, withPrivilegeLevel: privilegeLevel, completionHandler: completionHandler)
    }
    
    /// Execute AppleScript as text directly, asynchronously and concurrently
    ///
    /// - Parameters:
    ///   - scriptText: AppleScript text
    ///   - completionHandler: Handles script completion
    public func asyncExecute(appleScriptText scriptText: String, completionHandler: RequestHandler? = nil) {
        core.asyncExecute(appleScriptText: scriptText, completionHandler: completionHandler)
    }
    
    /// Execute a provided script file.
    ///
    /// - Parameters:
    ///   - scriptFileName: File path to script
    ///   - scriptArgs: Arguments for script
    ///   - privilegeLevel: Required privilege level (default = `user`)
    ///   - shellType: Choice of shell (default = `/bin/sh`)
    ///   - completionHandler: Handles script completion
    /// - Note: Take caution when using unix scripts that ask for user input on the command line (such as using `read`). This may unexpected halt execution and potentially crash your application.
    public func execute(unixScriptFile scriptPath: String, withArgs scriptArgs: [String]? = nil, withPrivilegeLevel privilegeLevel: Privileges? = .user, withShellType shellType: ShellType? = .sh, completionHandler: RequestHandler? = nil) {
        core.execute(unixScriptPath: scriptPath, withArgs: scriptArgs, withPrivilegeLevel: privilegeLevel, withShellType: shellType, completionHandler: completionHandler)
    }
    
    /// Execute a provided script file asynchronously and concurrently.
    ///
    /// - Parameters:
    ///   - scriptFileName: File path to script
    ///   - scriptArgs: Arguments for script
    ///   - privilegeLevel: Required privilege level (default = `user`)
    ///   - shellType: Choice of shell (default = `/bin/sh`)
    ///   - completionHandler: Handles script completion
    /// - Note: Take caution when using unix scripts that ask for user input on the command line (such as using `read`). This may unexpected halt execution and potentially crash your application.
    public func asyncExecute(unixScriptFile scriptPath: String, withArgs scriptArgs: [String]? = nil, withPrivilegeLevel privilegeLevel: Privileges? = .user, withShellType shellType: ShellType? = .sh, completionHandler: RequestHandler? = nil) {
        core.asyncExecute(unixScriptPath: scriptPath, withArgs: scriptArgs, withPrivilegeLevel: privilegeLevel, withShellType: shellType, completionHandler: completionHandler)
    }
    
    /// Executes provided script files asynchronously and concurrently.
    ///
    /// - Parameters:
    ///   - scriptBatch: List of script file paths
    ///   - scriptArgs: List of script args
    ///   - privilegeLevels: List of associated privilege levels
    ///   - shellTypes: List of shell types
    /// - Note: Take caution when using unix scripts that ask for user input on the command line (such as using `read`). This may unexpected halt execution and potentially crash your application.
    public func execute(serialBatch scriptBatch: [String], withArgs scriptArgs: [[String]?]? = nil, withPrivilegeLevels privilegeLevels: [Privileges?]? = nil, withShellTypes shellTypes: [ShellType?]? = nil) {
        core.execute(serialBatch: scriptBatch, withArgs: scriptArgs, withPrivilegeLevels: privilegeLevels, withShellTypes: shellTypes)
    }

}
