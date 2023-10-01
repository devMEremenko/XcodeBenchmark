//
//  BaseStorage.swift
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
import UIKit

/// Suggested supplementary kind for UITableView header
public let DTTableViewElementSectionHeader = "DTTableViewElementSectionHeader"
/// Suggested supplementary kind for UITableView footer
public let DTTableViewElementSectionFooter = "DTTableViewElementSectionFooter"

/// `BaseSupplementaryStorage` is a base class, that implements common functionality for `SupplementaryStorage` protocol and serves as a base class for `MemoryStorage`, `CoreDataStorage`, `SingleSectionStorage`, `RealmStorage`.
open class BaseSupplementaryStorage: NSObject, SupplementaryStorage {
    
    /// Returns a header model for specified section index or nil.
    open var headerModelProvider: ((Int) -> Any?)?
    
    /// Returns a footer model for specified section index or nil
    open var footerModelProvider: ((Int) -> Any?)?

    private lazy var _supplementaryModelProvider: ((String, IndexPath) -> Any?)? = { [weak self] kind, indexPath in
        if let headerModel = self?.headerModelProvider, self?.supplementaryHeaderKind == kind {
            return headerModel(indexPath.section)
        }
        if let footerModel = self?.footerModelProvider, self?.supplementaryFooterKind == kind {
            return footerModel(indexPath.section)
        }
        return nil
    }
    
    /// Returns supplementary model for specified section indexPath and supplementary kind, or nil. Setter for this property is overridden to allow calling `headerModelProvider` and `footerModelProvider` closures.
    open var supplementaryModelProvider: ((String, IndexPath) -> Any?)? {
        get {
            return _supplementaryModelProvider
        }
        set {
            _supplementaryModelProvider = { [weak self] kind, indexPath in
                if let headerModel = self?.headerModelProvider, self?.supplementaryHeaderKind == kind {
                    return headerModel(indexPath.section)
                }
                if let footerModel = self?.footerModelProvider, self?.supplementaryFooterKind == kind {
                    return footerModel(indexPath.section)
                }
                return newValue?(kind, indexPath)
            }
        }
    }
    
    /// Supplementary kind for header in current storage
    open var supplementaryHeaderKind: String?
    
    /// Supplementary kind for footer in current storage
    open var supplementaryFooterKind: String?
}

/// `StorageUpdating` protocol is used to transfer data storage updates.
public protocol StorageUpdating : AnyObject
{
    /// Transfers data storage updates.
    ///
    /// Object, that implements this method, may react to received update by updating UI for current storage.
    func storageDidPerformUpdate(_ update: StorageUpdate)
    
    /// Method is called when UI needs to be fully updated for data storage changes.
    func storageNeedsReloading()
}

/// Base class for storage classes
open class BaseUpdateDeliveringStorage: BaseSupplementaryStorage
{
    /// Current update
    open var currentUpdate: StorageUpdate?
    
    /// Batch updates are in progress. If true, update will not be finished.
    open var batchUpdatesInProgress = false
    
    /// Delegate for storage updates
    open weak var delegate: StorageUpdating?
    
    /// Performs update `block` in storage. After update is finished, delegate will be notified.
    /// Parameter block: Block to execute
    /// - Note: This method allows to execute several updates in a single batch. It is similar to UICollectionView method `performBatchUpdates:`.
    /// - Warning: Performing mutually exclusive updates inside block can cause application crash.
    open func performUpdates( _ block: () -> Void) {
        batchUpdatesInProgress = true
        startUpdate()
        block()
        batchUpdatesInProgress = false
        finishUpdate()
    }
    
    /// Starts update in storage. 
    ///
    /// This creates StorageUpdate instance and stores it into `currentUpdate` property.
    open func startUpdate(){
        if self.currentUpdate == nil {
            self.currentUpdate = StorageUpdate()
        }
    }
    
    /// Finishes update. 
    ///
    /// Method verifies, that update is not empty, and sends updates to the delegate. After this method finishes, `currentUpdate` property is nilled out.
    open func finishUpdate()
    {
        guard batchUpdatesInProgress == false else { return }
        defer { currentUpdate = nil }
        if let update = currentUpdate {
            if update.isEmpty {
                return
            }
            delegate?.storageDidPerformUpdate(update)
        }
    }
}
