//
//  SDTaskManager.swift
//  SDisk
//
//  Created by Mayank Kumar on 1/18/19.
//  Copyright © 2019 Mayank Kumar. All rights reserved.
//

import Foundation
import CoreData

/// Manages scheduled tasks for disks with persistence.
class SDTaskManager {
    
    /// Stores all disk-mapped tasks.
    var tasks = [SDTask]()
    
    private static var instance: SDTaskManager?
    private let managedContext = CDS.persistentContainer.viewContext
    
    /// Singleton object for `SDTaskManager`.
    static var shared: SDTaskManager {
        guard let prevInstance = instance else {
            instance = SDTaskManager()
            return instance!
        }
        return prevInstance
    }
    
    /// Adds a task to the application database.
    ///
    /// - Parameters:
    ///   - diskName: Name of the disk.
    ///   - taskType: Type of task.
    ///   - script: Script to execute.
    func addTask(withDiskName diskName: String, withTaskType taskType: TaskType, withTaskScript script: String) {
        let task = SDTask(context: managedContext)
        task.diskName = diskName
        task.taskLog = nil
        task.taskScript = script
        task.taskType = Int16(taskType.rawValue)
        saveContext {
            tasks.append(task)
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
    
    func removeTask(_ task: SDTask) {
        guard let index = tasks.index(of: task) else { return }
        managedContext.delete(tasks[index])
        saveContext {
            tasks.remove(at: index)
        }
    }
    
    /// Persist data changes made to container.
    ///
    /// - Parameter task: Perform any additional task if saving succeeds.
    private func saveContext(andDoTask task: () -> Void) {
        do {
            try managedContext.save()
            task()
        } catch {
            print("Could not save.")
        }
    }
    
}
