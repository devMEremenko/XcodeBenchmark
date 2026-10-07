//
//  DTCollectionViewDataSource.swift
//  DTCollectionViewManager
//
//  Created by Denys Telezhkin on 13.08.17.
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

// swiftlint:disable:next type_name
class DummyCollectionViewCellThatPreventsAppFromCrashing: UICollectionViewCell {}

/// Object, that implements `UICollectionViewDataSource` methods for `DTCollectionViewManager`.
open class DTCollectionViewDataSource: DTCollectionViewDelegateWrapper, UICollectionViewDataSource {
    override func delegateWasReset() {
        if collectionView?.dataSource === self {
            collectionView?.dataSource = nil
            collectionView?.dataSource = self
        }
    }
    
    private func dummyCell(for indexPath: IndexPath) -> UICollectionViewCell {
        let identifier =  String(describing: type(of: DummyCollectionViewCellThatPreventsAppFromCrashing.self))
        collectionView?.register(DummyCollectionViewCellThatPreventsAppFromCrashing.self,
                                 forCellWithReuseIdentifier: identifier)
        return collectionView?.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) ?? UICollectionViewCell()
    }
    
    /// Implementation of `UICollectionViewDataSource` protocol.
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return storage?.numberOfItems(inSection: section) ?? 0
    }
    
    /// Implementation of `UICollectionViewDataSource` protocol.
    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        return storage?.numberOfSections() ?? 0
    }
    
    /// Implementation of `UICollectionViewDataSource` protocol.
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let model = RuntimeHelper.recursivelyUnwrapAnyValue(storage?.item(at: indexPath) as Any) else {
            manager?.anomalyHandler.reportAnomaly(.nilCellModel(indexPath))
            return dummyCell(for: indexPath)
        }
        guard let cell = viewFactory?.cellForModel(model, atIndexPath: indexPath) else {
            return dummyCell(for: indexPath)
        }
        _ = EventReaction.performReaction(from: viewFactory?.mappings ?? [],
                                                    signature: EventMethodSignature.configureCell.rawValue,
                                                    view: cell,
                                                    model: model,
                                                    location: indexPath)
        return cell
    }
    
    /// Implementation of `UICollectionViewDataSource` protocol.
    open func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView
    {
        guard let model = supplementaryModel(ofKind: kind, forSectionAt: indexPath) else {
            manager?.anomalyHandler.reportAnomaly(DTCollectionViewManagerAnomaly.nilSupplementaryModel(kind: kind, indexPath: indexPath))
            return UICollectionReusableView()
        }
        guard let view = viewFactory?.supplementaryViewOfKind(kind, forModel: model, atIndexPath: indexPath) else {
            return UICollectionReusableView()
        }
        _ = EventReaction.performReaction(from: viewFactory?.mappings ?? [],
                                                    signature: EventMethodSignature.configureSupplementary.rawValue,
                                                    view: view,
                                                    model: model,
                                                    location: indexPath,
                                                    supplementaryKind: kind)
        return view
    }
    
    /// Implementation of `UICollectionViewDataSource` protocol.
    open func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        if let can = performCellReaction(.canMoveItemAtIndexPath, location: indexPath, provideCell: true) as? Bool {
            return can
        }
        return (delegate as? UICollectionViewDataSource)?.collectionView?(collectionView, canMoveItemAt: indexPath) ?? true
    }
    
    /// Implementation of `UICollectionViewDataSource` protocol.
    open func collectionView(_ collectionView: UICollectionView, moveItemAt source: IndexPath, to destination: IndexPath) {
        _ = performNonCellReaction(.moveItemAtIndexPathToIndexPath, argumentOne: source, argumentTwo: destination)
        (delegate as? UICollectionViewDataSource)?.collectionView?(collectionView,
                                                                  moveItemAt: source,
                                                                  to: destination)
    }
    
    @available(iOS 14.0, tvOS 10.2, *)
    /// Implementation of `UICollectionViewDataSource` protocol.
    open func indexTitles(for collectionView: UICollectionView) -> [String]? {
        if let reaction = unmappedReactions.first(where: { $0.methodSignature == EventMethodSignature.indexTitlesForCollectionView.rawValue }) {
            return reaction.performWithArguments((0, 0, 0)) as? [String]
        }
        return (delegate as? UICollectionViewDataSource)?.indexTitles?(for: collectionView)
    }
    
    @available(iOS 14.0, tvOS 10.2, *)
    /// Implementation of `UICollectionViewDataSource` protocol.
    open func collectionView(_ collectionView: UICollectionView, indexPathForIndexTitle title: String, at index: Int) -> IndexPath {
        if let indexPath = performNonCellReaction(.indexPathForIndexTitleAtIndex, argumentOne: title, argumentTwo: index) as? IndexPath {
            return indexPath
        }
        return (delegate as? UICollectionViewDataSource)?.collectionView?(collectionView,
                                                                          indexPathForIndexTitle: title,
                                                                          at: index) ?? IndexPath(item: 0, section: 0)
    }
}
