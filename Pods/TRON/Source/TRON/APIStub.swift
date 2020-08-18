//
//  APIStub.swift
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
import Alamofire

// This protocol is only needed to work around bogus warning message when casting Alamofire.Request below.
// For example this line
//        if let stubbedRequest = self as? UploadRequest
// produces a warning "Cast from `Self` to unrelated type `UploadRequest` always fails".
// This is wrong as the cast actually succeeds at runtime, and the only reason why it exists
// apparently is returning Self from method, which somehow affects this warning.
protocol DataRequestResponseSerialization {}
extension DataRequest: DataRequestResponseSerialization {}

extension DataRequestResponseSerialization {
    func performResponseSerialization<Serializer>(queue: DispatchQueue,
                                                  responseSerializer: Serializer,
                                                  completionHandler: @escaping (DataResponse<Serializer.SerializedObject, AFError>) -> Void) -> Self
        where Serializer: DataResponseSerializerProtocol {
            if let stubbedRequest = self as? DataRequest, let stub = stubbedRequest.tron_apiStub, stub.isEnabled {
                let start = CFAbsoluteTimeGetCurrent()
                let result = Result {
                    try responseSerializer.serialize(request: stub.request, response: stub.response, data: stub.data, error: stub.error)
                }.mapError { error in
                    error as? AFError ?? AFError.responseSerializationFailed(reason: AFError.ResponseSerializationFailureReason.decodingFailed(error: error))
                }
                let end = CFAbsoluteTimeGetCurrent()
                let response = DataResponse(request: stub.request,
                                            response: stub.response,
                                            data: stub.data,
                                            metrics: nil,
                                            serializationDuration: (end - start),
                                            result: result)
                queue.asyncAfter(deadline: .now() + stub.stubDelay) {
                    completionHandler(response)
                }
                return self
            } else if let uploadRequest = self as? UploadRequest {
                //swiftlint:disable:next force_cast
                return uploadRequest.response(queue: queue, responseSerializer: responseSerializer, completionHandler: completionHandler) as! Self
            } else if let dataRequest = self as? DataRequest {
                //swiftlint:disable:next force_cast
                return dataRequest.response(queue: queue, responseSerializer: responseSerializer, completionHandler: completionHandler) as! Self
            } else {
                fatalError("\(type(of: self)) is not supported")
            }
    }
}

extension DownloadRequest {
    func performResponseSerialization<Serializer>(queue: DispatchQueue,
                                                  responseSerializer: Serializer,
                                                  completionHandler: @escaping (DownloadResponse<Serializer.SerializedObject, AFError>) -> Void) -> Self
        where Serializer: DownloadResponseSerializerProtocol {
        if let stub = tron_apiStub, stub.isEnabled {
            let start = CFAbsoluteTimeGetCurrent()
            let result = Result {
                try responseSerializer.serializeDownload(request: stub.request, response: stub.response, fileURL: stub.fileURL, error: stub.error)
            }.mapError { error in
                error as? AFError ?? AFError.responseSerializationFailed(reason: AFError.ResponseSerializationFailureReason.decodingFailed(error: error))
            }
            let end = CFAbsoluteTimeGetCurrent()
            let response = DownloadResponse(request: stub.request,
                                            response: stub.response,
                                            fileURL: stub.fileURL,
                                            resumeData: resumeData,
                                            metrics: nil,
                                            serializationDuration: (end - start),
                                            result: result)
            queue.asyncAfter(deadline: .now() + stub.stubDelay) {
                completionHandler(response)
            }
            return self
        } else {
            return response(queue: queue, responseSerializer: responseSerializer, completionHandler: completionHandler)
        }
    }
}

private var TRONAPIStubAssociatedKey = "TRON APIStub Associated Key"
extension Request {
    var tron_apiStub: APIStub? {
        get {
            return objc_getAssociatedObject(self, &TRONAPIStubAssociatedKey) as? APIStub
        }
        set {
            if let stub = newValue {
                objc_setAssociatedObject(self, &TRONAPIStubAssociatedKey, stub, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
}

/**
 `APIStub` instance that is used to represent stubbed response. Any properties of this class is presented to serialization classes as if they would be received by URL loading system.
 */
open class APIStub {

    /// `URLRequest` object to use when request is being stubbed.
    open var request: URLRequest?

    /// `HTTPURLResponse` to use when request is being stubbed.
    open var response: HTTPURLResponse?

    /// `Data` to use when request is being stubbed. This property is ignored for `DownloadAPIRequest`.
    open var data: Data?

    /// Error to use when request is being stubbed.
    open var error: Error?

    /// File URL to use when stubbing `DownloadAPIRequest`. This property is ignored for `APIRequest` and `UploadAPIRequest`.
    open var fileURL: URL?

    /// Delay before stub is executed
    open var stubDelay: TimeInterval = 0

    /// When this property is set to true, stub will be activated. Defaults to false.
    open var isEnabled: Bool = false

    /// Creates `APIStub` instance for `APIRequest` and `UploadAPIRequest`.
    ///
    /// - Parameters:
    ///   - request: `URLRequest` object ot use when request is being stubbed. Defaults to nil.
    ///   - response: `HTTPURLResponse` object to use when request is being stubbed. Defaults to nil.
    ///   - data: `Data` object to use when request is being stubbed. Defaults to nil.
    ///   - error: `Error` to use when request is being stubbed. Defaults to nil.
    public init(request: URLRequest? = nil,
                response: HTTPURLResponse? = nil,
                data: Data? = nil,
                error: Error? = nil) {
        self.request = request
        self.response = response
        self.data = data
        self.error = error
    }

    /// Creates `APIStub` instance for `DownloadAPIRequest`.
    ///
    /// - Parameters:
    ///   - request: `URLRequest` object ot use when request is being stubbed. Defaults to nil.
    ///   - response: `HTTPURLResponse` object to use when request is being stubbed. Defaults to nil.
    ///   - fileURL: File URL of downloaded file to use when request is being stubbed. Defaults to nil.
    ///   - error: `Error` to use when request is being stubbed. Defaults to nil.
    public init(request: URLRequest? = nil,
                response: HTTPURLResponse? = nil,
                fileURL: URL? = nil,
                error: Error? = nil) {
        self.request = request
        self.response = response
        self.fileURL = fileURL
        self.error = error
    }
}
