//
//  Ariadne.swift
//  Ariadne
//
//  Created by Denys Telezhkin on 10/11/18.
//  Copyright © 2018 Denys Telezhkin. All rights reserved.
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
#if canImport(UIKit)
import UIKit
#endif
/// Type, responsible for finding currently visible view in existing view hierarchy.
public protocol ViewFinder {

    /// Returns currently visible view in view hierarchy.
    ///
    /// - Parameter startingFrom: root view to start searching from.
    /// - Returns: currently visible view or nil, if it was not found.
    func currentlyVisibleView(startingFrom: ViewController?) -> ViewController?
}

/// Type that is responsible for providing root view in current view hierarchy.
/// - Note: on iOS and tvOS, commonly, the root provider is UIWindow via UIApplication.shared.keyWindow, however there are scenarios where keyWindow might not be accessible, for example in iMesssage apps and application extensions. In those cases you can use root view controller that is accessible in those context, for example in iMessage extensions this could be `MSMessagesAppViewController`, or view controller presented on top of it.
/// Also, your app might have several UIWindow objects working in the same time, for example when app is using AirPlay, or if `UIWindow`s are used to present different interfaces modally. In those cases it's recommended to have multiple `Router` objects with different `RootViewProvider`s.
public protocol RootViewProvider {

    /// Root view in current view hierarchy.
    var rootViewController: ViewController? { get }
}

/// Type, that is capable of performing route from current screen to another one.
/// One example of such type is Route<ViewControllerBuilder,ViewTransition> type, that includes necessary builder to build next visible view, and transition object, that will perform a transition.
public protocol Routable {

    /// Type, responsible for building a view, that is needed for routing.
    associatedtype Builder: ViewControllerBuilder

    /// Type, responsible for performing a transition.
    associatedtype Transition: ViewTransition

    /// Instance of `ViewBuilder`.
    var builder: Builder { get }

    /// Instance of `ViewTransition`.
    var transition: Transition { get }

    /// Performs route using provided context.
    ///
    /// - Parameters:
    ///   - withViewFinder: object, that can be used to find currently visible view in view hierarchy
    ///   - context: object, that can be used for building a new route destination view.
    ///   - completion: closure to be called, once routing is completed.
    func perform(withViewFinder: ViewFinder,
                 context: Builder.Context,
                 completion: ((Bool) -> Void)?)
}

/// Object responsible for performing navigation to concrete routes, as well as keeping references to root view provider and view finder.
open class Router {

    /// Object responsible for finding view on which route should be performed.
    open var viewFinder: ViewFinder

    /// Object responsible for providing root view of interface hierarchy.
    open var rootViewProvider: RootViewProvider

    #if os(iOS) || os(tvOS)

    /// Creates `Router` with `CurrentlyVisibleViewFinder` object set as a `ViewFinder` instance.
    ///
    /// - Parameter rootViewProvider: provider of the root view of interface.
    public init(rootViewProvider: RootViewProvider) {
        self.viewFinder = CurrentlyVisibleViewFinder(rootViewProvider: rootViewProvider)
        self.rootViewProvider = rootViewProvider
    }

    #else

    /// Creates `Router` with specified root view provider and view finder.
    ///
    /// - Parameters:
    ///   - rootViewProvider: provider of the root view of interface.
    ///   - viewFinder: object responsible for finding view on which route should be performed.
    public init(rootViewProvider: RootViewProvider, viewFinder: ViewFinder) {
        self.viewFinder = viewFinder
        self.rootViewProvider = rootViewProvider
    }

    #endif

    #if os(iOS) || os(tvOS)

    /// Returns route, that calls `popViewController` method on currently visible navigation controller. No view is getting built in the process of routing.
    ///
    /// - Parameter isAnimated: should the transition be animated.
    /// - Returns: performable route.
    open class func popRoute(isAnimated: Bool = true) -> Route<NonBuilder, PopNavigationTransition> {
        return .init(builder: NonBuilder(), transition: PopNavigationTransition(isAnimated: isAnimated))
    }

    /// Returns route, that calls `popViewController` method on currently visible navigation controller. No view is getting built in the process of routing.
    ///
    /// - Parameter isAnimated: should the transition be animated.
    /// - Returns: performable route.
    open func popRoute(isAnimated: Bool = true) -> Route<NonBuilder, PopNavigationTransition> {
        return Router.popRoute(isAnimated: isAnimated)
    }

    /// Returns route, that calls `popToRootViewController` method on currently visible navigation controller. No view is getting built in the process of routing.
    ///
    /// - Parameter isAnimated: should the transition be animated.
    /// - Returns: performable route.
    open class func popToRootRoute(isAnimated: Bool = true) -> Route<NonBuilder, PopNavigationTransition> {
        return .init(builder: NonBuilder(), transition: PopNavigationTransition(.popToRoot, isAnimated: isAnimated))
    }

    /// Returns route, that calls `popToViewController(_:animated:)` method on currently visible navigation controller. No view is getting built in the process of routing. First instance of `type` view controllers available in navigation stack is selected
    /// - Parameters:
    ///   - type: type of view controller to search for in navigation stack
    ///   - isAnimated: should the transition be animated.
    open class func popToFirstInstanceOf(_ type: UIViewController.Type, isAnimated: Bool = true) -> Route<NonBuilder, PopNavigationTransition> {
        return Route(builder: NonBuilder(), transition: PopNavigationTransition(.popToFirstInstanceOf(type), isAnimated: isAnimated))
    }

    /// Returns route, that calls `popToViewController(_:animated:)` method on currently visible navigation controller. No view is getting built in the process of routing. First instance of `type` view controllers available in navigation stack is selected
    /// - Parameters:
    ///   - type: type of view controller to search for in navigation stack
    ///   - isAnimated: should the transition be animated.
    open func popToFirstInstanceOf(_ type: UIViewController.Type, isAnimated: Bool = true) -> Route<NonBuilder, PopNavigationTransition> {
        return Router.popToFirstInstanceOf(type, isAnimated: isAnimated)
    }

    /// Returns route, that calls `popToViewController(_:animated:)` method on currently visible navigation controller. No view is getting built in the process of routing. Last instance of `type` view controllers available in navigation stack is selected.
    /// - Parameters:
    ///   - type: type of view controller to search for in navigation stack
    ///   - isAnimated: should the transition be animated.
    open class func popToLastInstanceOf(_ type: UIViewController.Type, isAnimated: Bool = true) -> Route<NonBuilder, PopNavigationTransition> {
        return Route(builder: NonBuilder(), transition: PopNavigationTransition(.popToLastInstanceOf(type), isAnimated: isAnimated))
    }

    /// Returns route, that calls `popToViewController(_:animated:)` method on currently visible navigation controller. No view is getting built in the process of routing. Last instance of `type` view controllers available in navigation stack is selected.
    /// - Parameters:
    ///   - type: type of view controller to search for in navigation stack
    ///   - isAnimated: should the transition be animated.
    open func popToLastInstanceOf(_ type: UIViewController.Type, isAnimated: Bool = true) -> Route<NonBuilder, PopNavigationTransition> {
        return Router.popToLastInstanceOf(type, isAnimated: isAnimated)
    }

    /// Returns route, that calls `popToRootViewController` method on currently visible navigation controller. No view is getting built in the process of routing.
    ///
    /// - Parameter isAnimated: should the transition be animated.
    /// - Returns: performable route.
    open func popToRootRoute(isAnimated: Bool = true) -> Route<NonBuilder, PopNavigationTransition> {
        return Router.popToRootRoute(isAnimated: isAnimated)
    }

    /// Returns route, that calls `dismiss` method on currently visible view controller. No view is getting built in the process of routing.
    ///
    /// - Parameter isAnimated: should the transition be animated.
    /// - Returns: performable route.
    open class func dismissRoute(isAnimated: Bool = true) -> Route<NonBuilder, DismissTransition> {
        return .init(builder: NonBuilder(), transition: DismissTransition(isAnimated: isAnimated))
    }

    /// Returns route, that calls `dismiss` method on currently visible view controller. No view is getting built in the process of routing.
    ///
    /// - Parameter isAnimated: should the transition be animated.
    /// - Returns: performable route.
    open func dismissRoute(isAnimated: Bool = true) -> Route<NonBuilder, DismissTransition> {
        return Router.dismissRoute(isAnimated: isAnimated)
    }

    #endif

    /// Performs navigation to `route` using provided `context` and calling `completion` once routing process is completed.
    ///
    /// - Parameters:
    ///   - route: route to navigate to.
    ///   - context: object that will be used to build view to navigate to, if needed.
    ///   - completion: will be called once routing is completed.
    open func navigate<T: Routable>(to route: T,
                                    with context: T.Builder.Context,
                                    completion: ((Bool) -> Void)? = nil)
    {
        route.perform(withViewFinder: viewFinder, context: context, completion: completion)
    }

    /// Performs navigation to `route` and calls `completion` once routing process is completed.
    ///
    /// - Parameters:
    ///   - route: route to navigate to.
    ///   - completion: will be called once routing is completed.
    open func navigate<T: Routable>(to route: T, completion: ((Bool) -> Void)? = nil)
        where T.Builder.Context == Void {
        navigate(to: route, with: (), completion: completion)
    }
}
