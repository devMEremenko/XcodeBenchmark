//
// SwiftyJSON.swift
// XcodeBenchmark
//
// Created on 18.08.2020.
//

import SwiftyJSON

public extension JSON {
    
    mutating func makeSomething() throws {
        try merge(with: JSON(data: Data()))
    }
}
