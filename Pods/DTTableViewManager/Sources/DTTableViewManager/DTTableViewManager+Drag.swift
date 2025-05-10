//
//  DTTableViewManager+Drag.swift
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

/// Extension for drag events (UITableViewDragDelegate)
public extension DTTableViewManager
{
    #if os(iOS)
    
    /// Registers `closure` to be executed when `UITableViewDragDelegate.tableView(_:itemsForBeginning:at:)` method is called for `cellClass`.
    func itemsForBeginningDragSession<Cell:ModelTransfer>(from cellClass: Cell.Type, _ closure: @escaping (UIDragSession, Cell, Cell.ModelType, IndexPath) -> [UIDragItem]) where Cell:UITableViewCell
    {
        tableDragDelegate?.append4ArgumentReaction(for: Cell.self,
                                                   signature: .itemsForBeginningDragSession,
                                                   closure: closure)
    }
    
    /// Registers `closure` to be executed when `UITableViewDragDelegate.tableView(_:itemsForAddingTo:at:point:)` method is called for `cellClass`
    func itemsForAddingToDragSession<Cell:ModelTransfer>(from cellClass: Cell.Type, _ closure: @escaping (UIDragSession, CGPoint, Cell, Cell.ModelType, IndexPath) -> [UIDragItem]) where Cell: UITableViewCell
    {
        tableDragDelegate?.append5ArgumentReaction(for: Cell.self,
                                                   signature: .itemsForAddingToDragSession,
                                                   closure: closure)
    }
    
    /// Registers `closure` to be executed when `UITableViewDragDelegate.tableView(_:dragPreviewParametersForRowAt:)` method is called for `cellClass`
    func dragPreviewParameters<Cell:ModelTransfer>(for cellClass: Cell.Type, _ closure: @escaping (Cell, Cell.ModelType, IndexPath) -> UIDragPreviewParameters?) where Cell:UITableViewCell {
        tableDragDelegate?.appendReaction(for: Cell.self,
                                          signature: .dragPreviewParametersForRowAtIndexPath,
                                          closure: closure)
    }
    
    /// Registers `closure` to be executed when `UITableViewDragDelegate.tableView(_:dragSessionWillBegin:)` method is called.
    func dragSessionWillBegin(_ closure: @escaping (UIDragSession) -> Void) {
        tableDragDelegate?.appendNonCellReaction(.dragSessionWillBegin, closure: closure)
    }
    
    /// Registers `closure` to be executed when `UITableViewDragDelegate.tableView(_:dragSessionDidEnd:)` method is called.
    func dragSessionDidEnd(_ closure: @escaping (UIDragSession) -> Void) {
        tableDragDelegate?.appendNonCellReaction(.dragSessionDidEnd, closure: closure)
    }
    
    /// Registers `closure` to be executed when `UITableViewDragDelegate.tableView(_:dragSessionAllowsMoveOperation)` method is called.
    func dragSessionAllowsMoveOperation(_ closure: @escaping (UIDragSession) -> Bool) {
        tableDragDelegate?.appendNonCellReaction(.dragSessionAllowsMoveOperation, closure: closure)
    }
    
    /// Registers `closure` to be executed when `UITableViewDragDelegate.tableView(_:dragSessionIsRestrictedToDraggingApplication:)` method is called.
    func dragSessionIsRestrictedToDraggingApplication(_ closure: @escaping (UIDragSession) -> Bool) {
        tableDragDelegate?.appendNonCellReaction(.dragSessionIsRestrictedToDraggingApplication, closure: closure)
    }
    #endif
}

/// Extension for drag events (UITableViewDragDelegate)
public extension CellViewModelMappingProtocolGeneric {
    #if os(iOS)
    /// Registers `closure` to be executed when `UITableViewDragDelegate.tableView(_:itemsForBeginning:at:)` method is called.
    func itemsForBeginningDragSession(_ closure: @escaping (UIDragSession, Cell, Model, IndexPath) -> [UIDragItem])
    {
        reactions.append(FourArgumentsEventReaction(Cell.self, modelType: Model.self, argument: UIDragSession.self,
                                                    signature: EventMethodSignature.itemsForBeginningDragSession.rawValue,
                                                    closure))
    }
    
    /// Registers `closure` to be executed when `UITableViewDragDelegate.tableView(_:itemsForAddingTo:at:point:)` method is called.
    func itemsForAddingToDragSession(_ closure: @escaping (UIDragSession, CGPoint, Cell, Model, IndexPath) -> [UIDragItem])
    {
        reactions.append(FiveArgumentsEventReaction(Cell.self, modelType: Model.self, argumentOne: UIDragSession.self, argumentTwo: CGPoint.self,
                                                    signature: EventMethodSignature.itemsForAddingToDragSession.rawValue, closure))
    }
    
    /// Registers `closure` to be executed when `UITableViewDragDelegate.tableView(_:dragPreviewParametersForRowAt:)` method is called.
    func dragPreviewParameters(_ closure: @escaping (Cell, Model, IndexPath) -> UIDragPreviewParameters?) {
        reactions.append(EventReaction(viewType: Cell.self, modelType: Model.self, signature: EventMethodSignature.dragPreviewParametersForRowAtIndexPath.rawValue, closure))
    }
    #endif
}
