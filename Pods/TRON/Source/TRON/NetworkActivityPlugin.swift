//
//  NetworkActivityPlugin.swift
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

#if os(iOS)
import UIKit
import Alamofire

// swiftlint:disable:next line_length
@available(iOS, deprecated: 13, message: "UIApplication.isNetworkActivityIndicatorVisible is deprecated on iOS 13 and higher. Therefore, this plugin is also deprecated for iOS 13 and higher.")
/**
 Plugin, that monitors sent api requests, and automatically sets UIApplication networkActivityIndicatorVisible property.
 
 - Note: this plugin should be used globally by `TRON` instance. It also assumes, that you have only one `TRON` in your application.
 */
open class NetworkActivityPlugin: Plugin {

    fileprivate let application: UIApplication

    required public init(application: UIApplication) {
        self.application = application
    }
    /**
     Network activity count, based on sent `APIRequests`.
     */
    var networkActivityCount = 0 {
        didSet {
            DispatchQueue.main.async { [unowned self] in
                self.application.isNetworkActivityIndicatorVisible = self.networkActivityCount > 0
            }
        }
    }

    /// Called when network request was sent, increases networkActivityCount by 1
    open func didSendAlamofireRequest<Model, ErrorModel>(_ request: Request, formedFrom tronRequest: BaseRequest<Model, ErrorModel>) {
        DispatchQueue.main.async { [weak self] in self?.networkActivityCount += 1 }
    }

    /// Called when response for request was received, decreases networkActivityCount by 1
    open func willProcessResponse<Model, ErrorModel>(response: (URLRequest?, HTTPURLResponse?, Data?, Error?), forRequest request: Request, formedFrom tronRequest: BaseRequest<Model, ErrorModel>) {
        DispatchQueue.main.async { [weak self] in self?.networkActivityCount -= 1 }
    }
}

#endif
