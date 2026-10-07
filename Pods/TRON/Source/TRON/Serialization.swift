//
//  Serialization.swift
//  TRON
//
//  Created by Denys Telezhkin on 12/21/18.
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
import Alamofire

/// Response serializer, that wraps serialization closure to implement `Alamofire.DataResponseSerializerProtocol`. Is used for `APIRequest` and `UploadAPIRequest`.
public struct TRONDataResponseSerializer<Model>: DataResponseSerializerProtocol {

    /// Serialization closure to execute
    public let closure: ((URLRequest?, HTTPURLResponse?, Data?, Error?) throws -> Model)

    /// Creates response serializer from passed serialization closure
    ///
    /// - Parameter closure: serialization closure
    public init(closure: @escaping (URLRequest?, _ response: HTTPURLResponse?, _ data: Data?, _ error: Error?) throws -> Model) {
        self.closure = closure
    }

    /// Serializes received response into model object
    ///
    /// - Parameters:
    ///   - request: `URLRequest` that was sent to receive response.
    ///   - response: HTTP response object that was received
    ///   - data: Data object that was received.
    ///   - error: Error, received by URL loading system or Alamofire.
    /// - Returns: serialized model object
    /// - Throws: serialization errors.
    public func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> Model {
        return try closure(request, response, data, error)
    }
}

/// Response serializer, that wraps serialization closure to implement `Alamofire.DownloadResponseSerializerProtocol`. Is used for `DownloadAPIRequest`.
public struct TRONDownloadResponseSerializer<Model>: DownloadResponseSerializerProtocol {

    /// Serialization closure to execute
    public let closure: ((URLRequest?, HTTPURLResponse?, URL?, Error?) throws -> Model)

    /// Creates response serializer from passed serialization closure
    ///
    /// - Parameter closure: serialization closure
    public init(closure: @escaping (URLRequest?, HTTPURLResponse?, URL?, Error?) throws -> Model) {
        self.closure = closure
    }

    /// Serializes received response into model object
    ///
    /// - Parameters:
    ///   - request: `URLRequest` that was sent to receive response.
    ///   - response: HTTP response object that was received
    ///   - fileURL: File URL where downloaded file was placed after successful download.
    ///   - error: Error, received by URL loading system or Alamofire.
    /// - Returns: serialized model object
    /// - Throws: serialization errors.
    public func serializeDownload(request: URLRequest?, response: HTTPURLResponse?, fileURL: URL?, error: Error?) throws -> Model {
        return try closure(request, response, fileURL, error)
    }
}

/// Response serializer, that returns file URL upon successful download. Is used for `DownloadAPIRequest`.
public struct FileURLPassthroughResponseSerializer: DownloadResponseSerializerProtocol {

    /// Error returned when received fileURL is nil
    public struct MissingURLError: Error { }

    /// Extracts file URL from received response
    ///
    /// - Parameters:
    ///   - request: `URLRequest` that was sent to receive response.
    ///   - response: HTTP response object that was received.
    ///   - fileURL: File URL where downloaded file was placed after successful download.
    ///   - error: Error, received by URL loading system or Alamofire.
    /// - Returns: File URL
    /// - Throws: serialization errors.
    public func serializeDownload(request: URLRequest?, response: HTTPURLResponse?, fileURL: URL?, error: Error?) throws -> URL {
        if let error = error {
            throw error
        }
        if let url = fileURL {
            return url
        }
        throw MissingURLError()
    }
}
