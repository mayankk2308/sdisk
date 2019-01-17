//
//  SwiptCore.swift
//  Swipt
//
//  Created by Mayank Kumar on 6/6/18.
//  Copyright © 2018 Mayank Kumar. All rights reserved.
//

import Foundation

/// Defines Swipt Core Service for script processing and management.
internal class SwiptCore {
    
    /// Serial queue for multi-threading
    let queue = DispatchQueue(label: "com.mayank.swipt.execute")
    
    /// Compiles and executes target AppleScript object.
    ///
    /// - Parameters:
    ///   - aScript: Target `NSAppleScript` object
    ///   - completionHandler: Handles script completion
    private func execute(targetScript aScript: NSAppleScript, completionHandler: RequestHandler? = nil) {
        var errorInfo: NSDictionary?
        let scriptReturn = aScript.executeAndReturnError(&errorInfo)
        if let executeFailureData = errorInfo {
            guard let errorCode = executeFailureData[NSAppleScript.errorNumber] as? Int else {
                if let handler = completionHandler {
                    handler(.UnknownError(code: -3, message: "An unknown error occurred."), nil)
                }
                return
            }
            guard let errorMessage = executeFailureData[NSAppleScript.errorMessage] as? String else {
                if let handler = completionHandler {
                    handler(.UnknownError(code: -3, message: "An unknown error occurred."), nil)
                }
                return
            }
            if let handler = completionHandler {
                handler(.ExecutionError(code: errorCode, message: errorMessage), nil)
            }
            return
        }
        if let handler = completionHandler {
            handler(nil, scriptReturn.stringValue ?? nil)
        }
    }
    
    /// Executes a string representation of unix commands.
    ///
    /// - Parameters:
    ///   - scriptText: Any `unix` command
    ///   - privilegeLevel: Required privilege level (default = `user`)
    ///   - completionHandler: Handles script completion
    /// - Note: Take caution when using unix scripts directly as strings, as problems with symbol escaping may prevent AppleScript from correctly executing it.
    internal func execute(unixScriptText scriptText: String, withPrivilegeLevel privilegeLevel: Privileges? = .user, completionHandler: RequestHandler? = nil) {
        let aScriptText = convertUnixCommandToAppleScript(targetScript: scriptText, withPrivilegeLevel: privilegeLevel)
        guard let aScript = NSAppleScript(source: aScriptText) else {
            if let handler = completionHandler {
                handler(.ASEmbedError(code: -1, message: "Unable to embed unix command into AppleScript."), nil)
            }
            return
        }
        execute(targetScript: aScript, completionHandler: completionHandler)
    }
    
    /// Executes a provided script file.
    ///
    /// - Parameters:
    ///   - scriptFileName: File path to script
    ///   - scriptArgs: Arguments for script
    ///   - privilegeLevel: Required privilege level (default = `user`)
    ///   - shellType: Choice of shell (default = `/bin/sh`)
    ///   - completionHandler: Handles script completion
    /// - Note: Take caution when using unix scripts that ask for user input on the command line (such as using `read`). This may unexpected halt execution and potentially crash your application.
    internal func execute(unixScriptPath scriptFilePath: String, withArgs scriptArgs: [String]? = nil, withPrivilegeLevel privilegeLevel: Privileges? = .user, withShellType shellType: ShellType? = .sh, completionHandler: RequestHandler? = nil) {
        let aScriptText = convertUnixFileToAppleScript(targetScriptFilePath: scriptFilePath, withArgs: scriptArgs, withPrivilegeLevel: privilegeLevel, withShellType: shellType)
        guard let extractedAScriptText = aScriptText else {
            if let handler = completionHandler {
                handler(.ASEmbedError(code: -1, message: "Unable to embed unix command into AppleScript."), nil)
            }
            return
        }
        guard let aScript = NSAppleScript(source: extractedAScriptText) else {
            if let handler = completionHandler {
                handler(.ASGenError(code: -2, message: "Unable to generate AppleScript from source."), nil)
            }
            return
        }
        execute(targetScript: aScript, completionHandler: completionHandler)
    }
    
    /// Execute AppleScript as text directly.
    ///
    /// - Parameters:
    ///   - scriptText: AppleScript text
    ///   - completionHandler: Handles script completion
    internal func execute(appleScriptText scriptText: String, completionHandler: RequestHandler? = nil) {
        guard let aScript = NSAppleScript(source: scriptText) else {
            if let handler = completionHandler {
                handler(.ASGenError(code: -2, message: "Unable to generate AppleScript from source."), nil)
            }
            return
        }
        execute(targetScript: aScript, completionHandler: completionHandler)
    }
}


// MARK: - Unix script processing & management
extension SwiptCore {
    
    /// Manages script privileges
    ///
    /// - Parameters:
    ///   - aScript: Provided script
    ///   - privilegeLevel: Required privilege level (default = `user`)
    /// - Returns: Updated string representation of the script for AppleScript
    private func manageScriptPrivilege(processingAppleScript aScript: String, withPrivilegeLevel privilegeLevel: Privileges? = .user) -> String {
        var finalScript: String = aScript
        guard let privilege = privilegeLevel else {
            return finalScript
        }
        if privilege == .admin {
            finalScript.append(" \(aSAdminPrivilege)")
        }
        return finalScript
    }
    
    /// Manages input script files
    ///
    /// - Parameters:
    ///   - scriptPath: Path to script
    ///   - scriptArgs: Arguments for script
    ///   - privilegeLevel: Required privilege level (default = `user`)
    ///   - shellType: Choice of shell (default = `/bin/sh`)
    /// - Returns: Updated string representation of the script for AppleScript
    private func convertUnixFileToAppleScript(targetScriptFilePath scriptPath: String, withArgs scriptArgs: [String]? = nil, withPrivilegeLevel privilegeLevel: Privileges? = .user, withShellType shellType: ShellType? = .sh) -> String? {
        var aScript: String = "\(aSSaveTarget) \"\(scriptPath)\"\n"
        var primaryCommand = "\(aSInvokeShell) (\"\((shellType ?? .sh).rawValue) \" & target"
        var argCount = scriptArgs?.count ?? 0, argProcessed = 0
        while argProcessed < argCount {
            aScript.append("set arg\(argProcessed + 1) to quoted form of \"\(scriptArgs![argProcessed])\"\n")
            primaryCommand.append(" & \" \" & arg\(argProcessed + 1)")
            argProcessed += 1
        }
        primaryCommand.append(")")
        aScript.append(primaryCommand)
        return manageScriptPrivilege(processingAppleScript: aScript, withPrivilegeLevel: privilegeLevel)
    }
    
    /// Manages string-based scripts
    ///
    /// - Parameters:
    ///   - script: Script as text
    ///   - privilegeLevel: Required privilege level (default = `user`)
    /// - Returns: Updated string representation of the script for AppleScript
    /// - Note: Take caution when using unix scripts directly as strings, as problems with symbol escaping may prevent AppleScript from correctly executing it.
    private func convertUnixCommandToAppleScript(targetScript script: String, withPrivilegeLevel privilegeLevel: Privileges? = .user) -> String {
        let aScript: String = "\(aSInvokeShell) \"\(script.replacingOccurrences(of: "\"", with: "\\\""))\""
        return manageScriptPrivilege(processingAppleScript: aScript, withPrivilegeLevel: privilegeLevel)
    }
    
}

// MARK: - Multi-threaded, asynchronous, & high-perf workloads
extension SwiptCore {
    
    /// Executes a string representation of unix commands asynchronously and concurrently.
    ///
    /// - Parameters:
    ///   - scriptText: Any `unix` command
    ///   - privilegeLevel: Required privilege level (default = `user`)
    ///   - completionHandler: Handles script completion
    /// - Note: Take caution when using unix scripts directly as strings, as problems with symbol escaping may prevent AppleScript from correctly executing it.
    internal func asyncExecute(unixScriptText scriptText: String, withPrivilegeLevel privilegeLevel: Privileges? = .user, completionHandler: RequestHandler? = nil) {
        queue.async {
            self.execute(unixScriptText: scriptText, withPrivilegeLevel: privilegeLevel, completionHandler: completionHandler)
        }
    }
    
    /// Executes a provided script file asynchronously and concurrently.
    ///
    /// - Parameters:
    ///   - scriptFileName: File path to script
    ///   - scriptArgs: Arguments for script
    ///   - privilegeLevel: Required privilege level (default = `user`)
    ///   - shellType: Choice of shell (default = `/bin/sh`)
    ///   - completionHandler: Handles script completion
    /// - Note: Take caution when using unix scripts that ask for user input on the command line (such as using `read`). This may unexpected halt execution and potentially crash your application.
    internal func asyncExecute(unixScriptPath scriptFilePath: String, withArgs scriptArgs: [String]? = nil, withPrivilegeLevel privilegeLevel: Privileges? = .user, withShellType shellType: ShellType? = .sh, completionHandler: RequestHandler? = nil) {
        queue.async {
            self.execute(unixScriptPath: scriptFilePath, withArgs: scriptArgs, withPrivilegeLevel: privilegeLevel, withShellType: shellType, completionHandler: completionHandler)
        }
    }
    
    /// Execute AppleScript as text directly, asynchronously and concurrently
    ///
    /// - Parameters:
    ///   - scriptText: AppleScript text
    ///   - completionHandler: Handles script completion
    internal func asyncExecute(appleScriptText scriptText: String, completionHandler: RequestHandler? = nil) {
        queue.async {
            self.execute(appleScriptText: scriptText, completionHandler: completionHandler)
        }
    }
    
    /// Executes provided script files asynchronously and concurrently.
    ///
    /// - Parameters:
    ///   - scriptBatch: List of script file paths
    ///   - scriptArgs: List of script args
    ///   - privilegeLevels: List of associated privilege levels
    ///   - shellTypes: List of shell types
    /// - Note: Take caution when using unix scripts that ask for user input on the command line (such as using `read`). This may unexpected halt execution and potentially crash your application.
    internal func execute(serialBatch scriptBatch: [String], withArgs scriptArgs: [[String]?]? = nil, withPrivilegeLevels privilegeLevels: [Privileges?]? = nil, withShellTypes shellTypes: [ShellType?]? = nil) {
        let batchProcessingQueue = DispatchQueue(label: "com.mayank.swipt.batch", qos: .utility)
        batchProcessingQueue.async {
            for index in 0..<scriptBatch.count {
                let scriptFilePath = scriptBatch[index]
                var args = [String]()
                var privilegeLevel = Privileges.user
                var shellType = ShellType.sh
                if let allArgs = scriptArgs {
                    if let currentArgs = allArgs[index] {
                        args = currentArgs
                    }
                }
                if let allPrivilegeLevels = privilegeLevels {
                    if let currentPrivilege = allPrivilegeLevels[index] {
                        privilegeLevel = currentPrivilege
                    }
                }
                if let allShellTypes = shellTypes {
                    if let currentShellType = allShellTypes[index] {
                        shellType = currentShellType
                    }
                }
                self.asyncExecute(unixScriptPath: scriptFilePath, withArgs: args, withPrivilegeLevel: privilegeLevel, withShellType: shellType)
            }
        }
    }
}
