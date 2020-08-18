//
// Realm.swift
// XcodeBenchmark
//
// Created on 18.08.2020.
//

import Realm

public class Storage {
    
    public func make() throws -> RLMRealm {
        try RLMRealm(configuration: .default())
    }
}

public extension RLMArray {
    
    override var description: String {
        "Custom description"
    }
}
