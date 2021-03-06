//
//  SDTaskManager.swift
//  SDisk
//
//  Created by Mayank Kumar on 1/18/19.
//  Copyright © 2019 Mayank Kumar. All rights reserved.
//

import Foundation
import CoreData
import Swipt

/// Manages scheduled tasks for disks with persistence.
class SDTaskManager {
    
    /// Stores all disk-mapped tasks.
    var tasks = [SDTask]()
    
    private let managedContext = CDS.persistentContainer.viewContext
    private let swiptManager = SwiptManager()
    
    /// Perform necessary actions for updating the user interface.
    var userInterfaceHandler: ((SDTask) -> Void)?
    
    /// Singleton object for `SDTaskManager`.
    static var shared = SDTaskManager()
    
    private let dateFormatter = DateFormatter()
    
    /// Retrieve current timestamp by timezone.
    var currentTimeStamp: String {
        let now = Date()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSS Z"
        return "[\(dateFormatter.string(from: now))]"
    }
    
    /// Adds a task to the application database.
    ///
    /// - Parameters:
    ///   - diskName: Name of the disk.
    ///   - taskType: Type of task.
    ///   - script: Script to execute.
    func addTask(withDisk disk: Disk, withTaskType type: TaskType, withTaskScript script: String, withTaskLanguage language: TaskLanguage) {
        let task = SDTask(context: managedContext)
        task.targetDisk = disk
        disk.associatedTask = task
        task.taskLog = nil
        task.taskScript = script
        task.taskType = type.rawValue
        task.taskLanguage = language.rawValue
        CDS.saveContext {
            self.tasks.append(task)
        }
    }
    
    /// Retrieves all persisted tasks.
    func fetchTasks() {
        let fetchRequest = NSFetchRequest<SDTask>(entityName: "SDTask")
        do {
            tasks = try managedContext.fetch(fetchRequest)
        } catch {
            print("Could not fetch.")
        }
    }
    
    /// Removes specified task.
    ///
    /// - Parameter task: `SDTask` to remove.
    func removeTask(_ task: SDTask) {
        guard let index = tasks.firstIndex(of: task) else { return }
        managedContext.delete(tasks[index])
        CDS.saveContext {
            self.tasks.remove(at: index)
        }
    }
    
    /// Remove all queued tasks.
    func removeAllTasks() {
        for task in tasks {
            managedContext.delete(task)
        }
        CDS.saveContext {
            self.tasks.removeAll()
        }
    }
    
    /// Perform specified task based on disk name.
    ///
    /// - Parameters:
    ///   - diskUUID: Target disk name.
    ///   - taskCompletionHandler: Handle task after completion.
    func performTasks(forDiskUUID diskUUID: UUID, withTaskType type: TaskType, handler: @escaping (SDTask) -> Void) {
        for task in tasks where task.targetDisk?.uniqueID == diskUUID && task.taskType == type.rawValue {
            if TaskLanguage(rawValue: task.taskLanguage) == .bash {
                swiptManager.asyncExecute(unixScriptText: task.taskScript ?? "echo \"No script provided.\"") { error, result in
                    self.perTaskCompletionHandler(task: task, error: error, result: result, handler: handler)
                }
            } else if TaskLanguage(rawValue: task.taskLanguage) == .appleScript {
                swiptManager.asyncExecute(appleScriptText: task.taskScript ?? "echo \"No script provided.\"") { error, result in
                    self.perTaskCompletionHandler(task: task, error: error, result: result, handler: handler)
                }
            }
        }
    }
    
    /// A generic completion handler to generate essential logs.
    ///
    /// - Parameters:
    ///   - task: The `SDTask`
    ///   - error: Error, if any.
    ///   - result: Result of script execution.
    ///   - handler: Escaping handler with a reference to the task.
    private func perTaskCompletionHandler(task: SDTask, error: SwiptError?, result: String?, handler: @escaping (SDTask) -> Void) {
        task.taskLog = "\(currentTimeStamp)\nOutput:\n\(result ?? "None")\n\nErrors:\n\((error == nil ? "None" : String(describing: error!)) + "\n\n\(task.taskLog ?? "")")"
        CDS.saveContext()
        handler(task)
    }
    
    /// Executes the user interface handler, if provided.
    ///
    /// - Parameter task: Passthrough `Task`.
    func executeUIHandler(withTask task: SDTask) {
        guard let handler = userInterfaceHandler else { return }
        handler(task)
    }
}
