//
//  DTCollectionViewManager+Drag.swift
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

extension DTCollectionViewManager {
    
    #if os(iOS)
    
    /// Registers `closure` to be executed when `UICollectionViewDragDelegate.collectionView(_:itemsForBeginning:at:)` method is called for `cellClass`.
    open func itemsForBeginningDragSession<Cell:ModelTransfer>(from cellClass: Cell.Type, _ closure: @escaping (UIDragSession, Cell, Cell.ModelType, IndexPath) -> [UIDragItem]) where Cell:UICollectionViewCell
    {
        collectionDragDelegate?.append4ArgumentReaction(for: Cell.self,
                                                   signature: .itemsForBeginningDragSessionAtIndexPath,
                                                   closure: closure)
    }
    
    /// Registers `closure` to be executed when `UICollectionViewDragDelegate.collectionView(_:itemsForAddingTo:at:point:)` method is called for `cellClass`
    open func itemsForAddingToDragSession<Cell:ModelTransfer>(from cellClass: Cell.Type, _ closure: @escaping (UIDragSession, CGPoint, Cell, Cell.ModelType, IndexPath) -> [UIDragItem]) where Cell: UICollectionViewCell
    {
        collectionDragDelegate?.append5ArgumentReaction(for: Cell.self,
                                                   signature: .itemsForAddingToDragSessionAtIndexPath,
                                                   closure: closure)
    }
    
    /// Registers `closure` to be executed when `UICollectionViewDragDelegate.collectionView(_:dragPreviewParametersForRowAt:)` method is called for `cellClass`
    open func dragPreviewParameters<Cell:ModelTransfer>(for cellClass: Cell.Type, _ closure: @escaping (Cell, Cell.ModelType, IndexPath) -> UIDragPreviewParameters?) where Cell:UICollectionViewCell {
        collectionDragDelegate?.appendReaction(for: Cell.self,
                                          signature: .dragPreviewParametersForItemAtIndexPath,
                                          closure: closure)
    }
    
    /// Registers `closure` to be executed when `UICollectionViewDragDelegate.collectionView(_:dragSessionWillBegin:)` method is called.
    open func dragSessionWillBegin(_ closure: @escaping (UIDragSession) -> Void) {
        collectionDragDelegate?.appendNonCellReaction(.dragSessionWillBegin, closure: closure)
    }
    
    /// Registers `closure` to be executed when `UICollectionViewDragDelegate.collectionView(_:dragSessionDidEnd:)` method is called.
    open func dragSessionDidEnd(_ closure: @escaping (UIDragSession) -> Void) {
        collectionDragDelegate?.appendNonCellReaction(.dragSessionDidEnd, closure: closure)
    }
    
    /// Registers `closure` to be executed when `UICollectionViewDragDelegate.collectionView(_:dragSessionAllowsMoveOperation)` method is called.
    open func dragSessionAllowsMoveOperation(_ closure: @escaping (UIDragSession) -> Bool) {
        collectionDragDelegate?.appendNonCellReaction(.dragSessionAllowsMoveOperation, closure: closure)
    }
    
    /// Registers `closure` to be executed when `UICollectionViewDragDelegate.collectionView(_:dragSessionIsRestrictedToDraggingApplication:)` method is called.
    open func dragSessionIsRestrictedToDraggingApplication(_ closure: @escaping (UIDragSession) -> Bool) {
        collectionDragDelegate?.appendNonCellReaction(.dragSessionIsRestrictedToDraggingApplication, closure: closure)
    }
    #endif
}

extension ViewModelMapping where View: UICollectionViewCell {
    #if os(iOS)
    /// Registers `closure` to be executed when `UICollectionViewDragDelegate.collectionView(_:itemsForBeginning:at:)` method is called.
    open func itemsForBeginningDragSession(_ closure: @escaping (UIDragSession, View, Model, IndexPath) -> [UIDragItem])
    {
        reactions.append(FourArgumentsEventReaction(View.self, modelType: Model.self, argument: UIDragSession.self,
                                                    signature: EventMethodSignature.itemsForBeginningDragSessionAtIndexPath.rawValue,
                                                    closure))
    }
    
    /// Registers `closure` to be executed when `UICollectionViewDragDelegate.collectionView(_:itemsForAddingTo:at:point:)` method is called.
    open func itemsForAddingToDragSession(_ closure: @escaping (UIDragSession, CGPoint, View, Model, IndexPath) -> [UIDragItem])
    {
        reactions.append(FiveArgumentsEventReaction(View.self, modelType: Model.self, argumentOne: UIDragSession.self, argumentTwo: CGPoint.self,
                                                    signature: EventMethodSignature.itemsForAddingToDragSessionAtIndexPath.rawValue,
                                                    closure))
    }
    
    /// Registers `closure` to be executed when `UICollectionViewDragDelegate.collectionView(_:dragPreviewParametersForRowAt:)` method is called.
    open func dragPreviewParameters(_ closure: @escaping (View, Model, IndexPath) -> UIDragPreviewParameters?) where View:UICollectionViewCell {
        reactions.append(EventReaction(viewType: View.self, modelType: Model.self,
                                       signature: EventMethodSignature.dragPreviewParametersForItemAtIndexPath.rawValue,
                                       closure))
    }
    #endif
}
