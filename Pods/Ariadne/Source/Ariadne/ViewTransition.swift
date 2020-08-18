//
//  ViewTransition.swift
//  Ariadne
//
//  Created by Denys Telezhkin on 4/22/19.
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

/// Value type, that represents action, that `ViewTransition` object is performing.
/// For example, `PushNavigationTransition` is a .show transition type, where `PopNavigationTransition` is a .hide type.
///
/// - hide: Transition is hiding already shown view
/// - show: Transition is showing a new, or previously hidden view.
/// - custom: Transition that is custom and is not directly a show or a hide.
public enum TransitionType {
    case hide
    case show
    case custom
}

/// Type, that is responsible for making a transition between views.
public protocol ViewTransition {

    /// Flag, that shows whether transition should be animated.
    var isAnimated: Bool { get }

    /// Type of transition this object is capable of performing.
    var transitionType: TransitionType { get }

    /// Object, responsible for finding currently visible view in existing view hierarchy.
    var viewFinder: ViewFinder? { get }

    /// Performs transition with provided `view`, using currently `visibleView`, and calls `completion` once transition has been completed.
    ///
    /// - Parameters:
    ///   - view: view object that will be used for transition. In case of .hide transition type this parameter is nil.
    ///   - visibleView: Currently visible view.
    ///   - completion: closure to be called, once transition is completed.
    func perform(with view: ViewController?,
                 on visibleView: ViewController?,
                 completion: ((Bool) -> Void)?)
}

/// Transition, that should not be performed and asserts if asked to do so. Can be used for routes that do not clearly define a transition, for example instances of `ChainableRoute`, which may have multiple chainable transitions embedded.
public struct NonTransition: ViewTransition {

    /// Returns false
    public var isAnimated: Bool { return false }

    /// Returns .custom.
    public var transitionType: TransitionType { return .custom }

    /// Returns nil
    public var viewFinder: ViewFinder? { return nil }

    /// Creates NonTransition object.
    public init() {}

    /// This method is not expected to be called and asserts when it is.
    public func perform(with view: ViewController?, on visibleView: ViewController?, completion: ((Bool) -> Void)?) {
        assertionFailure("NonTransition should not be asked to perform transition")
        completion?(false)
    }
}
