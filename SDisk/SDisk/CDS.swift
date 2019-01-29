//
//  CDS.swift
//  SDisk
//
//  Created by Mayank Kumar on 1/17/19.
//  Copyright © 2019 Mayank Kumar. All rights reserved.
//

import CoreData
import Foundation

/// Defines the base `CoreData` stack.
class CDS {
    
    /// Reference to the CoreData peristent container.
    static var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "SDisk")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                fatalError("Unresolved error \(error)")
            }
        })
        return container
    }()
    
    /// Persist data changes made to container.
    ///
    /// - Parameter task: Perform any additional task if saving succeeds.
    static func saveContext(andDoTask task: (() -> Void)? = nil) {
        do {
            try persistentContainer.viewContext.save()
            guard let handler = task else { return }
            handler()
        } catch {
            print("Could not save.")
        }
    }
    
}
