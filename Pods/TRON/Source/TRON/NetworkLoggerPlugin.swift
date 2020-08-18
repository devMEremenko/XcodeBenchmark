//
//  NetworkLoggerPlugin.swift
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
 Plugin, that can be used to log network success and failure responses.
 */
open class NetworkLoggerPlugin: Plugin {

    /// Log successful requests
    open var logSuccess: Bool

    /// Log unsuccessful requests
    open var logFailures: Bool

    /// Log failures produced when request is cancelled. This property only works, if logFailures property is set to true.
    open var logCancelledRequests: Bool

    /// Creates 'NetworkLoggerPlugin'
    public init(
        logSuccess: Bool = false,
        logFailures: Bool = true,
        logCancelledRequests: Bool = false
        ) {
        self.logSuccess = logSuccess
        self.logFailures = logFailures
        self.logCancelledRequests = logCancelledRequests
    }

    /// Called, when response was successfully parsed. If `logSuccess` property has been turned on, prints cURL representation of request.
    open func didSuccessfullyParseResponse<Model, ErrorModel>(_ response: (URLRequest?, HTTPURLResponse?, Data?, Error?), creating result: Model, forRequest request: Request, formedFrom tronRequest: BaseRequest<Model, ErrorModel>) {
        if logSuccess {
            print(request.cURLDescription())
            print("Request success ✅")
        }
    }

    /// Called, when request received error. If `logFailures` has been turned on, prints cURL representation of request and helpful debugging information such as status code, HTTP body contents and error message. If `logCancelledRequests` property is turned to true, they are also printed.
    open func didReceiveError<Model, ErrorModel>(_ error: ErrorModel, forResponse response: (URLRequest?, HTTPURLResponse?, Data?, Error?), request: Request, formedFrom tronRequest: BaseRequest<Model, ErrorModel>) where ErrorModel: ErrorSerializable {
        if logFailures {
            if case .some(AFError.explicitlyCancelled) = response.3, !logCancelledRequests {
                return
            }
            if let apiError = error as? APIError, let nsError = apiError.error as NSError?, nsError.code == NSURLErrorCancelled, !logCancelledRequests {
                return
            }
            print("❗️ Request errored, gathered debug information: ")
            print(request.cURLDescription())

            print("⚠️ Response status code - \(response.1?.statusCode ?? 0)")
            if let responseData = response.2 {
                print("⚠️ HTTP Body contents: ")
                if let json = try? JSONSerialization.jsonObject(with: responseData, options: .allowFragments) {
                    debugPrint(json)
                } else if let string = String(data: responseData, encoding: .utf8) {
                    print("\(string)")
                }
            }
            if let underlyingError = (error as? APIError)?.error {
                print("⚠️ Received error: \n", underlyingError)
            }
        }
    }
}
