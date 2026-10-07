//
//  XMLIndexer.swift
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

/// Returned from XMLHash, allows easy element lookup into XML data.
public enum XMLIndexer {
    case element(XMLElement)
    case list([XMLElement])
    case stream(IndexOps)
    case xmlError(IndexingError)
    case parsingError(ParsingError)

// swiftlint:disable identifier_name
    // unavailable
    @available(*, unavailable, renamed: "element(_:)")
    public static func Element(_: XMLElement) -> XMLIndexer {
        fatalError("unavailable")
    }
    @available(*, unavailable, renamed: "list(_:)")
    public static func List(_: [XMLElement]) -> XMLIndexer {
        fatalError("unavailable")
    }
    @available(*, unavailable, renamed: "stream(_:)")
    public static func Stream(_: IndexOps) -> XMLIndexer {
        fatalError("unavailable")
    }
    @available(*, unavailable, renamed: "xmlError(_:)")
    public static func XMLError(_: IndexingError) -> XMLIndexer {
        fatalError("unavailable")
    }
    @available(*, unavailable, renamed: "withAttribute(_:_:)")
    public static func withAttr(_ attr: String, _ value: String) throws -> XMLIndexer {
        fatalError("unavailable")
    }
// swiftlint:enable identifier_name

    /// The underlying XMLElement at the currently indexed level of XML.
    public var element: XMLElement? {
        switch self {
        case .element(let elem):
            return elem
        case .stream(let ops):
            let list = ops.findElements()
            return list.element
        default:
            return nil
        }
    }

    /// All elements at the currently indexed level
    public var all: [XMLIndexer] {
        allElements.map { XMLIndexer($0) }
    }

    private var allElements: [XMLElement] {
        switch self {
        case .list(let list):
            return list
        case .element(let elem):
            return [elem]
        case .stream(let ops):
            let list = ops.findElements()
            return list.allElements
        default:
            return []
        }
    }

    /// All child elements from the currently indexed level
    public var children: [XMLIndexer] {
        childElements.map { XMLIndexer($0) }
    }

    private var childElements: [XMLElement] {
        var list = [XMLElement]()
        for elem in all.compactMap({ $0.element }) {
            for elem in elem.xmlChildren {
                list.append(elem)
            }
        }
        return list
    }

    @available(*, unavailable, renamed: "filterChildren(_:)")
    public func filter(_ included: (_ elem: XMLElement, _ index: Int) -> Bool) -> XMLIndexer {
        filterChildren(included)
    }

    public func filterChildren(_ included: (_ elem: XMLElement, _ index: Int) -> Bool) -> XMLIndexer {
        let children = handleFilteredResults(list: childElements, included: included)
        if let current = element {
            let filteredElem = XMLElement(name: current.name, index: current.index, options: current.options)
            filteredElem.children = children.allElements
            return .element(filteredElem)
        }
        return .xmlError(IndexingError.error)
    }

    public func filterAll(_ included: (_ elem: XMLElement, _ index: Int) -> Bool) -> XMLIndexer {
        handleFilteredResults(list: allElements, included: included)
    }

    private func handleFilteredResults(list: [XMLElement],
                                       included: (_ elem: XMLElement, _ index: Int) -> Bool) -> XMLIndexer {
        let results = zip(list.indices, list).filter { included($1, $0) }.map { $1 }
        if results.count == 1 {
            return .element(results.first!)
        }
        return .list(results)
    }

    public var userInfo: [CodingUserInfoKey: Any] {
        switch self {
        case .element(let elem):
            return elem.userInfo
        default:
            return [:]
        }
    }

    /**
    Allows for element lookup by matching attribute values.

    - parameters:
        - attr: should the name of the attribute to match on
        - value: should be the value of the attribute to match on
    - throws: an XMLIndexer.XMLError if an element with the specified attribute isn't found
    - returns: instance of XMLIndexer
    */
    public func withAttribute(_ attr: String, _ value: String) throws -> XMLIndexer {
        switch self {
        case .stream(let opStream):
            let match = opStream.findElements()
            return try match.withAttribute(attr, value)
        case .list(let list):
            if let elem = list.first(where: {
                value.compare($0.attribute(by: attr)?.text, $0.caseInsensitive)
            }) {
                return .element(elem)
            }
            throw IndexingError.attributeValue(attr: attr, value: value)
        case .element(let elem):
            if value.compare(elem.attribute(by: attr)?.text, elem.caseInsensitive) {
                return .element(elem)
            }
            throw IndexingError.attributeValue(attr: attr, value: value)
        default:
            throw IndexingError.attribute(attr: attr)
        }
    }

    /**
    Initializes the XMLIndexer

    - parameter _: should be an instance of XMLElement, but supports other values for error handling
    - throws: an Error if the object passed in isn't an XMLElement or LazyXMLParser
    */
    public init(_ rawObject: AnyObject) throws {
        switch rawObject {
        case let value as XMLElement:
            self = .element(value)
        case let value as LazyXMLParser:
            self = .stream(IndexOps(parser: value))
        default:
            throw IndexingError.initialize(instance: rawObject)
        }
    }

    /**
    Initializes the XMLIndexer

    - parameter _: an instance of XMLElement
    */
    public init(_ elem: XMLElement) {
        self = .element(elem)
    }

    init(_ stream: LazyXMLParser) {
        self = .stream(IndexOps(parser: stream))
    }

    /**
    Find an XML element at the current level by element name

    - parameter key: The element name to index by
    - returns: instance of XMLIndexer to match the element (or elements) found by key
    - throws: Throws an XMLIndexingError.Key if no element was found
    */
    public func byKey(_ key: String) throws -> XMLIndexer {
        switch self {
        case .stream(let opStream):
            let oper = IndexOp(key)
            opStream.ops.append(oper)
            return .stream(opStream)
        case .element(let elem):
            let match = elem.xmlChildren.filter({
                $0.name.compare(key, $0.caseInsensitive)
            })
            if !match.isEmpty {
                if match.count == 1 {
                    return .element(match[0])
                } else {
                    return .list(match)
                }
            }
            throw IndexingError.key(key: key)
        default:
            throw IndexingError.key(key: key)
        }
    }

    /**
    Find an XML element at the current level by element name

    - parameter key: The element name to index by
    - returns: instance of XMLIndexer to match the element (or elements) found by
    */
    public subscript(key: String) -> XMLIndexer {
        do {
            return try byKey(key)
        } catch let error as IndexingError {
            return .xmlError(error)
        } catch {
            return .xmlError(IndexingError.key(key: key))
        }
    }

    /**
    Find an XML element by index within a list of XML Elements at the current level

    - parameter index: The 0-based index to index by
    - throws: XMLIndexer.XMLError if the index isn't found
    - returns: instance of XMLIndexer to match the element (or elements) found by index
    */
    public func byIndex(_ index: Int) throws -> XMLIndexer {
        switch self {
        case .stream(let opStream):
            opStream.ops[opStream.ops.count - 1].index = index
            return .stream(opStream)
        case .list(let list):
            if index < list.count {
                return .element(list[index])
            }
            return .xmlError(IndexingError.index(idx: index))
        case .element(let elem):
            if index == 0 {
                return .element(elem)
            }
            return .xmlError(IndexingError.index(idx: index))
        default:
            return .xmlError(IndexingError.index(idx: index))
        }
    }

    /**
    Find an XML element by index

    - parameter index: The 0-based index to index by
    - returns: instance of XMLIndexer to match the element (or elements) found by index
    */
    public subscript(index: Int) -> XMLIndexer {
        do {
            return try byIndex(index)
        } catch let error as IndexingError {
            return .xmlError(error)
        } catch {
            return .xmlError(IndexingError.index(idx: index))
        }
    }
}

/// XMLIndexer extensions

extension XMLIndexer: CustomStringConvertible {
    /// The XML representation of the XMLIndexer at the current level
    public var description: String {
        switch self {
        case .list(let list):
            return list.reduce("", { $0 + $1.description })
        case .element(let elem):
            if elem.name == rootElementName {
                return elem.children.reduce("", { $0 + $1.description })
            }

            return elem.description
        default:
            return ""
        }
    }
}

/*: Provides XMLIndexer Serialization/Deserialization using String backed RawRepresentables
    Added by [PeeJWeeJ](https://github.com/PeeJWeeJ) */
extension XMLIndexer {
    /**
     Allows for element lookup by matching attribute values
     using a String backed RawRepresentables (E.g. `String` backed `enum` cases)

     - Note:
     Convenience for withAttribute(String, String)

     - parameters:
     - attr: should the name of the attribute to match on
     - value: should be the value of the attribute to match on
     - throws: an XMLIndexer.XMLError if an element with the specified attribute isn't found
     - returns: instance of XMLIndexer
     */
    public func withAttribute<A: RawRepresentable, V: RawRepresentable>(_ attr: A, _ value: V) throws -> XMLIndexer
            where A.RawValue == String, V.RawValue == String {
        try withAttribute(attr.rawValue, value.rawValue)
    }

    /**
     Find an XML element at the current level by element name
     using a String backed RawRepresentable (E.g. `String` backed `enum` cases)

     - Note:
     Convenience for byKey(String)

     - parameter key: The element name to index by
     - returns: instance of XMLIndexer to match the element (or elements) found by key
     - throws: Throws an XMLIndexingError.Key if no element was found
     */
    public func byKey<K: RawRepresentable>(_ key: K) throws -> XMLIndexer where K.RawValue == String {
        try byKey(key.rawValue)
    }

    /**
     Find an XML element at the current level by element name
     using a String backed RawRepresentable (E.g. `String` backed `enum` cases)

     - Note:
     Convenience for self[String]

     - parameter key: The element name to index by
     - returns: instance of XMLIndexer to match the element (or elements) found by
     */
    public subscript<K: RawRepresentable>(key: K) -> XMLIndexer where K.RawValue == String {
        self[key.rawValue]
    }
}
