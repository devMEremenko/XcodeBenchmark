//
//  AnomalyHandler.swift
//  DTModelStorage
//
//  Created by Denys Telezhkin on 28.04.2018.
//  Copyright © 2018 Denys Telezhkin. All rights reserved.
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

/// `AnomalyHandler` protocol serves as interface for various anomaly handlers.
/// - SeeAlso: `MemoryStorageAnomaly`, `DTTableViewManagerAnomaly`, `DTCollectionViewManagerAnomaly`.
public protocol AnomalyHandler: class {
    associatedtype Anomaly : Equatable, CustomDebugStringConvertible
    var anomalyAction : (Anomaly) -> Void { get set }
    func reportAnomaly(_ anomaly: Anomaly)
    func silenceAnomaly(_ anomaly: Anomaly)
}

extension AnomalyHandler {
    /// Executes anomalyAction for each reported anomaly.
    public func reportAnomaly(_ anomaly: Anomaly) {
        anomalyAction(anomaly)
    }
    
    /// Silences specific anomaly, anomalyHandler for it will never be called.
    public func silenceAnomaly(_ anomalyToSilence: Anomaly) {
        let tempAnomalyAction = anomalyAction
        anomalyAction = { anomaly in
            if anomaly == anomalyToSilence { return }
            tempAnomalyAction(anomaly)
        }
    }
    
    /// Silences anomalies, based on provided `condition`. If this condition returns true, anomalyHandler will not be called for this anomaly.
    public func silenceAnomaly(usingCondition condition: @escaping (Anomaly) -> Bool) {
        let tempAnomalyAction = anomalyAction
        anomalyAction = { anomaly in
            if condition(anomaly) { return }
            tempAnomalyAction(anomaly)
        }
    }
}
