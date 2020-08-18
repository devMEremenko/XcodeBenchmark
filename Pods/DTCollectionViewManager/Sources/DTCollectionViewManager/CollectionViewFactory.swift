//
//  CollectionViewFactory.swift
//  DTCollectionViewManager
//
//  Created by Denys Telezhkin on 23.08.15.
//  Copyright © 2015 Denys Telezhkin. All rights reserved.
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

/// Internal class, that is used to create collection view cells and supplementary views.
final class CollectionViewFactory
{
    fileprivate let collectionView: UICollectionView
    
    var mappings = [ViewModelMapping]()
    
    weak var anomalyHandler : DTCollectionViewManagerAnomalyHandler?
    
    init(collectionView: UICollectionView)
    {
        self.collectionView = collectionView
    }
}

// MARK: Registration
extension CollectionViewFactory
{
    func registerCellClass<T:ModelTransfer>(_ cellClass: T.Type, mappingBlock: ((ViewModelMapping) -> Void)?) where T: UICollectionViewCell
    {
        let mapping : ViewModelMapping = ViewModelMapping(viewType: .cell, viewClass: T.self, xibName: String(describing: T.self), mappingBlock: mappingBlock)
        if let xibName = mapping.xibName, UINib.nibExists(withNibName: xibName, inBundle: mapping.bundle) {
            collectionView.register(UINib(nibName: xibName, bundle: mapping.bundle),
                                    forCellWithReuseIdentifier: mapping.reuseIdentifier)
            verifyCell(T.self, nibName: xibName, withReuseIdentifier: mapping.reuseIdentifier, in: mapping.bundle)
        } else {
            mapping.xibName = nil
        }
        mappings.append(mapping)
    }
    
    func registerNiblessCellClass<T:ModelTransfer>(_ cellClass: T.Type, mappingBlock: ((ViewModelMapping) -> Void)?) where T:UICollectionViewCell
    {
        let mapping = ViewModelMapping(viewType: .cell, viewClass: T.self, mappingBlock: mappingBlock)
        collectionView.register(cellClass, forCellWithReuseIdentifier: mapping.reuseIdentifier)
        mappings.append(mapping)
        verifyCell(T.self, nibName: nil, withReuseIdentifier: mapping.reuseIdentifier, in: mapping.bundle)
    }
    
    func registerNibNamed<T:ModelTransfer>(_ nibName: String, forCellClass cellClass: T.Type, mappingBlock: ((ViewModelMapping) -> Void)?) where T: UICollectionViewCell
    {
        let mapping = ViewModelMapping(viewType: .cell, viewClass: T.self, xibName: nibName, mappingBlock: mappingBlock)
        assert(UINib.nibExists(withNibName: nibName, inBundle: mapping.bundle))
        collectionView.register(UINib(nibName: nibName, bundle: mapping.bundle), forCellWithReuseIdentifier: mapping.reuseIdentifier)
        mappings.append(mapping)
        verifyCell(T.self, nibName: nibName, withReuseIdentifier: mapping.reuseIdentifier, in: mapping.bundle)
    }
    
    func verifyCell<T:UICollectionViewCell>(_ cell: T.Type, nibName: String?,
                                            withReuseIdentifier reuseIdentifier: String, in bundle: Bundle) {
        var cell = T(frame: .zero)
        if let nibName = nibName, UINib.nibExists(withNibName: nibName, inBundle: bundle) {
            let nib = UINib(nibName: nibName, bundle: bundle)
            let objects = nib.instantiate(withOwner: cell, options: nil)
            if let instantiatedCell = objects.first as? T {
                cell = instantiatedCell
            } else {
                if let first = objects.first {
                    anomalyHandler?.reportAnomaly(.differentCellClass(xibName: nibName,
                                                                      cellClass: String(describing: type(of: first)),
                                                                      expectedCellClass: String(describing: T.self)))
                } else {
                    anomalyHandler?.reportAnomaly(.emptyXibFile(xibName: nibName, expectedViewClass: String(describing: T.self)))
                }
            }
        }
        if let cellReuseIdentifier = cell.reuseIdentifier, cellReuseIdentifier != reuseIdentifier {
            anomalyHandler?.reportAnomaly(.differentCellReuseIdentifier(mappingReuseIdentifier: reuseIdentifier, cellReuseIdentifier: cellReuseIdentifier))
        }
    }
    
    func registerNiblessSupplementaryClass<T:ModelTransfer>(_ supplementaryClass: T.Type, forKind kind: String, mappingBlock: ((ViewModelMapping) -> Void)?) where T: UICollectionReusableView
    {
        let mapping = ViewModelMapping(viewType: .supplementaryView(kind: kind), viewClass: T.self, mappingBlock: mappingBlock)
        collectionView.register(supplementaryClass, forSupplementaryViewOfKind: kind, withReuseIdentifier: mapping.reuseIdentifier)
        mappings.append(mapping)
        verifySupplementaryView(T.self, nibName: nil, reuseIdentifier: mapping.reuseIdentifier, in: mapping.bundle)
    }
    
    func registerSupplementaryClass<T:ModelTransfer>(_ supplementaryClass: T.Type, forKind kind: String, mappingBlock: ((ViewModelMapping) -> Void)?) where T:UICollectionReusableView
    {
        let mapping = ViewModelMapping(viewType: .supplementaryView(kind: kind), viewClass: T.self,
                                       xibName: String(describing: T.self), mappingBlock: mappingBlock)
        if let nibName = mapping.xibName, UINib.nibExists(withNibName: nibName, inBundle: mapping.bundle) {
            collectionView.register(UINib(nibName: nibName, bundle: mapping.bundle), forSupplementaryViewOfKind: kind, withReuseIdentifier: mapping.reuseIdentifier)
            verifySupplementaryView(T.self, nibName: nibName, reuseIdentifier: mapping.reuseIdentifier, in: mapping.bundle)
        } else {
            mapping.xibName = nil
            verifySupplementaryView(T.self, nibName: nil, reuseIdentifier: mapping.reuseIdentifier, in: mapping.bundle)
        }
        mappings.append(mapping)
    }
    
    func registerNibNamed<T:ModelTransfer>(_ nibName: String, forSupplementaryClass supplementaryClass: T.Type, forKind kind: String, mappingBlock: ((ViewModelMapping) -> Void)?) where T:UICollectionReusableView
    {
        let mapping = ViewModelMapping(viewType: .supplementaryView(kind: kind), viewClass: T.self, xibName: nibName, mappingBlock: mappingBlock)
        assert(UINib.nibExists(withNibName: nibName, inBundle: mapping.bundle))
        collectionView.register(UINib(nibName: nibName, bundle: mapping.bundle), forSupplementaryViewOfKind: kind, withReuseIdentifier: mapping.reuseIdentifier)
        mappings.append(mapping)
        verifySupplementaryView(T.self, nibName: nibName, reuseIdentifier: mapping.reuseIdentifier, in: mapping.bundle)
    }
    
    func verifySupplementaryView<T:UICollectionReusableView>(_ view: T.Type, nibName: String?,
                                                             reuseIdentifier: String, in bundle: Bundle) {
        var view = T(frame: .zero)
        if let nibName = nibName, UINib.nibExists(withNibName: nibName, inBundle: bundle) {
            let nib = UINib(nibName: nibName, bundle: bundle)
            let objects = nib.instantiate(withOwner: view, options: nil)
            if let instantiatedView = objects.first as? T {
                view = instantiatedView
            } else {
                if let first = objects.first {
                    anomalyHandler?.reportAnomaly(DTCollectionViewManagerAnomaly.differentSupplementaryClass(xibName: nibName,
                                                                              viewClass: String(describing: type(of: first)),
                                                                              expectedViewClass: String(describing: T.self)))
                } else {
                    anomalyHandler?.reportAnomaly(.emptyXibFile(xibName: nibName, expectedViewClass: String(describing: T.self)))
                }
            }
        }
        if let supplementaryReuseIdentifier = view.reuseIdentifier, supplementaryReuseIdentifier != reuseIdentifier {
            anomalyHandler?.reportAnomaly(DTCollectionViewManagerAnomaly.differentSupplementaryReuseIdentifier(mappingReuseIdentifier: reuseIdentifier, supplementaryReuseIdentifier: supplementaryReuseIdentifier))
        }
    }
    
    func unregisterCellClass<T:ModelTransfer>(_ cellClass: T.Type) where T: UICollectionViewCell {
        mappings = mappings.filter({ mapping in
            if mapping.viewClass is T.Type && mapping.viewType == .cell { return false }
            return true
        })
        let nilClass : AnyClass? = nil
        let nilNib : UINib? = nil
        collectionView.register(nilClass, forCellWithReuseIdentifier: String(describing: T.self))
        collectionView.register(nilNib, forCellWithReuseIdentifier: String(describing: T.self))
    }
    
    func unregisterSupplementaryClass<T:ModelTransfer>(_ klass: T.Type, forKind kind: String) where T:UICollectionReusableView {
        mappings = mappings.filter({ mapping in
            if mapping.viewClass is T.Type && mapping.viewType == .supplementaryView(kind: kind) { return false }
            return true
        })
        let nilClass : AnyClass? = nil
        let nilNib : UINib? = nil
        collectionView.register(nilClass, forSupplementaryViewOfKind: kind, withReuseIdentifier: String(describing: self))
        collectionView.register(nilNib, forSupplementaryViewOfKind: kind, withReuseIdentifier: String(describing: self))
    }
}

// MARK: View creation
extension CollectionViewFactory
{
    func viewModelMapping(for viewType: ViewType, model: Any, at indexPath: IndexPath) -> ViewModelMapping?
    {
        guard let unwrappedModel = RuntimeHelper.recursivelyUnwrapAnyValue(model) else {
            return nil
        }
        return mappings.mappingCandidates(for: viewType, withModel: unwrappedModel, at: indexPath).first
    }
    
    func cellForModel(_ model: Any, atIndexPath indexPath:IndexPath) -> UICollectionViewCell?
    {
        if let mapping = viewModelMapping(for: .cell, model: model, at: indexPath)
        {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: mapping.reuseIdentifier, for: indexPath)
            mapping.updateBlock(cell, model)
            return cell
        }
        anomalyHandler?.reportAnomaly(.noCellMappingFound(modelDescription: String(describing: model), indexPath: indexPath))
        return nil
    }
    
    func updateCellAt(_ indexPath : IndexPath, with model: Any) {
        guard let cell = collectionView.cellForItem(at: indexPath) else { return }
        guard let unwrappedModel = RuntimeHelper.recursivelyUnwrapAnyValue(model) else { return }
        if let mapping = viewModelMapping(for: .cell, model: unwrappedModel, at: indexPath) {
            mapping.updateBlock(cell, unwrappedModel)
        }
    }

    func supplementaryViewOfKind(_ kind: String, forModel model: Any, atIndexPath indexPath: IndexPath) -> UICollectionReusableView?
    {
        if let mapping = mappings.mappingCandidates(for: .supplementaryView(kind: kind), withModel: model, at: indexPath).first
        {
            let viewClassName = String(describing: mapping.viewClass)
            let reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: viewClassName, for: indexPath)
            mapping.updateBlock(reusableView, model)
            return reusableView
        }
        anomalyHandler?.reportAnomaly(.noSupplementaryMappingFound(modelDescription: String(describing: model), kind: kind, indexPath: indexPath))
        return nil
    }
}
