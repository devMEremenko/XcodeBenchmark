//
//  DTCollectionViewDropPlaceholderContext.swift
//  DTCollectionViewManager
//
//  Created by Denys Telezhkin on 02.09.17.
//  Copyright © 2017 Denys Telezhkin. All rights reserved.
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
import DTModelStorage

#if os(iOS)
    
/// Thin wrapper around `UICollectionViewDropPlaceholderContext`, which automates insertion of `dragItems` if you are using `MemoryStorage`.
/// Typically, you would not create this class directly, but use `DTCollectionViewManager.drop(_:to:with:)` convenience method.
open class DTCollectionViewDropPlaceholderContext {
    
    /// Drop context
    public let context : UICollectionViewDropPlaceholderContext
    
    /// Storage, on which drop operation is performed
    weak var storage: Storage?
    
    /// Creates `DTCollectionViewDropPlaceholderContext` with `context` and `storage`
    public init(context: UICollectionViewDropPlaceholderContext, storage: Storage) {
        self.context = context
        self.storage = storage
    }
    
    /// Commits insertion of item, using `UICollectionViewDropPlaceholderContext.commitInsertion(_:)` method. Both commit and `insertionIndexPathClosure` will be automatically dispatched to `DispatchQueue.main`.
    /// If you are using `MemoryStorage`, model will be automatically inserted, and no additional actions are required.
    open func commitInsertion<T>(ofItem item: T, _ insertionIndexPathClosure: ((IndexPath) -> Void)? = nil) {
        DispatchQueue.main.async { [weak self] in
            self?.context.commitInsertion { insertionIndexPath in
                guard let storage = self?.storage else { return }
                if let storage = storage as? MemoryStorage,
                    let section = storage.section(atIndex: insertionIndexPath.section),
                    section.items.count >= insertionIndexPath.item
                {
                    section.items.insert(item, at: insertionIndexPath.row)
                }
                insertionIndexPathClosure?(insertionIndexPath)
            }
        }
    }
    
    @discardableResult
    /// Convenience method to call `context.deletePlaceholder`.
    open func deletePlaceholder() -> Bool {
        return context.deletePlaceholder()
    }
}
#endif
