//
//  ViewUpdater.swift
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

/// Type, that can be updated with newly received `Context`
public protocol ContextUpdatable {

    /// Argument type, that can be used to update a `View`.
    associatedtype Context

    /// Updates current type with newly received `context`.
    ///
    /// - Parameter context: argument used for updating current object.
    func update(with context: Context)
}

/// Object, that searches view hierarchy to find `View`, that can be updated with provided `Context`.
public protocol UpdatableViewFinder {

    /// Type of `View` to search for
    associatedtype ViewType: ViewController

    /// Argument type, that can be used to update a `View`.
    associatedtype Context

    /// Searches view hierarchy to find `View`, that can be updated using provided `Context`.
    ///
    /// - Parameter context: argument used for updating current `View`.
    /// - Returns: Found `View` to update, or nil.
    func findUpdatableView(for context: Context) -> ViewType?
}

#if canImport(UIKit)

#if os(iOS) || os(tvOS)

/// `UpdatableViewFinder` type that searches current view hierarchy to find view, that can be updated using `Context`. Uses `CurrentlyVisibleViewFinder` to search view hierarchy for currently visible view.
open class CurrentlyVisibleUpdatableViewFinder<T: ViewController & ContextUpdatable> : UpdatableViewFinder {

    /// Object responsible for providing root view of interface hierarchy.
    public let rootProvider: RootViewProvider

    /// Creates `CurrentlyVisibleUpdatableViewFinder`.
    ///
    /// - Parameter rootProvider: Object responsible for providing root view of interface hierarchy.
    public init(rootProvider: RootViewProvider) {
        self.rootProvider = rootProvider
    }

    /// Searches view hierarchy to find `View`, that can be updated using provided `Context`. Uses `CurrentlyVisibleViewFinder` object to find currently visible view.
    ///
    /// - Parameter context: Argument, that can be used to update a `View`.
    /// - Returns: Found `View` to update, or nil.
    open func findUpdatableView(for context: T.Context) -> T? {
        return CurrentlyVisibleViewFinder(rootViewProvider: rootProvider).currentlyVisibleView() as? T
    }
}

#endif

#endif
