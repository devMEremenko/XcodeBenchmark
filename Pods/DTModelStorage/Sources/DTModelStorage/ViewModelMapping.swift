//
//  ViewModelMapping.swift
//  DTModelStorage
//
//  Created by Denys Telezhkin on 27.11.15.
//  Copyright © 2015 Denys Telezhkin. All rights reserved.
//
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

/// ViewType enum allows differentiating between mappings for different kinds of views. For example, UICollectionView headers might use ViewType.supplementaryView(UICollectionElementKindSectionHeader) value.
public enum ViewType: Equatable
{
    case cell
    case supplementaryView(kind: String)
    
    /// Returns supplementaryKind for .supplementaryView case, nil for .cell case.
    /// - Returns supplementaryKind string
    public func supplementaryKind() -> String?
    {
        switch self
        {
        case .cell: return nil
        case .supplementaryView(let kind): return kind
        }
    }
    
    /// Returns mappings candidates of correct `viewType`, for which `modelTypeCheckingBlock` with `model` returns true.
    /// - Returns: Array of view model mappings
    /// - Note: Usually returned array will consist of 0 or 1 element. Multiple candidates will be returned when several mappings correspond to current model - this can happen in case of protocol or subclassed model.
    public func mappingCandidates(for mappings: [ViewModelMappingProtocol], withModel model: Any, at indexPath: IndexPath) -> [ViewModelMappingProtocol] {
        return mappings.filter { mapping -> Bool in
            guard let unwrappedModel = RuntimeHelper.recursivelyUnwrapAnyValue(model) else { return false }
            return self == mapping.viewType &&
                mapping.modelTypeCheckingBlock(unwrappedModel) &&
                mapping.condition.isCompatible(with: indexPath, model: model)
        }
    }
}


/// Defines condition, under which mapping is going to be applied.
public enum MappingCondition {
    
    // Mapping is applicable at all times
    case none
    
    // Mapping is applicable only in specific section
    case section(Int)
    
    // Mapping is applicable only under custom condition
    case custom((_ indexPath: IndexPath, _ model: Any) -> Bool)
    
    
    /// Defines whether mapping is compatible with `model` at `indexPath`.
    ///
    /// - Parameters:
    ///   - indexPath: location of the model in storage
    ///   - model: model to apply mapping to
    /// - Returns: whether current mapping condition is applicable.
    func isCompatible(with indexPath: IndexPath, model: Any) -> Bool {
        switch self {
        case .none: return true
        case .section(let section): return indexPath.section == section
        case .custom(let condition): return condition(indexPath, model)
        }
    }
}

/// Type-erased interface for `ViewModelMapping` generic class.
public protocol ViewModelMappingProtocol: class {
    var xibName: String? { get }
    var bundle: Bundle { get }
    var viewType : ViewType { get }
    var modelTypeCheckingBlock: (Any) -> Bool { get }
    var modelTypeTypeCheckingBlock: (Any.Type) -> Bool { get }
    var updateBlock : (Any, Any) -> Void { get }
    var viewClass: AnyClass { get }
    var condition: MappingCondition { get }
    var reuseIdentifier : String { get }
    var cellRegisteredByStoryboard: Bool { get }
    var supplementaryRegisteredByStoryboard : Bool { get }
    var reactions: [EventReaction] { get set }
    
    func updateCell(cell: Any, at indexPath: IndexPath, with model: Any)
    
    func dequeueConfiguredReusableCell(for collectionView: UICollectionView, model: Any, indexPath: IndexPath) -> UICollectionViewCell?
    func dequeueConfiguredReusableSupplementaryView(for collectionView: UICollectionView, kind: String, model: Any, indexPath: IndexPath) -> UICollectionReusableView?
    
    func dequeueConfiguredReusableCell(for tableView: UITableView, model: Any, indexPath: IndexPath) -> UITableViewCell?
    func dequeueConfiguredReusableSupplementaryView(for tableView: UITableView, kind: String, model: Any, indexPath: IndexPath) -> UIView?
}

//swiftlint:disable type_body_length

/// `ViewModelMapping` class serves to store mappings, and capture model and cell types.
open class ViewModelMapping<View: AnyObject, Model> : ViewModelMappingProtocol
{
    /// View type for this mapping
    public let viewType: ViewType
    
    /// View class, that will be used for current mapping
    public let viewClass: AnyClass
    
    /// Xib name for mapping. This value will not be nil only if XIBs are used for this particular mapping.
    public var xibName: String?
    
    /// Bundle in which resources for this mapping will be searched for. For example, `DTTableViewManager` uses this property to get bundle, from which xib file for `UITableViewCell` will be retrieved. Defaults to `Bundle(for: T.self)`.
    /// When used for events that rely on modelClass(`.eventsModelMapping(viewType: modelClass:` method) defaults to `Bundle.main`.
    public var bundle: Bundle
    
    /// Type checking block, that will verify whether passed model should be mapped to `viewClass`.
    public let modelTypeCheckingBlock: (Any) -> Bool
    
    /// Closure, that can be used to check model type when model is not available(generic context for example, when model Type is available only).
    public var modelTypeTypeCheckingBlock: (Any.Type) -> Bool = {
        $0 is Model.Type
    }
    
    /// Type-erased update block, that will be called when `ModelTransfer` `update(with:)` method needs to be executed.
    public let updateBlock : (Any, Any) -> Void
    
    /// Mapping condition, under which this mapping is going to work. Defaults to .none.
    public var condition: MappingCondition = .none
    
    /// Reuse identifier to be used for reusable views. Mappings for UICollectionViewCell and UICollectionReusableView on iOS 14 / tvOS 14 and higher ignore this parameter.
    public var reuseIdentifier : String
    
    /// If cell is designed in storyboard, and thus don't require explicit UITableView/UICollectionView registration, please set this property to true. Defaults to false.
    public var cellRegisteredByStoryboard: Bool = false
    
    /// If supplementary view is designed in storyboard, and thus don't require explicit UITableView/UICollectionView registration, please set this property to true. Defaults to false.
    public var supplementaryRegisteredByStoryboard : Bool = false
    
    /// Event reactions, attached to current mapping instance
    public var reactions: [EventReaction] = []
    
    private var _cellConfigurationHandler: ((Any, Any, IndexPath) -> Void)?
    private var _cellDequeueClosure: ((_ containerView: Any, _ model: Any, _ indexPath: IndexPath) -> Any)?
    private var _supplementaryDequeueClosure: ((_ containerView: Any, _ model: Any, _ indexPath: IndexPath) -> Any)?
    
    /// Returns custom MappingCondition that allows to customize mappings based on IndexPath and ModelType.
    public func modelCondition(_ condition: @escaping (IndexPath, Model) -> Bool) -> MappingCondition {
        return .custom { indexPath, model in
            guard let model = model as? Model else { return false }
            return condition(indexPath, model)
        }
    }
    
    @available(*, deprecated, message: "Please use other constructors to create ViewModelMapping.")
    /// Creates `ViewModelMapping` for `viewClass`
    public init<T: ModelTransfer>(viewType: ViewType, viewClass: T.Type, xibName: String? = nil, mappingBlock: ((ViewModelMapping) -> Void)?) {
        self.viewType = viewType
        self.viewClass = viewClass
        self.xibName = xibName
        self.reuseIdentifier = String(describing: T.self)
        modelTypeCheckingBlock = { $0 is T.ModelType }
        updateBlock = { view, model in
            guard let view = view as? T, let model = model as? T.ModelType else { return }
            view.update(with: model)
        }
        bundle = Bundle(for: T.self)
        mappingBlock?(self)
    }
    
    /// Creates `ViewModelMapping` for UICollectionViewCell registration.
    /// - Parameters:
    ///   - cellConfiguration: Cell handler closure to be executed when cell is dequeued.
    ///   - mapping: mapping closure, that is executed at the end of initializer to allow mapping customization.
    public init(cellConfiguration: @escaping ((View, Model, IndexPath) -> Void),
                          mapping: ((ViewModelMapping<View, Model>) -> Void)?)
        where View: UICollectionViewCell
    {
        viewType = .cell
        viewClass = View.self
        xibName = String(describing: View.self)
        reuseIdentifier = String(describing: View.self)
        modelTypeCheckingBlock = { $0 is Model }
        updateBlock = { _, _ in }
        bundle = Bundle(for: View.self)
        _cellConfigurationHandler = { cell, model, indexPath in
            guard let view = cell as? View, let model = model as? Model else { return }
            cellConfiguration(view, model, indexPath)
        }
        _cellDequeueClosure = { [weak self] view, model, indexPath in
            guard let self = self, let collectionView = view as? UICollectionView else { return nil as Any? as Any }
            if let model = model as? Model, !self.cellRegisteredByStoryboard, #available(iOS 14, tvOS 14, *) {
                #if compiler(>=5.3)
                    let registration : UICollectionView.CellRegistration<View, Model>
                    
                    if let nibName = self.xibName, UINib.nibExists(withNibName: nibName, inBundle: self.bundle) {
                        registration = .init(cellNib: UINib(nibName: nibName, bundle: self.bundle), handler: { cell, indexPath, model in
                            cellConfiguration(cell, model, indexPath)
                        })
                    } else {
                        registration = .init(handler: { cell, indexPath, model in
                            cellConfiguration(cell, model, indexPath)
                        })
                    }
                    return collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: model)
                #else
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.reuseIdentifier, for: indexPath)
                    if let cell = cell as? T {
                        cellConfiguration(cell, model, indexPath)
                    }
                    return cell
                #endif
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.reuseIdentifier, for: indexPath)
                if let cell = cell as? View, let model = model as? Model {
                    cellConfiguration(cell, model, indexPath)
                }
                return cell
            }
        }
        mapping?(self)
    }
    
    /// Creates `ViewModelMapping` for UITableViewCell registration.
    /// - Parameters:
    ///   - cellConfiguration: Cell handler closure to be executed when cell is dequeued.
    ///   - mapping: mapping closure, that is executed at the end of initializer to allow mapping customization.
    public init(cellConfiguration: @escaping ((View, Model, IndexPath) -> Void),
                          mapping: ((ViewModelMapping<View, Model>) -> Void)?)
        where View: UITableViewCell
    {
        viewType = .cell
        viewClass = View.self
        xibName = String(describing: View.self)
        reuseIdentifier = String(describing: View.self)
        modelTypeCheckingBlock = { $0 is Model }
        updateBlock = { _, _ in }
        bundle = Bundle(for: View.self)
        _cellConfigurationHandler = { cell, model, indexPath in
            guard let view = cell as? View, let model = model as? Model else { return }
            cellConfiguration(view, model, indexPath)
        }
        _cellDequeueClosure = { [weak self] view, model, indexPath in
            guard let self = self, let model = model as? Model, let tableView = view as? UITableView else { return nil as Any? as Any }
            let cell = tableView.dequeueReusableCell(withIdentifier: self.reuseIdentifier, for: indexPath)
            if let cell = cell as? View {
                cellConfiguration(cell, model, indexPath)
            }
            return cell
        }
        mapping?(self)
    }
    
    /// Creates `ViewModelMapping` for UICollectionViewCell registration. This initializer is used, when UICollectionViewCell conforms to `ModelTransfer` protocol.
    /// - Parameters:
    ///   - cellConfiguration: Cell handler closure to be executed when cell is dequeued.
    ///   - mapping: mapping closure, that is executed at the end of initializer to allow mapping customization.
    public init(cellConfiguration: @escaping ((View, View.ModelType, IndexPath) -> Void),
                mapping: ((ViewModelMapping<View, View.ModelType>) -> Void)?)
        where View: UICollectionViewCell, View: ModelTransfer, View.ModelType == Model
    {
        viewType = .cell
        viewClass = View.self
        xibName = String(describing: View.self)
        reuseIdentifier = String(describing: View.self)
        modelTypeCheckingBlock = { $0 is View.ModelType }
        updateBlock = { view, model in
            guard let view = view as? View, let model = model as? View.ModelType else { return }
            view.update(with: model)
        }
        bundle = Bundle(for: View.self)
        _cellConfigurationHandler = { cell, model, indexPath in
            guard let view = cell as? View, let model = model as? Model else { return }
            cellConfiguration(view, model, indexPath)
        }
        _cellDequeueClosure = { [weak self] view, model, indexPath in
            guard let self = self, let model = model as? View.ModelType, let collectionView = view as? UICollectionView else {
                return nil as Any? as Any
            }
            if !self.cellRegisteredByStoryboard, #available(iOS 14, tvOS 14, *) {
                #if compiler(>=5.3)
                let registration : UICollectionView.CellRegistration<View, View.ModelType>
                    
                    if let nibName = self.xibName, UINib.nibExists(withNibName: nibName, inBundle: self.bundle) {
                        registration = .init(cellNib: UINib(nibName: nibName, bundle: self.bundle), handler: { cell, indexPath, model in
                            cellConfiguration(cell, model, indexPath)
                        })
                    } else {
                        registration = .init(handler: { cell, indexPath, model in
                            cellConfiguration(cell, model, indexPath)
                        })
                    }
                    return collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: model)
                #else
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.reuseIdentifier, for: indexPath)
                if let cell = cell as? T {
                        cellConfiguration(cell, model, indexPath)
                    }
                    return cell
                #endif
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.reuseIdentifier, for: indexPath)
                if let cell = cell as? View {
                    cellConfiguration(cell, model, indexPath)
                }
                return cell
            }
        }
        mapping?(self)
    }
    
    /// Creates `ViewModelMapping` for UITableViewCell registration. This initializer is used, when UICollectionViewCell conforms to `ModelTransfer` protocol.
    /// - Parameters:
    ///   - cellConfiguration: Cell handler closure to be executed when cell is dequeued.
    ///   - mapping: mapping closure, that is executed at the end of initializer to allow mapping customization.
    public init(cellConfiguration: @escaping ((View, View.ModelType, IndexPath) -> Void),
                mapping: ((ViewModelMapping<View, View.ModelType>) -> Void)?)
        where View: UITableViewCell, View: ModelTransfer, View.ModelType == Model
    {
        viewType = .cell
        viewClass = View.self
        xibName = String(describing: View.self)
        reuseIdentifier = String(describing: View.self)
        modelTypeCheckingBlock = { $0 is View.ModelType }
        updateBlock = { view, model in
            guard let view = view as? View, let model = model as? View.ModelType else { return }
            view.update(with: model)
        }
        bundle = Bundle(for: View.self)
        _cellConfigurationHandler = { cell, model, indexPath in
            guard let view = cell as? View, let model = model as? Model else { return }
            cellConfiguration(view, model, indexPath)
        }
        _cellDequeueClosure = { [weak self] view, model, indexPath in
            guard let self = self, let model = model as? View.ModelType, let tableView = view as? UITableView else {
                return nil as Any? as Any
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: self.reuseIdentifier, for: indexPath)
            if let cell = cell as? View {
                cellConfiguration(cell, model, indexPath)
            }
            return cell
        }
        mapping?(self)
    }
    
    /// Creates `ViewModelMapping` for UICollectionReusableView registration.
    /// - Parameters:
    ///   - kind: kind of supplementary view
    ///   - supplementaryConfiguration: Supplementary handler closure to be executed when supplementary view is dequeued
    ///   - mapping: mapping closure, that is executed at the end of initializer to allow mapping customization.
    public init(kind: String,
                supplementaryConfiguration: @escaping ((View, Model, IndexPath) -> Void),
                mapping: ((ViewModelMapping<View, Model>) -> Void)?)
        where View: UICollectionReusableView
    {
        viewType = .supplementaryView(kind: kind)
        viewClass = View.self
        xibName = String(describing: View.self)
        reuseIdentifier = String(describing: View.self)
        modelTypeCheckingBlock = { $0 is Model }
        updateBlock = { _, _ in }
        bundle = Bundle(for: View.self)
        _supplementaryDequeueClosure = { [weak self] collectionView, model, indexPath in
            guard let self = self, let model = model as? Model, let collectionView = collectionView as? UICollectionView else { return nil as Any? as Any }
            if !self.supplementaryRegisteredByStoryboard, #available(iOS 14, tvOS 14, *) {
                #if compiler(>=5.3)
                    let registration : UICollectionView.SupplementaryRegistration<View>
                
                    if let nibName = self.xibName, UINib.nibExists(withNibName: nibName, inBundle: self.bundle) {
                        registration = .init(supplementaryNib: UINib(nibName: nibName, bundle: self.bundle), elementKind: kind, handler: { view, kind, indexPath in
                            supplementaryConfiguration(view, model, indexPath)
                        })
                    } else {
                        registration = .init(elementKind: kind, handler: { view, kind, indexPath in
                            supplementaryConfiguration(view, model, indexPath)
                        })
                    }
                    return collectionView.dequeueConfiguredReusableSupplementary(using: registration, for: indexPath)
                #else
                    let supplementary = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: self.reuseIdentifier, for: indexPath)
                    if let supplementary = supplementary as? T {
                        supplementaryConfiguration(supplementary, model, indexPath)
                    }
                    return supplementary
                #endif
            } else {
                let supplementary = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: self.reuseIdentifier, for: indexPath)
                if let supplementary = supplementary as? View {
                    supplementaryConfiguration(supplementary, model, indexPath)
                }
                return supplementary
            }
        }
        mapping?(self)
    }
    
    /// Creates `ViewModelMapping` for UITableView header/footer registration.
    /// - Parameters:
    ///   - kind: kind of supplementary view. `DTTableViewElementSectionHeader` for headers and `DTTableViewElementSectionFooter` for footers.
    ///   - headerFooterConfiguration: Header/footer handler closure to be executed when header/footer is dequeued.
    ///   - mapping: mapping closure, that is executed at the end of initializer to allow mapping customization.
    public init(kind: String,
                headerFooterConfiguration: @escaping ((View, Model, Int) -> Void),
                mapping: ((ViewModelMapping<View, Model>) -> Void)?)
        where View: UIView
    {
        viewType = .supplementaryView(kind: kind)
        viewClass = View.self
        xibName = String(describing: View.self)
        reuseIdentifier = String(describing: View.self)
        modelTypeCheckingBlock = { $0 is Model }
        updateBlock = { _, _ in }
        bundle = Bundle(for: View.self)
        _supplementaryDequeueClosure = { [weak self] tableView, model, indexPath in
            guard let self = self, let tableView = tableView as? UITableView, let model = model as? Model else { return nil as Any? as Any }
            if let headerFooterView = tableView.dequeueReusableHeaderFooterView(withIdentifier: self.reuseIdentifier) {
                if let typedHeaderFooterView = headerFooterView as? View {
                    headerFooterConfiguration(typedHeaderFooterView, model, indexPath.section)
                }
                return headerFooterView
            } else {
                if let type = self.viewClass as? UIView.Type {
                    if let loadedFromXib = type.load(for: self) as? View {
                        headerFooterConfiguration(loadedFromXib, model, indexPath.section)
                        return loadedFromXib
                    }
                }
                return nil as Any? as Any
            }
        }
        mapping?(self)
    }
    
    /// Creates `ViewModelMapping` for UICollectionReusableView registration. This initializer is used, when UICollectionSupplementaryView conforms to `ModelTransfer` protocol.
    /// - Parameters:
    ///   - kind: kind of supplementary view
    ///   - supplementaryConfiguration: Supplementary handler closure to be executed when supplementary view is dequeued
    ///   - mapping: mapping closure, that is executed at the end of initializer to allow mapping customization.
    public init(kind: String,
                supplementaryConfiguration: @escaping ((View, View.ModelType, IndexPath) -> Void),
                mapping: ((ViewModelMapping<View, Model>) -> Void)?)
    where View: UICollectionReusableView, View: ModelTransfer, Model == View.ModelType
    {
        viewType = .supplementaryView(kind: kind)
        viewClass = View.self
        xibName = String(describing: View.self)
        reuseIdentifier = String(describing: View.self)
        modelTypeCheckingBlock = { $0 is View.ModelType }
        updateBlock = { view, model in
            guard let view = view as? View, let model = model as? View.ModelType else { return }
            view.update(with: model)
        }
        bundle = Bundle(for: View.self)
        _supplementaryDequeueClosure = { [weak self] collectionView, model, indexPath in
            guard let self = self, let model = model as? View.ModelType, let collectionView = collectionView as? UICollectionView else {
                return nil as Any? as Any
            }
            if !self.supplementaryRegisteredByStoryboard, #available(iOS 14, tvOS 14, *) {
                #if compiler(>=5.3)
                let registration : UICollectionView.SupplementaryRegistration<View>
                    
                    if let nibName = self.xibName, UINib.nibExists(withNibName: nibName, inBundle: self.bundle) {
                        registration = .init(supplementaryNib: UINib(nibName: nibName, bundle: self.bundle), elementKind: kind, handler: { view, kind, indexPath in
                            supplementaryConfiguration(view, model, indexPath)
                        })
                    } else {
                        registration = .init(elementKind: kind, handler: { view, kind, indexPath in
                            supplementaryConfiguration(view, model, indexPath)
                        })
                    }
                return collectionView.dequeueConfiguredReusableSupplementary(using: registration, for: indexPath)
            #else
                let supplementary = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: self.reuseIdentifier, for: indexPath)
                if let supplementary = supplementary as? T {
                    supplementaryConfiguration(supplementary, model, indexPath)
                }
                return supplementary
            #endif
            } else {
                let supplementary = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: self.reuseIdentifier, for: indexPath)
                if let supplementary = supplementary as? View {
                    supplementaryConfiguration(supplementary, model, indexPath)
                }
                return supplementary
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
                mapping: ((ViewModelMapping<View, Model>) -> Void)?)
    where View: UIView, View: ModelTransfer, Model == View.ModelType
    {
        viewType = .supplementaryView(kind: kind)
        viewClass = View.self
        xibName = String(describing: View.self)
        reuseIdentifier = String(describing: View.self)
        modelTypeCheckingBlock = { $0 is View.ModelType }
        updateBlock = { view, model in
            guard let view = view as? View, let model = model as? View.ModelType else { return }
            view.update(with: model)
        }
        bundle = Bundle(for: View.self)
        _supplementaryDequeueClosure = { [weak self] tableView, model, indexPath in
            guard let self = self, let tableView = tableView as? UITableView, let model = model as? Model else { return nil as Any? as Any }
            if let headerFooterView = tableView.dequeueReusableHeaderFooterView(withIdentifier: self.reuseIdentifier) {
                if let typedHeaderFooterView = headerFooterView as? View {
                    headerFooterConfiguration(typedHeaderFooterView, model, indexPath.section)
                }
                return headerFooterView
            } else {
                if let type = self.viewClass as? UIView.Type {
                    if let loadedFromXib = type.load(for: self) as? View {
                        headerFooterConfiguration(loadedFromXib, model, indexPath.section)
                        return loadedFromXib
                    }
                }
            }
            return nil as Any? as Any
        }
        mapping?(self)
    }
    
    /// Update `cell` at `indexPath` with `model`. This can be used in scenarios where you want to update a cell, but animations are not required.
    /// For example, `DTCollectionViewManager.coreDataUpdater()` uses this technique. For details, read more in https://github.com/DenTelezhkin/DTModelStorage/blob/master/Documentation/CoreData%20storage.md
    /// - Parameters:
    ///   - cell: visible cell instance
    ///   - indexPath: location of the cell
    ///   - model: data model to update with
    public func updateCell(cell: Any, at indexPath: IndexPath, with model: Any) {
        _cellConfigurationHandler?(cell, model, indexPath)
        updateBlock(cell, model)
    }
    
    /// Dequeues reusable cell for `model`, `indexPath` from `tableView`. Calls `cellConfiguration` closure, that was passed to initializer, then calls `ModelTransfer.update(with:)` if this cell conforms to `ModelTransfer` protocol.
    /// - Parameters:
    ///   - tableView: UITableView instance to dequeue cell from
    ///   - model: model object, that was mapped to cell type.
    ///   - indexPath: IndexPath, at which cell is going to be displayed.
    /// - Returns: dequeued configured UITableViewCell instance.
    public func dequeueConfiguredReusableCell(for tableView: UITableView, model: Any, indexPath: IndexPath) -> UITableViewCell? {
        guard viewType == .cell else {
            return nil
        }
        guard let cell = _cellDequeueClosure?(tableView, model, indexPath) else {
            return nil
        }
        updateBlock(cell, model)
        return cell as? UITableViewCell
    }
    
    /// Dequeues reusable supplementary view for `model`, `indexPath` from `tableView`. Calls `headerFooterConfiguration` closure, that was passed to initializer, then calls `ModelTransfer.update(with:)` if this header/footer conforms to `ModelTransfer` protocol.
    /// - Parameters:
    ///   - tableView: UITableView instance to dequeue header/footer from
    ///   - kind: kind of supplementary view. `DTTableViewElementSectionHeader` for headers and `DTTableViewElementSectionFooter` for footers.
    ///   - model: model object, that was mapped to header/footer type.
    ///   - indexPath: IndexPath, at which header/footer is going to be displayed. IndexPath.row of this IndexPath is ignored.
    /// - Returns: dequeued configured header/footer.
    public func dequeueConfiguredReusableSupplementaryView(for tableView: UITableView, kind: String, model: Any, indexPath: IndexPath) -> UIView? {
        guard viewType == .supplementaryView(kind: kind) else {
            return nil
        }
        guard let view = _supplementaryDequeueClosure?(tableView, model, indexPath) else {
            return nil
        }
        updateBlock(view, model)
        return view as? UIView
    }
    
    /// Dequeues reusable cell for `model`, `indexPath` from `collectionView`. Calls `cellConfiguration` closure, that was passed to initializer, then calls `ModelTransfer.update(with:)` if this cell conforms to `ModelTransfer` protocol.
    /// - Parameters:
    ///   - collectionView: UICollectionView instance to dequeue cell from
    ///   - model: model object, that was mapped to cell type.
    ///   - indexPath: IndexPath, at which cell is going to be displayed.
    /// - Returns: dequeued configured UICollectionViewCell instance.
    public func dequeueConfiguredReusableCell(for collectionView: UICollectionView, model: Any, indexPath: IndexPath) -> UICollectionViewCell? {
        guard viewType == .cell else {
            return nil
        }
        guard let cell = _cellDequeueClosure?(collectionView, model, indexPath) else {
            return nil
        }
        updateBlock(cell, model)
        return cell as? UICollectionViewCell
    }
    
    /// Dequeues reusable supplementary view for `model`, `indexPath` from `tableView`. Calls `supplementaryConfiguration` closure, that was passed to initializer, then calls `ModelTransfer.update(with:)` if this header/footer conforms to `ModelTransfer` protocol.
    /// - Parameters:
    ///   - collectionView: UICollectionView instance to dequeue supplementary view from
    ///   - kind: kind of supplementary view.
    ///   - model: model object, that was mapped to supplementary view type.
    ///   - indexPath: IndexPath, at which supplementary view is going to be displayed.
    /// - Returns: dequeued configured supplementary view.
    public func dequeueConfiguredReusableSupplementaryView(for collectionView: UICollectionView, kind: String, model: Any, indexPath: IndexPath) -> UICollectionReusableView? {
        guard viewType == .supplementaryView(kind: kind) else {
            return nil
        }
        guard let view = _supplementaryDequeueClosure?(collectionView, model, indexPath) else {
            return nil
        }
        updateBlock(view, model)
        return view as? UICollectionReusableView
    }
    
    internal init(viewType: ViewType, modelClass: Model.Type, viewClass: View.Type) {
        self.viewType = viewType
        self.viewClass = View.self
        modelTypeCheckingBlock = { $0 is Model }
        updateBlock = { _, _ in }
        reuseIdentifier = ""
        xibName = nil
        bundle = Bundle.main
    }
}
