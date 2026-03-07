//
//  DownloadAPIRequest.swift
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

/// Types of `DownloadAPIRequest`.
public enum DownloadRequestType {
    /// Will create `NSURLSessionDownloadTask` using `downloadTaskWithRequest(_)` method
    case download(DownloadRequest.Destination)

    /// Will create `NSURLSessionDownloadTask` using `downloadTaskWithResumeData(_)` method
    case downloadResuming(data: Data, destination: DownloadRequest.Destination)
}

/**
 `DownloadAPIRequest` encapsulates download request creation logic, stubbing options, and response/error parsing.
 */
open class DownloadAPIRequest<Model, ErrorModel: DownloadErrorSerializable>: BaseRequest<Model, ErrorModel> {

    /// DownloadAPIREquest type
    let type: DownloadRequestType

    /// Serialize download response into `Result<Model>`.
    public typealias DownloadResponseParser = (_ request: URLRequest?, _ response: HTTPURLResponse?, _ url: URL?, _ error: Error?) throws -> Model

    /// Serializes received failed response into APIError<ErrorModel> object
    public typealias DownloadErrorParser = (_ request: URLRequest?, _ response: HTTPURLResponse?, _ url: URL?, _ error: Error?) -> ErrorModel

    /// Serializes received response into Result<Model>
    open var responseParser: DownloadResponseParser

    /// Serializes received error into APIError<ErrorModel>
    open var errorParser: DownloadErrorParser

    /// Closure that is applied to request before it is sent.
    open var validationClosure: (DownloadRequest) -> DownloadRequest = { $0.validate() }

    /// Sets `validationClosure` to `validation` parameter and returns configured request
    ///
    /// - Parameter validation: validation to perform.
    /// - Returns: configured request.
    open func validation(_ validation: @escaping (DownloadRequest) -> DownloadRequest) -> Self {
        validationClosure = validation
        return self
    }

    /// Creates `DownloadAPIRequest` with specified `type`, `path` and configures it with to be used with `tron`.
    public init<Serializer: DownloadResponseSerializerProtocol>(type: DownloadRequestType, path: String, tron: TRON, responseSerializer: Serializer)
        where Serializer.SerializedObject == Model {
        self.type = type
        self.responseParser = { request, response, fileURL, error in
            try responseSerializer.serializeDownload(request: request, response: response, fileURL: fileURL, error: error)
        }
        self.errorParser = { request, response, fileURL, error in
            ErrorModel(request: request, response: response, fileURL: fileURL, error: error)
        }
        super.init(path: path, tron: tron)
    }

    override func alamofireRequest(from session: Session) -> Request {
        switch type {
        case .download(let destination):
            return session.download(urlBuilder.url(forPath: path),
                                    method: method,
                                    parameters: parameters,
                                    encoding: parameterEncoding,
                                    headers: headers,
                                    interceptor: interceptor,
                                    requestModifier: requestModifier,
                                    to: destination)

        case .downloadResuming(let data, let destination):
            return session.download(resumingWith: data,
                                    interceptor: interceptor,
                                    to: destination)
        }
    }

    @discardableResult
    /**
     Send current request.
     
     - parameter successBlock: Success block to be executed when request finished
     
     - parameter failureBlock: Failure block to be executed if request fails. Nil by default.
     
     - returns: Alamofire.Request or nil if request was stubbed.
     */
    open func perform(withSuccess successBlock: ((Model) -> Void)? = nil, failure failureBlock: ((ErrorModel) -> Void)? = nil) -> DownloadRequest {
        self.performCollectingTimeline { [weak self] response in
            switch response.result {
            case .success(let model):
                self?.resultDeliveryQueue.async {
                    successBlock?(model)
                }
            case .failure(let error):
                if let error = error.underlyingError as? ErrorModel {
                    self?.resultDeliveryQueue.async {
                        failureBlock?(error)
                    }
                }
            }
        }
    }

    @discardableResult
    /**
     Perform current request with completion block, that contains Alamofire.Response.
     
     - parameter completion: Alamofire.Response completion block.
     
     - returns: Alamofire.Request or nil if request was stubbed.
     */
    open func performCollectingTimeline(withCompletion completion: @escaping ((Alamofire.DownloadResponse<Model, AFError>) -> Void)) -> DownloadRequest {
        return performAlamofireRequest(completion)
    }

    private func performAlamofireRequest(_ completion : @escaping (DownloadResponse<Model, AFError>) -> Void) -> DownloadRequest {
        guard let session = tronDelegate?.session else {
            fatalError("Manager cannot be nil while performing APIRequest")
        }
        willSendRequest()
        guard let request = alamofireRequest(from: session) as? DownloadRequest else {
            fatalError("Failed to receive DataRequest")
        }
        if let stub = apiStub, stub.isEnabled {
            request.tron_apiStub = stub
        }
        willSendAlamofireRequest(request)
        let downloadRequest = validationClosure(request)
            .performResponseSerialization(queue: resultDeliveryQueue,
                                          responseSerializer: downloadResponseSerializer(with: request),
                                          completionHandler: { downloadResponse in
                                            self.didReceiveDownloadResponse(downloadResponse, forRequest: request)
                                            completion(downloadResponse)
            })
        if !session.startRequestsImmediately {
            request.resume()
        }
        didSendAlamofireRequest(request)
        return downloadRequest
    }

    internal func downloadResponseSerializer(with request: DownloadRequest) -> TRONDownloadResponseSerializer<Model> {
        return TRONDownloadResponseSerializer { urlRequest, response, url, error in
            self.willProcessResponse((urlRequest, response, nil, error), for: request)
            let parsedModel: Model
            do {
                parsedModel = try self.responseParser(urlRequest, response, url, error)
            } catch let catchedError {
                let parsedError = self.errorParser(urlRequest, response, url, catchedError)
                self.didReceiveError(parsedError, for: (urlRequest, response, url, error), request: request)
                throw parsedError
            }
            self.allPlugins.forEach {
                $0.didSuccessfullyParseDownloadResponse((urlRequest, response, url, error),
                                                        creating: parsedModel,
                                                        forRequest: request,
                                                        formedFrom: self)
            }
            return parsedModel
        }
    }

    internal func didReceiveError(_ error: ErrorModel, for response: (URLRequest?, HTTPURLResponse?, URL?, Error?), request: Alamofire.Request) {
        allPlugins.forEach { plugin in
            plugin.didReceiveDownloadError(error, forResponse: response, request: request, formedFrom: self)
        }
    }

    internal func didReceiveDownloadResponse(_ response: DownloadResponse<Model, AFError>, forRequest request: Alamofire.DownloadRequest) {
        allPlugins.forEach { plugin in
            plugin.didReceiveDownloadResponse(response, forRequest: request, formedFrom: self)
        }
    }
}
