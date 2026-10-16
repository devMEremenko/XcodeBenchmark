//
//  TableViewController.swift
//  DTTableViewManager
//
//  Created by Denys Telezhkin on 12.07.15.
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
import UIKit
import DTModelStorage
import SwiftUI

/// Adopting this protocol will automatically inject `manager` property to your object, that lazily instantiates `DTTableViewManager` object.
/// Target is not required to be `UITableViewController`, and can be a regular UIViewController with UITableView, or any other view, that contains UITableView.
public protocol DTTableViewManageable : AnyObject
{
    /// Table view, that will be managed by DTTableViewManager. This property or `optionalTableView` property must be implemented in order for `DTTableViewManager` to work.
    var tableView : UITableView! { get }
    
    // Table view, that will be managed by DTTableViewManager. This property or `tableView` property must be implemented in order for `DTTableViewManager` to work.
    var optionalTableView: UITableView? { get }
}

/// Extension for `DTTableViewManageable` that provides default implementations for `tableView` and `optionalTableView` properties. One of those properties must be implemented in `DTTableViewManageable` implementation.
public extension DTTableViewManageable {
    var tableView: UITableView! { return nil }
    
    var optionalTableView: UITableView? { return nil }
}

/// This key is used to store `DTTableViewManager` instance on `DTTableViewManageable` class using object association.
private var DTTableViewManagerAssociatedKey = "DTTableViewManager Associated Key"

/// Default implementation for `DTTableViewManageable` protocol, that will inject `manager` property to any object, that declares itself `DTTableViewManageable`.
extension DTTableViewManageable
{
    /// Lazily instantiated `DTTableViewManager` instance. When your table view is loaded, call startManagingWithDelegate: method and `DTTableViewManager` will take over UITableView datasource and delegate. Any method, that is not implemented by `DTTableViewManager`, will be forwarded to delegate.
    /// If this property is accessed when UITableView is loaded, and DTTableViewManager is not configured yet, startManaging(withDelegate:_) method will automatically be called once to initialize DTTableViewManager.
    /// - SeeAlso: `startManagingWithDelegate:`
    public var manager : DTTableViewManager {
        get {
            if let manager = objc_getAssociatedObject(self, &DTTableViewManagerAssociatedKey) as? DTTableViewManager {
                if !manager.isConfigured && (tableView != nil || optionalTableView != nil) {
                    manager.startManaging(withDelegate: self)
                }
                return manager
            }
            let manager = DTTableViewManager()
            if tableView != nil || optionalTableView != nil {
                manager.startManaging(withDelegate: self)
            }
            objc_setAssociatedObject(self, &DTTableViewManagerAssociatedKey, manager, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return manager
        }
        set {
            objc_setAssociatedObject(self, &DTTableViewManagerAssociatedKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

/// `DTTableViewManager` manages many of `UITableView` datasource and delegate methods and provides API for managing your data models in the table. Any method, that is not implemented by `DTTableViewManager`, will be forwarded to delegate.
/// - SeeAlso: `startManagingWithDelegate:`
open class DTTableViewManager {
    
    /// Stores all configuration options for `DTTableViewManager`.
    /// - SeeAlso: `TableViewConfiguration`.
    open var configuration = TableViewConfiguration()
    
    /// Anomaly handler, that handles reported by `DTTableViewManager` anomalies.
    open var anomalyHandler : DTTableViewManagerAnomalyHandler = .init()
    
    /// Bool property, that will be true, after `startManagingWithDelegate` method is called on `DTTableViewManager`.
    open var isManagingTableView : Bool {
        return tableView != nil
    }
    
    ///  Factory for creating cells and views for UITableView
    final lazy var viewFactory: TableViewFactory = {
        precondition(isManagingTableView, "Received attempt to register views for UITableView, but UITableView is nil.")
        // swiftlint:disable:next force_unwrapping
        let factory = TableViewFactory(tableView: self.tableView!)
        factory.anomalyHandler = anomalyHandler
        factory.resetDelegates = { [weak self] in
            self?.tableDataSource?.delegateWasReset()
            self?.tableDelegate?.delegateWasReset()
            self?.tablePrefetchDataSource?.delegateWasReset()
            
            #if os(iOS)
            self?.tableDragDelegate?.delegateWasReset()
            // Enabling next line causes crash as of Xcode 12 beta 3: UITableView internal inconsistency: attempted to end ignoring drags more times than begin ignoring drags
            // Since currently drop delegate does not contain any mapped events, resetting this particular delegate is unnecessary.
            // However, if in the future drop delegate will have a mapped event, this needs some resolution, which currently I don't have.
//            self?.tableDropDelegate?.delegateWasReset()
            #endif
        }
        return factory
    }()
    
    /// Internal weak link to `UITableView`
    final var tableView : UITableView?
    {
        if let delegate = delegate as? DTTableViewManageable { return delegate.optionalTableView ?? delegate.tableView }
        return nil
    }
    
    /// `DTTableViewManageable` delegate.
    final weak var delegate : AnyObject?
    
    /// Implicitly unwrap storage property to `MemoryStorage`.
    /// - Warning: if storage is not MemoryStorage, will throw an exception.
    open var memoryStorage : MemoryStorage!
    {
        guard let storage = storage as? MemoryStorage else {
            assertionFailure("DTTableViewManager memoryStorage method should be called only if you are using MemoryStorage")
            return nil
        }
        return storage
    }
    
    /// Storage, that holds your UITableView models. By default, it's `MemoryStorage` instance.
    /// - Note: When setting custom storage for this property, it will be automatically configured for using with UITableView and it's delegate will be set to `DTTableViewManager` instance.
    /// - Note: Previous storage `delegate` property will be nilled out to avoid collisions.
    /// - SeeAlso: `MemoryStorage`, `CoreDataStorage`, `RealmStorage`.
    open var storage : Storage {
        willSet {
            (storage as? BaseUpdateDeliveringStorage)?.delegate = nil
        }
        didSet {
            if let headerFooterCompatibleStorage = storage as? SupplementaryStorage {
                headerFooterCompatibleStorage.configureForTableViewUsage()
            }
            (storage as? BaseUpdateDeliveringStorage)?.delegate = tableViewUpdater
        }
    }
    
    /// Current storage, conditionally casted to `SupplementaryStorage` protocol.
    public var supplementaryStorage: SupplementaryStorage? {
        return storage as? SupplementaryStorage
    }
    
    /// Object, that is responsible for updating `UITableView`, when received update from `Storage`
    open var tableViewUpdater : TableViewUpdater? {
        didSet {
            (storage as? BaseUpdateDeliveringStorage)?.delegate = tableViewUpdater
            tableViewUpdater?.didUpdateContent?(nil)
        }
    }
    
    /// Object, that is responsible for implementing `UITableViewDelegate` protocol.
    open var tableDelegate: DTTableViewDelegate? {
        didSet {
            tableView?.delegate = tableDelegate
        }
    }
    
    /// Object, that is responsible for implementing `UITableViewDataSource` protocol.
    open var tableDataSource: DTTableViewDataSource? {
        didSet {
            tableView?.dataSource = tableDataSource
        }
    }
    
    /// Object, responsible for implementing `UITableViewDataSourcePrefetching` protocol
    open var tablePrefetchDataSource: DTTableViewPrefetchDataSource? {
        didSet {
            tableView?.prefetchDataSource = tablePrefetchDataSource
        }
    }
    
    #if os(iOS)
    
    /// Object, that is responsible for implementing `UITableViewDragDelegate` protocol
    open var tableDragDelegate : DTTableViewDragDelegate? {
        didSet {
            tableView?.dragDelegate = tableDragDelegate
        }
    }

    /// Object, that is responsible for implementing `UITableViewDropDelegate` protocol
    open var tableDropDelegate : DTTableViewDropDelegate? {
        didSet {
            tableView?.dropDelegate = tableDropDelegate
        }
    }
    #endif
    
    /// Storage construction block, used by `DTTableViewManager` when it's created. Returns `MemoryStorage` by default.
    public static var defaultStorage: () -> Storage = { MemoryStorage() }
    
    /// Creates `DTTableViewManager`. Usually you don't need to call this method directly, as `manager` property on `DTTableViewManageable` instance is filled automatically. `DTTableViewManager.defaultStorage` closure is used to determine which `Storage` would be used by default.
    ///
    /// - Parameter storage: storage class to be used
    public init(storage: Storage = DTTableViewManager.defaultStorage()) {
        (storage as? SupplementaryStorage)?.configureForTableViewUsage()
        self.storage = storage
    }
    
    @available(iOS 13.0, tvOS 13.0, *)
    /// Configures `UITableViewDiffableDataSource` to be used with `DTTableViewManager`.
    ///  Because `UITableViewDiffableDataSource` handles UITableView updates, `tableViewUpdater` property on `DTTableViewManager` will be set to nil.
    /// - Parameter modelProvider: closure that provides `DTTableViewManager` models.
    /// This closure mirrors `cellProvider` property on `UITableViewDiffableDataSource`, but strips away tableView, and asks for data model instead of a cell. Cell mapping is then executed in the same way as without diffable data sources.
    open func configureDiffableDataSource<SectionIdentifier, ItemIdentifier>(modelProvider: @escaping (IndexPath, ItemIdentifier) -> Any)
        -> UITableViewDiffableDataSource<SectionIdentifier, ItemIdentifier>
    {
        guard let tableView = tableView else {
            fatalError("Attempt to configure diffable datasource before tableView have been initialized")
        }
        // UITableViewDiffableDataSource will update UITableView instead of `TableViewUpdater` object.
        tableViewUpdater = nil
        
        // Cell is provided by `DTTableViewDataSource` without actually calling closure that is passed to `UITableViewDiffableDataSource`.
        let dataSource = DTTableViewDiffableDataSource<SectionIdentifier, ItemIdentifier>(
            tableView: tableView,
            viewFactory: viewFactory,
            manager: self,
            cellProvider: { _, _, _ in
            nil
            }, modelProvider: modelProvider)
        storage = dataSource
        tableView.dataSource = dataSource
        
        return dataSource
    }
    
    /// If you access `manager` property when managed `UITableView` is already created(for example: viewDidLoad method), calling this method is not necessary.
    /// If for any reason, `UITableView` is created later, please call this method before modifying storage or registering cells/supplementary views.
    /// - Precondition: UITableView instance on `delegate` should not be nil.
    /// - Note: If delegate is `DTViewModelMappingCustomizable`, it will also be used to determine which view-model mapping should be used by table view factory.
    open func startManaging(withDelegate delegate : DTTableViewManageable)
    {
        guard !isConfigured else { return }
        guard let tableView = delegate.optionalTableView ?? delegate.tableView else {
            preconditionFailure("Call startManagingWithDelegate: method only when UITableView has been created")
        }
        self.delegate = delegate
        startManaging(with: tableView)
    }
    
    fileprivate var isConfigured = false
    
    private func startManaging(with tableView: UITableView) {
        guard !isConfigured else { return }
        defer { isConfigured = true }
        tableViewUpdater = TableViewUpdater(tableView: tableView)
        tableDelegate = DTTableViewDelegate(delegate: delegate, tableViewManager: self)
        tableDataSource = DTTableViewDataSource(delegate: delegate, tableViewManager: self)
        tablePrefetchDataSource = DTTableViewPrefetchDataSource(delegate: delegate, tableViewManager: self)
        #if os(iOS)
        tableDragDelegate = DTTableViewDragDelegate(delegate: delegate, tableViewManager: self)
        tableDropDelegate = DTTableViewDropDelegate(delegate: delegate, tableViewManager: self)
        #endif
    }
    
    /// Returns closure, that updates cell at provided indexPath. 
    ///
    /// This is used by `coreDataUpdater` method and can be used to silently update a cell without reload row animation.
    open func updateCellClosure() -> (IndexPath, Any) -> Void {
        return { [weak self] indexPath, model in
            self?.viewFactory.updateCellAt(indexPath, with: model)
        }
    }
    
    
    /// Updates visible cells, using `tableView.indexPathsForVisibleRows`, and update block. This may be more efficient than running `reloadData`, if number of your data models does not change, and the change you want to reflect is completely within models state.
    ///
    /// - Parameter closure: closure to run for each cell after update has been completed.
    open func updateVisibleCells(_ closure: ((UITableViewCell) -> Void)? = nil) {
        (tableView?.indexPathsForVisibleRows ?? []).forEach { indexPath in
            guard let model = storage.item(at: indexPath),
                let visibleCell = tableView?.cellForRow(at: indexPath)
            else { return }
            updateCellClosure()(indexPath, model)
            closure?(visibleCell)
        }
    }
    
    /// Returns `TableViewUpdater`, configured to work with `CoreDataStorage` and `NSFetchedResultsController` updates.
    /// 
    /// - Precondition: UITableView instance on `delegate` should not be nil.
    open func coreDataUpdater() -> TableViewUpdater {
        guard let tableView = tableView else {
            preconditionFailure("Call coreDataUpdater() method only when UITableView is created and passed to `DTTableViewManager` via startManaging(with:) method.")
        }
        return TableViewUpdater(tableView: tableView,
                                reloadRow: updateCellClosure(),
                                animateMoveAsDeleteAndInsert: true)
    }
    
    func verifyItemEvent<Model>(for itemType: Model.Type, eventMethod: String) {
        switch itemType {
        case is UICollectionReusableView.Type:
            anomalyHandler.reportAnomaly(.modelEventCalledWithCellClass(modelType: String(describing: Model.self), methodName: eventMethod, subclassOf: "UICollectionReusableView"))
        case is UITableViewCell.Type:
            anomalyHandler.reportAnomaly(.modelEventCalledWithCellClass(modelType: String(describing: Model.self), methodName: eventMethod, subclassOf: "UITableViewCell"))
        case is UITableViewHeaderFooterView.Type: anomalyHandler.reportAnomaly(.modelEventCalledWithCellClass(modelType: String(describing: Model.self), methodName: eventMethod, subclassOf: "UITableViewHeaderFooterView"))
        default: ()
        }
    }
    
    func verifyViewEvent<View:ModelTransfer>(for viewType: View.Type, methodName: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            if self?.viewFactory.mappings.filter({ $0.viewClass.isSubclass(of: viewType) }).count == 0 {
                self?.anomalyHandler.reportAnomaly(DTTableViewManagerAnomaly.unusedEventDetected(viewType: String(describing: View.self), methodName: methodName))
            }
        }
    }
}

// MARK: - Method signatures
/// All supported Objective-C method signatures.
///
/// Some of signatures are made up, so that we would be able to link them with event, however they don't stop "responds(to:)" method from returning true.
internal enum EventMethodSignature: String {
    /// UITableViewDataSource
    case configureCell = "tableViewConfigureCell_imaginarySelector"
    case configureHeader = "tableViewConfigureHeader_imaginarySelector"
    case configureFooter = "tableViewConfigureFooter_imaginarySelector"
    case commitEditingStyleForRowAtIndexPath = "tableView:commitEditingStyle:forRowAtIndexPath:"
    case canEditRowAtIndexPath = "tableView:canEditRowAtIndexPath:"
    case canMoveRowAtIndexPath = "tableView:canMoveRowAtIndexPath:"
    case sectionIndexTitlesForTableView = "sectionIndexTitlesForTableView:"
    case sectionForSectionIndexTitleAtIndex = "tableView:sectionForSectionIndexTitle:atIndex:"
    case moveRowAtIndexPathToIndexPath = "tableView:moveRowAtIndexPath:toIndexPath:"
    
    /// UITableViewDelegate
    case heightForRowAtIndexPath = "tableView:heightForRowAtIndexPath:"
    case estimatedHeightForRowAtIndexPath = "tableView:estimatedHeightForRowAtIndexPath:"
    case indentationLevelForRowAtIndexPath = "tableView:indentationLevelForRowAtIndexPath:"
    case willDisplayCellForRowAtIndexPath = "tableView:willDisplayCell:forRowAtIndexPath:"
    
    case editActionsForRowAtIndexPath = "tableView:editActionsForRowAtIndexPath:"
    case accessoryButtonTappedForRowAtIndexPath = "tableView:accessoryButtonTappedForRowWithIndexPath:"
    
    case willSelectRowAtIndexPath = "tableView:willSelectRowAtIndexPath:"
    case didSelectRowAtIndexPath = "tableView:didSelectRowAtIndexPath:"
    case willDeselectRowAtIndexPath = "tableView:willDeselectRowAtIndexPath:"
    case didDeselectRowAtIndexPath = "tableView:didDeselectRowAtIndexPath:"
    
    case heightForHeaderInSection = "tableView:heightForHeaderInSection:"
    case estimatedHeightForHeaderInSection = "tableView:estimatedHeightForHeaderInSection:"
    case heightForFooterInSection = "tableView:heightForFooterInSection:"
    case estimatedHeightForFooterInSection = "tableView:estimatedHeightForFooterInSection:"
    case willDisplayHeaderForSection = "tableView:willDisplayHeaderView:forSection:"
    case willDisplayFooterForSection = "tableView:willDisplayFooterView:forSection:"
    
    case willBeginEditingRowAtIndexPath = "tableView:willBeginEditingRowAtIndexPath:"
    case didEndEditingRowAtIndexPath = "tableView:didEndEditingRowAtIndexPath:"
    case editingStyleForRowAtIndexPath = "tableView:editingStyleForRowAtIndexPath:"
    case titleForDeleteButtonForRowAtIndexPath = "tableView:titleForDeleteConfirmationButtonForRowAtIndexPath:"
    case shouldIndentWhileEditingRowAtIndexPath = "tableView:shouldIndentWhileEditingRowAtIndexPath:"
    
    case didEndDisplayingCellForRowAtIndexPath = "tableView:didEndDisplayingCell:forRowAtIndexPath:"
    case didEndDisplayingHeaderViewForSection = "tableView:didEndDisplayingHeaderView:forSection:"
    case didEndDisplayingFooterViewForSection = "tableView:didEndDisplayingFooterView:forSection:"
    
    case shouldShowMenuForRowAtIndexPath = "tableView:shouldShowMenuForRowAtIndexPath:"
    case canPerformActionForRowAtIndexPath = "tableView:canPerformAction:forRowAtIndexPath:withSender:"
    case performActionForRowAtIndexPath = "tableView:performAction:forRowAtIndexPath:withSender:"
    
    case shouldHighlightRowAtIndexPath = "tableView:shouldHighlightRowAtIndexPath:"
    case didHighlightRowAtIndexPath = "tableView:didHighlightRowAtIndexPath:"
    case didUnhighlightRowAtIndexPath = "tableView:didUnhighlightRowAtIndexPath:"
    
    case canFocusRowAtIndexPath = "tableView:canFocusRowAtIndexPath:"
    
    case leadingSwipeActionsConfigurationForRowAtIndexPath = "tableView:leadingSwipeActionsConfigurationForRowAtIndexPath:"
    case trailingSwipeActionsConfigurationForRowAtIndexPath = "tableView:trailingSwipeActionsConfigurationForRowAtIndexPath:"
    case targetIndexPathForMoveFromRowAtIndexPath = "tableView:targetIndexPathForMoveFromRowAtIndexPath:toProposedIndexPath:"
    case shouldUpdateFocusInContext = "tableView:shouldUpdateFocusInContext:"
    case didUpdateFocusInContextWithAnimationCoordinator = "tableView:didUpdateFocusInContext:withAnimationCoordinator:"
    case indexPathForPreferredFocusedViewInTableView = "indexPathForPreferredFocusedViewInTableView:"
    case shouldSpringLoadRowAtIndexPathWithContext = "tableView:shouldSpringLoadRowAtIndexPath:withContext:"
    
    case shouldBeginMultipleSelectionInteractionAtIndexPath = "tableView:shouldBeginMultipleSelectionInteractionAtIndexPath:"
    case didBeginMultipleSelectionInteractionAtIndexPath = "tableView:didBeginMultipleSelectionInteractionAtIndexPath:"
    case didEndMultipleSelectionInteraction = "tableViewDidEndMultipleSelectionInteraction:"
    case contextMenuConfigurationForRowAtIndexPath = "tableView:contextMenuConfigurationForRowAtIndexPath:point:"
    case previewForHighlightingContextMenu = "tableView:previewForHighlightingContextMenuWithConfiguration:"
    case previewForDismissingContextMenu = "tableView:previewForDismissingContextMenuWithConfiguration:"
    case selectionFollowsFocusForRowAtIndexPath = "tableView:selectionFollowsFocusForRowAtIndexPath:"
    case canPerformPrimaryActionForRowAtIndexPath = "tableView:canPerformPrimaryActionForRowAtIndexPath:"
    case performPrimaryActionForRowAtIndexPath = "tableView:performPrimaryActionForRowAtIndexPath:"
    
    /// UITableViewDragDelegate
    case itemsForBeginningDragSession = "tableView:itemsForBeginningDragSession:atIndexPath:"
    case itemsForAddingToDragSession = "tableView:itemsForAddingToDragSession:atIndexPath:point:"
    case dragPreviewParametersForRowAtIndexPath = "tableView:dragPreviewParametersForRowAtIndexPath:"
    case dragSessionWillBegin = "tableView:dragSessionWillBegin:"
    case dragSessionDidEnd = "tableView:dragSessionDidEnd:"
    case dragSessionAllowsMoveOperation = "tableView:dragSessionAllowsMoveOperation:"
    case dragSessionIsRestrictedToDraggingApplication = "tableView:dragSessionIsRestrictedToDraggingApplication:"
    
    /// UITableViewDropDelegate
    case performDropWithCoordinator = "tableView:performDropWithCoordinator:"
    case canHandleDropSession = "tableView:canHandleDropSession:"
    case dropSessionDidEnter = "tableView:dropSessionDidEnter:"
    case dropSessionDidUpdateWithDestinationIndexPath = "tableView:dropSessionDidUpdate:withDestinationIndexPath:"
    case dropSessionDidExit = "tableView:dropSessionDidExit:"
    case dropSessionDidEnd = "tableView:dropSessionDidEnd:"
    case dropPreviewParametersForRowAtIndexPath = "tableView:dropPreviewParametersForRowAtIndexPath:"
    
    /// UITableViewDataSourcePrefetching
    case prefetchRowsAtIndexPaths = "tableView:prefetchRowsAtIndexPaths:"
    case cancelPrefetchingForRowsAtIndexPaths = "tableView:cancelPrefetchingForRowsAtIndexPaths:"
}
