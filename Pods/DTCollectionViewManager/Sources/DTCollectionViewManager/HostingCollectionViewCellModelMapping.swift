//
//  HostingCollectionViewCellModelMapping.swift
//  DTCollectionViewManager
//
//  Created by Denys Telezhkin on 24.06.2022.
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
import UIKit
import SwiftUI
import DTModelStorage

@available(iOS 13, tvOS 13, *)
/// Configuration to be applied to `HostingCollectionViewCell`.
public struct HostingCollectionViewCellConfiguration<Content:View> {
    
    /// Parent view controller, that will have hosting controller added as a child, when cell is dequeued. Setting this property to nil causes assertionFailure.
    public weak var parentController: UIViewController?
    
    /// Closure, that allows customizing which UIHostingController is created for hosted cell.
    public var hostingControllerMaker: (Content) -> UIHostingController<Content> = { UIHostingController(rootView: $0) }
    
    /// Configuration handler for `HostingCollectionViewCell`, that is being run every time cell is updated.
    public var configureCell: (UICollectionViewCell) -> Void = { _ in }
    
    /// Background color set for `HostingCollectionViewCell`. Defaults to .clear.
    public var backgroundColor: UIColor? = .clear
    
    /// Background color set for `HostingCollectionViewCell`.`contentView`. Defaults to .clear.
    public var contentViewBackgroundColor: UIColor? = .clear
    
    /// Background color set for UIHostingViewController.view. Defaults to .clear.
    public var hostingViewBackgroundColor: UIColor? = .clear
}

@available(iOS 13, tvOS 13, *)
/// Cell - Model mapping for SwiftUI hosted cell.
open class HostingCellViewModelMapping<Content: View, Model>: CellViewModelMapping<Content, Model>, CellViewModelMappingProtocolGeneric {
    /// Cell type
    public typealias Cell = HostingCollectionViewCell<Content, Model>
    /// Model type
    public typealias Model = Model
    
    /// Configuration to use when updating cell
    public var configuration = HostingCollectionViewCellConfiguration<Content>()
    
    /// Custom subclass type of HostingCollectionViewCell. When set, resets reuseIdentifier to subclass type.
    public var hostingCellSubclass: HostingCollectionViewCell<Content, Model>.Type = HostingCollectionViewCell.self {
        didSet {
            reuseIdentifier = "\(hostingCellSubclass.self)"
        }
    }
    
    /// Reuse identifier to be used for reusable cells. Mappings for UICollectionViewCell on iOS 14 / tvOS 14 and higher ignore this parameter.
    public var reuseIdentifier : String
    
    private var _cellConfigurationHandler: ((Cell, Model, IndexPath) -> Void)?
    private var _cellDequeueClosure: ((_ containerView: UICollectionView, _ model: Model, _ indexPath: IndexPath) -> Cell?)?
    private var _cellRegistration: Any?
    
    /// Creates hosting cell model mapping
    /// - Parameters:
    ///   - cellContent: closure, creating SwiftUI view
    ///   - parentViewController: parent view controller, to which UIHostingController will be added as child.
    ///   - mapping: mapping closure
    public init(cellContent: @escaping ((Model, IndexPath) -> Content),
                parentViewController: UIViewController?,
                mapping: ((HostingCellViewModelMapping<Content, Model>) -> Void)?) {
        reuseIdentifier = "\(HostingCollectionViewCell<Content, Model>.self)"
        super.init(viewClass: HostingCollectionViewCell<Content, Model>.self)
        configuration.parentController = parentViewController
        _cellDequeueClosure = { [weak self] collectionView, model, indexPath in
            guard let self = self else { return nil }
            if #available(iOS 14, tvOS 14, *) {
                if let registration = self._cellRegistration as? UICollectionView.CellRegistration<HostingCollectionViewCell<Content, Model>, Model> {
                    return collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: model)
                }
            }
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.reuseIdentifier, for: indexPath)
            if #unavailable(iOS 14, tvOS 14), let cell = cell as? Cell {
                // We only need to update cell, if cell registrations are unavailable, because when they are, update is already called.
                self._cellConfigurationHandler?(cell, model, indexPath)
            }
            return cell as? Cell
        }
        _cellConfigurationHandler = { [weak self] cell, model, indexPath in
            guard let configuration = self?.configuration else { return }
            cell.updateWith(rootView: cellContent(model, indexPath), configuration: configuration)
        }
        mapping?(self)
        if #available(iOS 14, tvOS 14, *) {
            let registration = UICollectionView.CellRegistration<HostingCollectionViewCell<Content, Model>, Model>(handler: { [weak self] cell, indexPath, model in
                guard let configuration = self?.configuration else { return }
                cell.updateWith(rootView: cellContent(model, indexPath), configuration: configuration)
                })
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
            preconditionFailure("Cannot update a cell, which is not a \(Cell.self) with model that is not \(Model.self)")
        }
        _cellConfigurationHandler?(cell, model, indexPath)
    }
    
    @available(*, unavailable, message: "Dequeuing UITableViewCell from collection view mapping is not supported.")
    /// Unavailable method
    open override func dequeueConfiguredReusableCell(for tableView: UITableView, model: Any, indexPath: IndexPath) -> UITableViewCell? {
        preconditionFailure("This method should not be used in UICollectionView cell view model mapping")
    }
    
    /// Dequeues reusable cell for `model`, `indexPath` from `collectionView`.
    /// - Parameters:
    ///   - collectionView: UICollectionView instance to dequeue cell from
    ///   - model: model object, that was mapped to cell type.
    ///   - indexPath: IndexPath, at which cell is going to be displayed.
    /// - Returns: dequeued configured UICollectionViewCell instance.
    open override func dequeueConfiguredReusableCell(for collectionView: UICollectionView, model: Any, indexPath: IndexPath) -> UICollectionViewCell? {
        guard let model = model as? Model else { return nil }
        return _cellDequeueClosure?(collectionView, model, indexPath)
    }
}
