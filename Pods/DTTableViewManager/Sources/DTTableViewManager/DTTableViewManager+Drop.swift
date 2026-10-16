//
//  DTTableViewManager+Drop.swift
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

/// Extension for drop events (UITableViewDropDelegate)
public extension DTTableViewManager
{
    #if os(iOS)
    
    /// Registers `closure` to be executed when `UITableViewDropDelegate.tableView(_:performDropWith:)` method is called.
    func performDropWithCoordinator(_ closure: @escaping (UITableViewDropCoordinator) -> Void) {
        tableDropDelegate?.appendNonCellReaction(.performDropWithCoordinator, closure: closure)
    }
    
    /// Registers `closure` to be executed when `UITableViewDropDelegate.tableView(_:canHandle:)` method is called.
    func canHandleDropSession(_ closure: @escaping (UIDropSession) -> Bool) {
        tableDropDelegate?.appendNonCellReaction(.canHandleDropSession, closure: closure)
    }
    
    /// Registers `closure` to be executed when `UITableViewDropDelegate.tableView(_:dropSessionDidEnter:)` method is called.
    func dropSessionDidEnter(_ closure: @escaping (UIDropSession) -> Void) {
        tableDropDelegate?.appendNonCellReaction(.dropSessionDidEnter, closure: closure)
    }
    
    /// Registers `closure` to be executed when `UITableViewDropDelegate.tableView(_:dropSessionDidUpdate:withDestination:)` method is called.
    func dropSessionDidUpdate(_ closure: @escaping (UIDropSession, IndexPath?) -> UITableViewDropProposal) {
        tableDropDelegate?.appendNonCellReaction(.dropSessionDidUpdateWithDestinationIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed when `UITableViewDropDelegate.tableView(_:dropSessionDidExit:)` method is called.
    func dropSessionDidExit(_ closure: @escaping (UIDropSession) -> Void) {
        tableDropDelegate?.appendNonCellReaction(.dropSessionDidExit, closure: closure)
    }
    
    /// Registers `closure` to be executed when `UITableViewDropDelegate.tableView(_:dropSessionDidEnd:)` method is called.
    func dropSessionDidEnd(_ closure: @escaping (UIDropSession) -> Void) {
        tableDropDelegate?.appendNonCellReaction(.dropSessionDidEnd, closure: closure)
    }
    
    /// Registers `closure` to be executed when `UITableViewDropDelegate.tableView(_:dropPreviewParametersForRowAt:)` method is called.
    func dropPreviewParameters(_ closure: @escaping (IndexPath) -> UIDragPreviewParameters?) {
        tableDropDelegate?.appendNonCellReaction(.dropPreviewParametersForRowAtIndexPath, closure: closure)
    }
    
    /// Convenience method for dropping `item` into `placeholder`.
    /// Returns `DTTableViewDropPlaceholderContext`, which is a replacement for `UITableViewDropPlaceholderContext`, that automatically handles drop if you are using `MemoryStorage`. It also automatically dispatches insertion to `DispatchQueue.main`.
    func drop(_ item: UIDragItem, to placeholder: UITableViewDropPlaceholder,
                   with coordinator: UITableViewDropCoordinator) -> DTTableViewDropPlaceholderContext {
        let context = coordinator.drop(item, to: placeholder)
        return DTTableViewDropPlaceholderContext(context: context, storage: storage)
    }
    
    #endif
}
