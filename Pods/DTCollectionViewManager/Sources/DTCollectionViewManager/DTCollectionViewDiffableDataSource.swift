//
//  DTCollectionViewDiffableDataSource.swift
//  DTCollectionViewManager
//
//  Created by Denys Telezhkin on 11.07.2021.
//  Copyright © 2021 Denys Telezhkin. All rights reserved.
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

// swiftlint:disable generic_type_name

@available(iOS 13, tvOS 13, *)
class DTCollectionViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>: UICollectionViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>, Storage, SupplementaryStorage
    where SectionIdentifierType : Hashable, ItemIdentifierType : Hashable
{
    let collectionView: UICollectionView
    weak var manager: DTCollectionViewManager?
    let viewFactory: CollectionViewFactory
    let modelProvider: (IndexPath, ItemIdentifierType) -> Any
    
    var delegate: UICollectionViewDataSource? {
        manager?.delegate as? UICollectionViewDataSource
    }
    
    var dtCollectionViewDataSource: DTCollectionViewDataSource? {
        manager?.collectionDataSource
    }
    
    /// Returns a header model for specified section index or nil.
    var headerModelProvider: ((Int) -> Any?)?
    
    /// Returns a footer model for specified section index or nil
    var footerModelProvider: ((Int) -> Any?)?

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
    var supplementaryModelProvider: ((String, IndexPath) -> Any?)? {
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
    var supplementaryHeaderKind: String?
    
    /// Supplementary kind for footer in current storage
    var supplementaryFooterKind: String?
    
    init(collectionView: UICollectionView, viewFactory: CollectionViewFactory, manager: DTCollectionViewManager, cellProvider: @escaping UICollectionViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>.CellProvider, modelProvider: @escaping (IndexPath, ItemIdentifierType) -> Any) {
        self.collectionView = collectionView
        self.viewFactory = viewFactory
        self.manager = manager
        self.modelProvider = modelProvider
        super.init(collectionView: collectionView, cellProvider: cellProvider)
    }
    
    func numberOfSections() -> Int {
        numberOfSections(in: collectionView)
    }
    
    func numberOfItems(inSection section: Int) -> Int {
        collectionView(collectionView, numberOfItemsInSection: section)
    }
    
    func item(at indexPath: IndexPath) -> Any? {
        guard let itemIdentifier = itemIdentifier(for: indexPath) else {
            return nil
        }
        return modelProvider(indexPath, itemIdentifier)
    }
    
    private func dummyCell(for indexPath: IndexPath) -> UICollectionViewCell {
        let identifier =  String(describing: type(of: DummyCollectionViewCellThatPreventsAppFromCrashing.self))
        collectionView.register(DummyCollectionViewCellThatPreventsAppFromCrashing.self,
                                 forCellWithReuseIdentifier: identifier)
        return collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
    }
    
    /// Implementation of `UICollectionViewDataSource` protocol.
    open override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let model = RuntimeHelper.recursivelyUnwrapAnyValue(item(at: indexPath) as Any) else {
            manager?.anomalyHandler.reportAnomaly(.nilCellModel(indexPath))
            return dummyCell(for: indexPath)
        }
        guard let cell = viewFactory.cellForModel(model, atIndexPath: indexPath) else {
            return dummyCell(for: indexPath)
        }
        _ = EventReaction.performReaction(from: viewFactory.mappings,
                                                    signature: EventMethodSignature.configureCell.rawValue,
                                                    view: cell,
                                                    model: model,
                                                    location: indexPath)
        return cell
    }
    
    /// Implementation of `UICollectionViewDataSource` protocol.
    open override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView
    {
        guard let model = supplementaryModel(ofKind: kind, forSectionAt: indexPath) else {
            manager?.anomalyHandler.reportAnomaly(DTCollectionViewManagerAnomaly.nilSupplementaryModel(kind: kind, indexPath: indexPath))
            return UICollectionReusableView()
        }
        guard let view = viewFactory.supplementaryViewOfKind(kind, forModel: model, atIndexPath: indexPath) else {
            return UICollectionReusableView()
        }
        _ = EventReaction.performReaction(from: viewFactory.mappings,
                                                    signature: EventMethodSignature.configureSupplementary.rawValue,
                                                    view: view,
                                                    model: model,
                                                    location: indexPath,
                                                    supplementaryKind: kind)
        return view
    }
    
    /// Implementation of `UICollectionViewDataSource` protocol.
    open override func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        if let can = dtCollectionViewDataSource?.performCellReaction(.canMoveItemAtIndexPath, location: indexPath, provideCell: true) as? Bool {
            return can
        }
        return delegate?.collectionView?(collectionView, canMoveItemAt: indexPath) ?? true
    }
    
    /// Implementation of `UICollectionViewDataSource` protocol.
    open override func collectionView(_ collectionView: UICollectionView, moveItemAt source: IndexPath, to destination: IndexPath) {
        _ = dtCollectionViewDataSource?.performNonCellReaction(.moveItemAtIndexPathToIndexPath, argumentOne: source, argumentTwo: destination)
        delegate?.collectionView?(collectionView,
                                  moveItemAt: source,
                                  to: destination)
    }
    /// Implementation of `UICollectionViewDataSource` protocol.
    override func indexTitles(for collectionView: UICollectionView) -> [String]? {
        if let reaction = dtCollectionViewDataSource?.unmappedReactions.first(where: { $0.methodSignature == EventMethodSignature.indexTitlesForCollectionView.rawValue }) {
            return reaction.performWithArguments((0, 0, 0)) as? [String]
        }
        if #available(iOS 14, tvOS 14, *) {
            return delegate?.indexTitles?(for: collectionView)
        } else {
            return nil
        }
    }
    
    /// Implementation of `UICollectionViewDataSource` protocol.
    override func collectionView(_ collectionView: UICollectionView, indexPathForIndexTitle title: String, at index: Int) -> IndexPath {
        if let indexPath = dtCollectionViewDataSource?.performNonCellReaction(.indexPathForIndexTitleAtIndex, argumentOne: title, argumentTwo: index) as? IndexPath {
            return indexPath
        }
        if #available(iOS 14, tvOS 14, *) {
            return delegate?.collectionView?(collectionView,
                                             indexPathForIndexTitle: title,
                                             at: index) ?? IndexPath(item: 0, section: 0)
        } else {
            return IndexPath(item: 0, section: 0)
        }
    }
}
