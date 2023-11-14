//
//  DTCollectionViewPrefetchDataSource.swift
//  DTCollectionViewManager
//
//  Created by Denys Telezhkin on 04.10.2022.
//  Copyright © 2022 Denys Telezhkin. All rights reserved.
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

/// Object, that implements `UICollectionViewDataSourcePrefetching` methods for `DTCollectionViewManager`.
open class DTCollectionViewPrefetchDataSource: DTCollectionViewDelegateWrapper, UICollectionViewDataSourcePrefetching {
    
    override func delegateWasReset() {
        collectionView?.prefetchDataSource = nil
        collectionView?.prefetchDataSource = self
    }
    
    /// Implementation for `UICollectionViewDataSourcePrefetching` protocol
    public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        indexPaths.forEach {
            _ = performCellReaction(.prefetchItemsAtIndexPaths, location: $0, provideCell: false)
        }
        (delegate as? UICollectionViewDataSourcePrefetching)?.collectionView(collectionView, prefetchItemsAt: indexPaths)
    }
    
    /// Implementation for `UICollectionViewDataSourcePrefetching` protocol
    public func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        indexPaths.forEach {
            _ = performCellReaction(.cancelPrefetchingForItemsAtIndexPaths, location: $0, provideCell: false)
        }
        (delegate as? UICollectionViewDataSourcePrefetching)?.collectionView?(collectionView, cancelPrefetchingForItemsAt: indexPaths)
    }
}
