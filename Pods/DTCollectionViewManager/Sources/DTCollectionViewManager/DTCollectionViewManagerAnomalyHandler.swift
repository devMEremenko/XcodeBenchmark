//
//  DTCollectionViewManagerAnomalyHandler.swift
//  DTCollectionViewManager
//
//  Created by Denys Telezhkin on 03.05.2018.
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
import DTModelStorage

/// `DTCollectionViewManagerAnomaly` represents various errors and unwanted behaviors that can happen when using `DTCollectionViewManager` class.
/// - SeeAlso: `MemoryStorageAnomaly`, `DTTableViewManagerAnomaly`.
public enum DTCollectionViewManagerAnomaly: Equatable, CustomStringConvertible, CustomDebugStringConvertible {
    
    case nilCellModel(IndexPath)
    case nilSupplementaryModel(kind: String, indexPath: IndexPath)
    case noCellMappingFound(modelDescription: String, indexPath: IndexPath)
    case noSupplementaryMappingFound(modelDescription: String, kind: String, indexPath: IndexPath)
    
    @available(*, deprecated, message: "If you are using xibs or code cells, you should not set reuseIdentifier, because UICollectionView.CellRegistration gives you a random one. If you use storyboard, set reuseIdentifier equal to name of the cell subclass.")
    case differentCellReuseIdentifier(mappingReuseIdentifier: String, cellReuseIdentifier: String)
    
    case differentSupplementaryReuseIdentifier(mappingReuseIdentifier: String, supplementaryReuseIdentifier: String)
    case differentCellClass(xibName: String, cellClass: String, expectedCellClass: String)
    case differentSupplementaryClass(xibName: String, viewClass: String, expectedViewClass: String)
    case emptyXibFile(xibName: String, expectedViewClass: String)
    case modelEventCalledWithCellClass(modelType: String, methodName: String, subclassOf: String)
    case unusedEventDetected(viewType: String, methodName: String)
    case eventRegistrationForUnregisteredMapping(viewClass: String, signature: String)
    case flowDelegateLayoutMethodWithDifferentLayout(methodSignature: String)
    
    /// Debug information for happened anomaly
    public var debugDescription: String {
        switch self {
        case .nilCellModel(let indexPath): return "❗️[DTCollectionViewManager] UICollectionView requested a cell at \(indexPath), however the model at that indexPath was nil."
        case .nilSupplementaryModel(kind: let kind, indexPath: let indexPath): return "❗️[DTCollectionViewManager] UICollectionView requested a supplementary view of kind: \(kind) at \(indexPath), however the model was nil."
        case .noCellMappingFound(modelDescription: let description, indexPath: let indexPath): return "❗️[DTCollectionViewManager] UICollectionView requested a cell for model at \(indexPath), but view model mapping for it was not found, model description: \(description)"
        case .noSupplementaryMappingFound(modelDescription: let description, kind: let kind, let indexPath):
            return "❗️[DTCollectionViewManager] UICollectionView requested a supplementary view of kind: \(kind) for model ar \(indexPath), but view model mapping for it was not found, model description: \(description)"
        case .differentCellReuseIdentifier(mappingReuseIdentifier: let mappingReuseIdentifier,
                                           cellReuseIdentifier: let cellReuseIdentifier):
            return "❗️[DTCollectionViewManager] Reuse identifier of UICollectionViewCell: \(cellReuseIdentifier) does not match reuseIdentifier used to register with UICollectionView: \(mappingReuseIdentifier). \n" +
                "If you are using XIB, please remove reuseIdentifier from XIB file, or change it to name of UICollectionViewCell subclass. If you are using Storyboards, please change UICollectionViewCell identifier to name of the class. \n" +
            "If you need different reuseIdentifier for any reason, you can change reuseIdentifier when registering mapping."
        case .differentCellClass(xibName: let xibName, cellClass: let cellClass, expectedCellClass: let expectedCellClass):
            return "⚠️[DTCollectionViewManager] Attempted to register xib \(xibName), but view found in a xib was of type \(cellClass), while expected type is \(expectedCellClass). This can prevent cells from being updated with models and react to events."
        case .differentSupplementaryClass(xibName: let xibName, viewClass: let viewClass, expectedViewClass: let expectedViewClass):
            return "⚠️[DTCollectionViewManager] Attempted to register xib \(xibName), but view found in a xib was of type \(viewClass), while expected type is \(expectedViewClass). This can prevent supplementary views from being updated with models and react to events."
        case .emptyXibFile(xibName: let xibName, expectedViewClass: let expectedViewClass):
            return "⚠️[DTCollectionViewManager] Attempted to register xib \(xibName) for \(expectedViewClass), but this xib does not contain any views."
        case .differentSupplementaryReuseIdentifier(mappingReuseIdentifier: let mappingIdentifier, supplementaryReuseIdentifier: let supplementaryIdentifier):
            return "❗️[DTCollectionViewManager] Reuse identifier of UICollectionReusableView: \(supplementaryIdentifier) does not match reuseIdentifier used to register with UICollectionView: \(mappingIdentifier). \n" +
                "If you are using XIB, please remove reuseIdentifier from XIB file, or change it to name of UICollectionReusableView subclass. If you are using Storyboards, please change UICollectionReusableView identifier to name of the class. \n" +
            "If you need different reuseIdentifier for any reason, you can change reuseIdentifier when registering mapping."
        case .modelEventCalledWithCellClass(modelType: let modelType, methodName: let methodName, subclassOf: let subclassOf):
            return """
                ⚠️[DTCollectionViewManager] Event \(methodName) registered with model type, that happens to be a subclass of \(subclassOf): \(modelType).
                
                This is likely not what you want, because this event expects to receive model type used for current indexPath instead of cell/view.
                Reasoning behind it is the fact that for some events views have not yet been created(for example: func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath)).
                Because they are not created yet, this event cannot be called with cell/view object, and even it's type is unknown at this point, as the mapping resolution will happen later.
                
                Most likely you need to use model type, that will be passed to this cell/view through ModelTransfer protocol.
                For example, for size of cell that expects to receive model Int, event would look like so:
                
                manager.sizeForCell(withItem: Int.self) { model, indexPath in
                    return CGSize(height: 44, width: 44)
                }

                Alternatively, you can specify this event closure directly inside mapping block:

                manager.register(Cell.self) { mapping in
                    mapping.sizeForCell { model, indexPath in CGSize(height: 44, width: 44) }
                }
                """
        case .unusedEventDetected(viewType: let view, methodName: let methodName):
            return "⚠️[DTCollectionViewManager] \(methodName) event registered for \(view), but there were no view mappings registered for \(view) type. This event will never be called."
        case .eventRegistrationForUnregisteredMapping(let viewClass, let signature):
                return "⚠️[DTCollectionViewManager] While registering event reaction for \(signature), no view mapping was found for view: \(viewClass)"
        case .flowDelegateLayoutMethodWithDifferentLayout(methodSignature: let signature):
            return "⚠️[DTCollectionViewManager] Detected reaction for UICollectionViewDelegateFlowLayout protocol, but different layout class is used. This means, that method \(signature) will not be called, as well as registered reaction."
        }
    }
    
    /// Short description for `DTCollectionViewManagerAnomaly`. Useful for sending to analytics, which might have character limit.
    public var description: String {
        switch self {
        case .nilCellModel(let indexPath): return "DTCollectionViewManagerAnomaly.nilCellModel(\(indexPath))"
        case .nilSupplementaryModel(let kind, let indexPath): return "DTCollectionViewManagerAnomaly.nilSupplementaryModel(\(indexPath)) for kind \(kind)"
        case .noCellMappingFound(modelDescription: let description, indexPath: let indexPath): return "DTCollectionViewManagerAnomaly.noCellMappingFound(\(description), \(indexPath))"
        case .noSupplementaryMappingFound(modelDescription: let description, kind: let kind, indexPath: let indexPath): return "DTCollectionViewManagerAnomaly.noSupplementaryMappingFound(\(description), \(kind), \(indexPath))"
        case .differentCellReuseIdentifier(mappingReuseIdentifier: let mappingIdentifier, cellReuseIdentifier: let cellIdentifier): return "DTCollectionViewManagerAnomaly.differentCellReuseIdentifier(\(mappingIdentifier), \(cellIdentifier))"
        case .differentCellClass(xibName: let xibName, cellClass: let cellClass, expectedCellClass: let expected): return "DTCollectionViewManagerAnomaly.differentCellClass(\(xibName), \(cellClass), \(expected))"
        case .differentSupplementaryClass(xibName: let xibName, viewClass: let viewClass, expectedViewClass: let expected): return "DTCollectionViewManagerAnomaly.differentSupplementaryClass(\(xibName), \(viewClass), \(expected))"
        case .emptyXibFile(xibName: let xibName, expectedViewClass: let expected): return "DTCollectionViewManagerAnomaly.emptyXibFile(\(xibName), \(expected))"
        case .modelEventCalledWithCellClass(modelType: let model, methodName: let method, subclassOf: let subclass): return "DTCollectionViewManagerAnomaly.modelEventCalledWithCellClass(\(model), \(method), \(subclass))"
        case .unusedEventDetected(viewType: let view, methodName: let method): return "DTCollectionViewManagerAnomaly.unusedEventDetected(\(view), \(method))"
        case .differentSupplementaryReuseIdentifier(let mappingReuseIdentifier, let supplementaryReuseIdentifier): return "DTCollectionViewManagerAnomaly.differentSupplementaryReuseIdentifier(\(mappingReuseIdentifier), \(supplementaryReuseIdentifier))"
        case .eventRegistrationForUnregisteredMapping(let viewClass, let signature):
            return "DTCollectionViewManagerAnomaly.eventRegistrationForUnregisteredMapping(\(viewClass), \(signature)"
        case .flowDelegateLayoutMethodWithDifferentLayout(methodSignature: let signature):
            return "DTCollectionViewManagerAnomaly.flowDelegateLayoutMethodWithDifferentLayout(\(signature))"
        }
    }
}

/// `DTCollectionViewManagerAnomalyHandler` handles anomalies from `DTCollectionViewManager`.
open class DTCollectionViewManagerAnomalyHandler : AnomalyHandler {
    
    /// Default action to perform when anomaly is detected. Prints debugDescription of anomaly by default.
    public static var defaultAction : (DTCollectionViewManagerAnomaly) -> Void = {
        #if DEBUG
            print($0.debugDescription)
        #endif
    }
    
    /// Action to perform when anomaly is detected. Defaults to `defaultAction`.
    open var anomalyAction: (DTCollectionViewManagerAnomaly) -> Void = DTCollectionViewManagerAnomalyHandler.defaultAction
    
    /// Creates `DTCollectionViewManagerAnomalyHandler`.
    public init() {}
}
