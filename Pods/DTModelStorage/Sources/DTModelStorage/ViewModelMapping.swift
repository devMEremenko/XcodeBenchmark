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
public protocol ViewModelMappingProtocol: AnyObject {
    var viewType : ViewType { get }
    var modelTypeCheckingBlock: (Any) -> Bool { get }
    var modelTypeTypeCheckingBlock: (Any.Type) -> Bool { get }
    var viewClass: AnyClass { get }
    var condition: MappingCondition { get }
    var reactions: [EventReaction] { get set }
}

/// Extension of `ViewModelMappingProtocol` for working with UITableView and UICollectionView cells.
public protocol CellViewModelMappingProtocol: ViewModelMappingProtocol {
    func updateCell(cell: Any, at indexPath: IndexPath, with model: Any)
    
    func dequeueConfiguredReusableCell(for collectionView: UICollectionView, model: Any, indexPath: IndexPath) -> UICollectionViewCell?
    
    func dequeueConfiguredReusableCell(for tableView: UITableView, model: Any, indexPath: IndexPath) -> UITableViewCell?
}

/// Generic extension of CellViewModelMappingProtocol, that allows to capture Cell and Model types
public protocol CellViewModelMappingProtocolGeneric: CellViewModelMappingProtocol {
    associatedtype Cell
    associatedtype Model
}

/// Extension of `ViewModelMappingProtocol` for working with UITableView headers/footers and UICollectionView reusable views.
public protocol SupplementaryViewModelMappingProtocol: ViewModelMappingProtocol {
    func dequeueConfiguredReusableSupplementaryView(for collectionView: UICollectionView, kind: String, model: Any, indexPath: IndexPath) -> UICollectionReusableView?
    func dequeueConfiguredReusableSupplementaryView(for tableView: UITableView, kind: String, model: Any, indexPath: IndexPath) -> UIView?
}

/// Generic extension of `SupplementaryViewModelMappingProtocol`, that allows to capture View and Model types.
public protocol SupplementaryViewModelMappingProtocolGeneric: SupplementaryViewModelMappingProtocol {
    associatedtype View
    associatedtype Model
}

/// Base class for cell view model mappings.
open class CellViewModelMapping<View, Model> : CellViewModelMappingProtocol {
    
    /// Base method for updating cell with model. Must be overridden in subclasses.
    open func updateCell(cell: Any, at indexPath: IndexPath, with model: Any) {
        assertionFailure("Subclasses of CellViewModelMapping must override this method")
    }
    
    /// Base method for dequeuing reusable cells. Must be overridden in subclasses.
    open func dequeueConfiguredReusableCell(for collectionView: UICollectionView, model: Any, indexPath: IndexPath) -> UICollectionViewCell? {
        assertionFailure("Subclasses of CellViewModelMapping must override this method")
        return nil
    }
    
    /// Base method for dequeuing reusable cells. Must be overridden in subclasses.
    open func dequeueConfiguredReusableCell(for tableView: UITableView, model: Any, indexPath: IndexPath) -> UITableViewCell? {
        assertionFailure("Subclasses of CellViewModelMapping must override this method")
        return nil
    }
    
    /// View type of this mapping. Returns .cell
    public var viewType: ViewType { .cell }
    
    /// Closure, that is able to type-check type of a object's instance
    public var modelTypeCheckingBlock: (Any) -> Bool = {
        $0 is Model
    }
    
    /// Closure, that is able to type-check object type.
    public var modelTypeTypeCheckingBlock: (Any.Type) -> Bool = {
        $0 is Model.Type
    }
    
    /// View class to be used for this mapping
    open var viewClass: AnyClass
    
    /// Mapping condition, under which this mapping is going to work. Defaults to .none.
    open var condition: MappingCondition = .none
    
    /// Event reactions, attached to this mapping instance
    open var reactions: [EventReaction] = []
    
    /// Returns custom MappingCondition that allows to customize mappings based on IndexPath and ModelType.
    public func modelCondition(_ condition: @escaping (IndexPath, Model) -> Bool) -> MappingCondition {
        return .custom { indexPath, model in
            guard let model = model as? Model else { return false }
            return condition(indexPath, model)
        }
    }
    
    /// Creates Cell-Model mapping
    /// - Parameter viewClass: cell class.
    public init(viewClass: AnyClass) {
        self.viewClass = viewClass
    }
}

/// Base class for supplmenetary mappings
open class SupplementaryViewModelMapping<View, Model> : SupplementaryViewModelMappingProtocol {
    
    /// Base method for dequeuing supplementary views. Must be overridden in subclasses.
    open func dequeueConfiguredReusableSupplementaryView(for collectionView: UICollectionView, kind: String, model: Any, indexPath: IndexPath) -> UICollectionReusableView? {
        assertionFailure("Subclasses of SupplementaryViewModelMapping must override this method")
        return nil
    }
    
    /// Base method for dequeuing header/footer views. Must be overridden in subclasses.
    open func dequeueConfiguredReusableSupplementaryView(for tableView: UITableView, kind: String, model: Any, indexPath: IndexPath) -> UIView? {
        assertionFailure("Subclasses of SupplementaryViewModelMapping must override this method")
        return nil
    }
    
    /// View type for this mapping. Is expected to be .supplementaryView(kind: ...).
    public var viewType: ViewType
    
    /// Closure, that is able to type-check type of a object's instance
    public var modelTypeCheckingBlock: (Any) -> Bool = {
        $0 is Model
    }
    
    /// Closure, that is able to type-check object type.
    public var modelTypeTypeCheckingBlock: (Any.Type) -> Bool = {
        $0 is Model.Type
    }
    
    /// View class to be used for this mapping
    open var viewClass: AnyClass
    
    /// Mapping condition, under which this mapping is going to work. Defaults to .none.
    open var condition: MappingCondition = .none
    
    /// Event reactions, attached to this mapping instance
    open var reactions: [EventReaction] = []
    
    /// Returns custom MappingCondition that allows to customize mappings based on IndexPath and ModelType.
    public func modelCondition(_ condition: @escaping (IndexPath, Model) -> Bool) -> MappingCondition {
        return .custom { indexPath, model in
            guard let model = model as? Model else { return false }
            return condition(indexPath, model)
        }
    }
    
    /// Creates Supplementary mapping.
    /// - Parameters:
    ///   - viewClass: Supplementary view dynamic type
    ///   - viewType: supplementary view type
    public init(viewClass: AnyClass, viewType: ViewType) {
        assert(viewType.supplementaryKind() != nil)
        self.viewClass = viewClass
        self.viewType = viewType
    }
}
