//
//  DTCollectionViewManager+Registration.swift
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

/// Extension for registering cells and supplementary views
public extension DTCollectionViewManager {
    /// Registers mapping for `cellClass`. Mapping will automatically check for nib with the same name as `cellClass` and register it, if it is found. If cell is designed in storyboard, please set `mapping.cellRegisteredByStoryboard` property to `true` inside of `mapping` closure.
    /// - Parameters:
    ///   - cellClass: UICollectionViewCell subclass type, conforming to `ModelTransfer` protocol.
    ///   - mapping: mapping configuration closure, executed before any registration or dequeue is performed.
    ///   - handler: configuration closure, that is run when cell is dequeued.
    /// - Note: `handler` closure is called before `update(with:)` method.
    func register<T:ModelTransfer>(_ cellClass:T.Type, mapping: ((CollectionViewCellModelMapping<T, T.ModelType>) -> Void)? = nil,
                                        handler: @escaping (T, T.ModelType, IndexPath) -> Void = { _, _, _ in }) where T: UICollectionViewCell
    {
        viewFactory.registerCellClass(T.self, handler: handler, mapping: mapping)
    }
    
    /// Registers mapping from `modelType` to `cellClass`. Mapping will automatically check for nib with the same name as `cellClass` and register it, if it is found. If cell is designed in storyboard, please set `mapping.cellRegisteredByStoryboard` property to `true` inside of `mapping` closure.
    /// - Parameters:
    ///   - cellClass: UICollectionViewCell to register
    ///   - modelType: Model type, which is mapped to `cellClass`.
    ///   - mapping: mapping configuration closure, executed before any registration or dequeue is performed.
    ///   - handler: configuration closure, that is run when cell is dequeued.
    func register<Cell: UICollectionViewCell, Model>(_ cellClass: Cell.Type, for modelType: Model.Type, mapping: ((CollectionViewCellModelMapping<Cell, Model>) -> Void)? = nil, handler: @escaping (Cell, Model, IndexPath) -> Void) {
        viewFactory.registerCellClass(cellClass, modelType, handler: handler, mapping: mapping)
    }

    /// Registers mapping for `headerClass`. `UICollectionView.elementKindSectionHeader` is used as a supplementary kind. Mapping will automatically check for nib with the same name as `headerClass` and register it, if it is found.
    /// If supplementary view is designed in storyboard, please set `mapping.supplementaryRegisteredByStoryboard` property to `true` inside of `mapping` closure.
    /// - Parameters:
    ///   - headerClass: UICollectionReusableView class to register
    ///   - modelType: Model type, which is mapped to `headerClass`.
    ///   - mapping: mapping configuration closure, executed before any registration or dequeue is performed.
    ///   - handler: configuration closure, that is run when supplementary view is dequeued.
    /// - Note: `handler` closure is called before `update(with:)` method.
    func registerHeader<View:ModelTransfer>(_ headerClass : View.Type,
                                              mapping: ((CollectionSupplementaryViewModelMapping<View, View.ModelType>) -> Void)? = nil,
                                              handler: @escaping (View, View.ModelType, IndexPath) -> Void = { _, _, _ in }) where View: UICollectionReusableView
    {
        viewFactory.registerSupplementaryClass(View.self,
                                               ofKind: UICollectionView.elementKindSectionHeader,
                                               handler: handler,
                                               mapping: mapping)
    }
    
    /// Registers mapping from `modelType` to `headerClass`. `UICollectionView.elementKindSectionHeader` is used as a supplementary kind. Mapping will automatically check for nib with the same name as `headerClass` and register it, if it is found.
    /// If header is designed in storyboard, please set `mapping.supplementaryRegisteredByStoryboard` property to `true` inside of `mapping` closure.
    /// - Parameters:
    ///   - headerClass: UICollectionReusableView class to register
    ///   - modelType: Model type, which is mapped to `headerClass`.
    ///   - mapping: mapping configuration closure, executed before any registration or dequeue is performed.
    ///   - handler: configuration closure, that is run when header is dequeued.
    func registerHeader<View:UICollectionReusableView, Model>(_ headerClass: View.Type,
                                                                   for modelType: Model.Type,
                                                                   mapping: ((CollectionSupplementaryViewModelMapping<View, Model>) -> Void)? = nil,
                                                                   handler: @escaping (View, Model, IndexPath) -> Void = { _, _, _ in }) {
        registerSupplementary(View.self, for: Model.self, ofKind: UICollectionView.elementKindSectionHeader, mapping: mapping, handler: handler)
    }
    
    /// Registers mapping for `footerClass`. `UICollectionView.elementKindSectionFooter` is used as a supplementary kind. Mapping will automatically check for nib with the same name as `footerClass` and register it, if it is found.
    /// If supplementary view is designed in storyboard, please set `mapping.supplementaryRegisteredByStoryboard` property to `true` inside of `mapping` closure.
    /// - Parameters:
    ///   - footerClass: UICollectionReusableView class to register
    ///   - modelType: Model type, which is mapped to `footerClass`.
    ///   - mapping: mapping configuration closure, executed before any registration or dequeue is performed.
    ///   - handler: configuration closure, that is run when supplementary view is dequeued.
    /// - Note: `handler` closure is called before `update(with:)` method.
    func registerFooter<View:ModelTransfer>(_ footerClass: View.Type,
                                              mapping: ((CollectionSupplementaryViewModelMapping<View, View.ModelType>) -> Void)? = nil,
                                              handler: @escaping (View, View.ModelType, IndexPath) -> Void = { _, _, _ in }) where View:UICollectionReusableView
    {
        viewFactory.registerSupplementaryClass(View.self,
                                               ofKind: UICollectionView.elementKindSectionFooter,
                                               handler: handler,
                                               mapping: mapping)
    }
    
    /// Registers mapping from `modelType` to `footerClass`. `UICollectionView.elementKindSectionFooter` is used as a supplementary kind. Mapping will automatically check for nib with the same name as `footerClass` and register it, if it is found.
    /// If footer is designed in storyboard, please set `mapping.supplementaryRegisteredByStoryboard` property to `true` inside of `mapping` closure.
    /// - Parameters:
    ///   - footerClass: UICollectionReusableView class to register
    ///   - modelType: Model type, which is mapped to `footerClass`.
    ///   - mapping: mapping configuration closure, executed before any registration or dequeue is performed.
    ///   - handler: configuration closure, that is run when footer is dequeued.
    func registerFooter<View:UICollectionReusableView, Model>(_ footerClass: View.Type,
                                                                   for modelType: Model.Type,
                                                                   mapping: ((CollectionSupplementaryViewModelMapping<View, Model>) -> Void)? = nil,
                                                                   handler: @escaping (View, Model, IndexPath) -> Void = { _, _, _ in })
    {
        registerSupplementary(View.self, for: Model.self, ofKind: UICollectionView.elementKindSectionFooter, mapping: mapping, handler: handler)
    }
    
    /// Registers mapping for `footerClass`.  Mapping will automatically check for nib with the same name as `supplementaryClass` and register it, if it is found.
    /// If supplementary view is designed in storyboard, please set `mapping.supplementaryRegisteredByStoryboard` property to `true` inside of `mapping` closure.
    /// - Parameters:
    ///   - supplementaryClass: UICollectionReusableView class to register
    ///   - kind: supplementary view kind
    ///   - mapping: mapping configuration closure, executed before any registration or dequeue is performed.
    ///   - handler: configuration closure, that is run when supplementary view is dequeued.
    /// - Note: `handler` closure is called before `update(with:)` method.
    func registerSupplementary<View:ModelTransfer>(_ supplementaryClass: View.Type,
                                                     ofKind kind: String,
                                                     mapping: ((CollectionSupplementaryViewModelMapping<View, View.ModelType>) -> Void)? = nil,
                                                     handler: @escaping (View, View.ModelType, IndexPath) -> Void = { _, _, _ in }) where View:UICollectionReusableView
    {
        viewFactory.registerSupplementaryClass(View.self, ofKind: kind, handler: handler, mapping: mapping)
    }
    
    /// Registers mapping from `modelType` to `supplementaryClass`. Mapping will automatically check for nib with the same name as `supplementaryClass` and register it, if it is found.
    /// If supplementary view is designed in storyboard, please set `mapping.supplementaryRegisteredByStoryboard` property to `true` inside of `mapping` closure.
    /// - Parameters:
    ///   - footerClass: UICollectionReusableView class to register
    ///   - modelType: Model type, which is mapped to `supplementaryClass`.
    ///   - mapping: mapping configuration closure, executed before any registration or dequeue is performed.
    ///   - handler: configuration closure, that is run when supplementary view is dequeued.
    func registerSupplementary<View:UICollectionReusableView, Model>(_ supplementaryClass: View.Type,
                                                                          for modelType: Model.Type,
                                                                          ofKind kind: String,
                                                                          mapping: ((CollectionSupplementaryViewModelMapping<View, Model>) -> Void)? = nil,
                                                                          handler: @escaping (View, Model, IndexPath) -> Void = { _, _, _ in })
    {
        viewFactory.registerSupplementaryClass(supplementaryClass, modelType, ofKind: kind, handler: handler, mapping: mapping)
    }
    
    /// Unregisters `cellClass` from `DTCollectionViewManager` and `UICollectionView`.
    func unregister<Cell:ModelTransfer>(_ cellClass: Cell.Type) where Cell: UICollectionViewCell {
        viewFactory.unregisterCellClass(Cell.self)
    }
    
    /// Unregisters `headerClass` from `DTCollectionViewManager` and `UICollectionView`.
    func unregisterHeader<View:ModelTransfer>(_ headerClass: View.Type) where View:UICollectionReusableView {
        unregisterSupplementary(View.self, ofKind: UICollectionView.elementKindSectionHeader)
    }
    
    /// Unregisters `footerClass` from `DTCollectionViewManager` and `UICollectionView`.
    func unregisterFooter<View:ModelTransfer>(_ headerClass: View.Type) where View:UICollectionReusableView {
        unregisterSupplementary(View.self, ofKind: UICollectionView.elementKindSectionFooter)
    }
    
    /// Unregisters `supplementaryClass` of `kind` from `DTCollectionViewManager` and `UICollectionView`.
    func unregisterSupplementary<View:ModelTransfer>(_ supplementaryClass: View.Type, ofKind kind: String) where View:UICollectionReusableView {
        viewFactory.unregisterSupplementaryClass(View.self, ofKind: kind)
    }
}
