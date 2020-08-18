//
//  RootViewTransition.swift
//  Ariadne
//
//  Created by Denys Telezhkin on 10/18/18.
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

#if os(iOS) || os(tvOS)
import UIKit

/// Class, that implements transition for `UIWindow.rootViewController`.
open class RootViewTransition: ViewTransition {

    /// Transition type, defaults to .show.
    open var transitionType: TransitionType = .show

    /// CUrrently visible view finder. Defaults to nil and is not used in current transition.
    open var viewFinder: ViewFinder?

    /// `UIWindow` instance on which transition will be performed.
    public let window: UIWindow

    /// Duration of animated transition. Defaults to 0.3 seconds.
    open var duration: TimeInterval = 0.3

    /// Animation options for transition. Defaults to UIView.AnimationOptions.transitionCrossDissolve.
    open var animationOptions = UIView.AnimationOptions.transitionCrossDissolve

    /// Should the transition be animated.
    open var isAnimated: Bool

    /// Creates `RootViewTransition` from specified `UIWindow` instance.
    ///
    /// - Parameters:
    ///   - window: `UIWindow`, on which transition will be happening.
    ///   - isAnimated: Should the transition be animated.
    public init(window: UIWindow, isAnimated: Bool = true) {
        self.window = window
        self.isAnimated = isAnimated
    }

    /// Performs UIWindow.rootViewController switch using `UIView.transition(with:duration:options:animations:completion:)` method.
    ///
    /// - Parameters:
    ///   - view: View that will be set as a `rootViewController`.
    ///   - visibleView: Currently visibleView. Unused in this method.
    ///   - completion: Called once transition has been completed.
    open func perform(with view: ViewController?, on visibleView: ViewController?, completion: ((Bool) -> Void)?) {
        if isAnimated {
            UIView.performWithoutAnimation {
                UIView.transition(with: window, duration: duration,
                                  options: animationOptions,
                                  animations: {
                    self.window.rootViewController = view
                }, completion: { state in
                    completion?(state)
                })
            }
        } else {
            window.rootViewController = view
            completion?(true)
        }
    }
}

#endif
