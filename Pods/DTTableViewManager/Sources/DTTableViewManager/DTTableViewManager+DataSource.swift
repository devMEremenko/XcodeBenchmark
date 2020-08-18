//
//  DTTableViewManager+DataSource.swift
//  DTTableViewManager
//
//  Created by Denys Telezhkin on 26.08.17.
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

import Foundation
import UIKit
import DTModelStorage

extension DTTableViewManager
{
    /// Registers `closure` to be executed, when `UITableView` requests `cellClass` in `UITableViewDataSource.tableView(_:cellForRowAt:)` method and cell is being configured.
    ///
    /// This closure will be performed *after* cell is created and `update(with:)` method is called.
    open func configure<T:ModelTransfer>(_ cellClass:T.Type, _ closure: @escaping (T, T.ModelType, IndexPath) -> Void) where T: UITableViewCell
    {
        tableDataSource?.appendReaction(for: T.self, signature: .configureCell, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UITableView` requests `headerClass` in `UITableViewDelegate.tableView(_:viewForHeaderInSection:)` method and header is being configured.
    ///
    /// This closure will be performed *after* header is created and `update(with:)` method is called.
    open func configureHeader<T:ModelTransfer>(_ headerClass: T.Type, _ closure: @escaping (T, T.ModelType, Int) -> Void) where T: UIView
    {
        tableDelegate?.appendReaction(forSupplementaryKind: DTTableViewElementSectionHeader, supplementaryClass: T.self, signature: .configureHeader, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UITableView` requests `footerClass` in `UITableViewDelegate.tableView(_:viewForFooterInSection:)` method and footer is being configured.
    ///
    /// This closure will be performed *after* footer is created and `update(with:)` method is called.
    open func configureFooter<T:ModelTransfer>(_ footerClass: T.Type, _ closure: @escaping (T, T.ModelType, Int) -> Void) where T: UIView
    {
        tableDelegate?.appendReaction(forSupplementaryKind: DTTableViewElementSectionFooter, supplementaryClass: T.self, signature: .configureFooter, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UITableViewDelegate.tableView(_:canMoveRowAt:)` method is called for `cellClass`.
    open func canMove<T:ModelTransfer>(_ cellClass: T.Type, _ closure: @escaping (T, T.ModelType, IndexPath) -> Bool) where T: UITableViewCell {
        tableDataSource?.appendReaction(for: T.self, signature: EventMethodSignature.canMoveRowAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UITableViewDelegate.tableView(_:moveRowAt:to:)` method is called for `cellClass`.
    /// - warning: This method requires items to be moved without animations, since animation has already happened when user moved those cells. If you use `MemoryStorage`, it's appropriate to call `memoryStorage.moveItemWithoutAnimation(from:to:)` method to achieve desired behavior.
    /// - SeeAlso: 'tableView:moveRowAt:to:' method
    open func move<T:ModelTransfer>(_ cellClass: T.Type, _ closure: @escaping (_ destinationIndexPath: IndexPath, T, T.ModelType, _ sourceIndexPath: IndexPath) -> Void) where T: UITableViewCell {
        tableDataSource?.append4ArgumentReaction(for: T.self,
                                                 signature: .moveRowAtIndexPathToIndexPath,
                                                 closure: closure)
    }
    
    #if os(iOS)
    /// Registers `closure` to be executed, when `UITableViewDataSource.sectionIndexTitles(for:_) ` method is called.
    open func sectionIndexTitles(_ closure: @escaping () -> [String]?) {
        tableDataSource?.appendNonCellReaction(.sectionIndexTitlesForTableView, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UITableViewDataSource.tableView(_:sectionForSectionIndexTitle:at:)` method is called.
    open func sectionForSectionIndexTitle(_ closure: @escaping (String, Int) -> Int) {
        tableDataSource?.appendNonCellReaction(.sectionForSectionIndexTitleAtIndex, closure: closure)
    }
    #endif
    
    /// Registers `closure` to be executed, when `UITableViewDelegate.tableView(_:commitEditingStyle:forRowAt:)` method is called for `cellClass`.
    open func commitEditingStyle<T:ModelTransfer>(for cellClass: T.Type, _ closure: @escaping (UITableViewCell.EditingStyle, T, T.ModelType, IndexPath) -> Void) where T: UITableViewCell {
        tableDataSource?.append4ArgumentReaction(for: T.self,
                                                 signature: .commitEditingStyleForRowAtIndexPath,
                                                 closure: closure)
    }
    
    /// Registers `closure` to be executed in `UITableViewDelegate.tableView(_:canEditCellForRowAt:)` method, when it's called for cell which model is of `itemType`.
    open func canEditCell<T>(withItem itemType: T.Type, _ closure: @escaping (T, IndexPath) -> Bool) {
        tableDataSource?.appendReaction(for: T.self, signature: EventMethodSignature.canEditRowAtIndexPath, closure: closure)
    }
}
