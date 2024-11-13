//
//  HostingConfigurationViewModelMapping.swift
//  DTCollectionViewManager
//
//  Created by Denys Telezhkin on 05.10.2022.
//  Copyright © 2022 Denys Telezhkin. All rights reserved.
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
import SwiftUI

#if swift(>=5.7) && !canImport(AppKit) || (canImport(AppKit) && swift(>=5.7.1)) // Xcode 14.0 AND macCatalyst on Xcode 14.1 (which will have swift> 5.7.1)

@available(iOS 16, tvOS 16, *)
/// View - model mapping for creating UIHostingConfiguration from Model.
open class HostingConfigurationViewModelMapping<Content: View, Background: View, Model, Cell: UICollectionViewCell>: CellViewModelMapping<Content, Model>, CellViewModelMappingProtocolGeneric {
    /// Cell type
    public typealias Cell = Cell
    /// Model type
    public typealias Model = Model
    
    enum Kind {
        case `default`((Cell, Model, IndexPath) -> UIHostingConfiguration<Content, Background>)
        case stateUpdating((UICellConfigurationState, Cell, Model, IndexPath) -> UIHostingConfiguration<Content, Background>)
    }
    
    private let kind: Kind
    private var _cellRegistration: UICollectionView.CellRegistration<Cell, Model>?
    private var _cellDequeueClosure: ((_ containerView: UICollectionView, _ indexPath: IndexPath, _ model: Model) -> Cell?) {
        return { [weak self] collectionView, indexPath, model in
            guard let self, let registration = self._cellRegistration else { return nil }
            return collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: model)
        }
    }
    private var _cellConfigurationHandler: (Cell, Model, IndexPath) -> Void {
        return { [weak self] cell, model, indexPath in
            guard let self else { return }
            switch self.kind {
            case .default(let configuration):
                cell.contentConfiguration = configuration(cell, model, indexPath)
            case .stateUpdating(let configuration):
                cell.configurationUpdateHandler = { cell, state in
                    guard let cell = cell as? Cell else { return }
                    cell.contentConfiguration = configuration(state, cell, model, indexPath)
                }
            }
        }
    }
    
    /// Creates hosting configuration mapping
    /// - Parameters:
    ///   - cellConfiguration: Closure to configure SwiftUI hosting configuration on a cell
    ///   - mapping: additional mapping customization after all properties have been initialized.
    public init(cellConfiguration: @escaping (Cell, Model, IndexPath) -> UIHostingConfiguration<Content, Background>, mapping: ((HostingConfigurationViewModelMapping<Content, Background, Model, Cell>) -> Void)?) {
        self.kind = .default(cellConfiguration)
        super.init(viewClass: Cell.self)
        mapping?(self)
        _cellRegistration = UICollectionView.CellRegistration(handler: { [weak self] cell, indexPath, model in
            self?._cellConfigurationHandler(cell, model, indexPath)
        })
    }
    
    /// Creates hosting configuration mapping
    /// - Parameters:
    ///   - cellConfiguration: Closure to configure SwiftUI hosting configuration on a cell, based on state changes
    ///   - mapping: additional mapping customization after all properties have been initialized.
    public init(cellConfiguration: @escaping (UICellConfigurationState, Cell, Model, IndexPath) -> UIHostingConfiguration<Content, Background>, mapping: ((HostingConfigurationViewModelMapping<Content, Background, Model, Cell>) -> Void)?) {
        self.kind = .stateUpdating(cellConfiguration)
        super.init(viewClass: Cell.self)
        mapping?(self)
        _cellRegistration = UICollectionView.CellRegistration(handler: { [weak self] cell, indexPath, model in
            self?._cellConfigurationHandler(cell, model, indexPath)
        })
    }
    
    /// Dequeues reusable cell for `model`, `indexPath` from `tableView`.
    /// - Parameters:
    ///   - tableView: UITableView instance to dequeue cell from
    ///   - model: model object, that was mapped to cell type.
    ///   - indexPath: IndexPath, at which cell is going to be displayed.
    /// - Returns: dequeued configured UITableViewCell instance.
    open override func dequeueConfiguredReusableCell(for tableView: UITableView, model: Any, indexPath: IndexPath) -> UITableViewCell? {
        preconditionFailure("This method should not be used in UICollectionView cell view model mapping")
    }
    
    /// Updates cell with model
    /// - Parameters:
    ///   - cell: cell instance. Must be of `UITableViewCell`.Type.
    ///   - indexPath: indexPath of a cell
    ///   - model: model, mapped to a cell.
    open override func updateCell(cell: Any, at indexPath: IndexPath, with model: Any) {
        guard let cell = cell as? Cell else {
            preconditionFailure("Cannot update a cell, which is not a \(Cell.self)")
        }
        guard let model = model as? Model else {
            assertionFailure("Cannot update cell with model, that is not of \(Model.self) type.")
            return
        }
        _cellConfigurationHandler(cell, model, indexPath)
    }
    
    @available(*, unavailable, message:"Dequeing collection view cell from UITableView is not supported")
    /// Unsupported method
    open override func dequeueConfiguredReusableCell(for collectionView: UICollectionView, model: Any, indexPath: IndexPath) -> UICollectionViewCell? {
        guard let model = model as? Model else { return nil }
        return _cellDequeueClosure(collectionView, indexPath, model)
    }
}

#endif
