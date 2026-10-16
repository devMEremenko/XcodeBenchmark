//
//  Storage.swift
//  DTModelStorage
//
//  Created by Denys Telezhkin on 06.07.15.
//  Copyright (c) 2015 Denys Telezhkin. All rights reserved.
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

/// `Storage` protocol is used to define common interface for storage classes.
public protocol Storage : AnyObject
{
    /// Returns number of sections in storage.
    func numberOfSections() -> Int
    
    /// Returns number of items in section.
    func numberOfItems(inSection section: Int) -> Int
    
    /// Returns item at concrete indexPath.
    func item(at indexPath: IndexPath) -> Any?
}

/// `SupplementaryStorage` is used to handle header/footer and supplementary models in storage.
public protocol SupplementaryStorage : AnyObject
{
    /// Returns a header model for specified section index or nil.
    var headerModelProvider: ((_ sectionIndex: Int) -> Any?)? { get set }
    
    /// Returns a footer model for specified section index or nil
    var footerModelProvider: ((_ sectionIndex: Int) -> Any?)? { get set }
    
    /// Returns supplementary model for specified section indexPath and supplementary kind, or nil.
    var supplementaryModelProvider: ((_ kind: String, _ sectionIndexPath: IndexPath) -> Any?)? { get set }
    
    /// Supplementary kind for header in current storage
    var supplementaryHeaderKind: String? { get set }
    
    /// Supplementary kind for footer in current storage
    var supplementaryFooterKind: String?  { get set }
}

extension SupplementaryStorage {
    /// Configures storage for using with UITableView
    public func configureForTableViewUsage()
    {
        supplementaryHeaderKind = DTTableViewElementSectionHeader
        supplementaryFooterKind = DTTableViewElementSectionFooter
    }
    
    /// Configures storage for using with UICollectionViewFlowLayout
    public func configureForCollectionViewFlowLayoutUsage()
    {
        supplementaryHeaderKind = UICollectionView.elementKindSectionHeader
        supplementaryFooterKind = UICollectionView.elementKindSectionFooter
    }
    
/// Returns header model from section with section `index` or nil, if it was not set.
    /// - Requires: supplementaryHeaderKind to be set prior to calling this method
    public func headerModel(forSection index: Int) -> Any? {
        return headerModelProvider?(index)
    }
    
    /// Returns footer model from section with section `index` or nil, if it was not set.
    /// - Requires: supplementaryFooterKind to be set prior to calling this method
    public func footerModel(forSection index: Int) -> Any? {
        return footerModelProvider?(index)
    }
    
    /// Returns supplementary model of `kind` for section at `indexPath`.
    public func supplementaryModel(ofKind kind: String, forSectionAt indexPath: IndexPath) -> Any? {
        return supplementaryModelProvider?(kind, indexPath)
    }
}

extension SupplementaryStorage {
    /// Sets section header `models`, using `supplementaryHeaderKind`.
    public func setSectionHeaderModels<T>(_ models: [T])
    {
        headerModelProvider = { index in
            guard index < models.count else { return nil }
            return models[index]
        }
    }
    
    /// Sets section footer `models`, using `supplementaryFooterKind`.
    public func setSectionFooterModels<T>(_ models: [T])
    {
        footerModelProvider = { index in
            guard index < models.count else { return nil }
            return models[index]
        }
    }
}
