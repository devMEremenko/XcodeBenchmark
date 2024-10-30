//
//  File.swift
//  DTTableViewManager
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

/// Base class for objects, that implement various datasource and delegate methods from `UITableView`. Even though this class is declared as `open`, subclassing it is discouraged. Please subsclass concrete subclass of this class, such as `DTTableViewDelegate`.
open class DTTableViewDelegateWrapper : NSObject {
    weak var delegate: AnyObject?
    var tableView: UITableView? { return manager?.tableView }
    var viewFactory: TableViewFactory? { return manager?.viewFactory }
    var storage: Storage? { return manager?.storage }
    var configuration: TableViewConfiguration? { return manager?.configuration }
    weak var manager: DTTableViewManager?
    
    /// Creates base wrapper for datasource and delegate implementations
    public init(delegate: AnyObject?, tableViewManager: DTTableViewManager) {
        self.delegate = delegate
        manager = tableViewManager
    }
    
    /// Array of `UITableViewDataSource` reactions for `DTTableViewDataSource`
    /// - SeeAlso: `EventReaction`.
    final var unmappedReactions = [EventReaction]()  {
        didSet {
            delegateWasReset()
        }
    }
    
    func delegateWasReset() {
        // Subclasses need to override this method, resetting `UITableView` delegate or datasource.
        // Resetting delegate is needed, because UITableView caches results of `respondsToSelector` call, and never calls it again until `setDelegate` method is called.
        // We force UITableView to flush that cache and query us again, because with new event we might have new delegate or datasource method to respond to.
    }
    
    func shouldDisplayHeaderView(forSection index: Int) -> Bool {
        guard let storage = storage, let configuration = configuration else { return false }
        if storage.numberOfItems(inSection: index) == 0 && !configuration.displayHeaderOnEmptySection {
            return false
        }
        return true
    }
    
    func shouldDisplayFooterView(forSection index: Int) -> Bool {
        guard let storage = storage, let configuration = configuration else { return false }
        if storage.numberOfItems(inSection: index) == 0 && !configuration.displayFooterOnEmptySection {
            return false
        }
        return true
    }
    
    /// Returns header model for section at `index`, or nil if it is not found.
    ///
    /// If `TableViewConfiguration` `displayHeaderOnEmptySection` is false, this method also returns nil.
    final func headerModel(forSection index: Int) -> Any?
    {
        if !shouldDisplayHeaderView(forSection: index) { return nil }
        return RuntimeHelper.recursivelyUnwrapAnyValue((storage as? SupplementaryStorage)?.headerModel(forSection: index) as Any)
    }
    
    /// Returns footer model for section at `index`, or nil if it is not found.
    ///
    /// If `TableViewConfiguration` `displayFooterOnEmptySection` is false, this method also returns nil.
    final func footerModel(forSection index: Int) -> Any?
    {
        if !shouldDisplayFooterView(forSection: index) { return nil }
        return RuntimeHelper.recursivelyUnwrapAnyValue((storage as? SupplementaryStorage)?.footerModel(forSection: index) as Any)
    }
    
    final private func appendMappedReaction<View:UIView>(type: View.Type, reaction: EventReaction, signature: EventMethodSignature) {
        let compatibleMappings = (viewFactory?.mappings ?? []).filter {
            (($0.viewClass as? UIView.Type)?.isSubclass(of: View.self) ?? false)
        }
        
        if compatibleMappings.count == 0 {
            manager?.anomalyHandler.reportAnomaly(.eventRegistrationForUnregisteredMapping(viewClass: String(describing: View.self), signature: signature.rawValue))
        }
        
        compatibleMappings.forEach { mapping in
            mapping.reactions.append(reaction)
        }
        
        delegateWasReset()
    }
    
    final internal func appendReaction<Cell, ReturnType>(for cellClass: Cell.Type, signature: EventMethodSignature, methodName: String = #function, closure: @escaping (Cell, Cell.ModelType, IndexPath) -> ReturnType) where Cell: ModelTransfer, Cell:UITableViewCell
    {
        let reaction = EventReaction(viewType: Cell.self, modelType: Cell.ModelType.self, signature: signature.rawValue, closure)
        appendMappedReaction(type: Cell.self, reaction: reaction, signature: signature)
        manager?.verifyViewEvent(for: Cell.self, methodName: methodName)
    }
    
    final internal func append4ArgumentReaction<CellClass, Argument, Result>
        (for cellClass: CellClass.Type,
         signature: EventMethodSignature,
         methodName: String = #function,
         closure: @escaping (Argument, CellClass, CellClass.ModelType, IndexPath) -> Result)
        where CellClass: ModelTransfer, CellClass: UITableViewCell
    {
        let reaction = FourArgumentsEventReaction(CellClass.self,
                                                  modelType: CellClass.ModelType.self,
                                                  argument: Argument.self,
                                                  signature: signature.rawValue,
                                                  closure)
        appendMappedReaction(type: CellClass.self, reaction: reaction, signature: signature)
        manager?.verifyViewEvent(for: CellClass.self, methodName: methodName)
    }
    
    final internal func append5ArgumentReaction<CellClass, ArgumentOne, ArgumentTwo, Result>
        (for cellClass: CellClass.Type,
         signature: EventMethodSignature,
         methodName: String = #function,
         closure: @escaping (ArgumentOne, ArgumentTwo, CellClass, CellClass.ModelType, IndexPath) -> Result)
        where CellClass: ModelTransfer, CellClass: UITableViewCell
    {
        let reaction = FiveArgumentsEventReaction(CellClass.self, modelType: CellClass.ModelType.self,
                                                  argumentOne: ArgumentOne.self,
                                                  argumentTwo: ArgumentTwo.self,
                                                  signature: signature.rawValue,
                                                  closure)
        appendMappedReaction(type: CellClass.self, reaction: reaction, signature: signature)
        manager?.verifyViewEvent(for: CellClass.self, methodName: methodName)
    }
    
    final internal func appendReaction<Model, ReturnType>(viewType: ViewType,
                                             for modelClass: Model.Type,
                                             signature: EventMethodSignature,
                                             methodName: String = #function,
                                             closure: @escaping (Model, IndexPath) -> ReturnType)
    {
        let reaction = EventReaction(modelType: Model.self, signature: signature.rawValue, closure)
        appendMappedReaction(viewType: viewType, modelType: Model.self, reaction: reaction, signature: signature)
        manager?.verifyItemEvent(for: Model.self, eventMethod: methodName)
    }
    
    final func appendReaction<View, ReturnType>(forSupplementaryKind kind: String,
                                    supplementaryClass: View.Type,
                                    signature: EventMethodSignature,
                                    methodName: String = #function,
                                    closure: @escaping (View, View.ModelType, Int) -> ReturnType) where View: ModelTransfer, View: UIView
    {
        let reaction = EventReaction(viewType: View.self, modelType: View.ModelType.self,
                                     signature: signature.rawValue, { cell, model, indexPath in
                                        closure(cell, model, indexPath.section)
                                     })
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
    
    final func appendReaction<Model, ReturnType>(forSupplementaryKind kind: String,
                                    modelClass: Model.Type,
                                    signature: EventMethodSignature,
                                    methodName: String = #function,
                                    closure: @escaping (Model, Int) -> ReturnType)
    {
        let reaction = EventReaction(modelType: Model.self, signature: signature.rawValue) { model, indexPath in
            closure(model, indexPath.section)
        }
        appendMappedReaction(viewType: .supplementaryView(kind: kind), modelType: Model.self, reaction: reaction, signature: signature)
        manager?.verifyItemEvent(for: Model.self, eventMethod: methodName)
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
        var cell : UITableViewCell?
        if provideCell { cell = tableView?.cellForRow(at: location) }
        guard let model = storage?.item(at: location) else { return nil }
        return EventReaction.performReaction(from: viewFactory?.mappings ?? [], signature: signature.rawValue, view: cell, model: model, location: location)
    }
    
    final func perform4ArgumentCellReaction(_ signature: EventMethodSignature, argument: Any, location: IndexPath, provideCell: Bool) -> Any? {
        var cell : UITableViewCell?
        if provideCell { cell = tableView?.cellForRow(at: location) }
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
        var cell : UITableViewCell?
        if provideCell { cell = tableView?.cellForRow(at: location) }
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
        var cell : UITableViewCell?
        if provideCell { cell = tableView?.cellForRow(at: location) }
        guard let model = storage?.item(at: location) else { return nil }
        return reaction.performWithArguments((cell as Any, model, location))
    }
    
    final func cellReaction(_ signature: EventMethodSignature, location: IndexPath) -> EventReaction? {
        guard let model = storage?.item(at: location) else { return nil }
        return EventReaction.reaction(from: viewFactory?.mappings ?? [], signature: signature.rawValue, forModel: model, at: location, view: nil)
    }
    
    final func performHeaderReaction(_ signature: EventMethodSignature, location: Int, provideView: Bool) -> Any? {
        var view : UIView?
        if provideView {
            view = tableView?.headerView(forSection: location)
        }
        guard let model = headerModel(forSection: location) else { return nil }
        return EventReaction.performReaction(from: viewFactory?.mappings ?? [], signature: signature.rawValue, view: view, model: model, location: IndexPath(item: 0, section: location), supplementaryKind: DTTableViewElementSectionHeader)
    }
    
    final func performFooterReaction(_ signature: EventMethodSignature, location: Int, provideView: Bool) -> Any? {
        var view : UIView?
        if provideView {
            view = tableView?.footerView(forSection: location)
        }
        guard let model = footerModel(forSection: location) else { return nil }
        return EventReaction.performReaction(from: viewFactory?.mappings ?? [], signature: signature.rawValue, view: view, model: model, location: IndexPath(item: 0, section: location), supplementaryKind: DTTableViewElementSectionFooter)
    }
    
    func performNonCellReaction(_ signature: EventMethodSignature) -> Any? {
        EventReaction.performUnmappedReaction(from: unmappedReactions, signature.rawValue)
    }
    
    func performNonCellReaction<Argument>(_ signature: EventMethodSignature, argument: Argument) -> Any? {
        EventReaction.performUnmappedReaction(from: unmappedReactions, signature.rawValue, argument: argument)
    }
    
    func performNonCellReaction<ArgumentOne, ArgumentTwo>(_ signature: EventMethodSignature, argumentOne: ArgumentOne, argumentTwo: ArgumentTwo) -> Any? {
        EventReaction.performUnmappedReaction(from: unmappedReactions, signature.rawValue, argumentOne: argumentOne, argumentTwo: argumentTwo)
    }
    
    // MARK: - Target Forwarding
    
    /// Forwards `aSelector`, that is not implemented by `DTTableViewManager` to delegate, if it implements it.
    ///
    /// - Returns: `DTTableViewManager` delegate
    override open func forwardingTarget(for aSelector: Selector) -> Any? {
        return delegate
    }
    
    private func shouldEnableMethodCall(signature: EventMethodSignature) -> Bool {
        switch signature {
            case .heightForHeaderInSection: return configuration?.semanticHeaderHeight ?? false
            case .heightForFooterInSection: return configuration?.semanticFooterHeight ?? false
            default: return false
        }
    }
    
    /// Returns true, if `DTTableViewManageable` implements `aSelector`, or `DTTableViewManager` has an event, associated with this selector.
    ///
    /// - SeeAlso: `EventMethodSignature`
    override open func responds(to aSelector: Selector) -> Bool {
        if delegate?.responds(to: aSelector) ?? false {
            return true
        }
        if super.responds(to: aSelector) {
            if let eventSelector = EventMethodSignature(rawValue: String(describing: aSelector)) {
//                print("responds to \(aSelector)")
                let result = (unmappedReactions.contains {
                    $0.methodSignature == eventSelector.rawValue
                } ||
                (viewFactory?.mappings ?? [])
                .contains(where: { mapping in
                    mapping.reactions.contains(where: { reaction in
                        reaction.methodSignature == eventSelector.rawValue
                    })
                })) || shouldEnableMethodCall(signature: eventSelector)
//                print("result: \(result)")
                return result
            }
            return true
        }
        return false
    }
}
