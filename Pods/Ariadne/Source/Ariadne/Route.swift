//
//  Route.swift
//  Ariadne
//
//  Created by Denys Telezhkin on 1/29/19.
//  Copyright © 2019 Denys Telezhkin. All rights reserved.
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

/// Type, that is responsible for performing routing between views.
open class Route<Builder: ViewControllerBuilder, Transition: ViewTransition>: Routable {

    /// Object, responsible for building a view, that is needed for routing.
    public let builder: Builder

    /// Object, that is responsible for performing a transition between views
    public let transition: Transition

    /// Closure, that is called prior to executing .hide transition
    open var prepareForHideTransition: ((_ visibleView: ViewController, _ transition: Transition) -> Void)?

    /// Closure, that is called prior to executing .show transition
    open var prepareForShowTransition: ((_ view: Builder.ViewType, _ transition: Transition, _ toView: ViewController?) -> Void)?

    /// Closure, that is called prior to executing a .custom transition
    open var prepareForCustomTransition: ((_ visibleView: ViewController, _ transition: Transition) -> Void)?

    /// Creates Route with specified builder and transition.
    ///
    /// - Parameters:
    ///   - builder: Object, responsible for building a view.
    ///   - transition: Object, that is responsible for performing transition between views.
    public init(builder: Builder, transition: Transition) {
        self.builder = builder
        self.transition = transition
    }

    /// Performs route between views.
    ///
    /// - Parameters:
    ///   - viewFinder: Object, responsible for providing currently visible view.
    ///   - context: object that will be used to build view to navigate to, if needed.
    ///   - completion: will be called once routing is completed.
    open func perform(withViewFinder viewFinder: ViewFinder,
                      context: Builder.Context,
                      completion: ((Bool) -> Void)? = nil) {
        guard let visibleView = (transition.viewFinder ?? viewFinder)?.currentlyVisibleView(startingFrom: nil) else {
            completion?(false)
            return
        }

        switch transition.transitionType {
        case .hide:
            prepareForHideTransition?(visibleView, transition)
            transition.perform(with: nil, on: visibleView, completion: completion)
        case .show:
            guard let viewToShow = try? builder.build(with: context) else {
                completion?(false); return
            }
            prepareForShowTransition?(viewToShow, transition, visibleView)
            transition.perform(with: viewToShow, on: visibleView, completion: completion)
        case .custom:
            prepareForCustomTransition?(visibleView, transition)
            transition.perform(with: nil, on: visibleView, completion: completion)
        }
    }
}

/// Subclass of `Route`, that allows view to be updated instead of creating a new one to transition to.
open class UpdatingRoute<Finder: UpdatableViewFinder, Builder: ViewControllerBuilder, Transition: ViewTransition>: Route<Builder, Transition>
    where Builder.ViewType: ContextUpdatable,
        Builder.Context == Finder.ViewType.Context,
        Finder.Context == Builder.Context,
        Finder.ViewType == Builder.ViewType {

    /// Object, responsible for finding view to update.
    public let updatableViewFinder: Finder

    /// Creates `UpdatingRoute`.
    ///
    /// - Parameters:
    ///   - updatableViewFinder: Object, responsible for finding view to update.
    ///   - builder: Object, responsible for building a view, that is needed for routing.
    ///   - transition: Object, that is responsible for performing a transition between views.
    public init(updatableViewFinder: Finder, builder: Builder, transition: Transition) {
        self.updatableViewFinder = updatableViewFinder
        super.init(builder: builder, transition: transition)
    }

    /// Performs route between views. If updatable view is found, it's updated with newly received context. If it's not found, this method calls superclass method and behaves as a `Route` object.
    ///
    /// - Parameters:
    ///   - viewFinder: Object, responsible for providing currently visible view.
    ///   - context: object that will be used to build view to navigate to, if needed.
    ///   - completion: will be called once routing is completed.
    open override func perform(withViewFinder viewFinder: ViewFinder, context: Builder.Context, completion: ((Bool) -> Void)?) {
        guard let updatableView = updatableViewFinder.findUpdatableView(for: context) else {
            super.perform(withViewFinder: viewFinder,
                          context: context,
                          completion: completion)
            return
        }
        updatableView.update(with: context)
        completion?(true)
    }
}

#if os(iOS) || os(tvOS)

extension Route where Builder.ViewType: ContextUpdatable, Builder.ViewType.Context == Builder.Context {

    /// Converts `Route` to `UpdatingRoute` given provided `RootViewProvider`, using `CurrentlyVisibleUpdatableViewFinder` as a `ViewFinder`.
    ///
    /// - Parameter rootProvider: Object responsible for providing root view of interface hierarchy.
    /// - Returns: `UpdatingRoute` with generic types identical to the current `Route`.
    open func asUpdatingRoute(withRootProvider rootProvider: RootViewProvider) -> UpdatingRoute<CurrentlyVisibleUpdatableViewFinder<Builder.ViewType>, Builder, Transition> {
        return UpdatingRoute(updatableViewFinder: CurrentlyVisibleUpdatableViewFinder(rootProvider: rootProvider),
                             builder: builder,
                             transition: transition)
    }
}

#endif

/// `Routable` type, that can be used to chain multiple `Route` objects. This is useful, for example, if you want to hide one View, and then immediately after hiding completes, show a different one.
open class ChainableRoute<T: Routable, U: Routable>: Routable {

    /// `ChainableRoute` builder is identical to first route builder
    public typealias Builder = T.Builder

    /// First route in the chain
    public let headRoute: T

    /// Other routes in the chain
    public let tailRoute: U

    /// Context, that will be used to build next View in the chain
    public let tailContext: U.Builder.Context

    /// Returns headRoute builder
    public var builder: T.Builder {
        return headRoute.builder
    }

    /// Returns NonTransition instance.
    public var transition: NonTransition {
        return NonTransition()
    }

    /// Creates chain from two routes, by placing them in a `headRoute` and `tailRoute`.
    ///
    /// - Parameters:
    ///   - headRoute: Route to be performed first
    ///   - tailRoute: Route to be performed next in the chain
    ///   - tailContext: Context required to build view for next route in the chain
    public init(headRoute: T, tailRoute: U, tailContext: U.Builder.Context) {
        self.headRoute = headRoute
        self.tailRoute = tailRoute
        self.tailContext = tailContext
    }

    /// Performs `headRoute`, and once it completes, follows it with `tailRoute`, and once that is completed, calls completion closure.
    ///
    /// - Parameters:
    ///   - viewFinder: object responsible for finding view on which route should be performed.
    ///   - context: object that will be used to build view to navigate to, if needed. In this case, it's context for `headRoute`.
    ///   - completion: will be called once head and tail routes are completed.
    open func perform(withViewFinder viewFinder: ViewFinder, context: T.Builder.Context, completion: ((Bool) -> Void)?) {
        headRoute.perform(withViewFinder: viewFinder, context: context) { [weak self] completedHead in
            guard let self = self else {
                completion?(false)
                return
            }
            self.tailRoute.perform(withViewFinder: viewFinder, context: self.tailContext, completion: { completedTail in
                completion?(completedHead && completedTail)
            })
        }
    }
}

extension Routable {

    /// Chains current route with the next one.
    ///
    /// - Parameters:
    ///   - chainedRoute: Route to be performed after current one.
    ///   - context: Argument, used to build view for next route.
    /// - Returns: ChainedRoute with current Route set as `HeadRoute`, and `chainedRoute` set as `tailRoute`.
    public func chained<T: Routable>(with chainedRoute: T, context: T.Builder.Context) -> ChainableRoute<Self, T> {
        return ChainableRoute(headRoute: self, tailRoute: chainedRoute, tailContext: context)
    }

    /// Chains current route with the next one.
    ///
    /// - Parameters:
    ///   - chainedRoute: Route to be performed after current one.
    /// - Returns: ChainedRoute with current Route set as `HeadRoute`, and `chainedRoute` set as `tailRoute`.
    public func chained<T: Routable>(with chainedRoute: T) -> ChainableRoute<Self, T>
        where T.Builder.Context == Void {
        return chained(with: chainedRoute, context: ())
    }
}
