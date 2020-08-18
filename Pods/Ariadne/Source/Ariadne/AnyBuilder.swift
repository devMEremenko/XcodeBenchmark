//
//  AnyBuilder.swift
//  Ariadne
//
//  Created by Denys Telezhkin on 08.11.2019.
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

/// Type-erased wrapper for `ViewControllerBuilder`. It can be used to shorten `ViewControllerBuilder` signatures in cases, where generic type information is not needed by consumer of the Route.
/// Another reason to do this if this generic information obstructs your usage of `ViewControllerBuilder`s, for example in cases where you want to create a UITabBarController with array of builders, and each of them has completely different type. In this case, you can convert them to array of `AnyBuilder` objects.
///
/// For example, when using navigation view builder, signature can become pretty long - NavigationSingleViewEmbeddingBuilder<RouteBuilder<ProfileViewController>>. But generally, you don't really care about resulting type as long as it's type is ensured, and it is a UIViewController. In those cases, you could cast a builder like so:
/// `builder.asAnyBuilder`
/// which wraps builder in the `AnyBuilder`, which can be now used as return type that is much shorter.
public struct AnyBuilder: ViewControllerBuilder {

    /// Closure, that constructs `ViewController`.
    let builder: () throws -> ViewController

    /// Creates `AnyBuilder` instance.
    /// - Parameters:
    ///   - builder: builder, whose type is going to be erased.
    ///   - context: Context to be used when building `ViewController`
    public init<T: ViewControllerBuilder>(builder: T, context: T.Context) {
        self.builder = { try builder.build(with: context) }
    }

    /// Creates `AnyBuilder` instance
    /// - Parameter builder: builder, whose type is going to be erased.
    public init<T: ViewControllerBuilder>(builder: T) where T.Context == Void {
        self.builder = { try builder.build(with: ()) }
    }

    /// Creates `AnyBuilder` instance
    /// - Parameter buildingBy: closure to build `ViewController` when Route is executed.
    public init<T: ViewController>(buildingBy: @escaping () throws -> T) {
        self.builder = { try buildingBy() }
    }

    /// Builds `ViewController` by running `builder` closure.
    /// - Parameter context: context is always Void, because Builder and Context types have been erased and are unknown at this point.
    public func build(with context: ()) throws -> ViewController {
        return try builder()
    }
}

extension ViewControllerBuilder where Context == Void {
    /// Converts any `ViewControllerBuilder` with Void context to AnyBuilder, erasing it's type.
    public var asAnyBuilder: AnyBuilder {
        return AnyBuilder(builder: self)
    }
}
