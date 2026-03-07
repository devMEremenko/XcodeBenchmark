//
//  IndexingError.swift
//  SWXMLHash
//
//  Copyright (c) 2022 David Mohundro
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

/// Error type that is thrown when an indexing or parsing operation fails.
public enum IndexingError: Error {
    case attribute(attr: String)
    case attributeValue(attr: String, value: String)
    case key(key: String)
    case index(idx: Int)
    case initialize(instance: AnyObject)
    case encoding
    case error

// swiftlint:disable identifier_name
    // unavailable
    @available(*, unavailable, renamed: "attribute(attr:)")
    public static func Attribute(attr: String) -> IndexingError {
        fatalError("unavailable")
    }

    @available(*, unavailable, renamed: "attributeValue(attr:value:)")
    public static func AttributeValue(attr: String, value: String) -> IndexingError {
        fatalError("unavailable")
    }

    @available(*, unavailable, renamed: "key(key:)")
    public static func Key(key: String) -> IndexingError {
        fatalError("unavailable")
    }

    @available(*, unavailable, renamed: "index(idx:)")
    public static func Index(idx: Int) -> IndexingError {
        fatalError("unavailable")
    }

    @available(*, unavailable, renamed: "initialize(instance:)")
    public static func Init(instance: AnyObject) -> IndexingError {
        fatalError("unavailable")
    }

    @available(*, unavailable, renamed: "error")
    public static var Error: IndexingError {
        fatalError("unavailable")
    }
// swiftlint:enable identifier_name
}

extension IndexingError: CustomStringConvertible {
    /// The description for the `IndexingError`.
    public var description: String {
        switch self {
        case .attribute(let attr):
            return "XML Attribute Error: Missing attribute [\"\(attr)\"]"
        case let .attributeValue(attr, value):
            return "XML Attribute Error: Missing attribute [\"\(attr)\"] with value [\"\(value)\"]"
        case .key(let key):
            return "XML Element Error: Incorrect key [\"\(key)\"]"
        case .index(let index):
            return "XML Element Error: Incorrect index [\"\(index)\"]"
        case .initialize(let instance):
            return "XML Indexer Error: initialization with Object [\"\(instance)\"]"
        case .encoding:
            return "String Encoding Error"
        case .error:
            return "Unknown Error"
        }
    }
}

extension IndexingError: LocalizedError {
    /// The description for the `IndexingError`.
    public var errorDescription: String? {
        switch self {
        case .attribute(let attr):
            return "XML Attribute Error: Missing attribute [\"\(attr)\"]"
        case let .attributeValue(attr, value):
            return "XML Attribute Error: Missing attribute [\"\(attr)\"] with value [\"\(value)\"]"
        case .key(let key):
            return "XML Element Error: Incorrect key [\"\(key)\"]"
        case .index(let index):
            return "XML Element Error: Incorrect index [\"\(index)\"]"
        case .initialize(let instance):
            return "XML Indexer Error: initialization with Object [\"\(instance)\"]"
        case .encoding:
            return "String Encoding Error"
        case .error:
            return "Unknown Error"
        }
    }
}
