//
//  DTTableViewDataSource.swift
//  DTTableViewManager
//
//  Created by Denys Telezhkin on 13.08.17.
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

/// Object, that implements `UITableViewDataSource` methods for `DTTableViewManager`.
open class DTTableViewDataSource : DTTableViewDelegateWrapper, UITableViewDataSource {
    
    override func delegateWasReset() {
        if tableView?.dataSource === self {
            tableView?.dataSource = nil
            tableView?.dataSource = self
        }
    }
    
    /// Implementation for `UITableViewDataSource` protocol
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return storage?.numberOfItems(inSection: section) ?? 0
    }
    
    /// Implementation for `UITableViewDataSource` protocol
    open func numberOfSections(in tableView: UITableView) -> Int {
        return storage?.numberOfSections() ?? 0
    }
    
    /// Implementation for `UITableViewDataSource` protocol
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let model = RuntimeHelper.recursivelyUnwrapAnyValue(storage?.item(at: indexPath) as Any) else {
            manager?.anomalyHandler.reportAnomaly(.nilCellModel(indexPath))
            return UITableViewCell()
        }
        guard let cell = viewFactory?.cellForModel(model, atIndexPath: indexPath) else {
            return UITableViewCell()
        }
        _ = EventReaction.performReaction(from: viewFactory?.mappings ?? [],
                                                    signature: EventMethodSignature.configureCell.rawValue,
                                                    view: cell,
                                                    model: model,
                                                    location: indexPath)
        return cell
    }
    
    /// Implementation for `UITableViewDataSource` protocol
    open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if configuration?.sectionHeaderStyle == .view { return nil }
        
        return headerModel(forSection: section) as? String
    }
    
    /// Implementation for `UITableViewDataSource` protocol
    open func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if configuration?.sectionFooterStyle == .view { return nil }
        
        return footerModel(forSection: section) as? String
    }
    
    /// Implementation for `UITableViewDataSource` protocol
    open func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        _ = perform4ArgumentCellReaction(.moveRowAtIndexPathToIndexPath,
                                         argument: destinationIndexPath,
                                         location: sourceIndexPath,
                                         provideCell: true)
        (delegate as? UITableViewDataSource)?.tableView?(tableView, moveRowAt: sourceIndexPath, to: destinationIndexPath)
    }
    
    /// Implementation for `UITableViewDataSource` protocol
    open func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        defer { (delegate as? UITableViewDataSource)?.tableView?(tableView, commit: editingStyle, forRowAt: indexPath) }
        _ = perform4ArgumentCellReaction(.commitEditingStyleForRowAtIndexPath,
                                         argument: editingStyle,
                                         location: indexPath,
                                         provideCell: true)
    }
    
    /// Implementation for `UITableViewDataSource` protocol
    open func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if let canEdit = performCellReaction(.canEditRowAtIndexPath, location: indexPath, provideCell: false) as? Bool {
            return canEdit
        }
        return (delegate as? UITableViewDataSource)?.tableView?(tableView, canEditRowAt: indexPath) ?? false
    }
    
    /// Implementation for `UITableViewDataSource` protocol
    open func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        if let canMove = performCellReaction(.canMoveRowAtIndexPath, location: indexPath, provideCell: true) as? Bool {
            return canMove
        }
        return (delegate as? UITableViewDataSource)?.tableView?(tableView, canMoveRowAt: indexPath) ?? false
    }
    
    #if os(iOS)
    /// Implementation for `UITableViewDataSource` protocol
    open func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if let _ = unmappedReactions.first(where: { $0.methodSignature == EventMethodSignature.sectionIndexTitlesForTableView.rawValue }) {
            return performNonCellReaction(.sectionIndexTitlesForTableView) as? [String]
        }
        return (delegate as? UITableViewDataSource)?.sectionIndexTitles?(for: tableView) ?? nil
    }

    /// Implementation for `UITableViewDataSource` protocol
    open func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        if let section = performNonCellReaction(.sectionForSectionIndexTitleAtIndex,
                                                argumentOne: title,
                                                argumentTwo: index) as? Int {
            return section
        }
        return (delegate as? UITableViewDataSource)?.tableView?(tableView, sectionForSectionIndexTitle: title, at: index) ?? 0
    }
    #endif
}
