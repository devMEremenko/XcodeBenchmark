//
//  BackwardsCompatibility.swift
//  DTModelStorage
//
//  Created by Denys Telezhkin on 30.07.2020.
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

extension SectionLocatable {
    /// Supplementaries dictionary
    @available(*, unavailable, message: "Please use storage.supplementaryModelProvider closure to provide supplementaries.")
    var supplementaries: [String: [Int:Any]] { return [:] }
    
    @available(*, unavailable, message: "Please use storage.supplementaryModelProvider closure to provide supplementaries.")
    /// Returns supplementary model of `kind` at `index` or nil, if it was not found
    public func supplementaryModel(ofKind kind: String, atIndex index: Int) -> Any?
    {
        return nil
    }
    
    @available(*, unavailable, message: "Please use storage.supplementaryModelProvider closure to provide supplementaries.")
    /// Sets supplementary `model` for `kind` at `index`
    public func setSupplementaryModel(_ model : Any?, forKind kind: String, atIndex index: Int)
    {
    }
}

extension SupplementaryStorage {
    @available(*, unavailable, message: "Please use storage.supplementaryModel closure instead.")
    /// Sets supplementaries `models`, using `kind`.
    public func setSupplementaries(_ models: [[Int: Any]], forKind kind: String)
    {
    }
    
    @available(*, unavailable, message: "Please use storage.headerModelProvider closure instead.")
    /// Sets section header `model` for section at `sectionIndex`
    ///
    /// This method calls delegate?.storageNeedsReloading() method at the end, causing UI to be updated.
    /// - SeeAlso: `configureForTableViewUsage`
    /// - SeeAlso: `configureForCollectionViewUsage`
    public func setSectionHeaderModel<T>(_ model: T?, forSection sectionIndex: Int)
    {
    }
    
    @available(*, unavailable, message: "Please use storage.footerModelProvider closure instead.")
    /// Sets section footer `model` for section at `sectionIndex`
    ///
    /// This method calls delegate?.storageNeedsReloading() method at the end, causing UI to be updated.
    /// - SeeAlso: `configureForTableViewUsage`
    /// - SeeAlso: `configureForCollectionViewUsage`
    public func setSectionFooterModel<T>(_ model: T?, forSection sectionIndex: Int)
    {
    }
}
