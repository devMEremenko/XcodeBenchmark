//
//  DTCollectionViewManager.swift
//  DTCollectionViewManager
//
//  Created by Denys Telezhkin on 23.08.15.
//  Copyright © 2015 Denys Telezhkin. All rights reserved.
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
import UIKit
import DTModelStorage
import SwiftUI

/// Adopting this protocol will automatically inject manager property to your object, that lazily instantiates DTCollectionViewManager object.
/// Target is not required to be UICollectionViewController, and can be a regular UIViewController with UICollectionView, or any other view, that contains UICollectionView.
public protocol DTCollectionViewManageable : AnyObject
{
    /// Collection view, that will be managed by DTCollectionViewManager. This property or `optionalCollectionView` property must be implemented in order for `DTCollectionViewManager` to work.
    var collectionView : UICollectionView! { get }
    
    /// Collection view, that will be managed by DTCollectionViewManager. This property or `collectionView` property must be implemented in order for `DTCollectionViewManager` to work.
    var optionalCollectionView: UICollectionView? { get }
}

/// Extension for `DTCollectionViewManageable` that provides default implementations for `collectionView` and `optionalCollectionView` properties. One of those properties must be implemented in `DTCollectionViewManageable` implementation.
public extension DTCollectionViewManageable {
    var collectionView: UICollectionView! { return nil }
    var optionalCollectionView: UICollectionView? { return nil }
}

private var DTCollectionViewManagerAssociatedKey = "DTCollectionView Manager Associated Key"

/// Default implementation for `DTCollectionViewManageable` protocol, that will inject `manager` property to any object, that declares itself `DTCollectionViewManageable`.
extension DTCollectionViewManageable
{
    /// Lazily instantiated `DTCollectionViewManager` instance. When your collection view is loaded, call mapping registration methods and `DTCollectionViewManager` will take over UICollectionView datasource and delegate.
    /// Any method, that is not implemented by `DTCollectionViewManager`, will be forwarded to delegate.
    /// If this property is accessed when UICollectionView is loaded, and DTCollectionViewManager is not configured yet, startManaging(withDelegate:_) method will automatically be called once to initialize DTCollectionViewManager.
    /// - SeeAlso: `startManaging(withDelegate:)`
    public var manager : DTCollectionViewManager {
        get {
            if let manager = objc_getAssociatedObject(self, &DTCollectionViewManagerAssociatedKey) as? DTCollectionViewManager {
                if !manager.isConfigured && (optionalCollectionView != nil || collectionView != nil) {
                    manager.startManaging(withDelegate: self)
                }
                return manager
            }
            let manager = DTCollectionViewManager()
            if  optionalCollectionView != nil || collectionView != nil {
                manager.startManaging(withDelegate: self)
            }
            objc_setAssociatedObject(self, &DTCollectionViewManagerAssociatedKey, manager, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return manager
        }
        set {
            objc_setAssociatedObject(self, &DTCollectionViewManagerAssociatedKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}


/// `DTCollectionViewManager` manages most of `UICollectionView` datasource and delegate methods and provides API for managing your data models in the collection view. Any method, that is not implemented by `DTCollectionViewManager`, will be forwarded to delegate.
/// - SeeAlso: `startManagingWithDelegate:`
open class DTCollectionViewManager {
    
    var collectionView : UICollectionView? {
        if let delegate = delegate as? DTCollectionViewManageable { return delegate.optionalCollectionView ?? delegate.collectionView }
        return nil
    }
    
    weak var delegate : AnyObject?
    
    /// Bool property, that will be true, after `startManagingWithDelegate` method is called on `DTCollectionViewManager`.
    open var isManagingCollectionView : Bool { collectionView != nil }
    
    ///  Factory for creating cells and reusable views for UICollectionView
    final lazy var viewFactory: CollectionViewFactory = {
        precondition(self.isManagingCollectionView, "Please call manager.startManagingWithDelegate(self) before calling any other DTCollectionViewManager methods")
        // swiftlint:disable:next force_unwrapping
        let factory = CollectionViewFactory(collectionView: self.collectionView!)
        factory.resetDelegates = { [weak self] in
            self?.collectionDataSource?.delegateWasReset()
            self?.collectionDelegate?.delegateWasReset()
            self?.collectionPrefetchDataSource?.delegateWasReset()
            
            #if os(iOS)
            self?.collectionDropDelegate?.delegateWasReset()
            self?.collectionDragDelegate?.delegateWasReset()
            #endif
        }
        factory.anomalyHandler = anomalyHandler
        return factory
    }()
    
    /// Implicitly unwrap storage property to `MemoryStorage`.
    /// - Warning: if storage is not MemoryStorage, will throw an exception.
    open var memoryStorage : MemoryStorage! {
        precondition(storage is MemoryStorage, "DTCollectionViewManager memoryStorage method should be called only if you are using MemoryStorage")
        return storage as? MemoryStorage
    }
    
    /// Anomaly handler, that handles reported by `DTCollectionViewManager` anomalies.
    open var anomalyHandler : DTCollectionViewManagerAnomalyHandler = .init()
    
    /// Storage, that holds your UICollectionView models. By default, it's `MemoryStorage` instance.
    /// - Note: When setting custom storage for this property, it will be automatically configured for using with UICollectionViewFlowLayout and it's delegate will be set to `DTCollectionViewManager` instance.
    /// - Note: Previous storage `delegate` property will be nilled out to avoid collisions.
    /// - SeeAlso: `MemoryStorage`, `CoreDataStorage`.
    open var storage : Storage {
        willSet {
            (storage as? BaseUpdateDeliveringStorage)?.delegate = nil
        }
        didSet {
            if let headerFooterCompatibleStorage = storage as? SupplementaryStorage {
                headerFooterCompatibleStorage.configureForCollectionViewFlowLayoutUsage()
            }
            (storage as? BaseUpdateDeliveringStorage)?.delegate = collectionViewUpdater
        }
    }
    
    /// Current storage, conditionally casted to `SupplementaryStorage` protocol.
    public var supplementaryStorage: SupplementaryStorage? {
        return storage as? SupplementaryStorage
    }
    
    /// Object, that is responsible for updating `UICollectionView`, when received update from `Storage`
    open var collectionViewUpdater : CollectionViewUpdater? {
        didSet {
            (storage as? BaseUpdateDeliveringStorage)?.delegate = collectionViewUpdater
            collectionViewUpdater?.didUpdateContent?(nil)
        }
    }
    
    /// Object, that is responsible for implementing `UICollectionViewDataSource` protocol
    open var collectionDataSource: DTCollectionViewDataSource? {
        didSet {
            collectionView?.dataSource = collectionDataSource
        }
    }
    
    /// Object, that is responsible for implementing `UICollectionViewDelegate` and `UICollectionViewDelegateFlowLayout` protocols
    open var collectionDelegate : DTCollectionViewDelegate? {
        didSet {
            collectionView?.delegate = collectionDelegate
        }
    }
    
    /// Object, responsible for implementing `UICollectionViewDataSourcePrefetching` protocol
    open var collectionPrefetchDataSource: DTCollectionViewPrefetchDataSource? {
        didSet {
            collectionView?.prefetchDataSource = collectionPrefetchDataSource
        }
    }
    
    #if os(iOS)

    /// Object, that is responsible for implementing `UICollectionViewDragDelegate` protocol
    open var collectionDragDelegate : DTCollectionViewDragDelegate? {
        didSet {
            collectionView?.dragDelegate = collectionDragDelegate
        }
    }

    /// Object, that is responsible for implementing `UICOllectionViewDropDelegate` protocol
    open var collectionDropDelegate : DTCollectionViewDropDelegate? {
        didSet {
            collectionView?.dropDelegate = collectionDropDelegate
        }
    }
    #endif
    
    /// Storage construction block, used by `DTCollectionViewManager` when it's created. Returns `MemoryStorage` by default.
    public static var defaultStorage: () -> Storage = { MemoryStorage() }
    
    /// Creates `DTCollectionViewManager`. Usually you don't need to call this method directly, as `manager` property on `DTCollectionViewManageable` instance is filled automatically. `DTCollectionViewManager.defaultStorage` closure is used to determine which `Storage` would be used by default.
    ///
    /// - Parameter storage: storage class to be used
    public init(storage: Storage = DTCollectionViewManager.defaultStorage()) {
        (storage as? SupplementaryStorage)?.configureForCollectionViewFlowLayoutUsage()
        self.storage = storage
    }
    
    /// If you access `manager` property when managed `UICollectionView` is already created(for example: viewDidLoad method), calling this method is not necessary.
    /// If for any reason, `UICollectionView` is created later, please call this method before modifying storage or registering cells/supplementary views.
    /// - Precondition: UICollectionView instance on `delegate` should not be nil.
    /// - Parameter delegate: Object, that has UICollectionView, that will be managed by `DTCollectionViewManager`.
    open func startManaging(withDelegate delegate : DTCollectionViewManageable)
    {
        guard !isConfigured else { return }
        guard let collectionView = delegate.collectionView ?? delegate.optionalCollectionView else {
            preconditionFailure("Call startManagingWithDelegate: method only when UICollectionView has been created")
        }
        self.delegate = delegate
        startManaging(with: collectionView)
    }
    
    @available(iOS 13.0, tvOS 13.0, *)
    /// Configures `UICollectionViewDiffableDataSource` to be used with `DTCollectionViewManager`.
    ///  Because `UICollectionViewDiffableDataSource` handles UICollectionView updates, `collectionViewUpdater` property on `DTCollectionViewManager` will be set to nil.
    /// - Parameter modelProvider: closure that provides `DTCollectionViewManager` models.
    /// This closure mirrors `cellProvider` property on `UICollectionViewDiffableDataSource`, but strips away collectionView, and asks for data model instead of a cell. Cell mapping is then executed in the same way as without diffable data sources.
    open func configureDiffableDataSource<SectionIdentifier, ItemIdentifier>(modelProvider: @escaping (IndexPath, ItemIdentifier) -> Any)
        -> UICollectionViewDiffableDataSource<SectionIdentifier, ItemIdentifier>
    {
        guard let collectionView = collectionView else {
            fatalError("Attempt to configure diffable datasource before collectionView have been initialized")
        }
        // UICollectionViewDiffableDataSource will update UICollectionView instead of `CollectionViewUpdater` object.
        collectionViewUpdater = nil
        
        // Cell is provided by `DTCollectionViewDataSource` without actually calling closure that is passed to `UICollectionViewDiffableDataSource`.
        let dataSource = DTCollectionViewDiffableDataSource<SectionIdentifier, ItemIdentifier>(
            collectionView: collectionView,
            viewFactory: viewFactory,
            manager: self,
            cellProvider: { _, _, _ in nil },
            modelProvider: modelProvider)
        storage = dataSource
        collectionView.dataSource = dataSource
        
        return dataSource
    }
    
    fileprivate var isConfigured = false
    
    fileprivate func startManaging(with collectionView: UICollectionView) {
        guard !isConfigured else { return }
        defer { isConfigured = true }
        collectionViewUpdater = CollectionViewUpdater(collectionView: collectionView)
        collectionDataSource = DTCollectionViewDataSource(delegate: delegate, collectionViewManager: self)
        collectionDelegate = DTCollectionViewDelegate(delegate: delegate, collectionViewManager: self)
        collectionPrefetchDataSource = DTCollectionViewPrefetchDataSource(delegate: delegate, collectionViewManager: self)
        
        #if os(iOS)
        collectionDragDelegate = DTCollectionViewDragDelegate(delegate: delegate, collectionViewManager: self)
        collectionDropDelegate = DTCollectionViewDropDelegate(delegate: delegate, collectionViewManager: self)
        #endif
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.eventVerificationDelay) { [weak self] in
            self?.verifyEventsCompatibility()
        }
    }
    
    /// Returns closure, that updates cell at provided indexPath.
    ///
    /// This is used by `coreDataUpdater` method and can be used to silently update a cell without animation.
    open func updateCellClosure() -> (IndexPath, Any) -> Void {
        return { [weak self] indexPath, model in
            self?.viewFactory.updateCellAt(indexPath, with: model)
        }
    }
    
    /// Updates visible cells, using `collectionView.indexPathsForVisibleItems`, and update block. This may be more efficient than running `reloadData`, if number of your data models does not change, and the change you want to reflect is completely within models state.
    ///
    /// - Parameter closure: closure to run for each cell after update has been completed.
    open func updateVisibleCells(_ closure: ((UICollectionViewCell) -> Void)? = nil) {
        (collectionView?.indexPathsForVisibleItems ?? []).forEach { indexPath in
            guard let model = storage.item(at: indexPath),
                let visibleCell = collectionView?.cellForItem(at: indexPath)
                else { return }
            updateCellClosure()(indexPath, model)
            closure?(visibleCell)
        }
    }
    
    /// Returns `CollectionViewUpdater`, configured to work with `CoreDataStorage` and `NSFetchedResultsController` updates.
    ///
    /// - Precondition: UICollectionView instance on `delegate` should not be nil.
    open func coreDataUpdater() -> CollectionViewUpdater {
        guard let collectionView = self.collectionView else {
            preconditionFailure("Call coreDataUpdater() method only when UICollectionView is created and passed to `DTCollectionViewManager` via startManaging(with:) method.")
        }
        return CollectionViewUpdater(collectionView: collectionView,
                                     reloadItem: updateCellClosure(),
                                     animateMoveAsDeleteAndInsert: true)
    }
    
    static var eventVerificationDelay : TimeInterval = 1
    
    func verifyItemEvent<Model>(for itemType: Model.Type, methodName: String) {
        switch itemType {
        case is UICollectionReusableView.Type:
            anomalyHandler.reportAnomaly(.modelEventCalledWithCellClass(modelType: String(describing: Model.self), methodName: methodName, subclassOf: "UICollectionReusableView"))
        case is UICollectionViewCell.Type:
            anomalyHandler.reportAnomaly(.modelEventCalledWithCellClass(modelType: String(describing: Model.self), methodName: methodName, subclassOf: "UICollectionViewCell"))
        default: ()
        }
    }
    
    func verifyViewEvent<T:ModelTransfer>(for viewType: T.Type, methodName: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.eventVerificationDelay) { [weak self] in
            if self?.viewFactory.mappings.filter({ $0.viewClass.isSubclass(of: viewType) }).count == 0 {
                self?.anomalyHandler.reportAnomaly(DTCollectionViewManagerAnomaly.unusedEventDetected(viewType: String(describing: T.self), methodName: methodName))
            }
        }
    }
    
    func verifyEventsCompatibility() {
        let flowLayoutMethodSignatures = [
            EventMethodSignature.sizeForItemAtIndexPath,
            .referenceSizeForHeaderInSection,
            .referenceSizeForFooterInSection,
            .insetForSectionAtIndex,
            .minimumLineSpacingForSectionAtIndex,
            .minimumInteritemSpacingForSectionAtIndex
        ].map { $0.rawValue }
        
        let unmappedFlowDelegateEvents = collectionDelegate?.unmappedReactions.filter { flowLayoutMethodSignatures.contains($0.methodSignature) } ?? []
        let mappedFlowDelegateEvents = viewFactory.mappings.reduce(into: []) { result, current in
            result.append(contentsOf: current.reactions.filter { flowLayoutMethodSignatures.contains($0.methodSignature) })
        }
        
        guard let _ = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout else {
            (unmappedFlowDelegateEvents + mappedFlowDelegateEvents).forEach { reaction in
                anomalyHandler.reportAnomaly(.flowDelegateLayoutMethodWithDifferentLayout(methodSignature: reaction.methodSignature))
            }
            return
        }
    }
}

/// All supported Objective-C method signatures.
///
/// Some of signatures are made up, so that we would be able to link them with event, however they don't stop "responds(to:)" method from returning true.
internal enum EventMethodSignature: String {
    /// UICollectionViewDataSource
    case configureCell = "collectionViewConfigureCell_imaginarySelector"
    case configureSupplementary = "collectionViewConfigureSupplementary_imaginarySelector"
    case canMoveItemAtIndexPath = "collectionView:canMoveItemAtIndexPath:"
    case moveItemAtIndexPathToIndexPath = "collectionView:moveItemAtIndexPath:toIndexPath:"
    case indexTitlesForCollectionView = "indexTitlesForCollectionView:"
    case indexPathForIndexTitleAtIndex = "collectionView:indexPathForIndexTitle:atIndex:"
    
    // UICollectionViewDelegate
    case shouldSelectItemAtIndexPath = "collectionView:shouldSelectItemAtIndexPath:"
    case didSelectItemAtIndexPath = "collectionView:didSelectItemAtIndexPath:"
    case shouldDeselectItemAtIndexPath = "collectionView:shouldDeselectItemAtIndexPath:"
    case didDeselectItemAtIndexPath = "collectionView:didDeselectItemAtIndexPath:"
    
    case shouldHighlightItemAtIndexPath = "collectionView:shouldHighlightItemAtIndexPath:"
    case didHighlightItemAtIndexPath = "collectionView:didHighlightItemAtIndexPath:"
    case didUnhighlightItemAtIndexPath = "collectionView:didUnhighlightItemAtIndexPath:"
    
    case willDisplayCellForItemAtIndexPath = "collectionView:willDisplayCell:forItemAtIndexPath:"
    case willDisplaySupplementaryViewForElementKindAtIndexPath = "collectionView:willDisplaySupplementaryView:forElementKind:atIndexPath:"
    case didEndDisplayingCellForItemAtIndexPath = "collectionView:didEndDisplayingCell:forItemAtIndexPath:"
    case didEndDisplayingSupplementaryViewForElementKindAtIndexPath = "collectionView:didEndDisplayingSupplementaryView:forElementOfKind:atIndexPath:"
    
    case shouldShowMenuForItemAtIndexPath = "collectionView:shouldShowMenuForItemAtIndexPath:"
    case canPerformActionForItemAtIndexPath = "collectionView:canPerformAction:forItemAtIndexPath:withSender:"
    case performActionForItemAtIndexPath = "collectionView:performAction:forItemAtIndexPath:withSender:"
    
    case transitionLayoutForOldLayoutNewLayout = "collectionView:transitionLayoutForOldLayout:newLayout:"
    case canFocusItemAtIndexPath = "collectionView:canFocusItemAtIndexPath:"
    case shouldUpdateFocusInContext = "collectionView:shouldUpdateFocusInContext:"
    case didUpdateFocusInContext = "collectionView:didUpdateFocusInContext:withAnimationCoordinator:"
    case indexPathForPreferredFocusedView = "indexPathForPreferredFocusedViewInCollectionView:"
    
    @available(iOS, deprecated: 15.0)
    case targetIndexPathForMoveFromItemAtTo = "collectionView:targetIndexPathForMoveFromItemAtIndexPath:toProposedIndexPath:"
    case targetContentOffsetForProposedContentOffset = "collectionView:targetContentOffsetForProposedContentOffset:"
    case shouldSpringLoadItem = "collectionView:shouldSpringLoadItemAtIndexPath:withContext:"
    
    case shouldBeginMultipleSelectionInteractionAtIndexPath = "collectionView:shouldBeginMultipleSelectionInteractionAtIndexPath:"
    case didBeginMultipleSelectionInteractionAtIndexPath = "collectionView:didBeginMultipleSelectionInteractionAtIndexPath:"
    case didEndMultipleSelectionInteraction = "collectionViewDidEndMultipleSelectionInteraction:"
    case contextMenuConfigurationForItemAtIndexPath = "collectionView:contextMenuConfigurationForItemAtIndexPath:point:"
    case previewForHighlightingContextMenu = "collectionView:previewForHighlightingContextMenuWithConfiguration:"
    case previewForDismissingContextMenu = "collectionView:previewForDismissingContextMenuWithConfiguration:"
    case canEditItemAtIndexPath = "collectionView:canEditItemAtIndexPath:"
    case selectionFollowsFocusForItemAtIndexPath = "collectionView:selectionFollowsFocusForItemAtIndexPath:"
    case targetIndexPathForMoveOfItemFromOriginalIndexPath = "collectionView:targetIndexPathForMoveOfItemFromOriginalIndexPath:atCurrentIndexPath:toProposedIndexPath:"
    case canPerformPrimaryActionForItemAtIndexPath = "collectionView:canPerformPrimaryActionForItemAtIndexPath:"
    case performPrimaryActionForItemAtIndexPath = "collectionView:performPrimaryActionForItemAtIndexPath:"
    
    // iOS 16 SDK
    case contextMenuConfigurationForItemsAtIndexPaths = "collectionView:contextMenuConfigurationForItemsAtIndexPaths:point:"
    case highlightPreviewForItemAtIndexPath = "collectionView:contextMenuConfiguration:highlightPreviewForItemAtIndexPath:"
    case dismissalPreviewForItemAtIndexPath = "collectionView:contextMenuConfiguration:dismissalPreviewForItemAtIndexPath:"
    
    // UICollectionViewDelegateFlowLayout
    case sizeForItemAtIndexPath = "collectionView:layout:sizeForItemAtIndexPath:"
    case referenceSizeForHeaderInSection = "collectionView:layout:referenceSizeForHeaderInSection:_imaginarySelector"
    case referenceSizeForFooterInSection = "collectionView:layout:referenceSizeForFooterInSection:_imaginarySelector"
    case insetForSectionAtIndex = "collectionView:layout:insetForSectionAtIndex:"
    case minimumLineSpacingForSectionAtIndex = "collectionView:layout:minimumLineSpacingForSectionAtIndex:"
    case minimumInteritemSpacingForSectionAtIndex = "collectionView:layout:minimumInteritemSpacingForSectionAtIndex:"
    
    // UICollectionViewDragDelegate
    
    case itemsForBeginningDragSessionAtIndexPath = "collectionView:itemsForBeginningDragSession:atIndexPath:"
    case itemsForAddingToDragSessionAtIndexPath = "collectionView:itemsForAddingToDragSession:atIndexPath:point:"
    case dragPreviewParametersForItemAtIndexPath = "collectionView:dragPreviewParametersForItemAtIndexPath:"
    case dragSessionWillBegin = "collectionView:dragSessionWillBegin:"
    case dragSessionDidEnd = "collectionView:dragSessionDidEnd:"
    case dragSessionAllowsMoveOperation = "collectionView:dragSessionAllowsMoveOperation:"
    case dragSessionIsRestrictedToDraggingApplication = "collectionView:dragSessionIsRestrictedToDraggingApplication:"
    
    // UICollectionViewDropDelegate
    
    case performDropWithCoordinator = "collectionView:performDropWithCoordinator:"
    case canHandleDropSession = "collectionView:canHandleDropSession:"
    case dropSessionDidEnter = "collectionView:dropSessionDidEnter:"
    case dropSessionDidUpdate = "collectionView:dropSessionDidUpdate:withDestinationIndexPath:"
    case dropSessionDidExit = "collectionView:dropSessionDidExit:"
    case dropSessionDidEnd = "collectionView:dropSessionDidEnd:"
    case dropPreviewParametersForItemAtIndexPath = "collectionView:dropPreviewParametersForItemAtIndexPath:"
    
    /// UICollectionViewDataSourcePrefetching
    case prefetchItemsAtIndexPaths = "collectionView:prefetchItemsAtIndexPaths:"
    case cancelPrefetchingForItemsAtIndexPaths = "collectionView:cancelPrefetchingForItemsAtIndexPaths:"
    
    // TVCollectionViewDelegateFullScreenLayout
    
    case willCenterCellAtIndexPath = "collectionView:layout:willCenterCellAtIndexPath:"
    case didCenterCellAtIndexPath = "collectionView:layout:didCenterCellAtIndexPath:"
}
