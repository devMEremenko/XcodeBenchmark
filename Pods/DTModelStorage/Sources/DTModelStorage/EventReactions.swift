//
//  UIReactions.swift
//  DTModelStorage
//
//  Created by Denys Telezhkin on 29.11.15.
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

//swiftlint:disable large_tuple

/// Data holder for reaction
open class EventReaction {
    
    /// view -> model mapping of this reaction
    public let viewModelMapping: ViewModelMapping
    
    /// 3 arguments reaction block with all arguments type-erased.
    open var reaction : ((Any, Any, Any) -> Any)?
    
    /// Objective-C method signature
    public let methodSignature: String
    
    /// Creates reaction with `signature`.
    public init<T: ModelTransfer>(signature: String, viewType: ViewType, viewClass: T.Type) {
        self.methodSignature = signature
        viewModelMapping = ViewModelMapping(viewType: viewType, viewClass: T.self, mappingBlock: nil)
    }
    
    /// Creates reaction with `signature`, `viewType` and `modelType`.
    public init<T>(signature: String, viewType: ViewType, modelType: T.Type) {
        self.methodSignature = signature
        viewModelMapping = ViewModelMapping.eventsModelMapping(viewType: viewType, modelClass: T.self)
    }
    
    /// Creates reaction with type-erased T and T.ModelType into Any types.
    open func makeReaction<T: ModelTransfer, U>(_ block: @escaping (T, T.ModelType, IndexPath) -> U) {
        reaction = { cell, model, indexPath in
            guard let model = model as? T.ModelType,
                let indexPath = indexPath as? IndexPath,
                let cell = cell as? T
                else {
                    return 0
            }
            return block(cell, model, indexPath)
        }
    }
    
    /// Creates reaction with type-erased T into Any type.
    open func makeReaction<T, U>(_ block: @escaping (T, IndexPath) -> U) {
        reaction = { cell, model, indexPath in
            guard let model = model as? T,
                let indexPath = indexPath as? IndexPath else {
                    return 0
            }
            return block(model, indexPath)
        }
    }
    
    /// Performs reaction with `arguments`.
    open func performWithArguments(_ arguments: (Any, Any, Any)) -> Any {
        return reaction?(arguments.0, arguments.1, arguments.2) ?? 0
    }
}

/// Subclass of `EventReaction`, tuned to work with 4 arguments.
open class FourArgumentsEventReaction: EventReaction {
    
    /// Type-erased reaction with 4 arguments
    open var reaction4Arguments : ((Any, Any, Any, Any) -> Any)?
    
    /// Makes 4 argument reaction based on `View`.
    open func make4ArgumentsReaction<View:ModelTransfer, Argument, ReturnType>(_ block: @escaping (Argument, View, View.ModelType, IndexPath) -> ReturnType) {
        reaction4Arguments = { argument, view, model, indexPath in
            guard let model = model as? View.ModelType,
                let indexPath = indexPath as? IndexPath,
                let argument = argument as? Argument,
                let view = view as? View else { return 0 }
            return block(argument, view, model, indexPath)
        }
    }
    
    /// Creates FourArgumentsEventReaction for `viewClass`
    public override init<T: ModelTransfer>(signature: String, viewType: ViewType, viewClass: T.Type) {
        super.init(signature: signature, viewType: viewType, viewClass: viewClass)
    }
    
    /// Creates FourArgumentsEventReaction for `modelType`
    public override init<T>(signature: String, viewType: ViewType, modelType: T.Type) {
        super.init(signature: signature, viewType: viewType, modelType: modelType)
    }
    
    /// Performs reaction with `arguments`.
    open func performWithArguments(_ arguments: (Any, Any, Any, Any)) -> Any {
        return reaction4Arguments?(arguments.0, arguments.1, arguments.2, arguments.3) ?? 0
    }
}

/// Subclass of `EventReaction`, tuned to work with 5 arguments.
open class FiveArgumentsEventReaction: EventReaction {
    
    /// Type-erased reaction with 5 arguments
    open var reaction5Arguments : ((Any, Any, Any, Any, Any) -> Any)?
    
    /// Makes 5 argument reaction based on `View`.
    open func make5ArgumentsReaction<View:ModelTransfer, ArgumentOne, ArgumentTwo, ReturnType>(_ block: @escaping (ArgumentOne, ArgumentTwo, View, View.ModelType, IndexPath) -> ReturnType) {
        reaction5Arguments = { argumentOne, argumentTwo, view, model, indexPath in
            guard let model = model as? View.ModelType,
                let indexPath = indexPath as? IndexPath,
                let argument1 = argumentOne as? ArgumentOne,
                let argument2 = argumentTwo as? ArgumentTwo,
                let view = view as? View else { return 0 }
            return block(argument1, argument2, view, model, indexPath)
        }
    }
    
    /// Creates FiveArgumentsEventReaction for `viewClass`
    public override init<T: ModelTransfer>(signature: String, viewType: ViewType, viewClass: T.Type) {
        super.init(signature: signature, viewType: viewType, viewClass: viewClass)
    }
    
    /// Creates FiveArgumentsEventReaction for `modelType`
    public override init<T>(signature: String, viewType: ViewType, modelType: T.Type) {
        super.init(signature: signature, viewType: viewType, modelType: modelType)
    }
    
    /// Performs reaction with `arguments`.
    open func performWithArguments(_ arguments: (Any, Any, Any, Any, Any)) -> Any {
        return reaction5Arguments?(arguments.0, arguments.1, arguments.2, arguments.3, arguments.4) ?? 0
    }
}

extension Sequence where Self.Iterator.Element: EventReaction {
    /// Searches for reaction using specified parameters.
    public func reaction(of type: ViewType,
                         signature: String,
                         forModel model: Any,
                         view: UIView?) -> EventReaction? {
        return first(where: { reaction in
            guard let unwrappedModel = RuntimeHelper.recursivelyUnwrapAnyValue(model) else { return false }
            return reaction.viewModelMapping.viewType == type &&
                reaction.viewModelMapping.modelTypeCheckingBlock(unwrappedModel) &&
                view?.isKind(of: reaction.viewModelMapping.viewClass) ?? true &&
                reaction.methodSignature == signature
        })
    }
    
    /// Performs reaction of `type`, `signature`, with `view`, `model` in `location`.
    public func performReaction(of type: ViewType, signature: String, view: Any?, model: Any, location: Any) -> Any {
        guard let reaction = reaction(of: type, signature: signature, forModel: model, view: view as? UIView) else {
            return 0
        }
        return reaction.performWithArguments((view ?? 0, model, location))
    }
    
    //swiftlint:disable function_parameter_count
    /// Performs reaction of `type`, `signature`, with `argument`, `view`, `model` in `location`.
    public func perform4ArgumentsReaction(of type: ViewType, signature: String, argument: Any, view: Any?, model: Any, location: Any) -> Any {
        guard let reaction = reaction(of: type, signature: signature, forModel: model, view: view as? UIView) as? FourArgumentsEventReaction else { return 0 }
        return reaction.performWithArguments((argument, view ?? 0, model, location))
    }
    
    /// Performs reaction of `type`, `signature`, with `firstArgument`, `secondArgument`, `view`, `model` in `location`.
    public func perform5ArgumentsReaction(of type: ViewType, signature: String, firstArgument: Any, secondArgument: Any, view: Any?, model: Any, location: Any) -> Any {
        guard let reaction = reaction(of: type, signature: signature, forModel: model, view: view as? UIView) as? FiveArgumentsEventReaction else { return 0 }
        return reaction.performWithArguments((firstArgument, secondArgument, view ?? 0, model, location))
    }
}
