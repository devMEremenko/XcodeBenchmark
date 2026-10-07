//
//  XMLElement.swift
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

/// Models an XML element, including name, text and attributes
public class XMLElement: XMLContent {
    /// The name of the element
    public let name: String

    /// Whether the element is case insensitive or not
    public var caseInsensitive: Bool {
        options.caseInsensitive
    }

    var userInfo: [CodingUserInfoKey: Any] {
        options.userInfo
    }

    /// All attributes
    public var allAttributes = [String: XMLAttribute]()

    /// Find an attribute by name
    public func attribute(by name: String) -> XMLAttribute? {
        if caseInsensitive {
            return allAttributes.first(where: { $0.key.compare(name, true) })?.value
        }
        return allAttributes[name]
    }

    /// The inner text of the element, if it exists
    public var text: String {
        children.reduce("", {
            if let element = $1 as? TextElement {
                return $0 + element.text
            }

            return $0
        })
    }

    /// The inner text of the element and its children
    public var recursiveText: String {
        children.reduce("", {
            if let textElement = $1 as? TextElement {
                return $0 + textElement.text
            } else if let xmlElement = $1 as? XMLElement {
                return $0 + xmlElement.recursiveText
            } else {
                return $0
            }
        })
    }

    public var innerXML: String {
        children.reduce("", {
            $0.description + $1.description
        })
    }

    /// All child elements (text or XML)
    public var children = [XMLContent]()

    var count: Int = 0
    var index: Int
    let options: XMLHashOptions

    var xmlChildren: [XMLElement] {
        children.compactMap { $0 as? XMLElement }
    }

    /**
    Initialize an XMLElement instance

    - parameters:
        - name: The name of the element to be initialized
        - index: The index of the element to be initialized
        - options: The XMLHash options
    */
    init(name: String, index: Int = 0, options: XMLHashOptions) {
        self.name = name
        self.index = index
        self.options = options
    }

    /**
    Adds a new XMLElement underneath this instance of XMLElement

    - parameters:
        - name: The name of the new element to be added
        - withAttributes: The attributes dictionary for the element being added
    - returns: The XMLElement that has now been added
    */

    func addElement(_ name: String, withAttributes attributes: [String: String], caseInsensitive: Bool) -> XMLElement {
        let element = XMLElement(name: name, index: count, options: options)
        count += 1

        children.append(element)

        for (key, value) in attributes {
            element.allAttributes[key] = XMLAttribute(name: key, text: value)
        }

        return element
    }

    func addText(_ text: String) {
        let elem = TextElement(text: text)

        children.append(elem)
    }
}

extension XMLElement: CustomStringConvertible {
    /// The tag, attributes and content for a `XMLElement` instance (<elem id="foo">content</elem>)
    public var description: String {
        let attributesString = allAttributes.reduce("", { $0 + " " + $1.1.description })

        if !children.isEmpty {
            var xmlReturn = [String]()
            xmlReturn.append("<\(name)\(attributesString)>")
            for child in children {
                xmlReturn.append(child.description)
            }
            xmlReturn.append("</\(name)>")
            return xmlReturn.joined()
        }

        return "<\(name)\(attributesString)>\(text)</\(name)>"
    }
}

/*: Provides XMLIndexer Serialization/Deserialization using String backed RawRepresentables
 Added by [PeeJWeeJ](https://github.com/PeeJWeeJ) */
extension XMLElement {
    /**
     Find an attribute by name using a String backed RawRepresentable (E.g. `String` backed `enum` cases)

     - Note:
     Convenience for self[String]
     */
    public func attribute<N: RawRepresentable>(by name: N) -> XMLAttribute? where N.RawValue == String {
        attribute(by: name.rawValue)
    }
}

// Workaround for "'XMLElement' is ambiguous for type lookup in this context" error on macOS.
//
// On macOS, `XMLElement` is defined in Foundation.
// So, the code referencing `XMLElement` generates above error.
// Following code allow to using `SWXMLHash.XMLElement` in client codes.
extension XMLHash {
    public typealias XMLElement = XMLHashXMLElement
}

public typealias XMLHashXMLElement = XMLElement
