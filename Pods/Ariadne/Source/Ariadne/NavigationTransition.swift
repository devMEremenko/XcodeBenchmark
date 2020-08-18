//
//  NavigationTransition.swift
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

#if os(iOS) || os(tvOS)

/// Class, that encapsulates UINavigationController.pushViewController(_:animated:) method call as a transition.
open class PushNavigationTransition: BaseTransition, ViewTransition {

    /// Transition type .show.
    public let transitionType: TransitionType = .show

    /// Performs transition by calling `pushViewController(_:animated:)` on `visibleView` navigation controller with `view` argument.
    ///
    /// - Parameters:
    ///   - view: view that is being pushed.
    ///   - visibleView: visible view in navigation controller stack.
    ///   - completion: called once transition has been completed
    open func perform(with view: ViewController?, on visibleView: ViewController?, completion: ((Bool) -> Void)?) {
        guard let view = view else { completion?(false); return }
        guard let navigation = (visibleView as? UINavigationController) ?? visibleView?.navigationController else {
            completion?(false); return
        }
        navigation.pushViewController(view, animated: isAnimated)
        animateAlongsideTransition(with: visibleView, isAnimated: isAnimated, completion: completion)
    }
}

/// Class, that encapsulates UINavigationController.popViewController(_:animated:) method call as a transition.
open class PopNavigationTransition: BaseTransition, ViewTransition {

    /// Kind of pop navigation transition to perform
    public enum Behavior {
        case pop
        case popToRoot
        case popToFirstInstanceOf(UIViewController.Type)
        case popToLastInstanceOf(UIViewController.Type)
    }

    /// Transition type .hide.
    public let transitionType: TransitionType = .hide

    /// Behavior of pop navigation transition to perform
    public let behavior: Behavior

    /// Creates `PopNavigationTransition` with specified `behavior`.
    /// - Parameters:
    ///   - behavior: Behavior of pop navigation transition
    ///   - finder: Object responsible for finding currently visible view in view hierarchy. Defaults to nil.
    ///   - isAnimated: Should the transition be animated. Defaults to true.
    public init(_ behavior: Behavior = .pop, finder: ViewFinder? = nil, isAnimated: Bool = true) {
        self.behavior = behavior
        super.init(finder: finder, isAnimated: isAnimated)
    }

    /// Performs transition by calling `popViewController(_:animated:)` on `visibleView` navigation controller.
    ///
    /// - Parameters:
    ///   - view: currently visible view
    ///   - visibleView: currently visible view in view hierarchy
    ///   - completion: called once transition has been completed
    open func perform(with view: ViewController?, on visibleView: ViewController?, completion: ((Bool) -> Void)?) {
        guard let visibleView = visibleView else { completion?(false); return }
        guard let navigation = (visibleView as? UINavigationController) ?? visibleView.navigationController else {
            completion?(false); return
        }
        switch behavior {
            case .pop: navigation.popViewController(animated: isAnimated)
            case .popToRoot: navigation.popToRootViewController(animated: isAnimated)
            case .popToFirstInstanceOf(let type):
                let first = navigation.viewControllers.first(where: { $0.isKind(of: type) })
                _ = first.flatMap { navigation.popToViewController($0, animated: isAnimated) }
        case .popToLastInstanceOf(let type):
            let last = navigation.viewControllers.last(where: { $0.isKind(of: type) })
            _ = last.flatMap { navigation.popToViewController($0, animated: isAnimated) }
        }
        animateAlongsideTransition(with: visibleView, isAnimated: isAnimated, completion: completion)
    }
}

/// Class, that encapsulates UINavigationController.setViewControllers(_:animated:) method call as a transition.
open class ReplaceNavigationTransition: BaseTransition, ViewTransition {

    /// Behavior of `ReplaceNavigationTransition`.
    public enum Behavior {
        case replaceLast
        case replaceAll
        // Choose what view controllers to keep. Navigation stack after replacement will contain view controllers returned from custom closure + replacing view controller as a last of them.
        case custom(keepControllers: ([UIViewController]) -> [UIViewController])
    }

    /// Transition type .show
    public let transitionType: TransitionType = .show

    /// Behavior of replace navigation transition to perform
    public let behavior: Behavior

    /// Creates `ReplaceNavigationTransition` with specified `behavior`.
    /// - Parameters:
    ///   - behavior: Behavior of replace navigation transition
    ///   - finder: Object responsible for finding currently visible view in view hierarchy. Defaults to nil.
    ///   - isAnimated: Should the transition be animated. Defaults to true.
    public init(_ behavior: Behavior = .replaceLast, finder: ViewFinder? = nil, isAnimated: Bool = true) {
        self.behavior = behavior
        super.init(finder: finder, isAnimated: isAnimated)
    }

    /// Performs transition by calling `setViewControllers(_:animated:)` on visible navigation controller
    /// - Parameters:
    ///   - view: currently visible view
    ///   - visibleView: currently visible view in view hierarchy
    ///   - completion: called once transition has been completed
    open func perform(with view: ViewController?, on visibleView: ViewController?, completion: ((Bool) -> Void)?) {
        guard let view = view else { completion?(false); return }
        guard let navigation = (visibleView as? UINavigationController) ?? visibleView?.navigationController else {
            completion?(false); return
        }
        switch behavior {
        case .replaceAll:
            navigation.setViewControllers([view], animated: isAnimated)
        case .replaceLast:
            var stack = navigation.viewControllers.dropLast()
            stack.append(view)
            navigation.setViewControllers(stack.map { $0 }, animated: isAnimated)
        case .custom(keepControllers: let closure):
            var newStack = closure(navigation.viewControllers)
            newStack.append(view)
            navigation.setViewControllers(newStack.map { $0 }, animated: isAnimated)
        }
        animateAlongsideTransition(with: visibleView, isAnimated: isAnimated, completion: completion)
    }
}

@available(*, deprecated, message: "Please use PopNavigationTransition with .popToRoot Kind.")
/// Class, that encapsulates UINavigationController.popToRootViewController(animated:) method call as a transition.
open class PopToRootNavigationTransition: BaseTransition, ViewTransition {

    /// Transition type .hide.
    public let transitionType: TransitionType = .hide

    /// Performs transition by calling `popToRootViewController(animated:)` on `visibleView` navigation controller.
    ///
    /// - Parameters:
    ///   - view: currently visible view
    ///   - visibleView: currently visible view in view hierarchy
    ///   - completion: called once transition has been completed
    open func perform(with view: ViewController?, on visibleView: ViewController?, completion: ((Bool) -> Void)?) {
        PopNavigationTransition(.popToRoot, finder: viewFinder, isAnimated: isAnimated)
            .perform(with: view, on: visibleView, completion: completion)
    }
}

#endif

#endif
