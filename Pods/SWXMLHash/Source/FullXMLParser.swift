//
//  FullXMLParser.swift
//  SWXMLHash
//
//  Copyright (c) 2014 David Mohundro
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

/// The implementation of XMLParserDelegate and where the parsing actually happens.
class FullXMLParser: NSObject, SimpleXmlParser, XMLParserDelegate {
    required init(_ options: XMLHashOptions) {
        root = XMLElement(name: rootElementName, options: options)
        self.options = options
        super.init()
    }

    let root: XMLElement
    var parentStack = Stack<XMLElement>()
    let options: XMLHashOptions
    var parsingError: ParsingError?

    func parse(_ data: Data) -> XMLIndexer {
        // clear any prior runs of parse... expected that this won't be necessary,
        // but you never know
        parentStack.removeAll()

        parentStack.push(root)

        let parser = XMLParser(data: data)
        parser.shouldProcessNamespaces = options.shouldProcessNamespaces
        parser.delegate = self
        _ = parser.parse()

        if options.detectParsingErrors, let err = parsingError {
            return XMLIndexer.parsingError(err)
        } else {
            return XMLIndexer(root)
        }
    }

    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String: String]) {
        let currentNode = parentStack
                .top()
                .addElement(elementName, withAttributes: attributeDict, caseInsensitive: options.caseInsensitive)

        parentStack.push(currentNode)
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let current = parentStack.top()

        current.addText(string)
    }

    func parser(_ parser: XMLParser,
                didEndElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?) {
        parentStack.drop()
    }

    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        if let cdataText = String(data: CDATABlock, encoding: String.Encoding.utf8) {
            let current = parentStack.top()

            current.addText(cdataText)
        }
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        #if os(Linux) && !swift(>=4.1.50)
        if let err = parseError as? NSError {
            parsingError = ParsingError(
                    line: err.userInfo["NSXMLParserErrorLineNumber"] as? Int ?? 0,
                    column: err.userInfo["NSXMLParserErrorColumn"] as? Int ?? 0)
        }
        #else
        let err = parseError as NSError
        parsingError = ParsingError(
                line: err.userInfo["NSXMLParserErrorLineNumber"] as? Int ?? 0,
                column: err.userInfo["NSXMLParserErrorColumn"] as? Int ?? 0)
        #endif
    }
}
