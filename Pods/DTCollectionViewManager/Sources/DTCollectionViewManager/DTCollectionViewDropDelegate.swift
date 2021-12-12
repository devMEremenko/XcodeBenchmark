//
//  DTCollectionViewDropDelegate.swift
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
    
/// Object, that implements `UICollectionViewDropDelegate` methods for `DTCollectionViewManager`.
open class DTCollectionViewDropDelegate : DTCollectionViewDelegateWrapper, UICollectionViewDropDelegate {
    override func delegateWasReset() {
        // Currently, in Xcode 10, 11, 12, this resetting of the delegate is unnecessary and causes super weird interactions with UICollectionViewDropDelegate methods such as invalidating UICollectionView layouts all the time while drop session is in progress.
        
//        collectionView?.dropDelegate = nil
//        collectionView?.dropDelegate = self
    }
    
    /// Implementation of `UICollectionViewDropDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        _ = performNonCellReaction(.performDropWithCoordinator, argument: coordinator)
        (delegate as? UICollectionViewDropDelegate)?.collectionView(collectionView, performDropWith: coordinator)
    }
    
    /// Implementation of `UICollectionViewDropDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        if let canHandle = performNonCellReaction(.canHandleDropSession, argument: session) as? Bool {
            return canHandle
        }
        return (delegate as? UICollectionViewDropDelegate)?.collectionView?(collectionView, canHandle: session) ?? true
    }
    
    /// Implementation of `UICollectionViewDropDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, dropSessionDidEnter session: UIDropSession) {
        _ = performNonCellReaction(.dropSessionDidEnter, argument: session)
        (delegate as? UICollectionViewDropDelegate)?.collectionView?(collectionView, dropSessionDidEnter: session)
    }
    
    /// Implementation of `UICollectionViewDropDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if let proposal = performNonCellReaction(.dropSessionDidUpdate,
                                                 argumentOne: session,
                                                 argumentTwo: destinationIndexPath) as? UICollectionViewDropProposal {
            return proposal
        }
        return (delegate as? UICollectionViewDropDelegate)?.collectionView?(collectionView,
                                                                  dropSessionDidUpdate: session,
                                                                  withDestinationIndexPath: destinationIndexPath) ?? UICollectionViewDropProposal(operation: .cancel)
    }
    
    /// Implementation of `UICollectionViewDropDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, dropSessionDidExit session: UIDropSession) {
        _ = performNonCellReaction(.dropSessionDidExit, argument: session)
        (delegate as? UICollectionViewDropDelegate)?.collectionView?(collectionView, dropSessionDidExit: session)
    }
    
    /// Implementation of `UICollectionViewDropDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, dropSessionDidEnd session: UIDropSession) {
        _ = performNonCellReaction(.dropSessionDidEnd, argument: session)
        (delegate as? UICollectionViewDropDelegate)?.collectionView?(collectionView, dropSessionDidEnd: session)
    }
    
    /// Implementation of `UICollectionViewDropDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, dropPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        if let reaction = unmappedReactions.first(where: { $0.methodSignature == EventMethodSignature.dropPreviewParametersForItemAtIndexPath.rawValue }) {
            return reaction.performWithArguments((indexPath, 0, 0)) as? UIDragPreviewParameters
        }
        return (delegate as? UICollectionViewDropDelegate)?.collectionView?(collectionView,
                                                                  dropPreviewParametersForItemAt: indexPath)
    }
}
    
#endif
