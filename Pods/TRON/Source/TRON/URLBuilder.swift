//
//  RequestBuilder.swift
//  TRON
//
//  Created by Denys Telezhkin on 11.12.15.
//  Copyright © 2015 - present MLSDev. All rights reserved.
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

/**
 `URLBuilder` constructs resulting URL by calling `URLByAppendingPathComponent` method on baseURL.
 */
open class URLBuilder {

    /// Different behaviors to build URLs from base URL string and path.
    ///
    /// - appendingPathComponent: Construct URL by calling .appendingPathComponent method on URL formed from baseURL string.
    /// - relativeToBaseURL: Construct URL, using `URL(string:relativeTo:)` method
    /// - custom->URL: Construct URL using custom closure that was passed.
    public enum Behavior {
        case appendingPathComponent
        case relativeToBaseURL
        case custom((_ baseURL: String, _ path: String) -> URL)
    }

    /// Base URL string
    public let baseURLString: String

    /// Behavior to build URL
    public let behavior: Behavior

    /**
     Initialize URL builder with Base URL String
     
     - parameter baseURL: base URL string
     */
    public init(baseURL: String, behavior: Behavior = .appendingPathComponent) {
        self.baseURLString = baseURL
        self.behavior = behavior
    }

    /**
     Construct URL with given path
     
     - parameter path: relative path
     
     - returns constructed URL
     */
    open func url(forPath path: String) -> URL {
        let url: URL?
        switch behavior {
        case .appendingPathComponent: url = URL(string: baseURLString)?.appendingPathComponent(path)
        case .relativeToBaseURL: url = URL(string: path, relativeTo: URL(string: baseURLString))
        case .custom(let closure): url = closure(baseURLString, path)
        }
        return url ?? NSURL() as URL
    }
}
