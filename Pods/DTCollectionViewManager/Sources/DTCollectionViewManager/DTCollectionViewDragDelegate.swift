//
//  DTCollectionViewDragDelegate.swift
//  DTCollectionViewManager
//
//  Created by Denys Telezhkin on 01.09.17.
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
    
/// Object, that implements `UICollectionViewDragDelegate` methods for `DTCollectionViewManager`.
open class DTCollectionViewDragDelegate : DTCollectionViewDelegateWrapper, UICollectionViewDragDelegate {
    override func delegateWasReset() {
        collectionView?.dragDelegate = nil
        collectionView?.dragDelegate = self
    }
    
    /// Implementation of `UICollectionViewDragDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        if let items = perform4ArgumentCellReaction(.itemsForBeginningDragSessionAtIndexPath,
                                                    argument: session,
                                                    location: indexPath,
                                                    provideCell: true) as? [UIDragItem]
        {
            return items
        }
        return (delegate as? UICollectionViewDragDelegate)?.collectionView(collectionView, itemsForBeginning: session, at:indexPath) ?? []
    }
    
    /// Implementation of `UICollectionViewDragDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        if let items = perform5ArgumentCellReaction(.itemsForAddingToDragSessionAtIndexPath,
                                                    argumentOne: session,
                                                    argumentTwo: point,
                                                    location: indexPath,
                                                    provideCell: true) as? [UIDragItem] {
            return items
        }
        return (delegate as? UICollectionViewDragDelegate)?.collectionView?(collectionView, itemsForAddingTo: session, at: indexPath, point: point) ?? []
    }
    
    /// Implementation of `UICollectionViewDragDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        if let reaction = cellReaction(.dragPreviewParametersForItemAtIndexPath, location: indexPath) {
            return performNillableCellReaction(reaction, location: indexPath, provideCell: true) as? UIDragPreviewParameters
        }
        return (delegate as? UICollectionViewDragDelegate)?.collectionView?(collectionView, dragPreviewParametersForItemAt: indexPath)
    }
    
    /// Implementation of `UICollectionViewDragDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, dragSessionWillBegin session: UIDragSession) {
        _ = performNonCellReaction(.dragSessionWillBegin, argument: session)
        (delegate as? UICollectionViewDragDelegate)?.collectionView?(collectionView, dragSessionWillBegin: session)
    }
    
    /// Implementation of `UICollectionViewDragDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, dragSessionDidEnd session: UIDragSession) {
        _ = performNonCellReaction(.dragSessionDidEnd, argument: session)
        (delegate as? UICollectionViewDragDelegate)?.collectionView?(collectionView, dragSessionDidEnd: session)
    }
    
    /// Implementation of `UICollectionViewDragDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, dragSessionAllowsMoveOperation session: UIDragSession) -> Bool {
        if let allows = performNonCellReaction(.dragSessionAllowsMoveOperation, argument: session) as? Bool {
            return allows
        }
        return (delegate as? UICollectionViewDragDelegate)?.collectionView?(collectionView, dragSessionAllowsMoveOperation: session) ?? true
    }
    
    /// Implementation of `UICollectionViewDragDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, dragSessionIsRestrictedToDraggingApplication session: UIDragSession) -> Bool {
        if let allows = performNonCellReaction(.dragSessionIsRestrictedToDraggingApplication, argument: session) as? Bool {
            return allows
        }
        return (delegate as? UICollectionViewDragDelegate)?.collectionView?(collectionView, dragSessionIsRestrictedToDraggingApplication: session) ?? false
    }
}
    
#endif
