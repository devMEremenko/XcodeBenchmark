//
// Moya.swift
// XcodeBenchmark
//
// Created on 18.08.2020.
//

import Moya

public struct Target: TargetType {
    public var baseURL = URL(string: "google.com")!
    public var path = ""
    public var method = Method.get
    public var sampleData = Data()
    public var task: Task = .requestData(Data())
    public var headers: [String : String]? = nil
}

public func printError() {
    print(MoyaError.statusCode(.init(statusCode: 501, data: Data())))
}
