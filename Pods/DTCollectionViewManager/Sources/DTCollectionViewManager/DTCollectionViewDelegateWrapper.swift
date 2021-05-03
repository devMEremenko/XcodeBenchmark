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
    final var unmappedReactions = [EventReaction]()  {
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
        let reaction = EventReaction(viewType: T.self, modelType: T.ModelType.self, signature: signature.rawValue, closure)
        appendMappedReaction(viewType: .cell, type: T.self, reaction: reaction, signature: signature)
        manager?.verifyViewEvent(for: T.self, methodName: methodName)
    }
    
    final internal func append4ArgumentReaction<Cell, Argument, Result>
        (for cellClass: Cell.Type,
         signature: EventMethodSignature,
         methodName: String = #function,
         closure: @escaping (Argument, Cell, Cell.ModelType, IndexPath) -> Result)
        where Cell: ModelTransfer, Cell: UICollectionViewCell
    {
        let reaction = FourArgumentsEventReaction(Cell.self,
                                                  modelType: Cell.ModelType.self,
                                                  argument: Argument.self,
                                                  signature: signature.rawValue,
                                                  closure)
        appendMappedReaction(viewType: .cell, type: Cell.self, reaction: reaction, signature: signature)
        manager?.verifyViewEvent(for: Cell.self, methodName: methodName)
    }
    
    final internal func append5ArgumentReaction<Cell, ArgumentOne, ArgumentTwo, Result>
        (for cellClass: Cell.Type,
         signature: EventMethodSignature,
         methodName: String = #function,
         closure: @escaping (ArgumentOne, ArgumentTwo, Cell, Cell.ModelType, IndexPath) -> Result)
        where Cell: ModelTransfer, Cell: UICollectionViewCell
    {
        let reaction = FiveArgumentsEventReaction(Cell.self,
                                                  modelType: Cell.ModelType.self,
                                                  argumentOne: ArgumentOne.self,
                                                  argumentTwo: ArgumentTwo.self,
                                                  signature: signature.rawValue,
                                                  closure)
        appendMappedReaction(viewType: .cell, type: Cell.self, reaction: reaction, signature: signature)
        manager?.verifyViewEvent(for: Cell.self, methodName: methodName)
    }
    
    final internal func appendReaction<Model, ReturnType>(viewType: ViewType,
                                             for modelClass: Model.Type,
                                             signature: EventMethodSignature,
                                             methodName: String = #function,
                                             closure: @escaping (Model, IndexPath) -> ReturnType)
    {
        let reaction = EventReaction(modelType: Model.self, signature: signature.rawValue, closure)
        appendMappedReaction(viewType: viewType, modelType: Model.self, reaction: reaction, signature: signature)
        manager?.verifyItemEvent(for: Model.self, methodName: methodName)
    }
    
    final func appendReaction<View, ReturnType>(forSupplementaryKind kind: String,
                                    supplementaryClass: View.Type,
                                    signature: EventMethodSignature,
                                    methodName: String = #function,
                                    closure: @escaping (View, View.ModelType, IndexPath) -> ReturnType) where View: ModelTransfer, View: UICollectionReusableView
    {
        let reaction = EventReaction(viewType: View.self, modelType: View.ModelType.self,
                                     signature: signature.rawValue,
                                     closure)
        appendMappedReaction(viewType: .supplementaryView(kind: kind), type: View.self, reaction: reaction, signature: signature)
        manager?.verifyViewEvent(for: View.self, methodName: methodName)
    }
    
    final private func appendMappedReaction<View:UIView>(viewType: ViewType, type: View.Type, reaction: EventReaction, signature: EventMethodSignature) {
        let compatibleMappings = (viewFactory?.mappings ?? []).filter {
            (($0.viewClass as? UIView.Type)?.isSubclass(of: View.self) ?? false) &&
                $0.viewType == viewType
        }
        
        if compatibleMappings.count == 0 {
            manager?.anomalyHandler.reportAnomaly(.eventRegistrationForUnregisteredMapping(viewClass: String(describing: View.self), signature: signature.rawValue))
        }
        
        compatibleMappings.forEach { mapping in
            mapping.reactions.append(reaction)
        }
        
        delegateWasReset()
    }
    
    final private func appendMappedReaction<Model>(viewType: ViewType, modelType: Model.Type, reaction: EventReaction, signature: EventMethodSignature) {
        let compatibleMappings = (viewFactory?.mappings ?? []).filter {
            $0.viewType == viewType && $0.modelTypeTypeCheckingBlock(Model.self)
        }
        
        if compatibleMappings.count == 0 {
            manager?.anomalyHandler.reportAnomaly(.eventRegistrationForUnregisteredMapping(viewClass: String(describing: Model.self), signature: signature.rawValue))
        }
        
        compatibleMappings.forEach { mapping in
            mapping.reactions.append(reaction)
        }
        
        delegateWasReset()
    }
    
    final func appendNonCellReaction(_ signature: EventMethodSignature, closure: @escaping () -> Any) {
        unmappedReactions.append(EventReaction(signature: signature.rawValue, closure))
    }
    
    final func appendNonCellReaction<Arg>(_ signature: EventMethodSignature, closure: @escaping (Arg) -> Any) {
        unmappedReactions.append(EventReaction(argument: Arg.self, signature: signature.rawValue, closure))
    }
    
    final func appendNonCellReaction<Arg1, Arg2, Result>(_ signature: EventMethodSignature, closure: @escaping (Arg1, Arg2) -> Result) {
        unmappedReactions.append(EventReaction(argumentOne: Arg1.self, argumentTwo: Arg2.self, signature: signature.rawValue, closure))
    }
    
    final func performCellReaction(_ signature: EventMethodSignature, location: IndexPath, provideCell: Bool) -> Any? {
        var cell : UICollectionViewCell?
        if provideCell { cell = collectionView?.cellForItem(at: location) }
        guard let model = storage?.item(at: location) else { return nil }
        return EventReaction.performReaction(from: viewFactory?.mappings ?? [], signature: signature.rawValue, view: cell, model: model, location: location)
    }
    
    final func perform4ArgumentCellReaction(_ signature: EventMethodSignature, argument: Any, location: IndexPath, provideCell: Bool) -> Any? {
        var cell : UICollectionViewCell?
        if provideCell { cell = collectionView?.cellForItem(at: location) }
        guard let model = storage?.item(at: location) else { return nil }
        return EventReaction.perform4ArgumentsReaction(from: viewFactory?.mappings ?? [],
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
        return EventReaction.perform5ArgumentsReaction(from: viewFactory?.mappings ?? [],
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
        return EventReaction.reaction(from: viewFactory?.mappings ?? [], signature: signature.rawValue, forModel: model, at: location, view: nil)
    }
    
    func performNonCellReaction(_ signature: EventMethodSignature) -> Any? {
        EventReaction.performUnmappedReaction(from: unmappedReactions, signature.rawValue)
    }
    
    func performNonCellReaction<T>(_ signature: EventMethodSignature, argument: T) -> Any? {
        EventReaction.performUnmappedReaction(from: unmappedReactions, signature.rawValue, argument: argument)
    }
    
    func performNonCellReaction<T, U>(_ signature: EventMethodSignature, argumentOne: T, argumentTwo: U) -> Any? {
        EventReaction.performUnmappedReaction(from: unmappedReactions, signature.rawValue, argumentOne: argumentOne, argumentTwo: argumentTwo)
    }
    
    func performSupplementaryReaction(ofKind kind: String, signature: EventMethodSignature, location: IndexPath, view: UICollectionReusableView?) -> Any? {
        guard let model = supplementaryModel(ofKind: kind, forSectionAt: location) else { return nil }
        return EventReaction.performReaction(from: viewFactory?.mappings ?? [], signature: signature.rawValue, view: view, model: model, location: location, supplementaryKind: kind)
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
                return unmappedReactions.contains {
                    $0.methodSignature == eventSelector.rawValue
                } ||
                (viewFactory?.mappings ?? [])
                .contains(where: { mapping in
                    mapping.reactions.contains(where: { reaction in
                        reaction.methodSignature == eventSelector.rawValue
                    })
                })
            }
            return true
        }
        return false
    }
}
