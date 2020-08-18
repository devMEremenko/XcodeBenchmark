//
//  ModelTransfer.swift
//  DTModelStorage
//
//  Created by Denys Telezhkin on 06.07.15.
//  Copyright (c) 2015 Denys Telezhkin. All rights reserved.
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

/// Protocol used to pass `model` data to your cell or supplementary view. Every cell or supplementary view you have should conform to this protocol.
/// 
/// `ModelType` is associated type, that works as generic constraint for specific cell or view. When implementing this method, use model type, that you wish to transfer to cell.
///
/// For example:
/// class PostTableViewCell: UITableViewCell, ModelTransfer {
///     func update(with: Post) {
///     }
/// }
public protocol ModelTransfer : class
{
    /// Type of model that is being transferred
    associatedtype ModelType
    
    /// Updates view with `model`.
    func update(with model: ModelType)
}

extension ModelTransfer {
    /// Returns custom MappingCondition that allows to customize mappings based on IndexPath and ModelType.
    public static func modelCondition(_ condition: @escaping (IndexPath, ModelType) -> Bool) -> MappingCondition {
        return .custom { indexPath, model in
            guard let model = model as? ModelType else { return false }
            return condition(indexPath, model)
        }
    }
}
