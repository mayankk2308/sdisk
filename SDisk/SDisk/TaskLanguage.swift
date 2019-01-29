//
//  TaskLanguage.swift
//  SDisk
//
//  Created by Mayank Kumar on 1/18/19.
//  Copyright © 2019 Mayank Kumar. All rights reserved.
//

import Foundation

/// Describes available environments for tasks.
///
/// - bash: For shell scripts.
/// - appleScript: For AppleScript configurations.
enum TaskLanguage: Int16 {
    case bash = 1, appleScript = 2
}
