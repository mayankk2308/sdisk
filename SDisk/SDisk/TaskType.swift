//
//  TaskType.swift
//  SDisk
//
//  Created by Mayank Kumar on 1/17/19.
//  Copyright © 2019 Mayank Kumar. All rights reserved.
//

import Foundation

/// Defines the type of task.
///
/// - onMount: For tasks that should execute on disk mounts.
/// - periodic: For tasks that should execute periodically while disk is mounted.
/// - onUnmount: For tasks that should execute on disk unmounts.
enum TaskType: Int16 {
    case onMount = 1, periodic = 2, onUnmount = 3
}
