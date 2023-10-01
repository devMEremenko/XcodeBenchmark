//
//  DTCollectionViewManager+Drop.swift
//  DTCollectionViewManager
//
//  Created by Denys Telezhkin on 27.08.17.
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

/// Extension for UICollectionViewDropDelegate events
public extension DTCollectionViewManager {
    
    #if os(iOS)
    
    /// Registers `closure` to be executed when `UICollectionViewDropDelegate.collectionView(_:performDropWith:)` method is called.
    func performDropWithCoordinator(_ closure: @escaping (UICollectionViewDropCoordinator) -> Void) {
        collectionDropDelegate?.appendNonCellReaction(.performDropWithCoordinator, closure: closure)
    }
    
    /// Registers `closure` to be executed when `UICollectionViewDropDelegate.collectionView(_:canHandle:)` method is called.
    func canHandleDropSession(_ closure: @escaping (UIDropSession) -> Bool) {
        collectionDropDelegate?.appendNonCellReaction(.canHandleDropSession, closure: closure)
    }
    
    /// Registers `closure` to be executed when `UICollectionViewDropDelegate.collectionView(_:dropSessionDidEnter:)` method is called.
    func dropSessionDidEnter(_ closure: @escaping (UIDropSession) -> Void) {
        collectionDropDelegate?.appendNonCellReaction(.dropSessionDidEnter, closure: closure)
    }
    
    /// Registers `closure` to be executed when `UICollectionViewDropDelegate.collectionView(_:dropSessionDidUpdate:withDestination:)` method is called.
    func dropSessionDidUpdate(_ closure: @escaping (UIDropSession, IndexPath?) -> UICollectionViewDropProposal) {
        collectionDropDelegate?.appendNonCellReaction(.dropSessionDidUpdate, closure: closure)
    }
    
    /// Registers `closure` to be executed when `UICollectionViewDropDelegate.collectionView(_:dropSessionDidExit:)` method is called.
    func dropSessionDidExit(_ closure: @escaping (UIDropSession) -> Void) {
        collectionDropDelegate?.appendNonCellReaction(.dropSessionDidExit, closure: closure)
    }
    
    /// Registers `closure` to be executed when `UICollectionViewDropDelegate.collectionView(_:dropSessionDidEnd:)` method is called.
    func dropSessionDidEnd(_ closure: @escaping (UIDropSession) -> Void) {
        collectionDropDelegate?.appendNonCellReaction(.dropSessionDidEnd, closure: closure)
    }
    
    /// Registers `closure` to be executed when `UICollectionViewDropDelegate.collectionView(_:dropPreviewParametersForRowAt:)` method is called.
    func dropPreviewParameters(_ closure: @escaping (IndexPath) -> UIDragPreviewParameters?) {
        collectionDropDelegate?.appendNonCellReaction(.dropPreviewParametersForItemAtIndexPath, closure: closure)
    }
    
    /// Convenience method for dropping `item` into `placeholder`.
    /// Returns `DTCollectionViewDropPlaceholderContext`, which is a replacement for `UICollectionViewDropPlaceholderContext`, that automatically handles drop if you are using `MemoryStorage`. It also automatically dispatches insertion to `DispatchQueue.main`.
    func drop(_ item: UIDragItem, to placeholder: UICollectionViewDropPlaceholder,
                   with coordinator: UICollectionViewDropCoordinator) -> DTCollectionViewDropPlaceholderContext {
        let context = coordinator.drop(item, to: placeholder)
        return DTCollectionViewDropPlaceholderContext(context: context, storage: storage)
    }
    
    #endif
}
