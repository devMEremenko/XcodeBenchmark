//
//  UploadAPIRequest.swift
//  TRON
//
//  Created by Denys Telezhkin on 11.09.16.
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

/// Types of `UploadAPIRequest`
public enum UploadRequestType {

    /// Will create `NSURLSessionUploadTask` using `uploadTaskWithRequest(_:fromFile:)` method
    case uploadFromFile(URL)

    /// Will create `NSURLSessionUploadTask` using `uploadTaskWithRequest(_:fromData:)` method
    case uploadData(Data)

    /// Will create `NSURLSessionUploadTask` using `uploadTaskWithStreamedRequest(_)` method
    case uploadStream(InputStream)

    // Depending on resulting size of the payload will either stream from disk or from memory
    case multipartFormData(formData: (MultipartFormData) -> Void,
                           memoryThreshold: UInt64,
                           fileManager: FileManager)
}

/**
 `UploadAPIRequest` encapsulates upload request creation logic, stubbing options, and response/error parsing.
 */
open class UploadAPIRequest<Model, ErrorModel: ErrorSerializable>: BaseRequest<Model, ErrorModel> {

    /// UploadAPIRequest type
    let type: UploadRequestType

    /// Serializes received response into Result<Model>
    open var responseParser: ResponseParser

    /// Serializes received error into APIError<ErrorModel>
    open var errorParser: ErrorParser

    /// Closure that is applied to request before it is sent.
    open var validationClosure: (UploadRequest) -> UploadRequest = { $0.validate() }

    /// Sets `validationClosure` to `validation` parameter and returns configured request
    ///
    /// - Parameter validation: validation to perform.
    /// - Returns: configured request.
    open func validation(_ validation: @escaping (UploadRequest) -> UploadRequest) -> Self {
        validationClosure = validation
        return self
    }

    /// Creates `UploadAPIRequest` with specified `type`, `path` and configures it with to be used with `tron`.
    public init<Serializer: DataResponseSerializerProtocol>(type: UploadRequestType, path: String, tron: TRON, responseSerializer: Serializer)
        where Serializer.SerializedObject == Model {
        self.type = type
        self.responseParser = { request, response, data, error in
            try responseSerializer.serialize(request: request, response: response, data: data, error: error)
        }
        self.errorParser = { request, response, data, error in
            ErrorModel(request: request, response: response, data: data, error: error)
        }
        super.init(path: path, tron: tron)
    }

    override func alamofireRequest(from session: Session) -> Request {
        switch type {
        case .uploadFromFile(let url):
            return session.upload(url, to: urlBuilder.url(forPath: path), method: method,
                                  headers: headers, interceptor: interceptor)

        case .uploadData(let data):
            return session.upload(data, to: urlBuilder.url(forPath: path), method: method,
                                  headers: headers, interceptor: interceptor)

        case .uploadStream(let stream):
            return session.upload(stream, to: urlBuilder.url(forPath: path), method: method,
                                  headers: headers, interceptor: interceptor)

        case .multipartFormData(let constructionBlock, let memoryThreshold, let fileManager):
            return session.upload(multipartFormData: appendParametersToMultipartFormDataBlock(constructionBlock),
                                  to: urlBuilder.url(forPath: path),
                                  usingThreshold: memoryThreshold,
                                  method: method,
                                  headers: headers,
                                  interceptor: interceptor,
                                  fileManager: fileManager)
        }
    }

    private func appendParametersToMultipartFormDataBlock(_ block: @escaping (MultipartFormData) -> Void) -> (MultipartFormData) -> Void {
        return { formData in
            self.parameters.forEach { key, value in
                formData.append(String(describing: value).data(using: .utf8) ?? Data(), withName: key)
            }
            block(formData)
        }
    }

    @discardableResult
    /**
     Send current request.
     
     - parameter successBlock: Success block to be executed when request finished
     
     - parameter failureBlock: Failure block to be executed if request fails. Nil by default.
     
     - returns: Alamofire.Request or nil if request was stubbed.
     */
    open func perform(withSuccess successBlock: ((Model) -> Void)? = nil, failure failureBlock: ((ErrorModel) -> Void)? = nil) -> UploadRequest {
        return performAlamofireRequest {
            self.callSuccessFailureBlocks(successBlock, failure: failureBlock, response: $0)
        }
    }

    @discardableResult
    /**
     Perform current request with completion block, that contains Alamofire.Response.
     
     - parameter completion: Alamofire.Response completion block.
     
     - returns: Alamofire.Request or nil if request was stubbed.
     */
    open func performCollectingTimeline(withCompletion completion: @escaping ((Alamofire.DataResponse<Model, AFError>) -> Void)) -> UploadRequest {
        return performAlamofireRequest(completion)
    }

    private func performAlamofireRequest(_ completion : @escaping (DataResponse<Model, AFError>) -> Void) -> UploadRequest {
        guard let session = tronDelegate?.session else {
            fatalError("Manager cannot be nil while performing APIRequest")
        }
        willSendRequest()
        guard let request = alamofireRequest(from: session) as? UploadRequest else {
            fatalError("Failed to receive UploadRequest")
        }
        if let stub = apiStub, stub.isEnabled {
            request.tron_apiStub = stub
        }
        willSendAlamofireRequest(request)
        let uploadRequest = validationClosure(request)
            .performResponseSerialization(queue: resultDeliveryQueue,
                                          responseSerializer: dataResponseSerializer(with: request),
                                          completionHandler: { dataResponse in
                                            self.didReceiveDataResponse(dataResponse, forRequest: request)
                                            completion(dataResponse)
            })
        if !session.startRequestsImmediately {
            request.resume()
        }
        didSendAlamofireRequest(request)
        return uploadRequest
    }

    internal func dataResponseSerializer(with request: Request) -> TRONDataResponseSerializer<Model> {
        return TRONDataResponseSerializer { urlRequest, response, data, error in
            self.willProcessResponse((urlRequest, response, data, error), for: request)
            let parsedModel: Model
            do {
                parsedModel = try self.responseParser(urlRequest, response, data, error)
            } catch let catchedError {
                let parsedError = self.errorParser(urlRequest, response, data, catchedError)
                self.didReceiveError(parsedError, for: (urlRequest, response, data, error), request: request)
                throw parsedError
            }
            self.didSuccessfullyParseResponse((urlRequest, response, data, error), creating: parsedModel, forRequest: request)
            return parsedModel
        }
    }

    internal func didReceiveError(_ error: ErrorModel, for response: (URLRequest?, HTTPURLResponse?, Data?, Error?), request: Alamofire.Request) {
        allPlugins.forEach { plugin in
            plugin.didReceiveError(error, forResponse: response, request: request, formedFrom: self)
        }
    }
}
