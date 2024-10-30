//
//  TableViewHeaderFooterViewModelMapping.swift
//  DTTableViewManager
//
//  Created by Denys Telezhkin on 22.06.2022.
//  Copyright © 2022 Denys Telezhkin. All rights reserved.
//

import Foundation
import DTModelStorage
import UIKit

/// Header footer - model mapping
open class TableViewHeaderFooterViewModelMapping<View: UIView, Model>: SupplementaryViewModelMapping<View, Model>, SupplementaryViewModelMappingProtocolGeneric {
    /// View type
    public typealias View = View
    /// Model type
    public typealias Model = Model
    
    /// Reuse identifier to be used for reusable cells.
    public var reuseIdentifier : String
    
    /// Xib name for mapping. This value will not be nil only if XIBs are used for this particular mapping.
    public var xibName: String?
    
    /// Bundle in which resources for this mapping will be searched for. For example, `DTTableViewManager` uses this property to get bundle, from which xib file for `UITableViewCell` will be retrieved. Defaults to `Bundle(for: Cell.self)`.
    /// When used for events that rely on modelClass(`.eventsModelMapping(viewType: modelClass:` method) defaults to `Bundle.main`.
    public var bundle: Bundle
    
    /// Type-erased update block, that will be called when `ModelTransfer` `update(with:)` method needs to be executed.
    public let updateBlock : (View, Model) -> Void
    
    private var _supplementaryDequeueClosure: ((_ containerView: UITableView, _ model: Model, _ indexPath: IndexPath) -> View?)?
    
    /// Creates `ViewModelMapping` for UITableView header/footer registration.
    /// - Parameters:
    ///   - kind: kind of supplementary view. `DTTableViewElementSectionHeader` for headers and `DTTableViewElementSectionFooter` for footers.
    ///   - headerFooterConfiguration: Header/footer handler closure to be executed when header/footer is dequeued.
    ///   - mapping: mapping closure, that is executed at the end of initializer to allow mapping customization.
    public init(kind: String,
                headerFooterConfiguration: @escaping ((View, Model, Int) -> Void),
                mapping: ((TableViewHeaderFooterViewModelMapping<View, Model>) -> Void)?)
    {
        xibName = String(describing: View.self)
        reuseIdentifier = String(describing: View.self)
        updateBlock = { _, _ in }
        bundle = Bundle(for: View.self)
        super.init(viewClass: View.self, viewType: .supplementaryView(kind: kind))
        _supplementaryDequeueClosure = { [weak self] tableView, model, indexPath in
            guard let self = self else { return nil }
            if let headerFooterView = tableView.dequeueReusableHeaderFooterView(withIdentifier: self.reuseIdentifier) {
                if let typedHeaderFooterView = headerFooterView as? View {
                    headerFooterConfiguration(typedHeaderFooterView, model, indexPath.section)
                }
                return headerFooterView as? View
            } else {
                if let type = self.viewClass as? UIView.Type {
                    if let loadedFromXib = self.loadViewFromXib(viewClass: type) as? View {
                        headerFooterConfiguration(loadedFromXib, model, indexPath.section)
                        return loadedFromXib
                    }
                }
                return nil
            }
        }
        mapping?(self)
    }
    
    /// Creates `ViewModelMapping` for UITableView header/footer registration. This initializer is used when header/footer conforms to `ModelTransfer` protocol.
    /// - Parameters:
    ///   - kind: kind of supplementary view. `DTTableViewElementSectionHeader` for headers and `DTTableViewElementSectionFooter` for footers.
    ///   - headerFooterConfiguration: Header/footer handler closure to be executed when header/footer is dequeued.
    ///   - mapping: mapping closure, that is executed at the end of initializer to allow mapping customization.
    public init(kind: String,
                headerFooterConfiguration: @escaping ((View, View.ModelType, Int) -> Void),
                mapping: ((TableViewHeaderFooterViewModelMapping<View, Model>) -> Void)?)
    where View: ModelTransfer, Model == View.ModelType
    {
        xibName = String(describing: View.self)
        reuseIdentifier = String(describing: View.self)
        updateBlock = { view, model in
            view.update(with: model)
        }
        bundle = Bundle(for: View.self)
        super.init(viewClass: View.self, viewType: .supplementaryView(kind: kind))
        _supplementaryDequeueClosure = { [weak self] tableView, model, indexPath in
            guard let self = self else { return nil }
            if let headerFooterView = tableView.dequeueReusableHeaderFooterView(withIdentifier: self.reuseIdentifier) {
                if let typedHeaderFooterView = headerFooterView as? View {
                    headerFooterConfiguration(typedHeaderFooterView, model, indexPath.section)
                }
                return headerFooterView as? View
            } else {
                if let type = self.viewClass as? UIView.Type {
                    if let loadedFromXib = self.loadViewFromXib(viewClass: type) as? View {
                        headerFooterConfiguration(loadedFromXib, model, indexPath.section)
                        return loadedFromXib
                    }
                }
            }
            return nil
        }
        mapping?(self)
    }
    
    /// Dequeues reusable header footer view for `model`, `indexPath` from `tableView`. Calls `headerFooterConfiguration` closure, that was passed to initializer, then calls `ModelTransfer.update(with:)` if this header/footer view conforms to `ModelTransfer` protocol.
    /// - Parameters:
    ///   - tableView: UITableView instance to dequeue header/footer from
    ///   - model: model object, that was mapped to header/footer type.
    ///   - indexPath: IndexPath, at which header/footer is going to be displayed.
    /// - Returns: dequeued configured UIView instance.
    open override func dequeueConfiguredReusableSupplementaryView(for tableView: UITableView, kind: String, model: Any, indexPath: IndexPath) -> UIView? {
        guard viewType == .supplementaryView(kind: kind) else {
            return nil
        }
        guard let model = model as? Model, let view = _supplementaryDequeueClosure?(tableView, model, indexPath) else {
            return nil
        }
        updateBlock(view, model)
        return view
    }
    
    @available(*, unavailable, message: "Dequeing supplementary view from table view mapping is not supported")
    /// Unavailable method
    open override func dequeueConfiguredReusableSupplementaryView(for collectionView: UICollectionView, kind: String, model: Any, indexPath: IndexPath) -> UICollectionReusableView? {
        preconditionFailure("\(#function) should not be called with UICollectionView supplementary views")
    }

    internal func loadViewFromXib(viewClass: UIView.Type) -> UIView? {
        guard let xibName = xibName else { return nil }
        guard let topLevelObjects = bundle.loadNibNamed(xibName, owner: nil, options: nil) else {
            return nil
        }

        return topLevelObjects.lazy.compactMap { $0 as? UIView }.first(where: { $0.isKind(of: viewClass) })
    }
}
