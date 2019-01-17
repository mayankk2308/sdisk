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
    
    static var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "SDisk")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                fatalError("Unresolved error \(error)")
            }
        })
        return container
    }()
    
}
