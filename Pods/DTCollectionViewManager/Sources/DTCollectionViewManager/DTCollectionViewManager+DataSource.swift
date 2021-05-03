//
//  DTCollectionViewManager+DataSource.swift
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

import UIKit
import DTModelStorage

extension DTCollectionViewManager {
    /// Registers `closure` to be executed, when `UICollectionViewDataSource.collectionView(_:canMoveItemAt:)` method is called for `cellClass`.
    open func canMove<Cell:ModelTransfer>(_ cellClass:Cell.Type, _ closure: @escaping (Cell, Cell.ModelType, IndexPath) -> Bool) where Cell: UICollectionViewCell
    {
        collectionDataSource?.appendReaction(for: Cell.self, signature: EventMethodSignature.canMoveItemAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDataSrouce.(_:moveItemAt:to:)` method is called for `cellClass`.
    /// - warning: This method requires items to be moved without animations, since animation has already happened when user moved those cells. If you use `MemoryStorage`, it's appropriate to call `memoryStorage.moveItemWithoutAnimation(from:to:)` method to achieve desired behavior.
    /// - SeeAlso: 'collectionView:moveRowAt:to:' method
    open func moveItemAtTo(_ closure: @escaping (_ sourceIndexPath: IndexPath, _ destinationIndexPath: IndexPath) -> Void)
    {
        collectionDataSource?.appendNonCellReaction(.moveItemAtIndexPathToIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDataSource.indexTitlesForCollectionView(_:)` method is called.
    open func indexTitles(_ closure: @escaping () -> [String]?) {
        collectionDataSource?.appendNonCellReaction(.indexTitlesForCollectionView, closure: closure)
    }
    
    /// Registers `closure` to be executed when `UICollectionViewDataSource.collectionView(_:indexPathForIndexTitle:)` method is called.
    open func indexPathForIndexTitle(_ closure: @escaping (String, Int) -> IndexPath) {
        collectionDataSource?.appendNonCellReaction(.indexPathForIndexTitleAtIndex, closure: closure)
    }
}

extension ViewModelMapping where View : UICollectionViewCell {
    /// Registers `closure` to be executed, when `UICollectionViewDataSource.collectionView(_:canMoveItemAt:)` method is called.
    open func canMove(_ closure: @escaping (View, Model, IndexPath) -> Bool)
    {
        reactions.append(EventReaction(viewType: View.self, modelType: Model.self, signature: EventMethodSignature.canMoveItemAtIndexPath.rawValue, closure))
    }
}
