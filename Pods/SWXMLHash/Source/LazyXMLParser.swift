//
//  LazyXMLParser.swift
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

#if os(Linux) || os(Windows)
import FoundationXML
#endif

/// The implementation of XMLParserDelegate and where the lazy parsing actually happens.
class LazyXMLParser: NSObject, SimpleXmlParser, XMLParserDelegate {
    required init(_ options: XMLHashOptions) {
        root = XMLElement(name: rootElementName, options: options)
        self.options = options
        super.init()
    }

    var root: XMLElement
    var parentStack = Stack<XMLElement>()
    var elementStack = Stack<String>()

    var data: Data?
    var ops: [IndexOp] = []
    let options: XMLHashOptions

    func parse(_ data: Data) -> XMLIndexer {
        self.data = data
        return XMLIndexer(self)
    }

    func startParsing(_ ops: [IndexOp]) {
        // reset state for a new lazy parsing run
        root = XMLElement(name: rootElementName, options: root.options)
        parentStack.removeAll()
        parentStack.push(root)

        self.ops = ops
        let parser = XMLParser(data: data!)
        parser.shouldProcessNamespaces = options.shouldProcessNamespaces
        parser.delegate = self
        _ = parser.parse()
    }

    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String: String]) {
        elementStack.push(elementName)

        if !onMatch() {
            return
        }

        let currentNode = parentStack
                .top()
                .addElement(elementName, withAttributes: attributeDict, caseInsensitive: options.caseInsensitive)
        parentStack.push(currentNode)
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if !onMatch() {
            return
        }

        let current = parentStack.top()

        current.addText(string)
    }

    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        if !onMatch() {
            return
        }

        if let cdataText = String(data: CDATABlock, encoding: String.Encoding.utf8) {
            let current = parentStack.top()

            current.addText(cdataText)
        }
    }

    func parser(_ parser: XMLParser,
                didEndElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?) {
        let match = onMatch()

        elementStack.drop()

        if match {
            parentStack.drop()
        }
    }

    func onMatch() -> Bool {
        // we typically want to compare against the elementStack to see if it matches ops, *but*
        // if we're on the first element, we'll instead compare the other direction.
        if elementStack.items.count > ops.count {
            return elementStack.items.starts(with: ops.map { $0.key })
        } else {
            return ops.map { $0.key }.starts(with: elementStack.items)
        }
    }
}
