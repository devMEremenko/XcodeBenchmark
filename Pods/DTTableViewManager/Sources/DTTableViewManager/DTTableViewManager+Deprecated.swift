//
//  DTTableViewManager+Deprecated.swift
//  DTTableViewManager
//
//  Created by Denys Telezhkin on 29.07.2020.
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
import DTModelStorage

/// Deprecated methods
public extension DTTableViewManager {
    @available(*, deprecated, message: "Please use register(_:mapping:handler:) and set xibName in mapping closure instead.")
    /// Registers nib with `nibName` mapping from model class to `cellClass`.
    func registerNibNamed<T:ModelTransfer>(_ nibName: String, for cellClass: T.Type, mapping: ((TableViewCellModelMapping<T, T.ModelType>) -> Void)? = nil)
    {
        register(T.self, mapping:  { mapping in
            mapping.xibName = nibName
        })
    }
    
    @available(*, deprecated, message: "Please use registerHeader(_:mapping:handler:) instead.")
    /// Registers mapping from model class to header view of `headerClass` type.
    ///
    /// This method is intended to be used for headers created from code - without UI made in XIB.
    /// This method also sets TableViewConfiguration.sectionHeaderStyle property to .view.
    func registerNiblessHeader<T:ModelTransfer>(_ headerClass : T.Type, mapping: ((TableViewHeaderFooterViewModelMapping<T, T.ModelType>) -> Void)? = nil) where T: UITableViewHeaderFooterView
    {
        configuration.sectionHeaderStyle = .view
        registerHeader(T.self, mapping:  { mappingInstance in
            mappingInstance.xibName = nil
            mapping?(mappingInstance)
        })
    }
    
    @available(*, deprecated, message: "Please use registerFooter(_:mapping:handler:) instead.")
    /// Registers mapping from model class to footer view of `footerClass` type.
    ///
    /// This method is intended to be used for footers created from code - without UI made in XIB.
    /// This method also sets TableViewConfiguration.sectionFooterStyle property to .view.
    func registerNiblessFooter<T:ModelTransfer>(_ footerClass : T.Type, mapping: ((TableViewHeaderFooterViewModelMapping<T, T.ModelType>) -> Void)? = nil) where T: UITableViewHeaderFooterView
    {
        configuration.sectionFooterStyle = .view
        viewFactory.registerSupplementaryClass(T.self, ofKind: DTTableViewElementSectionFooter, handler: { _, _, _ in }, mapping: { mappingInstance in
            mappingInstance.xibName = nil
            mapping?(mappingInstance)
        })
    }
    
    @available(*, deprecated, message: "Please use registerHeader(_:mapping:handler:) and set xibName in mapping closure instead.")
    /// Registers mapping from model class to headerView view of `headerClass` type with `nibName`.
    ///
    /// This method also sets TableViewConfiguration.sectionHeaderStyle property to .view.
    /// - Note: Views does not need to be `UITableViewHeaderFooterView`, if it's a `UIView` subclass, it also will be created from XIB.
    /// - SeeAlso: `UIView+XibLoading`.
    func registerNibNamed<T:ModelTransfer>(_ nibName: String, forHeader headerClass: T.Type, mapping: ((TableViewHeaderFooterViewModelMapping<T, T.ModelType>) -> Void)? = nil)
    {
        configuration.sectionHeaderStyle = .view
        registerHeader(T.self, mapping:  { mappingInstance in
            mappingInstance.xibName = nibName
            mapping?(mappingInstance)
        })
    }
    
    @available(*, deprecated, message: "Please use registerFooter(_:mapping:handler:) and set xibName in mapping closure instead.")
    /// Registers mapping from model class to headerView view of `footerClass` type with `nibName`.
    ///
    /// This method also sets TableViewConfiguration.sectionFooterStyle property to .view.
    /// - Note: Views does not need to be `UITableViewHeaderFooterView`, if it's a `UIView` subclass, it also will be created from XIB.
    /// - SeeAlso: `UIView+XibLoading`.
    func registerNibNamed<T:ModelTransfer>(_ nibName: String, forFooter footerClass: T.Type, mapping: ((TableViewHeaderFooterViewModelMapping<T, T.ModelType>) -> Void)? = nil)
    {
        configuration.sectionFooterStyle = .view
        registerFooter(T.self, mapping:  { mappingInstance in
            mappingInstance.xibName = nibName
            mapping?(mappingInstance)
        })
    }
    
    @available(*, deprecated, message: "Please use handler parameter in register(_:mapping:handler:) method instead.")
    /// Registers `closure` to be executed, when `UITableView` requests `cellClass` in `UITableViewDataSource.tableView(_:cellForRowAt:)` method and cell is being configured.
    ///
    /// This closure will be performed *after* cell is created and `update(with:)` method is called.
    func configure<T:ModelTransfer>(_ cellClass:T.Type, _ closure: @escaping (T, T.ModelType, IndexPath) -> Void) where T: UITableViewCell
    {
        tableDataSource?.appendReaction(for: T.self, signature: .configureCell, closure: closure)
    }
    
    @available(*, deprecated, message: "Please use handler parameter in registerHeader(_:mapping:handler:) method instead.")
    /// Registers `closure` to be executed, when `UITableView` requests `headerClass` in `UITableViewDelegate.tableView(_:viewForHeaderInSection:)` method and header is being configured.
    ///
    /// This closure will be performed *after* header is created and `update(with:)` method is called.
    func configureHeader<T:ModelTransfer>(_ headerClass: T.Type, _ closure: @escaping (T, T.ModelType, Int) -> Void) where T: UIView
    {
        tableDelegate?.appendReaction(forSupplementaryKind: DTTableViewElementSectionHeader, supplementaryClass: T.self, signature: .configureHeader, closure: closure)
    }
    
    @available(*, deprecated, message: "Please use handler parameter in registerFooter(_:mapping:handler:) method instead.")
    /// Registers `closure` to be executed, when `UITableView` requests `footerClass` in `UITableViewDelegate.tableView(_:viewForFooterInSection:)` method and footer is being configured.
    ///
    /// This closure will be performed *after* footer is created and `update(with:)` method is called.
    func configureFooter<T:ModelTransfer>(_ footerClass: T.Type, _ closure: @escaping (T, T.ModelType, Int) -> Void) where T: UIView
    {
        tableDelegate?.appendReaction(forSupplementaryKind: DTTableViewElementSectionFooter, supplementaryClass: T.self, signature: .configureFooter, closure: closure)
    }
    
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
}
