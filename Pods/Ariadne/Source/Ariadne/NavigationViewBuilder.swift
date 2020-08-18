//
//  NavigationViewBuilder.swift
//  Ariadne
//
//  Created by Denys Telezhkin on 10/1/18.
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

/// Builder for `UINavigationController` instance with array of views.
open class NavigationEmbeddingBuilder: ViewControllerBuilder {

    /// Defines how `UINavigationController` should be created.
    open var navigationControllerBuilder : () -> UINavigationController = { .init() }

    // swiftlint:disable multiple_closure_params

    /// Creates `NavigationEmbeddingBuilder`.
    public init(navigationBuilder: @escaping () -> UINavigationController = { .init() }) {
        self.navigationControllerBuilder = navigationBuilder
    }

    /// Builds `UINavigationController` from provided array of views, setting them in `viewControllers` property of `UINavigationController`.
    ///
    /// - Parameter context: Array of views to set in `viewControllers` property.
    /// - Returns: Created `UINavigationController`.
    open func build(with context: [ViewController]) -> UINavigationController {
        let navigation = navigationControllerBuilder()
        navigation.viewControllers = context
        return navigation
    }
}

/// Builder for `UINavigationController` instance with a single embedded view. This builder keeps `Context` the same as `Context` of embedded view builder, thus allowing building a combination of those by passing embedded view Context.
open class NavigationSingleViewEmbeddingBuilder<T: ViewControllerBuilder>: ViewControllerBuilder {

    /// `NavigationSingleViewEmbeddingBuilder`.Context is identical to embedded view Context.
    public typealias Context = T.Context

    /// Embedded view builder.
    public let builder: T

    /// Defines how `UINavigationController` should be created
    open var navigationControllerBuilder : () -> UINavigationController = { .init() }

    /// Creates `NavigationSingleViewEmbeddingBuilder` from provided embedded view builder.
    ///
    /// - Parameter builder: Embedded view builder.
    public init(builder: T) {
        self.builder = builder
    }

    /// Builds `UINavigationController` instance with embedded view, which is set in its `viewControllers` property.
    ///
    /// - Parameter context: Argument to build embedded view.
    /// - Returns: Created `UINavigationController`.
    /// - Throws: Embedded view build errors.
    open func build(with context: Context) throws -> UINavigationController {
        let view = try builder.build(with: context)
        let navigation = navigationControllerBuilder()
        navigation.viewControllers = [view]
        return navigation
    }
}

extension ViewControllerBuilder {

    /// Creates a `NavigationSingleViewEmbeddingBuilder`, embedding current view builder in it.
    ///
    /// - Returns: `NavigationSingleViewEmbeddingBuilder` with current builder embedded.
    public func embeddedInNavigation(navigationBuilder: @escaping () -> UINavigationController = { .init() }) -> NavigationSingleViewEmbeddingBuilder<Self> {
        let builder = NavigationSingleViewEmbeddingBuilder(builder: self)
        builder.navigationControllerBuilder = navigationBuilder
        return builder
    }
}

#endif

#endif
