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

extension DTCollectionViewManager {
    /// Registers mapping from model class to `cellClass`.
    ///
    /// Method will automatically check for nib with the same name as `cellClass`. If it exists - nib will be registered instead of class. If not - it is assumed that cell is registered in storyboard.
    /// - Note: If you need to create cell interface from code, use `registerNibless(_:)` method
    open func register<T:ModelTransfer>(_ cellClass:T.Type, mappingBlock: ((ViewModelMapping) -> Void)? = nil) where T: UICollectionViewCell
    {
        viewFactory.registerCellClass(cellClass, mappingBlock: mappingBlock)
    }
    
    /// Registers mapping from model class to `cellClass`.
    open func registerNibless<T:ModelTransfer>(_ cellClass:T.Type, mappingBlock: ((ViewModelMapping) -> Void)? = nil) where T: UICollectionViewCell
    {
        viewFactory.registerNiblessCellClass(cellClass, mappingBlock: mappingBlock)
    }
    
    /// Registers nib with `nibName` mapping from model class to `cellClass`.
    open func registerNibNamed<T:ModelTransfer>(_ nibName: String, for cellClass: T.Type, mappingBlock: ((ViewModelMapping) -> Void)? = nil) where T: UICollectionViewCell
    {
        viewFactory.registerNibNamed(nibName, forCellClass: cellClass, mappingBlock: mappingBlock)
    }
    
    /// Registers mapping from model class to suppplementary view of `headerClass` type for UICollectionElementKindSectionHeader.
    ///
    /// Method will automatically check for nib with the same name as `headerClass`. If it exists - nib will be registered instead of class.
    open func registerHeader<T:ModelTransfer>(_ headerClass : T.Type, mappingBlock: ((ViewModelMapping) -> Void)? = nil) where T: UICollectionReusableView
    {
        viewFactory.registerSupplementaryClass(T.self, forKind: UICollectionView.elementKindSectionHeader, mappingBlock: mappingBlock)
    }
    
    /// Registers mapping from model class to suppplementary view of `footerClass` type for UICollectionElementKindSectionFooter.
    ///
    /// Method will automatically check for nib with the same name as `footerClass`. If it exists - nib will be registered instead of class.
    open func registerFooter<T:ModelTransfer>(_ footerClass: T.Type, mappingBlock: ((ViewModelMapping) -> Void)? = nil) where T:UICollectionReusableView
    {
        viewFactory.registerSupplementaryClass(T.self, forKind: UICollectionView.elementKindSectionFooter, mappingBlock: mappingBlock)
    }
    
    /// Registers mapping from model class to supplementary view of `headerClass` type with `nibName` for UICollectionElementKindSectionHeader.
    open func registerNibNamed<T:ModelTransfer>(_ nibName: String, forHeader headerClass: T.Type, mappingBlock: ((ViewModelMapping) -> Void)? = nil) where T:UICollectionReusableView
    {
        viewFactory.registerNibNamed(nibName, forSupplementaryClass: T.self, forKind: UICollectionView.elementKindSectionHeader, mappingBlock: mappingBlock)
    }
    
    /// Registers mapping from model class to supplementary view of `footerClass` type with `nibName` for UICollectionElementKindSectionFooter.
    open func registerNibNamed<T:ModelTransfer>(_ nibName: String, forFooter footerClass: T.Type, mappingBlock: ((ViewModelMapping) -> Void)? = nil) where T:UICollectionReusableView
    {
        viewFactory.registerNibNamed(nibName, forSupplementaryClass: T.self, forKind: UICollectionView.elementKindSectionFooter, mappingBlock: mappingBlock)
    }
    
    /// Registers mapping from model class to suppplementary view of `supplementaryClass` type for supplementary `kind`.
    ///
    /// Method will automatically check for nib with the same name as `supplementaryClass`. If it exists - nib will be registered instead of class.
    open func registerSupplementary<T:ModelTransfer>(_ supplementaryClass: T.Type, forKind kind: String, mappingBlock: ((ViewModelMapping) -> Void)? = nil) where T:UICollectionReusableView
    {
        viewFactory.registerSupplementaryClass(T.self, forKind: kind, mappingBlock: mappingBlock)
    }
    
    /// Registers mapping from model class to supplementary view of `supplementaryClass` type with `nibName` for supplementary `kind`.
    open func registerNibNamed<T:ModelTransfer>(_ nibName: String, forSupplementary supplementaryClass: T.Type, ofKind kind: String, mappingBlock: ((ViewModelMapping) -> Void)? = nil) where T:UICollectionReusableView
    {
        viewFactory.registerNibNamed(nibName, forSupplementaryClass: T.self, forKind: kind, mappingBlock: mappingBlock)
    }
    
    /// Registers mapping from model class to supplementary view of `supplementaryClass` type for supplementary `kind`.
    open func registerNiblessSupplementary<T:ModelTransfer>(_ supplementaryClass: T.Type, forKind kind: String, mappingBlock: ((ViewModelMapping) -> Void)? = nil) where T:UICollectionReusableView {
        viewFactory.registerNiblessSupplementaryClass(supplementaryClass, forKind: kind, mappingBlock: mappingBlock)
    }
    
    /// Registers mapping from model class to header view of `headerClass` type for `UICollectionElementKindSectionHeader`.
    open func registerNiblessHeader<T:ModelTransfer>(_ headerClass: T.Type, mappingBlock: ((ViewModelMapping) -> Void)? = nil) where T:UICollectionReusableView {
        registerNiblessSupplementary(T.self, forKind: UICollectionView.elementKindSectionHeader)
    }
    
    /// Registers mapping from model class to footer view of `footerClass` type for `UICollectionElementKindSectionFooter`.
    open func registerNiblessFooter<T:ModelTransfer>(_ footerClass: T.Type, mappingBlock: ((ViewModelMapping) -> Void)? = nil) where T:UICollectionReusableView {
        registerNiblessSupplementary(T.self, forKind: UICollectionView.elementKindSectionFooter)
    }
    
    /// Unregisters `cellClass` from `DTCollectionViewManager` and `UICollectionView`.
    open func unregister<T:ModelTransfer>(_ cellClass: T.Type) where T: UICollectionViewCell {
        viewFactory.unregisterCellClass(T.self)
    }
    
    /// Unregisters `headerClass` from `DTCollectionViewManager` and `UICollectionView`.
    open func unregisterHeader<T:ModelTransfer>(_ headerClass: T.Type) where T:UICollectionReusableView {
        unregisterSupplementary(T.self, forKind: UICollectionView.elementKindSectionHeader)
    }
    
    /// Unregisters `footerClass` from `DTCollectionViewManager` and `UICollectionView`.
    open func unregisterFooter<T:ModelTransfer>(_ headerClass: T.Type) where T:UICollectionReusableView {
        unregisterSupplementary(T.self, forKind: UICollectionView.elementKindSectionFooter)
    }
    
    /// Unregisters `supplementaryClass` of `kind` from `DTCollectionViewManager` and `UICollectionView`.
    open func unregisterSupplementary<T:ModelTransfer>(_ supplementaryClass: T.Type, forKind kind: String) where T:UICollectionReusableView {
        viewFactory.unregisterSupplementaryClass(T.self, forKind: kind)
    }
}
