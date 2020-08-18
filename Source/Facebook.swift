//
// Facebook.swift
// XcodeBenchmark
//
// Created on 18.08.2020.
//

import FacebookCore
import FacebookLogin
import FacebookShare

public func makeGraphRequest() -> FacebookCore.GraphRequest {
    GraphRequest(graphPath: "", httpMethod: .get)
}

public func printFacebook() {
    print(FacebookLoginVersionNumber)
    print(FacebookShareVersionNumber)
    print(FacebookCoreVersionNumber)
}
