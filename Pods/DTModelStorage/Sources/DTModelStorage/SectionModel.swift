//
//  SectionModel.swift
//  DTModelStorage
//
//  Created by Denys Telezhkin on 10.07.15.
//  Copyright (c) 2015 Denys Telezhkin. All rights reserved.
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

/// Data holder for single section in `MemoryStorage`.
open class SectionModel: Section, SectionLocatable
{
    /// Returns item at index, if it exists, nil otherwise.
    /// - Parameter index: Index to search for.
    open func item(at index: Int) -> Any? {
        guard items.count > index else { return nil }
        return items[index]
    }
    
    /// Returns whether section contains no elements.
    public var isEmpty: Bool {
        items.isEmpty
    }
    
    /// Items for current section
    open var items = [Any]()
    
    /// delegate, that knows about current section index in storage.
    open weak var sectionLocationDelegate: SectionLocationIdentifyable?
    
    /// section index of current section in `MemoryStorage`.
    open var currentSectionIndex: Int? {
        return sectionLocationDelegate?.sectionIndex(for: self)
    }
    
    /// Creates section model.
    public init(items: [Any] = []) {
        self.items = items
    }
    
    @available(*, deprecated, message: "Please assign items using .items property directly.")
    /// Set items of specific time to items property.
    /// - Note: Historically, Swift was unable to cast [T] to [Any]. This method allowed to set items, using simple map underneath. In current Swift releases, you can directly set items using `section.items = newValue` syntax.
    open func setItems<T>(_ items: [T])
    {
        self.items = items.map { $0 }
    }

    /// Returns items of `type` in current section
    open func items<T>(ofType type: T.Type) -> [T]
    {
        return items.compactMap { $0 as? T }
    }
    
    /// Number of items in current section
    open var numberOfItems: Int {
        return items.count
    }
}
