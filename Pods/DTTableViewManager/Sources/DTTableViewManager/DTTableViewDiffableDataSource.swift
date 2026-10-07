//
//  DTTableViewDiffableDataSource.swift
//  DTTableViewManager
//
//  Created by Denys Telezhkin on 11.07.2021.
//  Copyright © 2021 Denys Telezhkin. All rights reserved.
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

// swiftlint:disable generic_type_name

@available(iOS 13, tvOS 13, *)
class DTTableViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>: UITableViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>, Storage, SupplementaryStorage
    where SectionIdentifierType : Hashable, ItemIdentifierType : Hashable
{
    let tableView: UITableView
    weak var manager: DTTableViewManager?
    let viewFactory: TableViewFactory
    let modelProvider: (IndexPath, ItemIdentifierType) -> Any
    
    var configuration: TableViewConfiguration? {
        manager?.configuration
    }
    
    var delegate: UITableViewDataSource? {
        manager?.delegate as? UITableViewDataSource
    }
    
    var dtTableViewDataSource: DTTableViewDataSource? {
        manager?.tableDataSource
    }
    
    /// Returns a header model for specified section index or nil.
    var headerModelProvider: ((Int) -> Any?)?
    
    /// Returns a footer model for specified section index or nil
    var footerModelProvider: ((Int) -> Any?)?

    private lazy var _supplementaryModelProvider: ((String, IndexPath) -> Any?)? = { [weak self] kind, indexPath in
        if let headerModel = self?.headerModelProvider, self?.supplementaryHeaderKind == kind {
            return headerModel(indexPath.section)
        }
        if let footerModel = self?.footerModelProvider, self?.supplementaryFooterKind == kind {
            return footerModel(indexPath.section)
        }
        return nil
    }
    
    /// Returns supplementary model for specified section indexPath and supplementary kind, or nil. Setter for this property is overridden to allow calling `headerModelProvider` and `footerModelProvider` closures.
    var supplementaryModelProvider: ((String, IndexPath) -> Any?)? {
        get {
            return _supplementaryModelProvider
        }
        set {
            _supplementaryModelProvider = { [weak self] kind, indexPath in
                if let headerModel = self?.headerModelProvider, self?.supplementaryHeaderKind == kind {
                    return headerModel(indexPath.section)
                }
                if let footerModel = self?.footerModelProvider, self?.supplementaryFooterKind == kind {
                    return footerModel(indexPath.section)
                }
                return newValue?(kind, indexPath)
            }
        }
    }
    
    /// Supplementary kind for header in current storage
    var supplementaryHeaderKind: String?
    
    /// Supplementary kind for footer in current storage
    var supplementaryFooterKind: String?
    
    init(tableView: UITableView, viewFactory: TableViewFactory, manager: DTTableViewManager, cellProvider: @escaping UITableViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>.CellProvider, modelProvider: @escaping (IndexPath, ItemIdentifierType) -> Any) {
        self.tableView = tableView
        self.viewFactory = viewFactory
        self.manager = manager
        self.modelProvider = modelProvider
        super.init(tableView: tableView, cellProvider: cellProvider)
    }
    
    func numberOfSections() -> Int {
        numberOfSections(in: tableView)
    }
    
    func numberOfItems(inSection section: Int) -> Int {
        tableView(tableView, numberOfRowsInSection: section)
    }
    
    func item(at indexPath: IndexPath) -> Any? {
        guard let itemIdentifier = itemIdentifier(for: indexPath) else {
            return nil
        }
        return modelProvider(indexPath, itemIdentifier)
    }
    
    /// Implementation for `UITableViewDataSource` protocol
    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let model = RuntimeHelper.recursivelyUnwrapAnyValue(item(at: indexPath) as Any) else {
            manager?.anomalyHandler.reportAnomaly(.nilCellModel(indexPath))
            return UITableViewCell()
        }
        guard let cell = viewFactory.cellForModel(model, atIndexPath: indexPath) else {
            return UITableViewCell()
        }
        _ = EventReaction.performReaction(from: viewFactory.mappings,
                                                    signature: EventMethodSignature.configureCell.rawValue,
                                                    view: cell,
                                                    model: model,
                                                    location: indexPath)
        return cell
    }
    
    /// Implementation for `UITableViewDataSource` protocol
    open override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if configuration?.sectionHeaderStyle == .view { return nil }
        
        return dtTableViewDataSource?.headerModel(forSection: section) as? String
    }
    
    /// Implementation for `UITableViewDataSource` protocol
    open override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if configuration?.sectionFooterStyle == .view { return nil }
        
        return dtTableViewDataSource?.footerModel(forSection: section) as? String
    }
    
    /// Implementation for `UITableViewDataSource` protocol
    open override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        _ = dtTableViewDataSource?.perform4ArgumentCellReaction(.moveRowAtIndexPathToIndexPath,
                                         argument: destinationIndexPath,
                                         location: sourceIndexPath,
                                         provideCell: true)
        delegate?.tableView?(tableView, moveRowAt: sourceIndexPath, to: destinationIndexPath)
    }
    
    /// Implementation for `UITableViewDataSource` protocol
    open override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        defer { delegate?.tableView?(tableView, commit: editingStyle, forRowAt: indexPath) }
        _ = dtTableViewDataSource?.perform4ArgumentCellReaction(.commitEditingStyleForRowAtIndexPath,
                                         argument: editingStyle,
                                         location: indexPath,
                                         provideCell: true)
    }
    
    /// Implementation for `UITableViewDataSource` protocol
    open override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if let canEdit = dtTableViewDataSource?.performCellReaction(.canEditRowAtIndexPath, location: indexPath, provideCell: false) as? Bool {
            return canEdit
        }
        return delegate?.tableView?(tableView, canEditRowAt: indexPath) ?? false
    }
    
    /// Implementation for `UITableViewDataSource` protocol
    open override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        if let canMove = dtTableViewDataSource?.performCellReaction(.canMoveRowAtIndexPath, location: indexPath, provideCell: true) as? Bool {
            return canMove
        }
        return delegate?.tableView?(tableView, canMoveRowAt: indexPath) ?? false
    }
    
    #if os(iOS)
    /// Implementation for `UITableViewDataSource` protocol
    open override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if let _ = dtTableViewDataSource?.unmappedReactions.first(where: { $0.methodSignature == EventMethodSignature.sectionIndexTitlesForTableView.rawValue }) {
            return dtTableViewDataSource?.performNonCellReaction(.sectionIndexTitlesForTableView) as? [String]
        }
        return delegate?.sectionIndexTitles?(for: tableView) ?? nil
    }

    /// Implementation for `UITableViewDataSource` protocol
    open override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        if let section = dtTableViewDataSource?.performNonCellReaction(.sectionForSectionIndexTitleAtIndex,
                                                argumentOne: title,
                                                argumentTwo: index) as? Int {
            return section
        }
        return delegate?.tableView?(tableView, sectionForSectionIndexTitle: title, at: index) ?? 0
    }
    #endif
}
