//
//  BaseRequest.swift
//  TRON
//
//  Created by Denys Telezhkin on 15.05.16.
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

/// Protocol used to allow `APIRequest` to communicate with `TRON` instance.
public protocol TronDelegate: AnyObject {

    /// Alamofire.Session used to send requests
    var session: Alamofire.Session { get }

    /// Global array of plugins on `TRON` instance
    var plugins: [Plugin] { get }
}

/// Base class, that contains common functionality, extracted from `APIRequest` and `MultipartAPIRequest`.
open class BaseRequest<Model, ErrorModel> {

    /// Serializes Data into Model
    public typealias ResponseParser = (_ request: URLRequest?, _ response: HTTPURLResponse?, _ data: Data?, _ error: Error?) throws -> Model

    /// Serializes received failed response into APIError<ErrorModel> object
    public typealias ErrorParser = (_ request: URLRequest?, _ response: HTTPURLResponse?, _ data: Data?, _ error: Error?) -> ErrorModel

    /// Relative path of current request
    public let path: String

    /// HTTP method
    open var method: Alamofire.HTTPMethod = .get

    /// Parameters of current request.
    open var parameters: [String: Any] = [:]

    /// Defines how parameters are encoded.
    open var parameterEncoding: Alamofire.ParameterEncoding

    /// Headers, that should be used for current request. Defaults to HTTPHeaders.default
    open var headers: HTTPHeaders = .default

    /// URL builder for current request
    open var urlBuilder: URLBuilder

    /// API stub to be used when stubbing this request
    open var apiStub: APIStub? {
        didSet {
            apiStub?.isEnabled = (tronDelegate as? TRON)?.stubbingEnabled ?? false
        }
    }

    /// Request interceptor that allows to adapt and retry requests.
    open var interceptor: RequestInterceptor?

    /// Closure which provides a `URLRequest` for mutation.
    open var requestModifier: Session.RequestModifier?

    /// Queue, used to deliver result completion blocks. Defaults to TRON.resultDeliveryQueue queue.
    open var resultDeliveryQueue: DispatchQueue

    /// Delegate property that is used to communicate with `TRON` instance.
    weak var tronDelegate: TronDelegate?

    /// Array of plugins for current `APIRequest`.
    open var plugins: [Plugin] = []

    internal var allPlugins: [Plugin] {
        return plugins + (tronDelegate?.plugins ?? [])
    }

    /// Creates `BaseRequest` instance, initialized with several `TRON` properties.
    public init(path: String, tron: TRON) {
        self.path = path
        self.tronDelegate = tron
        self.urlBuilder = tron.urlBuilder
        self.resultDeliveryQueue = tron.resultDeliveryQueue
        self.parameterEncoding = tron.parameterEncoding
    }

    internal func alamofireRequest(from session: Alamofire.Session) -> Alamofire.Request {
        fatalError("Needs to be implemented in subclasses")
    }

    internal func callSuccessFailureBlocks(_ success: ((Model) -> Void)?,
                                           failure: ((ErrorModel) -> Void)?,
                                           response: Alamofire.DataResponse<Model, AFError>) {
        switch response.result {
        case .success(let value):
            resultDeliveryQueue.async {
                success?(value)
            }
        case .failure(let error):
            resultDeliveryQueue.async {
                guard let error = error.underlyingError as? ErrorModel else {
                    return
                }
                failure?(error)
            }
        }
    }

    internal func willSendRequest() {
        allPlugins.forEach { plugin in
            plugin.willSendRequest(self)
        }
    }

    internal func willSendAlamofireRequest(_ request: Alamofire.Request) {
        allPlugins.forEach { plugin in
            plugin.willSendAlamofireRequest(request, formedFrom: self)
        }
    }

    internal func didSendAlamofireRequest(_ request: Alamofire.Request) {
        allPlugins.forEach { plugin in
            plugin.didSendAlamofireRequest(request, formedFrom: self)
        }
    }

    internal func willProcessResponse(_ response: (URLRequest?, HTTPURLResponse?, Data?, Error?), for request: Request) {
        allPlugins.forEach { plugin in
            plugin.willProcessResponse(response: response, forRequest: request, formedFrom: self)
        }
    }

    internal func didSuccessfullyParseResponse(_ response: (URLRequest?, HTTPURLResponse?, Data?, Error?), creating result: Model, forRequest request: Alamofire.Request) {
        allPlugins.forEach { plugin in
            plugin.didSuccessfullyParseResponse(response, creating: result, forRequest: request, formedFrom: self)
        }
    }

    internal func didReceiveDataResponse(_ response: DataResponse<Model, AFError>, forRequest request: Alamofire.Request) {
        allPlugins.forEach { plugin in
            plugin.didReceiveDataResponse(response, forRequest: request, formedFrom: self)
        }
    }

    /// Sets `method` variable to `httpMethod` and returns.
    ///
    /// - Parameter httpMethod: http method to set on Request.
    /// - Returns: configured request.
    open func method(_ httpMethod: HTTPMethod) -> Self {
        self.method = httpMethod
        return self
    }

    /// Sets `method` variable to `.post` and returns.
    ///
    /// - Returns: configured request.
    open func post() -> Self {
        method = .post
        return self
    }

    /// Sets `method` variable to `.connect` and returns.
    ///
    /// - Returns: configured request.
    open func connect() -> Self {
        method = .connect
        return self
    }

    /// Sets `method` variable to `.delete` and returns.
    ///
    /// - Returns: configured request.
    open func delete() -> Self {
        method = .delete
        return self
    }

    /// Sets `method` variable to `.get` and returns.
    ///
    /// - Returns: configured request.
    open func get() -> Self {
        method = .get
        return self
    }

    /// Sets `method` variable to `.head` and returns.
    ///
    /// - Returns: configured request.
    open func head() -> Self {
        method = .head
        return self
    }

    /// Sets `method` variable to `.options` and returns.
    ///
    /// - Returns: configured request.
    open func options() -> Self {
        method = .options
        return self
    }

    /// Sets `method` variable to `.patch` and returns.
    ///
    /// - Returns: configured request.
    open func patch() -> Self {
        method = .patch
        return self
    }

    /// Sets `method` variable to `.put` and returns.
    ///
    /// - Returns: configured request.
    open func put() -> Self {
        method = .put
        return self
    }

    /// Sets `method` variable to `.trace` and returns.
    ///
    /// - Returns: configured request.
    open func trace() -> Self {
        method = .trace
        return self
    }

    /// Sets `parameterEncoding` variable to `encoding` and returns configured request.
    ///
    /// - Parameter encoding: Alamofire.ParameterEncoding value. Common values are: JSONEncoding.default, URLEncoding.default.
    /// - Returns: configured request
    open func parameterEncoding(_ encoding: ParameterEncoding) -> Self {
        parameterEncoding = encoding
        return self
    }

    /// Sets `headers` variable to `headers` and returns configured request.
    ///
    /// - Parameter headers: Alamofire.HTTPHeaders value.
    /// - Returns: confiured request
    open func headers(_ headers: HTTPHeaders) -> Self {
        self.headers = headers
        return self
    }

    /// Appends `plugin` to `plugins` variable and returns configured request.
    ///
    /// - Parameter plugin: Plugin implementation
    /// - Returns: configured request
    open func usingPlugin(_ plugin: Plugin) -> Self {
        plugins.append(plugin)
        return self
    }

    /// Replaces `urlBuilder` with `URLBuilder` with the same baseURL string and `behavior`.
    ///
    /// - Parameter behavior: URL building behavior to use when constructing request.
    /// - Returns: configured request.
    open func buildURL(_ behavior: URLBuilder.Behavior) -> Self {
        urlBuilder = URLBuilder(baseURL: urlBuilder.baseURLString, behavior: behavior)
        return self
    }

    /// Sets per-request Interceptor for current request and returns.
    ///
    /// - Parameter interceptor: request interceptor
    /// - Returns: configured request
    open func intercept(using interceptor: RequestInterceptor) -> Self {
        self.interceptor = interceptor
        return self
    }

    /// Sets per-request modifier to configure URLRequest, that will be created.
    /// - Parameter closure: request modifier closure
    /// - Returns: configured request
    open func modifyRequest(_ closure: @escaping Session.RequestModifier) -> Self {
        self.requestModifier = closure
        return self
    }

    /// Configures current given request by executing `closure` and returning.
    ///
    /// - Parameter closure: configuration closure to run
    /// - Returns: configured request
    open func configure(_ closure: (BaseRequest) -> Void) -> Self {
        closure(self)
        return self
    }

    /// Sets `parameters` into `parameters` variable on request. If `rootKey` is non-nil, parameters are wrapped in external dictionary and set into `parameters` using `rootKey` as a single key.
    ///
    /// - Parameters:
    ///   - parameters: parameters to set for request
    ///   - rootKey: Key to use in a wrapper dictionary to wrap passed parameters. Defaults to nil.
    /// - Returns: configured request
    open func parameters(_ parameters: [String: Any], rootKey: String? = nil) -> Self {
        if let rootKey = rootKey {
            var wrappedParameters: [String: Any] = [:]
            parameters.forEach {
                wrappedParameters[$0.key] = $0.value
            }
            self.parameters[rootKey] = wrappedParameters
        } else {
            parameters.forEach {
                self.parameters[$0.key] = $0.value
            }
        }
        return self
    }

    /// Sets `parameters` into `parameters` variable on request. If `rootKey` is non-nil, parameters are wrapped in external dictionary and set into `parameters` using `rootKey` as a single key.
    /// If `setNilToNull` is set to true, every nil value will be converted to `NSNull` instance.
    ///
    /// - Parameters:
    ///   - parameters: parameters to set for request
    ///   - setNilToNull: If true, converts nil values into NSNull instance to be presented as `null` when converted to JSON. Defaults to false.
    ///   - rootKey: Key to use in a wrapper dictionary to wrap passed parameters. Defaults to nil.
    /// - Returns: configured request
    open func optionalParameters(_ parameters: [String: Any?], setNilToNull: Bool = false, rootKey: String? = nil) -> Self {
        if let rootKey = rootKey {
            var wrappedParameters: [String: Any] = [:]
            parameters.forEach {
                if let value = $0.value {
                    wrappedParameters[$0.key] = value
                } else if setNilToNull {
                    wrappedParameters[$0.key] = NSNull()
                }
            }
            self.parameters[rootKey] = wrappedParameters
        } else {
            parameters.forEach {
                if let value = $0.value {
                    self.parameters[$0.key] = value
                } else if setNilToNull {
                    self.parameters[$0.key] = NSNull()
                }
            }
        }
        return self
    }

    /// Sets `stub` into `apiStub` property, `delay` into `apiStub.stubDelay` property. Also `enabled` is set to `apiStub.isEnabled` property.
    ///
    /// - Parameters:
    ///   - stub: stub to use when stubbing the request
    ///   - delay: Stub delay after which stub will return results. Defaults to 0.
    ///   - enabled: Specifies, if `apiStub` needs to be enabled. Defaults to true.
    /// - Returns: configured request
    open func stub(with stub: APIStub, delay: TimeInterval = 0.0, enabled: Bool = true) -> Self {
        apiStub = stub
        apiStub?.isEnabled = enabled
        apiStub?.stubDelay = delay
        return self
    }
}
