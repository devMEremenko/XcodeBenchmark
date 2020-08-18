//
//  AccumulationStrategy.swift
//  DTModelStorage
//
//  Created by Denys Telezhkin on 21.09.2018.
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

/// Strategy to accumulate `oldItems` and `newItems` into resulting array.
public protocol AccumulationStrategy {
    
    /// Accumulate `oldItems` and `newItems` into resulting array.
    ///
    /// - Parameters:
    ///   - oldItems: array of items, already present in storage
    ///   - newItems: array of items, that will be accumulated
    /// - Returns: Accumulated items array.
    func accumulate<T:EntityIdentifiable>(oldItems: [T], newItems: [T]) -> [T]
}

/// Strategy, that adds new items to old items, without comparing their identifiers.
/// This strategy is used by default by `addItems` method of `SingleSectionStorage`.
public struct AdditiveAccumulationStrategy: AccumulationStrategy {
    
    /// Creates additive accumulation strategy
    public init() {}
    
    /// Accumulate `oldItems` and `newItems` into resulting array by appending `newItems` to `oldItems`.
    ///
    /// - Parameters:
    ///   - oldItems: array of items, already present in storage
    ///   - newItems: array of items, that will be accumulated
    /// - Returns: Array, that consists of old items and new items.
    public func accumulate<T>(oldItems: [T], newItems: [T]) -> [T] where T : EntityIdentifiable {
        return oldItems + newItems
    }
}

/// Strategy to update old values with a new ones, using old items position.
public struct UpdateOldValuesAccumulationStrategy: AccumulationStrategy {
    
    /// Creates update old values accumulation strategy
    public init() {}
    
    /// Accumulate `oldItems` and `newItems` into resulting array by updating old items with new values, using old item positions in collection.
    /// Identity of item is determined by `identifier` property.
    ///
    /// - Parameters:
    ///   - oldItems: array of items, already present in storage
    ///   - newItems: array of items, that will be accumulated
    /// - Returns: Accumulated items array, that contains old items updated with new values and new unique values.
    public func accumulate<T>(oldItems: [T], newItems: [T]) -> [T] where T : EntityIdentifiable {
        var newArray = oldItems
        var existingIdentifiers = [AnyHashable:Int]()
        for (index, oldItem) in oldItems.enumerated() {
            existingIdentifiers[oldItem.identifier] = index
        }
        for (index, newItem) in newItems.enumerated() {
            let newIdentifier = newItem.identifier
            if let oldIndex = existingIdentifiers[newIdentifier] {
                // Detected duplicate
                newArray[oldIndex] = newItem
            } else {
                existingIdentifiers[newIdentifier] = index
                newArray.append(newItem)
            }
        }
        return newArray
    }
}

/// Strategy to delete old values when accumulating newItems
public struct DeleteOldValuesAccumulationStrategy: AccumulationStrategy {
    
    /// Creates strategy
    public init() {}
    
    /// Accumulate `oldItems` and `newItems` into resulting array by deleting old items, that have new values in `newItems`, from `oldItems`.
    /// This way old duplicated values are basically moved to their location in `newItems` and updated with new data.
    ///
    /// - Parameters:
    ///   - oldItems: array of items, already present in storage
    ///   - newItems: array of items, that will be accumulated
    /// - Returns: Accumulated items array.
    public func accumulate<T>(oldItems: [T], newItems: [T]) -> [T] where T : EntityIdentifiable {
        var newArray = oldItems
        var existingIdentifiers = [AnyHashable:Int]()
        var indexesToDelete = [Int]()
        for (index, oldItem) in oldItems.enumerated() {
            existingIdentifiers[oldItem.identifier] = index
        }
        for (index, newItem) in newItems.enumerated() {
            let newIdentifier = newItem.identifier
            if let oldIndex = existingIdentifiers[newIdentifier] {
                // Detected duplicate
                newArray.append(newItem)
                
                // Old item will be deleted later
                indexesToDelete.append(oldIndex)
            } else {
                existingIdentifiers[newIdentifier] = index
                newArray.append(newItem)
            }
        }
        
        indexesToDelete.sorted().reversed().forEach { newArray.remove(at: $0) }
        return newArray
    }
}
