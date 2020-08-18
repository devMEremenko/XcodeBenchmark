//
//  BaseTransition.swift
//  Ariadne
//
//  Created by Denys Telezhkin on 2/9/19.
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

/// Base class for transition objects.
open class BaseTransition {

    /// Should the transition be animated.
    open var isAnimated: Bool

    /// Object responsible for finding currently visible view in view hierarchy.
    public let viewFinder: ViewFinder?

    /// Creates animated transition object. If `finder` argument is nil, `Route` class uses `ViewFinder` passed by the `Router` that performs the route. This is recommended behavior unless you want to customize view searching for this particular transition.
    ///
    /// - Parameters:
    ///   - finder: Object responsible for finding currently visible view in view hierarchy. Defaults to nil.
    ///   - isAnimated: Should the transition be animated. Defaults to true.
    public init(finder: ViewFinder? = nil, isAnimated: Bool = true) {
        viewFinder = finder
        self.isAnimated = isAnimated
    }

    #if os(iOS) || os(tvOS)

    /// If `isAnimated` flag is true, calls visibleView.transitionCoordinator `animate(alongsideTransition:)` method and calls completion block once transition has been completed. If `isAnimated` is false, just calls completion block and returns.
    /// - Parameter visibleView: View to perform transition on
    /// - Parameter isAnimated: whether transition should be animated
    /// - Parameter completion: completion block to call once transition is completed
    open func animateAlongsideTransition(with visibleView: ViewController?, isAnimated: Bool, completion: ((Bool) -> Void)?) {
        if let coordinator = visibleView?.transitionCoordinator, isAnimated {
            coordinator.animate(alongsideTransition: nil) { _ in
                completion?(true)
            }
        } else {
            completion?(true)
        }
    }

    #endif
}
