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
    
    var mappings = [ViewModelMappingProtocol]() {
        didSet {
            resetDelegates?()
        }
    }
    
    weak var anomalyHandler : DTCollectionViewManagerAnomalyHandler?
    var resetDelegates : (() -> Void)?
    
    init(collectionView: UICollectionView)
    {
        self.collectionView = collectionView
    }
}

// MARK: Registration
extension CollectionViewFactory
{
    func registerCellClass<Cell:ModelTransfer>(_ cellClass: Cell.Type, handler: @escaping (Cell, Cell.ModelType, IndexPath) -> Void, mapping: ((ViewModelMapping<Cell, Cell.ModelType>) -> Void)?) where Cell: UICollectionViewCell
    {
        let mapping = ViewModelMapping<Cell, Cell.ModelType>(cellConfiguration: handler, mapping: mapping)
        
        func registerCell() {
            if let xibName = mapping.xibName, UINib.nibExists(withNibName: xibName, inBundle: mapping.bundle) {
                collectionView.register(UINib(nibName: xibName, bundle: mapping.bundle),
                                        forCellWithReuseIdentifier: mapping.reuseIdentifier)
            } else {
                if !mapping.cellRegisteredByStoryboard {
                    collectionView.register(cellClass, forCellWithReuseIdentifier: mapping.reuseIdentifier)
                }
            }
        }
        #if compiler(<5.3)
        registerCell()
        #else
        if #available(iOS 14, tvOS 14, *) {
            // Registration is not needed, dequeue provided by ViewModelMapping instance
        } else {
            registerCell()
        }
        #endif
        if !mapping.cellRegisteredByStoryboard {
            verifyCell(Cell.self, nibName: mapping.xibName, withReuseIdentifier: mapping.reuseIdentifier, in: mapping.bundle)
        }
        mappings.append(mapping)
    }
    
    func registerCellClass<Cell: UICollectionViewCell, Model>(_ cellType: Cell.Type, _ modelType: Model.Type, handler: @escaping (Cell, Model, IndexPath) -> Void, mapping: ((ViewModelMapping<Cell, Model>) -> Void)? = nil)
    {
        let mapping = ViewModelMapping<Cell, Model>(cellConfiguration: handler, mapping: mapping)
        func registerCell() {
            if let xibName = mapping.xibName, UINib.nibExists(withNibName: xibName, inBundle: mapping.bundle) {
                collectionView.register(UINib(nibName: xibName, bundle: mapping.bundle),
                                        forCellWithReuseIdentifier: mapping.reuseIdentifier)
            } else {
                if !mapping.cellRegisteredByStoryboard {
                    collectionView.register(cellType, forCellWithReuseIdentifier: mapping.reuseIdentifier)
                }
            }
        }
        #if compiler(<5.3)
        registerCell()
        #else
        if #available(iOS 14, tvOS 14, *) {
            // Registration is not needed, dequeue provided by ViewModelMapping instance
        } else {
            registerCell()
        }
        #endif
        if !mapping.cellRegisteredByStoryboard {
            verifyCell(Cell.self, nibName: mapping.xibName, withReuseIdentifier: mapping.reuseIdentifier, in: mapping.bundle)
        }
        mappings.append(mapping)
    }
    
    func verifyCell<Cell:UICollectionViewCell>(_ cell: Cell.Type, nibName: String?,
                                            withReuseIdentifier reuseIdentifier: String, in bundle: Bundle) {
        var cell = Cell(frame: .zero)
        if let nibName = nibName, UINib.nibExists(withNibName: nibName, inBundle: bundle) {
            let nib = UINib(nibName: nibName, bundle: bundle)
            let objects = nib.instantiate(withOwner: cell, options: nil)
            if let instantiatedCell = objects.first as? Cell {
                cell = instantiatedCell
            } else {
                if let first = objects.first {
                    anomalyHandler?.reportAnomaly(.differentCellClass(xibName: nibName,
                                                                      cellClass: String(describing: type(of: first)),
                                                                      expectedCellClass: String(describing: Cell.self)))
                } else {
                    anomalyHandler?.reportAnomaly(.emptyXibFile(xibName: nibName, expectedViewClass: String(describing: Cell.self)))
                }
            }
        }
        if let cellReuseIdentifier = cell.reuseIdentifier, cellReuseIdentifier != reuseIdentifier {
            anomalyHandler?.reportAnomaly(.differentCellReuseIdentifier(mappingReuseIdentifier: reuseIdentifier, cellReuseIdentifier: cellReuseIdentifier))
        }
    }
    
    func registerSupplementaryClass<View:ModelTransfer>(_ supplementaryClass: View.Type, ofKind kind: String, handler: @escaping (View, View.ModelType, IndexPath) -> Void, mapping: ((ViewModelMapping<View, View.ModelType>) -> Void)?) where View:UICollectionReusableView
    {
        let mapping = ViewModelMapping<View, View.ModelType>(kind: kind, supplementaryConfiguration: handler, mapping: mapping)
        
        func registerSupplementary() {
            if let nibName = mapping.xibName, UINib.nibExists(withNibName: nibName, inBundle: mapping.bundle) {
                collectionView.register(UINib(nibName: nibName, bundle: mapping.bundle), forSupplementaryViewOfKind: kind, withReuseIdentifier: mapping.reuseIdentifier)
                
            } else {
                if !mapping.supplementaryRegisteredByStoryboard {
                    collectionView.register(View.self, forSupplementaryViewOfKind: kind, withReuseIdentifier: mapping.reuseIdentifier)
                }
            }
        }
        #if compiler(<5.3)
        registerSupplementary()
        #else
        if #available(iOS 14, tvOS 14, *) {
            // Registration is not needed, dequeue provided by ViewModelMapping instance
        } else {
            registerSupplementary()
        }
        #endif
        
        if !mapping.supplementaryRegisteredByStoryboard {
            verifySupplementaryView(View.self, nibName: mapping.xibName, reuseIdentifier: mapping.reuseIdentifier, in: mapping.bundle)
        }
        
        mappings.append(mapping)
    }
    
    func registerSupplementaryClass<View:UICollectionReusableView, Model>(_ supplementaryClass: View.Type, _ modelType: Model.Type, ofKind kind: String, handler: @escaping (View, Model, IndexPath) -> Void, mapping: ((ViewModelMapping<View, Model>) -> Void)?)
    {
        let mapping = ViewModelMapping<View, Model>(kind: kind, supplementaryConfiguration: handler, mapping: mapping)
        
        func registerSupplementary() {
            if let nibName = mapping.xibName, UINib.nibExists(withNibName: nibName, inBundle: mapping.bundle) {
                collectionView.register(UINib(nibName: nibName, bundle: mapping.bundle), forSupplementaryViewOfKind: kind, withReuseIdentifier: mapping.reuseIdentifier)
                verifySupplementaryView(View.self, nibName: nibName, reuseIdentifier: mapping.reuseIdentifier, in: mapping.bundle)
            } else {
                if !mapping.supplementaryRegisteredByStoryboard {
                    collectionView.register(View.self, forSupplementaryViewOfKind: kind, withReuseIdentifier: mapping.reuseIdentifier)
                }
                verifySupplementaryView(View.self, nibName: nil, reuseIdentifier: mapping.reuseIdentifier, in: mapping.bundle)
            }
        }
        #if compiler(<5.3)
        registerSupplementary()
        #else
        if #available(iOS 14, tvOS 14, *) {
            // Registration is not needed, dequeue provided by ViewModelMapping instance
        } else {
            registerSupplementary()
        }
        #endif
        
        mappings.append(mapping)
    }
    
    func verifySupplementaryView<View:UICollectionReusableView>(_ view: View.Type, nibName: String?,
                                                             reuseIdentifier: String, in bundle: Bundle) {
        var view = View(frame: .zero)
        if let nibName = nibName, UINib.nibExists(withNibName: nibName, inBundle: bundle) {
            let nib = UINib(nibName: nibName, bundle: bundle)
            let objects = nib.instantiate(withOwner: view, options: nil)
            if let instantiatedView = objects.first as? View {
                view = instantiatedView
            } else {
                if let first = objects.first {
                    anomalyHandler?.reportAnomaly(DTCollectionViewManagerAnomaly.differentSupplementaryClass(xibName: nibName,
                                                                              viewClass: String(describing: type(of: first)),
                                                                              expectedViewClass: String(describing: View.self)))
                } else {
                    anomalyHandler?.reportAnomaly(.emptyXibFile(xibName: nibName, expectedViewClass: String(describing: View.self)))
                }
            }
        }
        if let supplementaryReuseIdentifier = view.reuseIdentifier, supplementaryReuseIdentifier != reuseIdentifier {
            anomalyHandler?.reportAnomaly(DTCollectionViewManagerAnomaly.differentSupplementaryReuseIdentifier(mappingReuseIdentifier: reuseIdentifier, supplementaryReuseIdentifier: supplementaryReuseIdentifier))
        }
    }
    
    func unregisterCellClass<Cell:ModelTransfer>(_ cellClass: Cell.Type) where Cell: UICollectionViewCell {
        mappings = mappings.filter({ mapping in
            if mapping.viewClass is Cell.Type && mapping.viewType == .cell { return false }
            return true
        })
        let nilClass : AnyClass? = nil
        let nilNib : UINib? = nil
        collectionView.register(nilClass, forCellWithReuseIdentifier: String(describing: Cell.self))
        collectionView.register(nilNib, forCellWithReuseIdentifier: String(describing: Cell.self))
    }
    
    func unregisterSupplementaryClass<View:ModelTransfer>(_ klass: View.Type, ofKind kind: String) where View:UICollectionReusableView {
        mappings = mappings.filter({ mapping in
            if mapping.viewClass is View.Type && mapping.viewType == .supplementaryView(kind: kind) { return false }
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
    func viewModelMapping(for viewType: ViewType, model: Any, at indexPath: IndexPath) -> ViewModelMappingProtocol?
    {
        guard let unwrappedModel = RuntimeHelper.recursivelyUnwrapAnyValue(model) else {
            return nil
        }
        return viewType.mappingCandidates(for: mappings, withModel: unwrappedModel, at: indexPath).first
    }
    
    func cellForModel(_ model: Any, atIndexPath indexPath:IndexPath) -> UICollectionViewCell?
    {
        if let mapping = viewModelMapping(for: .cell, model: model, at: indexPath)
        {
            return mapping.dequeueConfiguredReusableCell(for: collectionView, model: model, indexPath: indexPath)
        }
        anomalyHandler?.reportAnomaly(.noCellMappingFound(modelDescription: String(describing: model), indexPath: indexPath))
        return nil
    }
    
    func updateCellAt(_ indexPath : IndexPath, with model: Any) {
        guard let cell = collectionView.cellForItem(at: indexPath) else { return }
        guard let unwrappedModel = RuntimeHelper.recursivelyUnwrapAnyValue(model) else { return }
        if let mapping = viewModelMapping(for: .cell, model: unwrappedModel, at: indexPath) {
            mapping.updateCell(cell: cell, at: indexPath, with: unwrappedModel)
        }
    }

    func supplementaryViewOfKind(_ kind: String, forModel model: Any, atIndexPath indexPath: IndexPath) -> UICollectionReusableView?
    {
        if let mapping = ViewType.supplementaryView(kind: kind).mappingCandidates(for: mappings, withModel: model, at: indexPath).first
        {
            return mapping.dequeueConfiguredReusableSupplementaryView(for: collectionView, kind: kind, model: model, indexPath: indexPath)
        }
        anomalyHandler?.reportAnomaly(.noSupplementaryMappingFound(modelDescription: String(describing: model), kind: kind, indexPath: indexPath))
        return nil
    }
}
