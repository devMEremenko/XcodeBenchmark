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
    
    // Compares view types, `Equatable` protocol.
    static public func == (left: ViewType, right: ViewType) -> Bool {
        switch (left, right) {
        case (.cell, .cell): return true
        case (.supplementaryView(let leftKind), .supplementaryView(let rightKind)): return leftKind == rightKind
        default: return false
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

/// `ViewModelMapping` struct serves to store mappings, and capture model and cell types. Due to inability of moving from dynamic types to compile-time types, we are forced to use (Any,Any) closure and force cast types when mapping is performed.
open class ViewModelMapping
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
    
    /// Type-erased update block, that will be called when `ModelTransfer` `update(with:)` method needs to be executed.
    public let updateBlock : (Any, Any) -> Void
    
    /// Mapping condition, under which this mapping is going to work. Defaults to .none.
    public var condition: MappingCondition = .none
    
    /// Reuse identifier to be used for reusable views.
    public var reuseIdentifier : String
    
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
    
    /// Creates `ViewModelMapping` for `modelType`
    public static func eventsModelMapping<T>(viewType: ViewType, modelClass: T.Type) -> ViewModelMapping {
        return ViewModelMapping(viewType: viewType, modelClass: modelClass)
    }
    
    private init<T>(viewType: ViewType, modelClass: T.Type) {
        self.viewType = viewType
        viewClass = NSObject.self
        modelTypeCheckingBlock = { $0 is T }
        updateBlock = { _, _ in }
        reuseIdentifier = ""
        xibName = nil
        bundle = Bundle.main
    }
}

extension RangeReplaceableCollection where Self.Iterator.Element == ViewModelMapping {
    
    /// Returns mappings candidates of correct `viewType`, for which `modelTypeCheckingBlock` with `model` returns true.
    /// - Returns: Array of view model mappings
    /// - Note: Usually returned array will consist of 0 or 1 element. Multiple candidates will be returned when several mappings correspond to current model - this can happen in case of protocol or subclassed model.
    /// - SeeAlso: `addMappingForViewType(_:viewClass:)`
    public func mappingCandidates(for viewType: ViewType, withModel model: Any, at indexPath: IndexPath) -> [ViewModelMapping] {
        return filter { mapping -> Bool in
            guard let unwrappedModel = RuntimeHelper.recursivelyUnwrapAnyValue(model) else { return false }
            return viewType == mapping.viewType &&
                mapping.modelTypeCheckingBlock(unwrappedModel) &&
                mapping.condition.isCompatible(with: indexPath, model: model)
        }
    }
}
