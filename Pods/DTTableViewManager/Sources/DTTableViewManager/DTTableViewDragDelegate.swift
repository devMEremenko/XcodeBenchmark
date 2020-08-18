//
//  DTTableViewDragDelegate.swift
//  DTTableViewManager
//
//  Created by Denys Telezhkin on 20.08.17.
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

#if os(iOS)
        
/// Object, that implements `UITableViewDragDelegate` methods for `DTTableViewManager`.
open class DTTableViewDragDelegate: DTTableViewDelegateWrapper, UITableViewDragDelegate {

    /// Implementation for `UITableViewDragDelegate` protocol
    open func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession,
                          at indexPath: IndexPath) -> [UIDragItem]
    {
        if let items = perform4ArgumentCellReaction(.itemsForBeginningDragSession,
                                                     argument: session,
                                                     location: indexPath,
                                                     provideCell: true) as? [UIDragItem]
        {
            return items
        }
        return (delegate as? UITableViewDragDelegate)?.tableView(tableView, itemsForBeginning: session, at:indexPath) ?? []
    }
    
    /// Implementation for `UITableViewDragDelegate` protocol
    open func tableView(_ tableView: UITableView, itemsForAddingTo session: UIDragSession,
                          at indexPath: IndexPath,
                          point: CGPoint) -> [UIDragItem]
    {
        if let items = perform5ArgumentCellReaction(.itemsForAddingToDragSession,
                                           argumentOne: session,
                                           argumentTwo: point,
                                           location: indexPath,
                                           provideCell: true) as? [UIDragItem] {
            return items
        }
        return (delegate as? UITableViewDragDelegate)?.tableView?(tableView, itemsForAddingTo: session, at: indexPath, point: point) ?? []
    }
    
    /// Implementation for `UITableViewDragDelegate` protocol
    open func tableView(_ tableView: UITableView, dragPreviewParametersForRowAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        if let reaction = cellReaction(.dragPreviewParametersForRowAtIndexPath, location: indexPath) {
            return performNillableCellReaction(reaction, location: indexPath, provideCell: true) as? UIDragPreviewParameters
        }
        return (delegate as? UITableViewDragDelegate)?.tableView?(tableView, dragPreviewParametersForRowAt: indexPath)
    }
    
    /// Implementation for `UITableViewDragDelegate` protocol
    open func tableView(_ tableView: UITableView, dragSessionWillBegin session: UIDragSession) {
        _ = performNonCellReaction(.dragSessionWillBegin, argument: session)
        (delegate as? UITableViewDragDelegate)?.tableView?(tableView, dragSessionWillBegin: session)
    }
    
    /// Implementation for `UITableViewDragDelegate` protocol
    open func tableView(_ tableView: UITableView, dragSessionDidEnd session: UIDragSession) {
        _ = performNonCellReaction(.dragSessionDidEnd, argument: session)
        (delegate as? UITableViewDragDelegate)?.tableView?(tableView, dragSessionDidEnd: session)
    }
    
    /// Implementation for `UITableViewDragDelegate` protocol
    open func tableView(_ tableView: UITableView, dragSessionAllowsMoveOperation session: UIDragSession) -> Bool {
        if let allows = performNonCellReaction(.dragSessionAllowsMoveOperation, argument: session) as? Bool {
            return allows
        }
        return (delegate as? UITableViewDragDelegate)?.tableView?(tableView, dragSessionAllowsMoveOperation: session) ?? true
    }
    
    /// Implementation for `UITableViewDragDelegate` protocol
    open func tableView(_ tableView: UITableView, dragSessionIsRestrictedToDraggingApplication session: UIDragSession) -> Bool {
        if let allows = performNonCellReaction(.dragSessionIsRestrictedToDraggingApplication, argument: session) as? Bool {
            return allows
        }
        return (delegate as? UITableViewDragDelegate)?.tableView?(tableView, dragSessionIsRestrictedToDraggingApplication: session) ?? false
    }
    
    override func delegateWasReset() {
        tableView?.dragDelegate = nil
        tableView?.dragDelegate = self
    }
}
#endif
