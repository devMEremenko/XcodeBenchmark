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

/// Extension for registering UITableViewDataSource events
public extension DTTableViewManager
{
    /// Registers `closure` to be executed, when `UITableViewDataSource.tableView(_:canMoveRowAt:)` method is called for `cellClass`.
    func canMove<Cell:ModelTransfer>(_ cellClass: Cell.Type, _ closure: @escaping (Cell, Cell.ModelType, IndexPath) -> Bool) where Cell: UITableViewCell {
        tableDataSource?.appendReaction(for: Cell.self, signature: EventMethodSignature.canMoveRowAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UITableViewDataSource.tableView(_:moveRowAt:to:)` method is called for `cellClass`.
    /// - warning: This method requires items to be moved without animations, since animation has already happened when user moved those cells. If you use `MemoryStorage`, it's appropriate to call `memoryStorage.moveItemWithoutAnimation(from:to:)` method to achieve desired behavior.
    /// - SeeAlso: 'tableView:moveRowAt:to:' method
    func move<Cell:ModelTransfer>(_ cellClass: Cell.Type, _ closure: @escaping (_ destinationIndexPath: IndexPath, Cell, Cell.ModelType, _ sourceIndexPath: IndexPath) -> Void) where Cell: UITableViewCell {
        tableDataSource?.append4ArgumentReaction(for: Cell.self,
                                                 signature: .moveRowAtIndexPathToIndexPath,
                                                 closure: closure)
    }
    
    #if os(iOS)
    /// Registers `closure` to be executed, when `UITableViewDataSource.sectionIndexTitles(for:_) ` method is called.
    func sectionIndexTitles(_ closure: @escaping () -> [String]?) {
        tableDataSource?.appendNonCellReaction(.sectionIndexTitlesForTableView, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UITableViewDataSource.tableView(_:sectionForSectionIndexTitle:at:)` method is called.
    func sectionForSectionIndexTitle(_ closure: @escaping (String, Int) -> Int) {
        tableDataSource?.appendNonCellReaction(.sectionForSectionIndexTitleAtIndex, closure: closure)
    }
    #endif
    
    /// Registers `closure` to be executed, when `UITableViewDelegate.tableView(_:commitEditingStyle:forRowAt:)` method is called for `cellClass`.
    func commitEditingStyle<Cell:ModelTransfer>(for cellClass: Cell.Type, _ closure: @escaping (UITableViewCell.EditingStyle, Cell, Cell.ModelType, IndexPath) -> Void) where Cell: UITableViewCell {
        tableDataSource?.append4ArgumentReaction(for: Cell.self,
                                                 signature: .commitEditingStyleForRowAtIndexPath,
                                                 closure: closure)
    }
    
    /// Registers `closure` to be executed in `UITableViewDelegate.tableView(_:canEditCellForRowAt:)` method, when it's called for cell which model is of `itemType`.
    func canEditCell<Model>(withItem itemType: Model.Type, _ closure: @escaping (Model, IndexPath) -> Bool) {
        tableDataSource?.appendReaction(viewType: .cell, for: Model.self, signature: EventMethodSignature.canEditRowAtIndexPath, closure: closure)
    }
}

/// Extension for datasource events (UITableViewDataSource)
public extension CellViewModelMappingProtocolGeneric {
    /// Registers `closure` to be executed, when `UITableViewDataSource.tableView(_:canMoveRowAt:)` method is called.
    func canMove(_ closure: @escaping (Cell, Model, IndexPath) -> Bool) {
        reactions.append(EventReaction(viewType: Cell.self, modelType: Model.self, signature: EventMethodSignature.canMoveRowAtIndexPath.rawValue, closure))
    }
    
    /// Registers `closure` to be executed, when `UITableViewDataSource.tableView(_:moveRowAt:to:)` method is called.
    /// - warning: This method requires items to be moved without animations, since animation has already happened when user moved those cells. If you use `MemoryStorage`, it's appropriate to call `memoryStorage.moveItemWithoutAnimation(from:to:)` method to achieve desired behavior.
    /// - SeeAlso: 'tableView:moveRowAt:to:' method
    func moveRowTo(_ closure: @escaping (_ destinationIndexPath: IndexPath, Cell, Model, _ sourceIndexPath: IndexPath) -> Void) {
        reactions.append(FourArgumentsEventReaction(Cell.self, modelType: Model.self, argument: IndexPath.self, signature: EventMethodSignature.moveRowAtIndexPathToIndexPath.rawValue, closure))
    }
    
    /// Registers `closure` to be executed, when `UITableViewDataSource.tableView(_:commitEditingStyle:forRowAt:)` method is called.
    func commitEditingStyle(_ closure: @escaping (UITableViewCell.EditingStyle, Cell, Model, IndexPath) -> Void) {
        reactions.append(FourArgumentsEventReaction(Cell.self, modelType: Model.self,
                                                    argument: UITableViewCell.EditingStyle.self,
                                                    signature: EventMethodSignature.commitEditingStyleForRowAtIndexPath.rawValue,
                                                    closure))
    }
    
    /// Registers `closure` to be executed in `UITableViewDataSource.tableView(_:canEditCellForRowAt:)` method, when it's called.
    func canEditCell(_ closure: @escaping (Model, IndexPath) -> Bool) {
        reactions.append(EventReaction(modelType: Model.self, signature: EventMethodSignature.canEditRowAtIndexPath.rawValue, closure))
    }
}
