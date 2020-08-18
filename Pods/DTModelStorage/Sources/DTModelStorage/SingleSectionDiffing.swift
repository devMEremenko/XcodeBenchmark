//
//  SingleSectionDiffing.swift
//  DTModelStorage
//
//  Created by Denys Telezhkin on 21.09.2018.
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

/// A type that can be identified by `identifier`.
public protocol EntityIdentifiable {
    
    /// Unique identifier of object. It must never change for this specific object.
    var identifier: AnyHashable { get }
}

/// Edit operation in single section.
///
/// - delete: item is deleted at index
/// - insert: item is inserted at index
/// - move: item is moved `from` index `to` index.
/// - update: item is updated at index.
public enum SingleSectionOperation {
    case delete(Int)
    case insert(Int)
    case move(from: Int, to: Int)
    case update(Int)
}

/// Algorithm that requires elements in collection to be `Hashable`
public protocol HashableDiffingAlgorithm {
    func diff<T: EntityIdentifiable & Hashable>(from: [T], to: [T]) -> [SingleSectionOperation]
}

/// Algorithm that requires elements in collection to be `Equatable`
public protocol EquatableDiffingAlgorithm {
    func diff<T: EntityIdentifiable & Equatable>(from: [T], to: [T]) -> [SingleSectionOperation]
}
