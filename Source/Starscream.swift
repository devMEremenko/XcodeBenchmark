//
// Starscream.swift
// XcodeBenchmark
//
// Created on 18.08.2020.
//

import Starscream

public struct MyEngine: Engine {
    
    private let engine: Engine
    
    public func register(delegate: EngineDelegate) {
        engine.register(delegate: delegate)
    }
    
    public func start(request: URLRequest) {
        engine.start(request: request)
    }
    
    public func stop(closeCode: UInt16) {
        engine.stop(closeCode: closeCode)
    }
    
    public func forceStop() {
        engine.forceStop()
    }
    
    public func write(data: Data, opcode: FrameOpCode, completion: (() -> ())?) {
        engine.write(data: data, opcode: opcode, completion: completion)
    }
    
    public func write(string: String, completion: (() -> ())?) {
        engine.write(string: string, completion: completion)
    }
}

public extension MyEngine {
    
    static func make() -> Engine {
        MyEngine(engine: NativeEngine())
    }
}
