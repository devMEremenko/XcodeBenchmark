//
//  CollectionViewCellModelMapping.swift
//  DTCollectionViewManager
//
//  Created by Denys Telezhkin on 22.06.2022.
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
import DTModelStorage
import UIKit

/// UICollectionViewCell - Model mapping
open class CollectionViewCellModelMapping<Cell: UICollectionViewCell, Model>: CellViewModelMapping<Cell, Model>, CellViewModelMappingProtocolGeneric {
    /// Cell type
    public typealias Cell = Cell
    /// Model type
    public typealias Model = Model
    /// Reuse identifier to be used for reusable cells. Mappings for UICollectionViewCell and UICollectionReusableView on iOS 14 / tvOS 14 and higher ignore this parameter unless you are using storyboard prototyped cells or supplementary views.
    public var reuseIdentifier : String
    
    /// Xib name for mapping. This value will not be nil only if XIBs are used for this particular mapping.
    public var xibName: String?
    
    /// Bundle in which resources for this mapping will be searched for. For example, `DTCollectionViewManager` uses this property to get bundle, from which xib file for `UICollectionViewCell` will be retrieved. Defaults to `Bundle(for: Cell.self)`.
    /// When used for events that rely on modelClass(`.eventsModelMapping(viewType: modelClass:` method) defaults to `Bundle.main`.
    public var bundle: Bundle
    
    /// If cell is designed in storyboard, and thus don't require explicit UICollectionView registration, please set this property to true. Defaults to false.
    public var cellRegisteredByStoryboard: Bool = false
    
    /// Type-erased update block, that will be called when `ModelTransfer` `update(with:)` method needs to be executed.
    public let updateBlock : (Cell, Model) -> Void
    
    private var _cellConfigurationHandler: ((Cell, Model, IndexPath) -> Void)?
    private var _cellDequeueClosure: ((_ containerView: UICollectionView, _ model: Model, _ indexPath: IndexPath) -> Cell?)?
    
    private var _cellRegistration: Any?
    
    /// Creates `ViewModelMapping` for UICollectionViewCell registration.
    /// - Parameters:
    ///   - cellConfiguration: Cell handler closure to be executed when cell is dequeued.
    ///   - mapping: mapping closure, that is executed at the end of initializer to allow mapping customization.
    public init(cellConfiguration: @escaping ((Cell, Model, IndexPath) -> Void),
                          mapping: ((CollectionViewCellModelMapping<Cell, Model>) -> Void)?)
    {
        
        xibName = String(describing: Cell.self)
        reuseIdentifier = String(describing: Cell.self)
        bundle = Bundle(for: Cell.self)
        updateBlock = { _, _ in }
        super.init(viewClass: Cell.self)
        _cellConfigurationHandler = { cell, model, indexPath in
            cellConfiguration(cell, model, indexPath)
        }
        _cellDequeueClosure = { [weak self] collectionView, model, indexPath in
            guard let self = self else { return nil }
            if !self.cellRegisteredByStoryboard, #available(iOS 14, tvOS 14, *) {
                if let registration = self._cellRegistration as? UICollectionView.CellRegistration<Cell, Model> {
                    return collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: model)
                }
            }
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.reuseIdentifier, for: indexPath)
            if let cell = cell as? Cell {
                cellConfiguration(cell, model, indexPath)
            }
            return cell as? Cell
        }
        mapping?(self)
        if !self.cellRegisteredByStoryboard, #available(iOS 14, tvOS 14, *) {
            let registration : UICollectionView.CellRegistration<Cell, Model>

            if let nibName = self.xibName, UINib.nibExists(withNibName: nibName, inBundle: self.bundle) {
                registration = .init(cellNib: UINib(nibName: nibName, bundle: self.bundle), handler: { cell, indexPath, model in
                    cellConfiguration(cell, model, indexPath)
                })
            } else {
                registration = .init(handler: { cell, indexPath, model in
                    cellConfiguration(cell, model, indexPath)
                })
            }
            self._cellRegistration = registration
        }
    }
    
    /// Creates `ViewModelMapping` for UICollectionViewCell registration. This initializer is used, when UICollectionViewCell conforms to `ModelTransfer` protocol.
    /// - Parameters:
    ///   - cellConfiguration: Cell handler closure to be executed when cell is dequeued.
    ///   - mapping: mapping closure, that is executed at the end of initializer to allow mapping customization.
    public init(cellConfiguration: @escaping ((Cell, Cell.ModelType, IndexPath) -> Void),
                mapping: ((CollectionViewCellModelMapping<Cell, Cell.ModelType>) -> Void)?)
        where Cell: ModelTransfer, Cell.ModelType == Model
    {
        xibName = String(describing: Cell.self)
        reuseIdentifier = String(describing: Cell.self)
        bundle = Bundle(for: Cell.self)
        updateBlock = { view, model in
            view.update(with: model)
        }
        super.init(viewClass: Cell.self)
        
        _cellConfigurationHandler = { cell, model, indexPath in
            cellConfiguration(cell, model, indexPath)
        }
        _cellDequeueClosure = { [weak self] collectionView, model, indexPath in
            guard let self = self else {
                return nil
            }
            if !self.cellRegisteredByStoryboard, #available(iOS 14, tvOS 14, *) {
                if let registration = self._cellRegistration as? UICollectionView.CellRegistration<Cell, Cell.ModelType> {
                    return collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: model)
                }
            }
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.reuseIdentifier, for: indexPath)
            if let cell = cell as? Cell {
                cellConfiguration(cell, model, indexPath)
            }
            return cell as? Cell
        }
        mapping?(self)

        if !self.cellRegisteredByStoryboard, #available(iOS 14, tvOS 14, *) {
            let registration : UICollectionView.CellRegistration<Cell, Model>

            if let nibName = self.xibName, UINib.nibExists(withNibName: nibName, inBundle: self.bundle) {
                registration = .init(cellNib: UINib(nibName: nibName, bundle: self.bundle), handler: { cell, indexPath, model in
                    cellConfiguration(cell, model, indexPath)
                })
            } else {
                registration = .init(handler: { cell, indexPath, model in
                    cellConfiguration(cell, model, indexPath)
                })
            }
            self._cellRegistration = registration
        }
    }
    
    /// Updates cell with model
    /// - Parameters:
    ///   - cell: cell instance. Must be of `UICollectionViewCell`.Type.
    ///   - indexPath: indexPath of a cell
    ///   - model: model, mapped to a cell.
    open override func updateCell(cell: Any, at indexPath: IndexPath, with model: Any) {
        guard let cell = cell as? Cell, let model = model as? Model else {
            preconditionFailure("Cannot update a cell, which is not a \(Cell.self) with model that is not a \(Model.self)")
        }
        _cellConfigurationHandler?(cell, model, indexPath)
        updateBlock(cell, model)
    }
    
    /// Dequeues reusable cell for `model`, `indexPath` from `collectionView`. Calls `cellConfiguration` closure, that was passed to initializer, then calls `ModelTransfer.update(with:)` if this cell conforms to `ModelTransfer` protocol.
    /// - Parameters:
    ///   - collectionView: UICollectionView instance to dequeue cell from
    ///   - model: model object, that was mapped to cell type.
    ///   - indexPath: IndexPath, at which cell is going to be displayed.
    /// - Returns: dequeued configured UICollectionViewCell instance.
    open override func dequeueConfiguredReusableCell(for collectionView: UICollectionView, model: Any, indexPath: IndexPath) -> UICollectionViewCell? {
        guard let model = model as? Model, let cell = _cellDequeueClosure?(collectionView, model, indexPath) else {
            return nil
        }
        updateBlock(cell, model)
        return cell
    }
    
    
    @available(*, unavailable, message: "Dequeuing UITableViewCell from collection view mapping is not supported")
    /// Unavailable method
    open override func dequeueConfiguredReusableCell(for tableView: UITableView, model: Any, indexPath: IndexPath) -> UITableViewCell? {
        preconditionFailure("Cannot dequeue UITableViewCell from CollectionViewCell mapping")
    }
}
