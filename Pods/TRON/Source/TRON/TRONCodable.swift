//
//  TRONCodable.swift
//  TRON
//
//  Created by Denys Telezhkin on 06.02.16.
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

/// `CodableParser` is a wrapper around `modelDecoder` and `errorDecoder` JSONDecoders to be used when decoding JSON response.
open class CodableParser<Model: Decodable>: DataResponseSerializerProtocol {

    /// Decoder used for decoding model object
    public let modelDecoder: JSONDecoder

    /// Creates `CodableParser` with model and error decoders
    public init(modelDecoder: JSONDecoder) {
        self.modelDecoder = modelDecoder
    }

    /// Method used by response handlers that takes a request, response, data and error and returns a result.
    open func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> Model {
        if let error = error {
            throw error
        }
        if let type = Model.self as? EmptyResponse.Type, let emptyValue = type.emptyValue() as? Model {
            return emptyValue
        }
        return try modelDecoder.decode(Model.self, from: data ?? Data())
    }
}

/// Serializer for objects, that conform to `Decodable` protocol.
open class CodableSerializer {

    /// `TRON` instance to be used to send requests
    let tron: TRON

    /// Decoder to be used while parsing model.
    public let modelDecoder: JSONDecoder

    /// Creates `CodableSerializer` with `tron` instance to send requests, and `decoder` to be used while parsing response.
    public init(_ tron: TRON, modelDecoder: JSONDecoder = JSONDecoder()) {
        self.tron = tron
        self.modelDecoder = modelDecoder
    }

    /**
     Creates APIRequest with specified relative path and type RequestType.Default.

     - parameter path: Path, that will be appended to current `baseURL`.

     - returns: APIRequest instance.
     */
    open func request<Model: Decodable, ErrorModel: ErrorSerializable>(_ path: String) -> APIRequest<Model, ErrorModel> {
        return tron.request(path, responseSerializer: CodableParser(modelDecoder: modelDecoder))
    }

    /**
     Creates APIRequest with specified relative path and type RequestType.UploadFromFile.

     - parameter path: Path, that will be appended to current `baseURL`.

     - parameter fileURL: File url to upload from.

     - returns: APIRequest instance.
     */
    open func upload<Model: Decodable, ErrorModel: ErrorSerializable>(_ path: String, fromFileAt fileURL: URL) -> UploadAPIRequest<Model, ErrorModel> {
        return tron.upload(path, fromFileAt: fileURL,
                           responseSerializer: CodableParser(modelDecoder: modelDecoder))
    }

    /**
     Creates APIRequest with specified relative path and type RequestType.UploadData.

     - parameter path: Path, that will be appended to current `baseURL`.

     - parameter data: Data to upload.

     - returns: APIRequest instance.
     */
    open func upload<Model: Decodable, ErrorModel: ErrorSerializable>(_ path: String, data: Data) -> UploadAPIRequest<Model, ErrorModel> {
        return tron.upload(path, data: data, responseSerializer: CodableParser(modelDecoder: modelDecoder))
    }

    /**
     Creates APIRequest with specified relative path and type RequestType.UploadStream.

     - parameter path: Path, that will be appended to current `baseURL`.

     - parameter stream: Stream to upload from.

     - returns: APIRequest instance.
     */
    open func upload<Model: Decodable, ErrorModel: ErrorSerializable>(_ path: String, from stream: InputStream) -> UploadAPIRequest<Model, ErrorModel> {
        return tron.upload(path, from: stream, responseSerializer: CodableParser(modelDecoder: modelDecoder))
    }

    /**
     Creates MultipartAPIRequest with specified relative path.

     - parameter path: Path, that will be appended to current `baseURL`.

     - parameter formData: Multipart form data creation block.

     - returns: MultipartAPIRequest instance.
     */
    open func uploadMultipart<Model: Decodable, ErrorModel: ErrorSerializable>(_ path: String,
                                                                               encodingMemoryThreshold: UInt64 = MultipartFormData.encodingMemoryThreshold,
                                                                               fileManager: FileManager = .default,
                                                                               formData: @escaping (MultipartFormData) -> Void) -> UploadAPIRequest<Model, ErrorModel> {
        return tron.uploadMultipart(path, responseSerializer: CodableParser(modelDecoder: modelDecoder),
                                    encodingMemoryThreshold: encodingMemoryThreshold,
                                    fileManager: fileManager,
                                    formData: formData)
    }
}

extension TRON {
    /// Creates `CodableSerializer` with current `TRON` instance and specific `modelDecoder`.
    open func codable(modelDecoder: JSONDecoder) -> CodableSerializer {
        return CodableSerializer(self, modelDecoder: modelDecoder)
    }
}
