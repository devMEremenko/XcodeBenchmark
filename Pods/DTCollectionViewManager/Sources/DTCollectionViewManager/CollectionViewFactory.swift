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
import SwiftUI

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
    
#if swift(>=5.7) && !canImport(AppKit) || (canImport(AppKit) && swift(>=5.7.1)) // Xcode 14.0 AND macCatalyst on Xcode 14.1 (which will have swift> 5.7.1)
    @available(iOS 16, tvOS 16, *)
    func registerHostingConfiguration<Content: View, Background: View, Model, Cell: UICollectionViewCell>(
        configuration: @escaping (Cell, Model, IndexPath) -> UIHostingConfiguration<Content, Background>,
        mapping: ((HostingConfigurationViewModelMapping<Content, Background, Model, Cell>) -> Void)?
    ) {
        mappings.append(HostingConfigurationViewModelMapping(cellConfiguration: configuration, mapping: mapping))
    }
    
    @available(iOS 16, tvOS 16, *)
    func registerHostingConfiguration<Content: View, Background: View, Model, Cell: UICollectionViewCell>(
        configuration: @escaping (UICellConfigurationState, Cell, Model, IndexPath) -> UIHostingConfiguration<Content, Background>,
        mapping: ((HostingConfigurationViewModelMapping<Content, Background, Model, Cell>) -> Void)?
    ) {
        mappings.append(HostingConfigurationViewModelMapping(cellConfiguration: configuration, mapping: mapping))
    }
#endif
    
    @available(iOS 13, tvOS 13, *)
    func registerHostingCell<Content: View, Model>(_ content: @escaping (Model, IndexPath) -> Content, parentViewController: UIViewController?,
                                                   mapping: ((HostingCellViewModelMapping<Content, Model>) -> Void)?) {
        let mapping = HostingCellViewModelMapping<Content, Model>(cellContent: content, parentViewController: parentViewController, mapping: mapping)
        if mapping.configuration.parentController == nil {
            assertionFailure("HostingCollectionViewCellConfiguration.parentController is nil. This will prevent HostingCell from sizing and appearing correctly. Please set parentController to controller, that contains managed collection view.")
        }
        if #unavailable(iOS 14, tvOS 14) {
            collectionView.register(mapping.hostingCellSubclass.self, forCellWithReuseIdentifier: mapping.reuseIdentifier)
        }
        
        mappings.append(mapping)
    }
    
    func registerCellClass<Cell:ModelTransfer>(_ cellClass: Cell.Type, handler: @escaping (Cell, Cell.ModelType, IndexPath) -> Void, mapping: ((CollectionViewCellModelMapping<Cell, Cell.ModelType>) -> Void)?)
    {
        let mapping = CollectionViewCellModelMapping<Cell, Cell.ModelType>(cellConfiguration: handler, mapping: mapping)
        
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
        if #unavailable(iOS 14, tvOS 14) {
            registerCell()
        }
        if !mapping.cellRegisteredByStoryboard {
            verifyCell(Cell.self, nibName: mapping.xibName, withReuseIdentifier: mapping.reuseIdentifier, in: mapping.bundle)
        }
        mappings.append(mapping)
    }
    
    func registerCellClass<Cell: UICollectionViewCell, Model>(_ cellType: Cell.Type, _ modelType: Model.Type, handler: @escaping (Cell, Model, IndexPath) -> Void, mapping: ((CollectionViewCellModelMapping<Cell, Model>) -> Void)? = nil)
    {
        let mapping = CollectionViewCellModelMapping<Cell, Model>(cellConfiguration: handler, mapping: mapping)
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
        if #unavailable(iOS 14, tvOS 14) {
            registerCell()
        }
        if !mapping.cellRegisteredByStoryboard {
            verifyCell(Cell.self, nibName: mapping.xibName, withReuseIdentifier: mapping.reuseIdentifier, in: mapping.bundle)
        }
        mappings.append(mapping)
    }
    
    func verifyCell<Cell:UICollectionViewCell>(_ cell: Cell.Type, nibName: String?,
                                            withReuseIdentifier reuseIdentifier: String, in bundle: Bundle) {
        guard Cell.instancesRespond(to: #selector(Cell.init(frame:))) else { return }
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
    }
    
    func registerSupplementaryClass<View:ModelTransfer>(_ supplementaryClass: View.Type, ofKind kind: String, handler: @escaping (View, View.ModelType, IndexPath) -> Void, mapping: ((CollectionSupplementaryViewModelMapping<View, View.ModelType>) -> Void)?) where View:UICollectionReusableView
    {
        let mapping = CollectionSupplementaryViewModelMapping<View, View.ModelType>(kind: kind, supplementaryConfiguration: handler, mapping: mapping)
        
        func registerSupplementary() {
            if let nibName = mapping.xibName, UINib.nibExists(withNibName: nibName, inBundle: mapping.bundle) {
                collectionView.register(UINib(nibName: nibName, bundle: mapping.bundle), forSupplementaryViewOfKind: kind, withReuseIdentifier: mapping.reuseIdentifier)
                
            } else {
                if !mapping.supplementaryRegisteredByStoryboard {
                    collectionView.register(View.self, forSupplementaryViewOfKind: kind, withReuseIdentifier: mapping.reuseIdentifier)
                }
            }
        }
        if #unavailable(iOS 14, tvOS 14) {
            registerSupplementary()
        }
        
        if !mapping.supplementaryRegisteredByStoryboard {
            verifySupplementaryView(View.self, nibName: mapping.xibName, reuseIdentifier: mapping.reuseIdentifier, in: mapping.bundle)
        }
        
        mappings.append(mapping)
    }
    
    func registerSupplementaryClass<View:UICollectionReusableView, Model>(_ supplementaryClass: View.Type, _ modelType: Model.Type, ofKind kind: String, handler: @escaping (View, Model, IndexPath) -> Void, mapping: ((CollectionSupplementaryViewModelMapping<View, Model>) -> Void)?)
    {
        let mapping = CollectionSupplementaryViewModelMapping<View, Model>(kind: kind, supplementaryConfiguration: handler, mapping: mapping)
        
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
        if #unavailable(iOS 14, tvOS 14) {
            registerSupplementary()
        }
        
        mappings.append(mapping)
    }
    
    func verifySupplementaryView<View:UICollectionReusableView>(_ view: View.Type, nibName: String?,
                                                             reuseIdentifier: String, in bundle: Bundle) {
        guard View.instancesRespond(to: #selector(View.init(frame:))) else { return }
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
        if let mapping = viewModelMapping(for: .cell, model: model, at: indexPath) as? CellViewModelMappingProtocol
        {
            return mapping.dequeueConfiguredReusableCell(for: collectionView, model: model, indexPath: indexPath)
        }
        anomalyHandler?.reportAnomaly(.noCellMappingFound(modelDescription: String(describing: model), indexPath: indexPath))
        return nil
    }
    
    func updateCellAt(_ indexPath : IndexPath, with model: Any) {
        guard let cell = collectionView.cellForItem(at: indexPath) else { return }
        guard let unwrappedModel = RuntimeHelper.recursivelyUnwrapAnyValue(model) else { return }
        if let mapping = viewModelMapping(for: .cell, model: unwrappedModel, at: indexPath) as? CellViewModelMappingProtocol {
            mapping.updateCell(cell: cell, at: indexPath, with: unwrappedModel)
        }
    }

    func supplementaryViewOfKind(_ kind: String, forModel model: Any, atIndexPath indexPath: IndexPath) -> UICollectionReusableView?
    {
        if let mapping = ViewType.supplementaryView(kind: kind).mappingCandidates(for: mappings, withModel: model, at: indexPath).first
        as? SupplementaryViewModelMappingProtocol {
            return mapping.dequeueConfiguredReusableSupplementaryView(for: collectionView, kind: kind, model: model, indexPath: indexPath)
        }
        anomalyHandler?.reportAnomaly(.noSupplementaryMappingFound(modelDescription: String(describing: model), kind: kind, indexPath: indexPath))
        return nil
    }
}
