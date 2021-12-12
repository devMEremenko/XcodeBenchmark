//
//  DTTableViewDropDelegate.swift
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

#if os(iOS)
    
/// Object, that implements `UITableViewDropDelegate` for `DTTableViewManager`.
open class DTTableViewDropDelegate: DTTableViewDelegateWrapper, UITableViewDropDelegate {

    /// Implementation for `UITableViewDropDelegate` protocol
    open func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        _ = performNonCellReaction(.performDropWithCoordinator, argument: coordinator)
        (delegate as? UITableViewDropDelegate)?.tableView(tableView, performDropWith: coordinator)
    }
    
    override func delegateWasReset() {
        tableView?.dropDelegate = nil
        tableView?.dropDelegate = self
    }
    
    /// Implementation for `UITableViewDropDelegate` protocol
    open func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        if let canHandle = performNonCellReaction(.canHandleDropSession, argument: session) as? Bool {
            return canHandle
        }
        return (delegate as? UITableViewDropDelegate)?.tableView?(tableView, canHandle: session) ?? true
    }
    
    /// Implementation for `UITableViewDropDelegate` protocol
    open func tableView(_ tableView: UITableView, dropSessionDidEnter session: UIDropSession) {
        _ = performNonCellReaction(.dropSessionDidEnter, argument: session)
        (delegate as? UITableViewDropDelegate)?.tableView?(tableView, dropSessionDidEnter: session)
    }
    
    /// Implementation for `UITableViewDropDelegate` protocol
    open func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        if let proposal = performNonCellReaction(.dropSessionDidUpdateWithDestinationIndexPath,
                                                 argumentOne: session,
                                                 argumentTwo: destinationIndexPath) as? UITableViewDropProposal {
            return proposal
        }
        return (delegate as? UITableViewDropDelegate)?.tableView?(tableView,
                                                                  dropSessionDidUpdate: session,
                                                                  withDestinationIndexPath: destinationIndexPath) ?? UITableViewDropProposal(operation: .cancel)
    }
    
    /// Implementation for `UITableViewDropDelegate` protocol
    open func tableView(_ tableView: UITableView, dropSessionDidExit session: UIDropSession) {
        _ = performNonCellReaction(.dropSessionDidExit, argument: session)
        (delegate as? UITableViewDropDelegate)?.tableView?(tableView, dropSessionDidExit: session)
    }
    
    /// Implementation for `UITableViewDropDelegate` protocol
    open func tableView(_ tableView: UITableView, dropSessionDidEnd session: UIDropSession) {
        _ = performNonCellReaction(.dropSessionDidEnd, argument: session)
        (delegate as? UITableViewDropDelegate)?.tableView?(tableView, dropSessionDidEnd: session)
    }
    
    /// Implementation for `UITableViewDropDelegate` protocol
    open func tableView(_ tableView: UITableView, dropPreviewParametersForRowAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        if let reaction = unmappedReactions.first(where: { $0.methodSignature == EventMethodSignature.dropPreviewParametersForRowAtIndexPath.rawValue }) {
            return reaction.performWithArguments((indexPath, 0, 0)) as? UIDragPreviewParameters
        }
        return (delegate as? UITableViewDropDelegate)?.tableView?(tableView,
                                                                  dropPreviewParametersForRowAt: indexPath)
    }
}
#endif
