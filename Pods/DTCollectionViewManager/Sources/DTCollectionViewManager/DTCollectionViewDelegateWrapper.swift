//
//  DTCollectionViewDelegateWrapper.swift
//  DTCollectionViewManager
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
import DTModelStorage

/// Base class for delegate wrappers.
open class DTCollectionViewDelegateWrapper : NSObject {
    
    /// Weak reference to `DTCollectionViewManageable` instance. It is used to dispatch `UICollectionView` delegate events in case `delegate` implements them.
    weak var delegate: AnyObject?
    var collectionView: UICollectionView? { return manager?.collectionView }
    var viewFactory: CollectionViewFactory? { return manager?.viewFactory }
    var storage: Storage? { return manager?.storage }
    weak var manager: DTCollectionViewManager?
    
    /// Creates delegate wrapper with `delegate` and `collectionViewManager`
    public init(delegate: AnyObject?, collectionViewManager: DTCollectionViewManager) {
        self.delegate = delegate
        manager = collectionViewManager
    }
    
    /// Array of `DTCollectionViewManager` reactions
    /// - SeeAlso: `EventReaction`.
    final var collectionViewReactions = ContiguousArray<EventReaction>()  {
        didSet {
            delegateWasReset()
        }
    }
    
    func delegateWasReset() {
        // Subclasses need to override this method, resetting `UICollectionView` delegate or datasource.
        // Resetting delegate and dataSource are needed, because UICollectionView caches results of `respondsToSelector` call, and never calls it again until `setDelegate` method is called.
        // We force UICollectionView to flush that cache and query us again, because with new event we might have new delegate or datasource method to respond to.
    }
    
    /// Returns header model for section at `index`, or nil if it is not found.
    final func headerModel(forSection index: Int) -> Any?
    {
        return RuntimeHelper.recursivelyUnwrapAnyValue((storage as? SupplementaryStorage)?.headerModel(forSection: index) as Any)
    }
    
    /// Returns footer model for section at `index`, or nil if it is not found.
    final func footerModel(forSection index: Int) -> Any?
    {
        return RuntimeHelper.recursivelyUnwrapAnyValue((storage as? SupplementaryStorage)?.footerModel(forSection: index) as Any)
    }
    
    final func supplementaryModel(ofKind kind: String, forSectionAt indexPath: IndexPath) -> Any? {
        return RuntimeHelper.recursivelyUnwrapAnyValue((storage as? SupplementaryStorage)?.supplementaryModel(ofKind: kind, forSectionAt: indexPath) as Any)
    }
    
    final internal func appendReaction<T, U>(for cellClass: T.Type, signature: EventMethodSignature,
                                             methodName: String = #function,
                                             closure: @escaping (T, T.ModelType, IndexPath) -> U)
        where T: ModelTransfer, T:UICollectionViewCell
    {
        let reaction = EventReaction(signature: signature.rawValue, viewType: .cell, viewClass: T.self)
        reaction.makeReaction(closure)
        collectionViewReactions.append(reaction)
        manager?.verifyViewEvent(for: T.self, methodName: methodName)
    }
    
    final internal func append4ArgumentReaction<CellClass, Argument, Result>
        (for cellClass: CellClass.Type,
         signature: EventMethodSignature,
         methodName: String = #function,
         closure: @escaping (Argument, CellClass, CellClass.ModelType, IndexPath) -> Result)
        where CellClass: ModelTransfer, CellClass: UICollectionViewCell
    {
        let reaction = FourArgumentsEventReaction(signature: signature.rawValue,
                                                  viewType: .cell,
                                                  viewClass: CellClass.self)
        reaction.make4ArgumentsReaction(closure)
        collectionViewReactions.append(reaction)
        manager?.verifyViewEvent(for: CellClass.self, methodName: methodName)
    }
    
    final internal func append5ArgumentReaction<CellClass, ArgumentOne, ArgumentTwo, Result>
        (for cellClass: CellClass.Type,
         signature: EventMethodSignature,
         methodName: String = #function,
         closure: @escaping (ArgumentOne, ArgumentTwo, CellClass, CellClass.ModelType, IndexPath) -> Result)
        where CellClass: ModelTransfer, CellClass: UICollectionViewCell
    {
        let reaction = FiveArgumentsEventReaction(signature: signature.rawValue,
                                                  viewType: .cell,
                                                  viewClass: CellClass.self)
        reaction.make5ArgumentsReaction(closure)
        collectionViewReactions.append(reaction)
        manager?.verifyViewEvent(for: CellClass.self, methodName: methodName)
    }
    
    final internal func appendReaction<T, U>(for modelClass: T.Type,
                                             signature: EventMethodSignature,
                                             methodName: String = #function,
                                             closure: @escaping (T, IndexPath) -> U)
    {
        let reaction = EventReaction(signature: signature.rawValue, viewType: .cell, modelType: T.self)
        reaction.makeReaction(closure)
        collectionViewReactions.append(reaction)
        manager?.verifyItemEvent(for: T.self, methodName: methodName)
    }
    
    final func appendReaction<T, U>(forSupplementaryKind kind: String,
                                    supplementaryClass: T.Type,
                                    signature: EventMethodSignature,
                                    methodName: String = #function,
                                    closure: @escaping (T, T.ModelType, IndexPath) -> U) where T: ModelTransfer, T: UICollectionReusableView {
        let reaction = EventReaction(signature: signature.rawValue, viewType: .supplementaryView(kind: kind), viewClass: T.self)
        reaction.makeReaction(closure)
        collectionViewReactions.append(reaction)
        manager?.verifyViewEvent(for: T.self, methodName: methodName)
    }
    
    final func appendReaction<T, U>(forSupplementaryKind kind: String,
                                    modelClass: T.Type,
                                    signature: EventMethodSignature,
                                    methodName: String = #function,
                                    closure: @escaping (T, IndexPath) -> U) {
        let reaction = EventReaction(signature: signature.rawValue, viewType: .supplementaryView(kind: kind), modelType: T.self)
        reaction.makeReaction(closure)
        collectionViewReactions.append(reaction)
        manager?.verifyItemEvent(for: T.self, methodName: methodName)
    }
    
    final func appendNonCellReaction(_ signature: EventMethodSignature, closure: @escaping () -> Any) {
        let reaction = EventReaction(signature: signature.rawValue, viewType: .cell, modelType: Any.self)
        reaction.reaction = { _, _, _ in
            return closure()
        }
        collectionViewReactions.append(reaction)
    }
    
    final func appendNonCellReaction<Arg>(_ signature: EventMethodSignature, closure: @escaping (Arg) -> Any) {
        let reaction = EventReaction(signature: signature.rawValue, viewType: .cell, modelType: Any.self)
        reaction.reaction = { arg, _, _ in
            guard let arg = arg as? Arg else { return nil as Any? as Any }
            return closure(arg)
        }
        collectionViewReactions.append(reaction)
    }
    
    final func appendNonCellReaction<Arg1, Arg2, Result>(_ signature: EventMethodSignature, closure: @escaping (Arg1, Arg2) -> Result) {
        let reaction = EventReaction(signature: signature.rawValue, viewType: .cell, modelType: Any.self)
        reaction.reaction = { arg1, arg2, _ in
            guard let arg1 = arg1 as? Arg1,
                let arg2 = arg2 as? Arg2
                else { return nil as Any? as Any }
            return closure(arg1, arg2)
        }
        collectionViewReactions.append(reaction)
    }
    
    final func performCellReaction(_ signature: EventMethodSignature, location: IndexPath, provideCell: Bool) -> Any? {
        var cell : UICollectionViewCell?
        if provideCell { cell = collectionView?.cellForItem(at: location) }
        guard let model = storage?.item(at: location) else { return nil }
        return collectionViewReactions.performReaction(of: .cell, signature: signature.rawValue, view: cell, model: model, location: location)
    }
    
    final func perform4ArgumentCellReaction(_ signature: EventMethodSignature, argument: Any, location: IndexPath, provideCell: Bool) -> Any? {
        var cell : UICollectionViewCell?
        if provideCell { cell = collectionView?.cellForItem(at: location) }
        guard let model = storage?.item(at: location) else { return nil }
        return collectionViewReactions.perform4ArgumentsReaction(of: .cell,
                                                                 signature: signature.rawValue,
                                                                 argument: argument,
                                                                 view: cell,
                                                                 model: model,
                                                                 location: location)
    }
    
    final func perform5ArgumentCellReaction(_ signature: EventMethodSignature,
                                            argumentOne: Any,
                                            argumentTwo: Any,
                                            location: IndexPath,
                                            provideCell: Bool) -> Any? {
        var cell : UICollectionViewCell?
        if provideCell { cell = collectionView?.cellForItem(at: location) }
        guard let model = storage?.item(at: location) else { return nil }
        return collectionViewReactions.perform5ArgumentsReaction(of: .cell,
                                                                 signature: signature.rawValue,
                                                                 firstArgument: argumentOne,
                                                                 secondArgument: argumentTwo,
                                                                 view: cell,
                                                                 model: model,
                                                                 location: location)
    }
    
    final func performNillableCellReaction(_ reaction: EventReaction, location: IndexPath, provideCell: Bool) -> Any? {
        var cell : UICollectionViewCell?
        if provideCell { cell = collectionView?.cellForItem(at: location) }
        guard let model = storage?.item(at: location) else { return nil }
        return reaction.performWithArguments((cell as Any, model, location))
    }
    
    final func cellReaction(_ signature: EventMethodSignature, location: IndexPath) -> EventReaction? {
        guard let model = storage?.item(at: location) else { return nil }
        return collectionViewReactions.reaction(of: .cell, signature: signature.rawValue, forModel: model, view: nil)
    }
    
    func performNonCellReaction(_ signature: EventMethodSignature) -> Any? {
        return collectionViewReactions.first(where: { $0.methodSignature == signature.rawValue })?
            .performWithArguments((0, 0, 0))
    }
    
    func performNonCellReaction<T>(_ signature: EventMethodSignature, argument: T) -> Any? {
        return collectionViewReactions.first(where: { $0.methodSignature == signature.rawValue })?
            .performWithArguments((argument, 0, 0))
    }
    
    func performNonCellReaction<T, U>(_ signature: EventMethodSignature, argumentOne: T, argumentTwo: U) -> Any? {
        return collectionViewReactions.first(where: { $0.methodSignature == signature.rawValue })?
            .performWithArguments((argumentOne, argumentTwo, 0))
    }
    
    func performSupplementaryReaction(forKind kind: String, signature: EventMethodSignature, location: IndexPath, view: UICollectionReusableView?) -> Any? {
        guard let model = supplementaryModel(ofKind: kind, forSectionAt: location) else { return nil }
        return collectionViewReactions.performReaction(of: .supplementaryView(kind: kind), signature: signature.rawValue, view: view, model: model, location: location)
    }
    
    // MARK: - Target Forwarding
    
    /// Forwards `aSelector`, that is not implemented by `DTCollectionViewManager` to delegate, if it implements it.
    ///
    /// - Returns: `DTCollectionViewManager` delegate
    open override func forwardingTarget(for aSelector: Selector) -> Any? {
        return delegate
    }
    
    /// Returns true, if `DTCollectionViewManageable` implements `aSelector`, or `DTCollectionViewManager` has an event, associated with this selector.
    ///
    /// - SeeAlso: `EventMethodSignature`
    open override func responds(to aSelector: Selector) -> Bool {
        if self.delegate?.responds(to: aSelector) ?? false {
            return true
        }
        if super.responds(to: aSelector) {
            if let eventSelector = EventMethodSignature(rawValue: String(describing: aSelector)) {
                return collectionViewReactions.contains(where: { $0.methodSignature == eventSelector.rawValue })
            }
            return true
        }
        return false
    }
}
