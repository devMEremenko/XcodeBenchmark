//
//  CollectionSupplementaryViewModelMapping.swift
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

/// Supplementary view - model mapping
open class CollectionSupplementaryViewModelMapping<View: UICollectionReusableView, Model>: SupplementaryViewModelMapping<View, Model>, SupplementaryViewModelMappingProtocolGeneric {
    /// View type
    public typealias View = View
    /// Model type
    public typealias Model = Model
    
    /// Reuse identifier to be used for reusable views. Mappings for UICollectionReusableView on iOS 14 / tvOS 14 and higher ignore this parameter unless you are using storyboard prototyped cells or supplementary views.
    public var reuseIdentifier : String
    
    /// Xib name for mapping. This value will not be nil only if XIBs are used for this particular mapping.
    public var xibName: String?
    
    /// Bundle in which resources for this mapping will be searched for. `DTCollectionViewManager` uses this property to get bundle, from which xib file for `UICollectionReusableView` will be retrieved. Defaults to `Bundle(for: View.self)`.
    /// When used for events that rely on modelClass(`.eventsModelMapping(viewType: modelClass:` method) defaults to `Bundle.main`.
    public var bundle: Bundle
    
    /// If supplementary view is designed in storyboard, and thus don't require explicit UICollectionView registration, please set this property to true. Defaults to false.
    public var supplementaryRegisteredByStoryboard : Bool = false
    
    /// Type-erased update block, that will be called when `ModelTransfer` `update(with:)` method needs to be executed.
    public let updateBlock : (View, Model) -> Void
    
    private var _supplementaryDequeueClosure: ((_ containerView: UICollectionView, _ model: Model, _ indexPath: IndexPath) -> View?)?
    private var _supplementaryRegistration: Any?
    
    /// Creates `ViewModelMapping` for UICollectionReusableView registration.
    /// - Parameters:
    ///   - kind: kind of supplementary view
    ///   - supplementaryConfiguration: Supplementary handler closure to be executed when supplementary view is dequeued
    ///   - mapping: mapping closure, that is executed at the end of initializer to allow mapping customization.
    public init(kind: String,
                supplementaryConfiguration: @escaping ((View, Model, IndexPath) -> Void),
                mapping: ((CollectionSupplementaryViewModelMapping<View, Model>) -> Void)?)
    {
        xibName = String(describing: View.self)
        reuseIdentifier = String(describing: View.self)
        updateBlock = { _, _ in }
        bundle = Bundle(for: View.self)
        super.init(viewClass: View.self, viewType: .supplementaryView(kind: kind))
        _supplementaryDequeueClosure = { [weak self] collectionView, model, indexPath in
            guard let self = self else { return nil }
            if !self.supplementaryRegisteredByStoryboard, #available(iOS 14, tvOS 14, *) {
                if let registration = self._supplementaryRegistration as? UICollectionView.SupplementaryRegistration<View> {
                    let supplementaryView = collectionView.dequeueConfiguredReusableSupplementary(using: registration, for: indexPath)
                    supplementaryConfiguration(supplementaryView, model, indexPath)
                    return supplementaryView
                }
            }
            let supplementary = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: self.reuseIdentifier, for: indexPath)
            if let supplementary = supplementary as? View {
                supplementaryConfiguration(supplementary, model, indexPath)
            }
            return supplementary as? View
        }
        mapping?(self)

        if !self.supplementaryRegisteredByStoryboard, #available(iOS 14, tvOS 14, *) {
            let registration : UICollectionView.SupplementaryRegistration<View>

            if let nibName = self.xibName, UINib.nibExists(withNibName: nibName, inBundle: self.bundle) {
                registration = .init(supplementaryNib: UINib(nibName: nibName, bundle: self.bundle), elementKind: kind, handler: { _, _, _ in
                    // Supplementary configuration can be only run when model is known, e.g. while dequeing
//                    supplementaryConfiguration(view, model, indexPath)
                })
            } else {
                registration = .init(elementKind: kind, handler: { _, _, _ in
//                    supplementaryConfiguration(view, model, indexPath)
                })
            }
            self._supplementaryRegistration = registration
        }
    }
    
    /// Creates `ViewModelMapping` for UICollectionReusableView registration. This initializer is used, when UICollectionSupplementaryView conforms to `ModelTransfer` protocol.
    /// - Parameters:
    ///   - kind: kind of supplementary view
    ///   - supplementaryConfiguration: Supplementary handler closure to be executed when supplementary view is dequeued
    ///   - mapping: mapping closure, that is executed at the end of initializer to allow mapping customization.
    public init(kind: String,
                supplementaryConfiguration: @escaping ((View, View.ModelType, IndexPath) -> Void),
                mapping: ((CollectionSupplementaryViewModelMapping<View, Model>) -> Void)?)
    where View: ModelTransfer, Model == View.ModelType
    {
        xibName = String(describing: View.self)
        reuseIdentifier = String(describing: View.self)
        updateBlock = { view, model in
            view.update(with: model)
        }
        bundle = Bundle(for: View.self)
        super.init(viewClass: View.self, viewType: .supplementaryView(kind: kind))
        _supplementaryDequeueClosure = { [weak self] collectionView, model, indexPath in
            guard let self = self else {
                return nil
            }
            if !self.supplementaryRegisteredByStoryboard, #available(iOS 14, tvOS 14, *) {
                if let registration = self._supplementaryRegistration as? UICollectionView.SupplementaryRegistration<View> {
                    let supplementaryView = collectionView.dequeueConfiguredReusableSupplementary(using: registration, for: indexPath)
                    supplementaryConfiguration(supplementaryView, model, indexPath)
                    return supplementaryView
                }
            }
            let supplementary = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: self.reuseIdentifier, for: indexPath)
            if let supplementary = supplementary as? View {
                supplementaryConfiguration(supplementary, model, indexPath)
            }
            return supplementary as? View
        }
        mapping?(self)

        if !self.supplementaryRegisteredByStoryboard, #available(iOS 14, tvOS 14, *) {
            let registration : UICollectionView.SupplementaryRegistration<View>

            if let nibName = self.xibName, UINib.nibExists(withNibName: nibName, inBundle: self.bundle) {
                registration = .init(supplementaryNib: UINib(nibName: nibName, bundle: self.bundle), elementKind: kind, handler: { _, _, _ in
                    // Supplementary configuration can be only run when model is known, e.g. while dequeing
//                    supplementaryConfiguration(view, model, indexPath)
                })
            } else {
                registration = .init(elementKind: kind, handler: { _, _, _ in
//                    supplementaryConfiguration(view, model, indexPath)
                })
            }
            self._supplementaryRegistration = registration
        }
    }
    
    @available(*, unavailable, message: "Dequeueing UITableView header footer view from collection view mapping is not supported.")
    /// Unavailable method
    open override func dequeueConfiguredReusableSupplementaryView(for tableView: UITableView, kind: String, model: Any, indexPath: IndexPath) -> UIView? {
        preconditionFailure("\(#function) should not be called with UITableView headers/footers")
    }
    
    /// Dequeues reusable supplementary view for `model`, `indexPath` from `collectionView`. Calls `supplementaryConfiguration` closure, that was passed to initializer, then calls `ModelTransfer.update(with:)` if this supplementary view conforms to `ModelTransfer` protocol.
    /// - Parameters:
    ///   - collectionView: UICollectionView instance to dequeue supplementary view from
    ///   - model: model object, that was mapped to supplementary view type.
    ///   - indexPath: IndexPath, at which supplementary view is going to be displayed.
    /// - Returns: dequeued configured UICollectionReusableView instance.
    open override func dequeueConfiguredReusableSupplementaryView(for collectionView: UICollectionView, kind: String, model: Any, indexPath: IndexPath) -> UICollectionReusableView? {
        guard viewType == .supplementaryView(kind: kind), let model = model as? Model else {
            return nil
        }
        guard let view = _supplementaryDequeueClosure?(collectionView, model, indexPath) else {
            return nil
        }
        updateBlock(view, model)
        return view
    }
}
