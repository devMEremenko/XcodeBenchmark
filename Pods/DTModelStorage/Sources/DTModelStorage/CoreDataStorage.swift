//
//  CoreDataStorage.swift
//  DTModelStorage
//
//  Created by Denys Telezhkin on 06.07.15.
//  Copyright (c) 2015 Denys Telezhkin. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import CoreData
import UIKit

/// This class represents model storage in CoreData
/// It uses NSFetchedResultsController to monitor all changes in CoreData and automatically notify delegate of any changes
open class CoreDataStorage<T: NSFetchRequestResult> : BaseUpdateDeliveringStorage, Storage, NSFetchedResultsControllerDelegate
{
    /// Fetched results controller of storage
    public let fetchedResultsController: NSFetchedResultsController<T>
    
    /// Initialize CoreDataStorage with NSFetchedResultsController
    /// - Parameter fetchedResultsController: fetch results controller
    public init(fetchedResultsController: NSFetchedResultsController<T>)
    {
        self.fetchedResultsController = fetchedResultsController
        super.init()
        self.fetchedResultsController.delegate = self
        headerModelProvider = { index in
            if let sections = self.fetchedResultsController.sections
            {
                return sections[index].name
            }
            return nil
        }
    }
    
    /// Returns number of sections in storage.
    open func numberOfSections() -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    /// Returns number of items in a given section
    /// - Parameter section: given section.
    open func numberOfItems(inSection section: Int) -> Int {
        if (fetchedResultsController.sections?.count ?? 0) > section {
            return fetchedResultsController.sections?[section].numberOfObjects ?? 0
        }
        return 0
    }
    
    // MARK: - Storage
    
    /// Retrieve object at index path from `CoreDataStorage`
    /// - Parameter indexPath: IndexPath for object
    /// - Returns: model at indexPath or nil, if item not found
    open func item(at indexPath: IndexPath) -> Any? {
        return fetchedResultsController.object(at: indexPath)
    }
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    /// NSFetchedResultsController is about to start changing content - we'll start monitoring for updates.
    @objc open func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.startUpdate()
    }
    
    /// React to specific change in NSFetchedResultsController
    @objc open func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?)
    {
        switch type
        {
        case .insert:
            if let new = newIndexPath {
                currentUpdate?.objectChanges.append((.insert, [new]))
            }
        case .delete:
            if let indexPath = indexPath {
                currentUpdate?.objectChanges.append((.delete, [indexPath]))
            }
        case .move:
            if let indexPath = indexPath, let newIndexPath = newIndexPath {
                if indexPath != newIndexPath {
                    currentUpdate?.objectChanges.append((.delete, [indexPath]))
                    currentUpdate?.objectChanges.append((.insert, [newIndexPath]))
                } else {
                    currentUpdate?.objectChanges.append((.update, [indexPath]))
                    currentUpdate?.updatedObjects[indexPath] = anObject
                }
            }
        case .update:
            if let indexPath = indexPath {
                if let newIndexPath = newIndexPath, indexPath != newIndexPath {
                    currentUpdate?.objectChanges.append((.delete, [indexPath]))
                    currentUpdate?.objectChanges.append((.insert, [newIndexPath]))
                } else {
                    currentUpdate?.objectChanges.append((.update, [indexPath]))
                    currentUpdate?.updatedObjects[indexPath] = anObject
                }
            }
        default: ()
        }
    }
    
    
    @objc
    /// React to changed section in NSFetchedResultsController. 
    open func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType)
    {
        switch type {
        case .insert:
            currentUpdate?.sectionChanges.append((.insert, [sectionIndex]))
        case .delete:
            currentUpdate?.sectionChanges.append((.delete, [sectionIndex]))
        case .update:
            currentUpdate?.sectionChanges.append((.update, [sectionIndex]))
        default: ()
        }
    }
    
    /// Finish update from NSFetchedResultsController
    @objc open func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.finishUpdate()
    }
}
