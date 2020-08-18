//
//  Plugin.swift
//  TRON
//
//  Created by Denys Telezhkin on 20.01.16.
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

/**
 Protocol that serves to provide plugin functionality to `TRON`.
 */
public protocol Plugin {

    /// Notifies that `request` is about to be converted to Alamofire.Request
    ///
    /// - parameter request: TRON BaseRequest
    func willSendRequest<Model, ErrorModel>(_ request: BaseRequest<Model, ErrorModel>)

    /// Notifies that `request` formed from `tronRequest`, is about to be sent.
    ///
    /// - parameter request: Alamofire.Request instance
    /// - parameter formedFrom: TRON.BaseRequest instance or one of the subclasses
    func willSendAlamofireRequest<Model, ErrorModel>(_ request: Request, formedFrom tronRequest: BaseRequest<Model, ErrorModel>)

    /// Notifies that `request`, formed from `tronRequest`, was sent.
    ///
    /// - parameter request:     Alamofire.Request instance
    /// - parameter tronRequest: TRON.BaseRequest or one of the subclasses
    func didSendAlamofireRequest<Model, ErrorModel>(_ request: Request, formedFrom tronRequest: BaseRequest<Model, ErrorModel>)

    /// Notifies that `response` was received for `request`, formed from `tronRequest`.
    ///
    /// - parameter response:    Tuple with (URLRequest?, HTTPURLResponse?, Data?, Error?)
    /// - parameter request:     Alamofire.Request instance
    /// - parameter tronRequest: TRON.BaseRequest or one of the subclasses
    func willProcessResponse<Model, ErrorModel>(response: (URLRequest?, HTTPURLResponse?, Data?, Error?),
                                                forRequest request: Request,
                                                formedFrom tronRequest: BaseRequest<Model, ErrorModel>)

    /// Notifies that `response` for `request`, formed from `tronRequest`, was successfully parsed into `result`.
    ///
    /// - parameter response:    Tuple with (URLRequest?, HTTPURLResponse?, Data?, Error?)
    /// - parameter result:      parsed Model
    /// - parameter request:     Alamofire.Request instance
    /// - parameter tronRequest: TRON.BaseRequest or one of the subclasses
    func didSuccessfullyParseResponse<Model, ErrorModel>(_ response: (URLRequest?, HTTPURLResponse?, Data?, Error?),
                                                         creating result: Model,
                                                         forRequest request: Request,
                                                         formedFrom tronRequest: BaseRequest<Model, ErrorModel>)

    /// Notifies that request processed response and created `APIError<ErrorModel>` instance.
    ///
    /// - parameter error:       parsed APIError<ErrorModel> instance
    /// - parameter response:    Tuple with (URLRequest?, HTTPURLResponse?, Data?, Error?)
    /// - parameter request:     Alamofire.Request instance
    /// - parameter tronRequest: TRON.BaseRequest or one of the subclasses
    func didReceiveError<Model, ErrorModel: ErrorSerializable>(_ error: ErrorModel,
                                                               forResponse response: (URLRequest?, HTTPURLResponse?, Data?, Error?),
                                                               request: Alamofire.Request,
                                                               formedFrom tronRequest: BaseRequest<Model, ErrorModel>)

    /// Notifies that request processed response and created `APIError<ErrorModel>` instance.
    ///
    /// - parameter error:       parsed APIError<ErrorModel> instance
    /// - parameter response:    Tuple with (URLRequest?, HTTPURLResponse?, URL?, Error?)
    /// - parameter request:     Alamofire.Request instance
    /// - parameter tronRequest: TRON.BaseRequest or one of the subclasses
    func didReceiveDownloadError<Model, ErrorModel: DownloadErrorSerializable>(_ error: ErrorModel,
                                                                               forResponse response: (URLRequest?, HTTPURLResponse?, URL?, Error?),
                                                                               request: Alamofire.Request,
                                                                               formedFrom tronRequest: BaseRequest<Model, ErrorModel>)

    /// Notifies about data `response` that was received for `request`, formed from `tronRequest`. This method is called after parsing has completed.
    ///
    /// - parameter response:    DataResponse instance
    /// - parameter request:     Alamofire.Request instance
    /// - parameter tronRequest: TRON.BaseRequest or one of the subclasses
    func didReceiveDataResponse<Model, ErrorModel>(_ response: DataResponse<Model, AFError>, forRequest request: Alamofire.Request, formedFrom tronRequest: BaseRequest<Model, ErrorModel>)

    /// Notifies about download `response` that was received for `request`, formed from `tronRequest`. This method is called after parsing has completed.
    ///
    /// - parameter _response:   DownloadResponse instance
    /// - parameter request:     Alamofire.Request instance
    /// - parameter tronRequest: TRON.BaseRequest or one of the subclasses.
    func didReceiveDownloadResponse<Model, ErrorModel: DownloadErrorSerializable>(_ response: DownloadResponse<Model, AFError>,
                                                                                  forRequest request: Alamofire.DownloadRequest,
                                                                                  formedFrom tronRequest: BaseRequest<Model, ErrorModel>)

    /// Notifies that `response` for `request`, formed from `tronRequest`, was successfully parsed into `result`.
    ///
    /// - parameter response:    Tuple with (URLRequest?, HTTPURLResponse?, URL?, Error?)
    /// - parameter result:      parsed Model
    /// - parameter request:     Alamofire.Request instance
    /// - parameter tronRequest: TRON.BaseRequest or one of the subclasses
    func didSuccessfullyParseDownloadResponse<Model, ErrorModel: DownloadErrorSerializable>(_ response: (URLRequest?, HTTPURLResponse?, URL?, Error?),
                                                                                            creating result: Model,
                                                                                            forRequest request: Request,
                                                                                            formedFrom tronRequest: BaseRequest<Model, ErrorModel>)
}

/// Default empty methods for Plugin protocol
public extension Plugin {
    func willSendRequest<Model, ErrorModel>(_ request: BaseRequest<Model, ErrorModel>) {}

    func willSendAlamofireRequest<Model, ErrorModel>(_ request: Request, formedFrom tronRequest: BaseRequest<Model, ErrorModel>) {}

    func didSendAlamofireRequest<Model, ErrorModel>(_ request: Request, formedFrom tronRequest: BaseRequest<Model, ErrorModel>) {}

    func willProcessResponse<Model, ErrorModel>(response: (URLRequest?, HTTPURLResponse?, Data?, Error?), forRequest request: Request, formedFrom tronRequest: BaseRequest<Model, ErrorModel>) {}

    func didSuccessfullyParseResponse<Model, ErrorModel>(_ response: (URLRequest?, HTTPURLResponse?, Data?, Error?),
                                                         creating result: Model,
                                                         forRequest request: Request,
                                                         formedFrom tronRequest: BaseRequest<Model, ErrorModel>) {}

    func didReceiveError<Model, ErrorModel: ErrorSerializable>(_ error: ErrorModel,
                                                               forResponse response: (URLRequest?, HTTPURLResponse?, Data?, Error?),
                                                               request: Alamofire.Request,
                                                               formedFrom tronRequest: BaseRequest<Model, ErrorModel>) {}

    func didReceiveDataResponse<Model, ErrorModel>(_ response: DataResponse<Model, AFError>, forRequest request: Alamofire.Request, formedFrom tronRequest: BaseRequest<Model, ErrorModel>) {}

    func didReceiveDownloadResponse<Model, ErrorModel: DownloadErrorSerializable>(_ response: DownloadResponse<Model, AFError>, forRequest request: Alamofire.DownloadRequest, formedFrom tronRequest: BaseRequest<Model, ErrorModel>) {}

    func didReceiveDownloadError<Model, ErrorModel: DownloadErrorSerializable>(_ error: ErrorModel,
                                                                               forResponse response: (URLRequest?, HTTPURLResponse?, URL?, Error?),
                                                                               request: Alamofire.Request,
                                                                               formedFrom tronRequest: BaseRequest<Model, ErrorModel>) {}

    func didSuccessfullyParseDownloadResponse<Model, ErrorModel: DownloadErrorSerializable>(_ response: (URLRequest?, HTTPURLResponse?, URL?, Error?),
                                                                                            creating result: Model,
                                                                                            forRequest request: Request,
                                                                                            formedFrom tronRequest: BaseRequest<Model, ErrorModel>) {}
}
