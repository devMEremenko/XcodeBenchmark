//
//  IndexOp.swift
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

/// Represents an indexed operation against a lazily parsed `XMLIndexer`
public class IndexOp {
    var index: Int
    let key: String

    init(_ key: String) {
        self.key = key
        index = -1
    }

    func toString() -> String {
        if index >= 0 {
            return key + " " + index.description
        }

        return key
    }
}

/// Represents a collection of `IndexOp` instances. Provides a means of iterating them
/// to find a match in a lazily parsed `XMLIndexer` instance.
public class IndexOps {
    var ops: [IndexOp] = []

    let parser: LazyXMLParser

    init(parser: LazyXMLParser) {
        self.parser = parser
    }

    func findElements() -> XMLIndexer {
        parser.startParsing(ops)
        let indexer = XMLIndexer(parser.root)
        var childIndex = indexer
        for oper in ops {
            childIndex = childIndex[oper.key]
            if oper.index >= 0 {
                childIndex = childIndex[oper.index]
            }
        }
        ops.removeAll(keepingCapacity: false)
        return childIndex
    }

    func stringify() -> String {
        var ret = ""
        for oper in ops {
            ret += "[" + oper.toString() + "]"
        }
        return ret
    }
}
