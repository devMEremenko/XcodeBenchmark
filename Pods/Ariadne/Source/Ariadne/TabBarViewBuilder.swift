//
//  TabBarViewBuilder.swift
//  Ariadne
//
//  Created by Denys Telezhkin on 10/30/18.
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

/// Builder for `UITabBarController` instance.
open class TabBarEmbeddingBuilder: ViewControllerBuilder {

    /// Defines how `UITabBarController` should be created.
    open var tabBarControllerBuilder: () -> UITabBarController = { .init() }

    // swiftlint:disable multiple_closure_params

    /// Creates `TabBarEmbeddingBuilder`.
    public init(tabBarBuilder: @escaping () -> UITabBarController = { .init() }) {
        self.tabBarControllerBuilder = tabBarBuilder
    }

    /// Builds `UITabBarController` from provided array of views, setting them in `viewControllers` property of `UITabBarController`.
    ///
    /// - Parameter context: array of views to set in `viewControllers` property.
    /// - Returns: created `UITabBarController`.
    open func build(with context: [ViewController]) -> UITabBarController {
        let tabBar = tabBarControllerBuilder()
        tabBar.viewControllers = context
        return tabBar
    }
}

#endif

#endif
