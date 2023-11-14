//
//  DTCollectionViewManager+Deprecated.swift
//
//  Created by Denys Telezhkin on 22.07.2020.
//  Copyright © 2020 Denys Telezhkin. All rights reserved.
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

/// Deprecated methods
public extension DTCollectionViewManager {
    @available(*, deprecated, message: "All cell and view events are now available inside mapping closure in register(_:mapping:handler:) method, along with type already inferred, thus making this method obsolete")
    /// Immediately runs closure to provide access to both T and T.ModelType for `klass`.
    ///
    /// - Discussion: This is particularly useful for registering events, because near 1/3 of events don't have cell or view before they are getting run, which prevents view type from being known, and required developer to remember, which model is mapped to which cell.
    /// By using this container closure you will be able to provide compile-time safety for all events.
    /// - Parameters:
    ///   - klass: Class of reusable view to be used in configuration container
    ///   - closure: closure to run with view types.
    func configureEvents<T:ModelTransfer>(for klass: T.Type, _ closure: (T.Type, T.ModelType.Type) -> Void) {
        closure(T.self, T.ModelType.self)
    }
    
    @available(*, deprecated, message: "Please use handler parameter in register(_:mapping:handler:) method instead.")
    /// Registers `closure` to be executed, when `UICollectionView` requests `cellClass` in `UICollectionViewDataSource.collectionView(_:cellForItemAt:)` method and cell is being configured.
    ///
    /// This closure will be performed *after* cell is created and `update(with:)` method is called.
    func configure<T:ModelTransfer>(_ cellClass:T.Type, _ closure: @escaping (T, T.ModelType, IndexPath) -> Void) where T: UICollectionViewCell
    {
        collectionDataSource?.appendReaction(for: T.self, signature: .configureCell, closure: closure)
    }
    
    @available(*, deprecated, message: "Please use handler parameter in registerHeader(_:mapping:handler:) method instead.")
    /// Registers `closure` to be executed, when `UICollectionView` requests `headerClass` in `UICollectionViewDataSource.collectionView(_:viewForSupplementaryElementOf:at:)` method and header is being configured.
    ///
    /// This closure will be performed *after* header is created and `update(with:)` method is called.
    func configureHeader<T:ModelTransfer>(_ headerClass: T.Type, _ closure: @escaping (T, T.ModelType, Int) -> Void) where T: UICollectionReusableView
    {
        let indexPathClosure : (T, T.ModelType, IndexPath) -> Void = { view, model, indexPath in
            closure(view, model, indexPath.section)
        }
        configureSupplementary(T.self, ofKind: UICollectionView.elementKindSectionHeader, indexPathClosure)
    }
    
    @available(*, deprecated, message: "Please use handler parameter in registerFooter(_:mapping:handler:) method instead.")
    /// Registers `closure` to be executed, when `UICollectionView` requests `footerClass` in `UICollectionViewDataSource.collectionView(_:viewForSupplementaryElementOf:at:)` method and footer is being configured.
    ///
    /// This closure will be performed *after* footer is created and `update(with:)` method is called.
    func configureFooter<T:ModelTransfer>(_ footerClass: T.Type, _ closure: @escaping (T, T.ModelType, Int) -> Void) where T: UICollectionReusableView
    {
        let indexPathClosure : (T, T.ModelType, IndexPath) -> Void = { view, model, indexPath in
            closure(view, model, indexPath.section)
        }
        configureSupplementary(T.self, ofKind: UICollectionView.elementKindSectionFooter, indexPathClosure)
    }
    
    @available(*, deprecated, message: "Please use handler parameter in registerSupplementary(_:ofKind:mapping:handler:) method instead.")
    /// Registers `closure` to be executed, when `UICollectionView` requests `supplementaryClass` of `kind` in `UICollectionViewDataSource.collectionView(_:viewForSupplementaryElementOf:at:)` method and supplementary view is being configured.
    ///
    /// This closure will be performed *after* supplementary view is created and `update(with:)` method is called.
    func configureSupplementary<T:ModelTransfer>(_ supplementaryClass: T.Type, ofKind kind: String, _ closure: @escaping (T, T.ModelType, IndexPath) -> Void) where T: UICollectionReusableView
    {
        collectionDataSource?.appendReaction(forSupplementaryKind: kind, supplementaryClass: T.self, signature: .configureSupplementary, closure: closure)
    }
    
    @available(*, deprecated, message: "Please use registerSupplementary(_:kind:mapping:handler:) instead.")
    /// Registers mapping from model class to supplementary view of `supplementaryClass` type for supplementary `kind`.
    func registerNiblessSupplementary<T:ModelTransfer>(_ supplementaryClass: T.Type, forKind kind: String, mappingBlock: ((CollectionSupplementaryViewModelMapping<T, T.ModelType>) -> Void)? = nil) where T:UICollectionReusableView {
        viewFactory.registerSupplementaryClass(T.self, ofKind: kind, handler: { _, _, _ in }, mapping: { mapping in
            mapping.xibName = nil
            mappingBlock?(mapping)
        })
    }
    @available(*, deprecated, message: "Please use registerHeader(_:mapping:handler:) instead.")
    /// Registers mapping from model class to header view of `headerClass` type for `UICollectionElementKindSectionHeader`.
    func registerNiblessHeader<T:ModelTransfer>(_ headerClass: T.Type, mappingBlock: ((CollectionSupplementaryViewModelMapping<T, T.ModelType>) -> Void)? = nil) where T:UICollectionReusableView {
        registerHeader(T.self, mapping: { mapping in
            mapping.xibName = nil
            mappingBlock?(mapping)
        }, handler: { _, _, _ in })
    }
    
    @available(*, deprecated, message: "Please use registerFooter(_:mapping:handler:) instead")
    /// Registers mapping from model class to footer view of `footerClass` type for `UICollectionElementKindSectionFooter`.
    func registerNiblessFooter<T:ModelTransfer>(_ footerClass: T.Type, mappingBlock: ((CollectionSupplementaryViewModelMapping<T, T.ModelType>) -> Void)? = nil) where T:UICollectionReusableView {
        registerFooter(T.self, mapping: { mapping in
            mapping.xibName = nil
            mappingBlock?(mapping)
        }, handler: { _, _, _ in })
    }
    @available(*, deprecated, message: "Please use register(_:mapping:handler:) instead.")
    func registerNibless<T:ModelTransfer>(_ cellClass:T.Type, mappingBlock: ((CollectionViewCellModelMapping<T, T.ModelType>) -> Void)? = nil) where T: UICollectionViewCell
    {
        viewFactory.registerCellClass(T.self, handler: { _, _, _ in }, mapping: { mappingInstance in
            mappingInstance.xibName = nil
            mappingBlock?(mappingInstance)
        })
    }
    
    @available(*, deprecated, message: "Please use registerSupplementary(_:kind:mapping:handler:) and set xibName in mapping closure instead.")
    /// Registers mapping from model class to supplementary view of `supplementaryClass` type with `nibName` for supplementary `kind`.
    func registerNibNamed<T:ModelTransfer>(_ nibName: String, forSupplementary supplementaryClass: T.Type, ofKind kind: String, mappingBlock: ((CollectionSupplementaryViewModelMapping<T, T.ModelType>) -> Void)? = nil) where T:UICollectionReusableView
    {
        registerSupplementary(T.self, ofKind: kind,
                              mapping: { mappingInstance in
                                mappingInstance.xibName = nibName
                                mappingBlock?(mappingInstance)
                              }, handler: { _, _, _ in })
    }
    
    @available(*, deprecated, message: "Please use registerHeader(_:mapping:handler:) and set xibName in mapping closure instead.")
    /// Registers mapping from model class to supplementary view of `headerClass` type with `nibName` for UICollectionElementKindSectionHeader.
    func registerNibNamed<T:ModelTransfer>(_ nibName: String, forHeader headerClass: T.Type, mappingBlock: ((CollectionSupplementaryViewModelMapping<T, T.ModelType>) -> Void)? = nil) where T:UICollectionReusableView
    {
        registerSupplementary(T.self,
                              ofKind: UICollectionView.elementKindSectionHeader,
                              mapping: { mappingInstance in
                                mappingInstance.xibName = nibName
                                mappingBlock?(mappingInstance)
                              }, handler: { _, _, _ in })
    }
    
    @available(*, deprecated, message: "Please use registerFooter(_:mapping:handler:) and set xibName in mapping closure instead.")
    /// Registers mapping from model class to supplementary view of `footerClass` type with `nibName` for UICollectionElementKindSectionFooter.
    func registerNibNamed<T:ModelTransfer>(_ nibName: String, forFooter footerClass: T.Type, mappingBlock: ((CollectionSupplementaryViewModelMapping<T, T.ModelType>) -> Void)? = nil) where T:UICollectionReusableView
    {
        registerSupplementary(T.self,
                              ofKind: UICollectionView.elementKindSectionFooter,
                              mapping: { mappingInstance in
                                mappingInstance.xibName = nibName
                                mappingBlock?(mappingInstance)
                              }, handler: { _, _, _ in })
    }
    
    @available(*, deprecated, message: "Please use register(_:mapping:handler:) and set xibName in mapping closure instead.")
    /// Registers nib with `nibName` mapping from model class to `cellClass`.
    func registerNibNamed<T:ModelTransfer>(_ nibName: String, for cellClass: T.Type, mappingBlock: ((CollectionViewCellModelMapping<T, T.ModelType>) -> Void)? = nil) where T: UICollectionViewCell
    {
        register(T.self, mapping: { mapping in
            mapping.xibName = nibName
        })
    }
}

/// Upgrade shims for easier API upgrading
public extension DTCollectionViewManager {
    @available(*, unavailable, renamed: "register(_:mapping:handler:)")
    /// This method is unavailable, please use `register(_:mapping:handler:)` as a replacement.
    func register<T:ModelTransfer>(_ cellClass:T.Type, mappingBlock: ((CollectionViewCellModelMapping<T, T.ModelType>) -> Void)? = nil) where T: UICollectionViewCell
    {
    }
    
    @available(*, unavailable, renamed: "registerSupplementary(_:ofKind:mapping:handler:)")
    /// This method is unavailable, please use `registerSupplementary(_:mapping:handler:)` as a replacement.
    func registerSupplementary<T:ModelTransfer>(_ supplementaryClass: T.Type, forKind kind: String, mappingBlock: ((CollectionSupplementaryViewModelMapping<T, T.ModelType>) -> Void)? = nil) where T:UICollectionReusableView
    {
    }
    
    @available(*, unavailable, renamed: "registerHeader(_:mapping:handler:)")
    /// This method is unavailable, please use `registerHeader(_:mapping:handler:)` as a replacement.
    func registerHeader<T:ModelTransfer>(_ headerClass : T.Type, mappingBlock: ((CollectionSupplementaryViewModelMapping<T, T.ModelType>) -> Void)? = nil) where T: UICollectionReusableView {
        
    }
    
    @available(*, unavailable, renamed: "registerFooter(_:mapping:handler:)")
    /// This method is unavailable, please use `registerFooter(_:mapping:handler:)` as a replacement.
    func registerFooter<T:ModelTransfer>(_ footerClass: T.Type,
                                              mappingBlock: ((CollectionSupplementaryViewModelMapping<T, T.ModelType>) -> Void)? = nil) where T:UICollectionReusableView {
        
    }
}
