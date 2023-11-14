//
//  XMLIndexer+XMLObjectDeserialization.swift
//  SWXMLHash
//
//  Copyright (c) 2016 Maciek Grzybowskio
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

// swiftlint:disable line_length
// swiftlint:disable file_length

import Foundation

public extension XMLIndexer {
    /**
     Attempts to deserialize the value of the specified attribute of the current XMLIndexer
     element to `T`

     - parameter attr: The attribute to deserialize
     - throws: an XMLDeserializationError if there is a problem with deserialization
     - returns: The deserialized `T` value
     */
    func value<T: XMLAttributeDeserializable>(ofAttribute attr: String) throws -> T {
        switch self {
        case .element(let element):
            return try element.value(ofAttribute: attr)
        case .stream(let opStream):
            return try opStream.findElements().value(ofAttribute: attr)
        case .xmlError(let indexingError):
            throw XMLDeserializationError.nodeIsInvalid(node: indexingError.description)
        default:
            throw XMLDeserializationError.nodeIsInvalid(node: "Unexpected error deserializing XMLAttribute \(attr) -> T")
        }
    }

    /**
     Attempts to deserialize the value of the specified attribute of the current XMLIndexer
     element to `T?`

     - parameter attr: The attribute to deserialize
     - returns: The deserialized `T?` value, or nil if the attribute does not exist
     */
    func value<T: XMLAttributeDeserializable>(ofAttribute attr: String) -> T? {
        switch self {
        case .element(let element):
            return element.value(ofAttribute: attr)
        case .stream(let opStream):
            return opStream.findElements().value(ofAttribute: attr)
        default:
            return nil
        }
    }

    /**
     Attempts to deserialize the value of the specified attribute of the current XMLIndexer
     element to `[T]`

     - parameter attr: The attribute to deserialize
     - throws: an XMLDeserializationError if there is a problem with deserialization
     - returns: The deserialized `[T]` value
     */
    func value<T: XMLAttributeDeserializable>(ofAttribute attr: String) throws -> [T] {
        switch self {
        case .list(let elements):
            return try elements.map {
                try $0.value(ofAttribute: attr)
            }
        case .element(let element):
            return try [element].map {
                try $0.value(ofAttribute: attr)
            }
        case .stream(let opStream):
            return try opStream.findElements().value(ofAttribute: attr)
        case .xmlError(let indexingError):
            throw XMLDeserializationError.nodeIsInvalid(node: indexingError.description)
        default:
            throw XMLDeserializationError.nodeIsInvalid(node: "Unexpected error deserializing XMLAttribute \(attr) -> [T]")
        }
    }

    /**
     Attempts to deserialize the value of the specified attribute of the current XMLIndexer
     element to `[T]?`

     - parameter attr: The attribute to deserialize
     - throws: an XMLDeserializationError if there is a problem with deserialization
     - returns: The deserialized `[T]?` value
     */
    func value<T: XMLAttributeDeserializable>(ofAttribute attr: String) throws -> [T]? {
        switch self {
        case .list(let elements):
            return try elements.map {
                try $0.value(ofAttribute: attr)
            }
        case .element(let element):
            return try [element].map {
                try $0.value(ofAttribute: attr)
            }
        case .stream(let opStream):
            return try opStream.findElements().value(ofAttribute: attr)
        default:
            return nil
        }
    }

    /**
     Attempts to deserialize the value of the specified attribute of the current XMLIndexer
     element to `[T?]`

     - parameter attr: The attribute to deserialize
     - throws: an XMLDeserializationError if there is a problem with deserialization
     - returns: The deserialized `[T?]` value
     */
    func value<T: XMLAttributeDeserializable>(ofAttribute attr: String) throws -> [T?] {
        switch self {
        case .list(let elements):
            return elements.map {
                $0.value(ofAttribute: attr)
            }
        case .element(let element):
            return [element].map {
                $0.value(ofAttribute: attr)
            }
        case .stream(let opStream):
            return try opStream.findElements().value(ofAttribute: attr)
        case .xmlError(let indexingError):
            throw XMLDeserializationError.nodeIsInvalid(node: indexingError.description)
        default:
            throw XMLDeserializationError.nodeIsInvalid(node: "Unexpected error deserializing XMLAttribute \(attr) -> [T?]")
        }
    }

    /**
    Attempts to deserialize the current XMLElement element to `T`

    - throws: an XMLDeserializationError.nodeIsInvalid if the current indexed level isn't an Element
    - returns: the deserialized `T` value
    */
    func value<T: XMLElementDeserializable>() throws -> T {
        switch self {
        case .element(let element):
            let deserialized = try T.deserialize(element)
            try deserialized.validate()
            return deserialized
        case .stream(let opStream):
            return try opStream.findElements().value()
        case .xmlError(let indexingError):
            throw XMLDeserializationError.nodeIsInvalid(node: indexingError.description)
        default:
            throw XMLDeserializationError.nodeIsInvalid(node: "Unexpected error deserializing XMLElement -> T")
        }
    }

    /**
    Attempts to deserialize the current XMLElement element to `T?`

    - returns: the deserialized `T?` value
    - throws: an XMLDeserializationError is there is a problem with deserialization
    */
    func value<T: XMLElementDeserializable>() throws -> T? {
        switch self {
        case .element(let element):
            let deserialized = try T.deserialize(element)
            try deserialized.validate()
            return deserialized
        case .stream(let opStream):
            return try opStream.findElements().value()
        default:
            return nil
        }
    }

    /**
    Attempts to deserialize the current XMLElement element to `[T]`

    - returns: the deserialized `[T]` value
    - throws: an XMLDeserializationError is there is a problem with deserialization
    */
    func value<T: XMLElementDeserializable>() throws -> [T] {
        switch self {
        case .list(let elements):
            return try elements.map {
                let deserialized = try T.deserialize($0)
                try deserialized.validate()
                return deserialized
            }
        case .element(let element):
            return try [element].map {
                let deserialized = try T.deserialize($0)
                try deserialized.validate()
                return deserialized
            }
        case .stream(let opStream):
            return try opStream.findElements().value()
        default:
            return []
        }
    }

    /**
    Attempts to deserialize the current XMLElement element to `[T]?`

    - returns: the deserialized `[T]?` value
    - throws: an XMLDeserializationError is there is a problem with deserialization
    */
    func value<T: XMLElementDeserializable>() throws -> [T]? {
        switch self {
        case .list(let elements):
            return try elements.map {
                let deserialized = try T.deserialize($0)
                try deserialized.validate()
                return deserialized
            }
        case .element(let element):
            return try [element].map {
                let deserialized = try T.deserialize($0)
                try deserialized.validate()
                return deserialized
            }
        case .stream(let opStream):
            return try opStream.findElements().value()
        default:
            return nil
        }
    }

    /**
    Attempts to deserialize the current XMLElement element to `[T?]`

    - returns: the deserialized `[T?]` value
    - throws: an XMLDeserializationError is there is a problem with deserialization
    */
    func value<T: XMLElementDeserializable>() throws -> [T?] {
        switch self {
        case .list(let elements):
            return try elements.map {
                let deserialized = try T.deserialize($0)
                try deserialized.validate()
                return deserialized
            }
        case .element(let element):
            return try [element].map {
                let deserialized = try T.deserialize($0)
                try deserialized.validate()
                return deserialized
            }
        case .stream(let opStream):
            return try opStream.findElements().value()
        default:
            return []
        }
    }

    /**
    Attempts to deserialize the current XMLIndexer element to `T`

    - returns: the deserialized `T` value
    - throws: an XMLDeserializationError is there is a problem with deserialization
    */
    func value<T: XMLObjectDeserialization>() throws -> T {
        switch self {
        case .element:
            let deserialized = try T.deserialize(self)
            try deserialized.validate()
            return deserialized
        case .stream(let opStream):
            return try opStream.findElements().value()
        case .xmlError(let indexingError):
            throw XMLDeserializationError.nodeIsInvalid(node: indexingError.description)
        default:
            throw XMLDeserializationError.nodeIsInvalid(node: "Unexpected error deserializing XMLIndexer -> T")
        }
    }

    /**
    Attempts to deserialize the current XMLIndexer element to `T?`

    - returns: the deserialized `T?` value
    - throws: an XMLDeserializationError is there is a problem with deserialization
    */
    func value<T: XMLObjectDeserialization>() throws -> T? {
        switch self {
        case .element:
            let deserialized = try T.deserialize(self)
            try deserialized.validate()
            return deserialized
        case .stream(let opStream):
            return try opStream.findElements().value()
        default:
            return nil
        }
    }

    /**
    Attempts to deserialize the current XMLIndexer element to `[T]`

    - returns: the deserialized `[T]` value
    - throws: an XMLDeserializationError is there is a problem with deserialization
    */
    func value<T>() throws -> [T] where T: XMLObjectDeserialization {
        switch self {
        case .list(let elements):
            return try elements.map {
                let deserialized = try T.deserialize(XMLIndexer($0))
                try deserialized.validate()
                return deserialized
            }
        case .element(let element):
            return try [element].map {
                let deserialized = try T.deserialize(XMLIndexer($0))
                try deserialized.validate()
                return deserialized
            }
        case .stream(let opStream):
            return try opStream.findElements().value()
        case .xmlError(let indexingError):
            throw XMLDeserializationError.nodeIsInvalid(node: indexingError.description)
        default:
            throw XMLDeserializationError.nodeIsInvalid(node: "Unexpected error deserializing XMLIndexer -> [T]")
        }
    }

    /**
    Attempts to deserialize the current XMLIndexer element to `[T]?`

    - returns: the deserialized `[T]?` value
    - throws: an XMLDeserializationError is there is a problem with deserialization
    */
    func value<T: XMLObjectDeserialization>() throws -> [T]? {
        switch self {
        case .list(let elements):
            return try elements.map {
                let deserialized = try T.deserialize(XMLIndexer($0))
                try deserialized.validate()
                return deserialized
            }
        case .element(let element):
            return try [element].map {
                let deserialized = try T.deserialize(XMLIndexer($0))
                try deserialized.validate()
                return deserialized
            }
        case .stream(let opStream):
            return try opStream.findElements().value()
        default:
            return nil
        }
    }

    /**
    Attempts to deserialize the current XMLIndexer element to `[T?]`

    - returns: the deserialized `[T?]` value
    - throws: an XMLDeserializationError is there is a problem with deserialization
    */
    func value<T: XMLObjectDeserialization>() throws -> [T?] {
        switch self {
        case .list(let elements):
            return try elements.map {
                let deserialized = try T.deserialize(XMLIndexer($0))
                try deserialized.validate()
                return deserialized
            }
        case .element(let element):
            return try [element].map {
                let deserialized = try T.deserialize(XMLIndexer($0))
                try deserialized.validate()
                return deserialized
            }
        case .stream(let opStream):
            return try opStream.findElements().value()
        case .xmlError(let indexingError):
            throw XMLDeserializationError.nodeIsInvalid(node: indexingError.description)
        default:
            throw XMLDeserializationError.nodeIsInvalid(node: "Unexpected error deserializing XMLIndexer -> [T?]")
        }
    }
}

/*: Provides XMLIndexer XMLAttributeDeserializable deserialization from String backed RawRepresentables
    Added by [PeeJWeeJ](https://github.com/PeeJWeeJ) */
public extension XMLIndexer {
    /**
     Attempts to deserialize the value of the specified attribute of the current XMLIndexer
     element to `T` using a String backed RawRepresentable (E.g. `String` backed `enum` cases)

     - Note:
     Convenience for value(ofAttribute: String)

     - parameter attr: The attribute to deserialize
     - throws: an XMLDeserializationError if there is a problem with deserialization
     - returns: The deserialized `T` value
     */
    func value<T: XMLAttributeDeserializable, A: RawRepresentable>(ofAttribute attr: A) throws -> T where A.RawValue == String {
        try value(ofAttribute: attr.rawValue)
    }

    /**
     Attempts to deserialize the value of the specified attribute of the current XMLIndexer
     element to `T?` using a String backed RawRepresentable (E.g. `String` backed `enum` cases)

     - Note:
     Convenience for value(ofAttribute: String)

     - parameter attr: The attribute to deserialize
     - returns: The deserialized `T?` value, or nil if the attribute does not exist
     */
    func value<T: XMLAttributeDeserializable, A: RawRepresentable>(ofAttribute attr: A) -> T? where A.RawValue == String {
        value(ofAttribute: attr.rawValue)
    }

    /**
     Attempts to deserialize the value of the specified attribute of the current XMLIndexer
     element to `[T]` using a String backed RawRepresentable (E.g. `String` backed `enum` cases)

     - Note:
     Convenience for value(ofAttribute: String)

     - parameter attr: The attribute to deserialize
     - throws: an XMLDeserializationError if there is a problem with deserialization
     - returns: The deserialized `[T]` value
     */
    func value<T: XMLAttributeDeserializable, A: RawRepresentable>(ofAttribute attr: A) throws -> [T] where A.RawValue == String {
        try value(ofAttribute: attr.rawValue)
    }

    /**
     Attempts to deserialize the value of the specified attribute of the current XMLIndexer
     element to `[T]?` using a String backed RawRepresentable (E.g. `String` backed `enum` cases)

     - Note:
     Convenience for value(ofAttribute: String)

     - parameter attr: The attribute to deserialize
     - throws: an XMLDeserializationError if there is a problem with deserialization
     - returns: The deserialized `[T]?` value
     */
    func value<T: XMLAttributeDeserializable, A: RawRepresentable>(ofAttribute attr: A) throws -> [T]? where A.RawValue == String {
        try value(ofAttribute: attr.rawValue)
    }

    /**
     Attempts to deserialize the value of the specified attribute of the current XMLIndexer
     element to `[T?]` using a String backed RawRepresentable (E.g. `String` backed `enum` cases)

     - Note:
     Convenience for value(ofAttribute: String)

     - parameter attr: The attribute to deserialize
     - throws: an XMLDeserializationError if there is a problem with deserialization
     - returns: The deserialized `[T?]` value
     */
    func value<T: XMLAttributeDeserializable, A: RawRepresentable>(ofAttribute attr: A) throws -> [T?] where A.RawValue == String {
        try value(ofAttribute: attr.rawValue)
    }
}

extension XMLElement {
    /**
     Attempts to deserialize the specified attribute of the current XMLElement to `T`

     - parameter attr: The attribute to deserialize
     - throws: an XMLDeserializationError if there is a problem with deserialization
     - returns: The deserialized `T` value
     */
    public func value<T: XMLAttributeDeserializable>(ofAttribute attr: String) throws -> T {
        if let attr = attribute(by: attr) {
            let deserialized = try T.deserialize(attr)
            try deserialized.validate()
            return deserialized
        } else {
            throw XMLDeserializationError.attributeDoesNotExist(element: self, attribute: attr)
        }
    }

    /**
     Attempts to deserialize the specified attribute of the current XMLElement to `T?`

     - parameter attr: The attribute to deserialize
     - returns: The deserialized `T?` value, or nil if the attribute does not exist.
     */
    public func value<T: XMLAttributeDeserializable>(ofAttribute attr: String) -> T? {
        if let attr = attribute(by: attr) {
            let deserialized = try? T.deserialize(attr)
            if deserialized != nil {
                try? deserialized?.validate()
            }
            return deserialized
        } else {
            return nil
        }
    }

    /**
     Gets the text associated with this element, or throws an exception if the text is empty

     - throws: XMLDeserializationError.nodeHasNoValue if the element text is empty
     - returns: The element text
     */
    internal func nonEmptyTextOrThrow() throws -> String {
        let textVal = text
        if !textVal.isEmpty {
            return textVal
        }

        throw XMLDeserializationError.nodeHasNoValue
    }
}

/*: Provides XMLIndexer XMLAttributeDeserializable deserialization from String backed RawRepresentables
    Added by [PeeJWeeJ](https://github.com/PeeJWeeJ) */
public extension XMLElement {
    /**
     Attempts to deserialize the specified attribute of the current XMLElement to `T`
     using a String backed RawRepresentable (E.g. `String` backed `enum` cases)

     - Note:
     Convenience for value(ofAttribute: String)

     - parameter attr: The attribute to deserialize
     - throws: an XMLDeserializationError if there is a problem with deserialization
     - returns: The deserialized `T` value
     */
    func value<T: XMLAttributeDeserializable, A: RawRepresentable>(ofAttribute attr: A)  throws -> T where A.RawValue == String {
        try value(ofAttribute: attr.rawValue)
    }

    /**
     Attempts to deserialize the specified attribute of the current XMLElement to `T?`
     using a String backed RawRepresentable (E.g. `String` backed `enum` cases)

     - Note:
     Convenience for value(ofAttribute: String)

     - parameter attr: The attribute to deserialize
     - returns: The deserialized `T?` value, or nil if the attribute does not exist.
     */
    func value<T: XMLAttributeDeserializable, A: RawRepresentable>(ofAttribute attr: A) -> T? where A.RawValue == String {
        value(ofAttribute: attr.rawValue)
    }
}

// swiftlint:enable line_length
