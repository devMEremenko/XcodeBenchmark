//
//  MemoryStorage.swift
//  DTModelStorage
//
//  Created by Denys Telezhkin on 10.07.15.
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

/// `MemoryStorageAnomaly` represents various errors and unwanted behaviors that can happen when using `MemoryStorage` class.
/// - SeeAlso: `DTTableViewManagerAnomaly`, `DTCollectionViewManagerAnomaly`
public enum MemoryStorageAnomaly: Equatable, CustomStringConvertible, CustomDebugStringConvertible {
    
    /// When inserting item to `indexPath`, there were only `countOfElementsInSection` items in section
    case insertionIndexPathTooBig(indexPath: IndexPath, countOfElementsInSection: Int)
    
    /// When inserting batch of items, number of items and number of indexPaths was different
    case batchInsertionItemCountMismatch(itemsCount: Int, indexPathsCount: Int)
    
    /// Attempt to replace item, that is not found in storage
    case replaceItemFailedItemNotFound(itemDescription: String)
    
    /// Attempt to remove item, that is not found in storage
    case removeItemFailedItemNotFound(itemDescription: String)
    
    /// Attempt to move item, that is not found in storage
    case moveItemFailedItemNotFound(indexPath: IndexPath)
    
    /// Attempt to move item to too big `indexPath`.
    case moveItemFailedIndexPathTooBig(indexPath: IndexPath, countOfElementsInSection: Int)
    
    /// Inconsistent indexPaths when moving item from `sourceIndexPath` to `destinationIndexPath`.
    case moveItemFailedInvalidIndexPaths(sourceIndexPath: IndexPath, destinationIndexPath: IndexPath, sourceElementsInSection: Int, destinationElementsInSection: Int)
    
    /// Debug information for `MemoryStorageAnomaly`.
    public var debugDescription: String {
        switch self {
        case .insertionIndexPathTooBig(indexPath: let indexPath, countOfElementsInSection: let count):
            return "⚠️ [MemoryStorage] Failed to insert item into IndexPath: \(indexPath), count of elements in the section: \(count)"
        case .batchInsertionItemCountMismatch(itemsCount: let itemsCount, indexPathsCount: let indexPathsCount):
            return "⚠️ [MemoryStorage] Failed to insert batch of items, items count: \(itemsCount), indexPaths count: \(indexPathsCount)"
        case .replaceItemFailedItemNotFound(itemDescription:let description):
            return "⚠️ [MemoryStorage] Failed to find item for replacement: \(description)"
        case .removeItemFailedItemNotFound(itemDescription: let description):
            return "⚠️ [MemoryStorage] Failed to find item for removal: \(description)"
        case .moveItemFailedItemNotFound(indexPath: let indexPath):
            return "⚠️ [MemoryStorage] Failed to find item for moving at indexPath: \(indexPath)"
        case .moveItemFailedIndexPathTooBig(indexPath: let indexPath, countOfElementsInSection: let count):
            return "⚠️ [MemoryStorage] Failed to move item, destination indexPath is too big: \(indexPath), number of items in section after removing source item: \(count)"
        case .moveItemFailedInvalidIndexPaths(sourceIndexPath: let source, destinationIndexPath: let destination, sourceElementsInSection: let sourceCount, destinationElementsInSection: let destinationCount):
            return "⚠️ [MemoryStorage] Failed to move item, sourceIndexPath: \(source), destination indexPath: \(destination), number of items in source section: \(sourceCount), number of items in destination section after removing source item: \(destinationCount)"
        }
    }
    
    /// Short description for `MemoryStorageAnomaly`. Useful for sending to analytics, which might have character limit.
    public var description: String {
        switch self {
        case .insertionIndexPathTooBig(indexPath: let indexPath, countOfElementsInSection: let count): return "MemoryStorageAnomaly.insertionIndexPathTooBig(\(indexPath), \(count))"
        case .batchInsertionItemCountMismatch(itemsCount: let itemsCount, indexPathsCount: let indexPathsCount): return "MemoryStorageAnomaly.batchInsertionItemCountMismatch(\(itemsCount), \(indexPathsCount))"
        case .replaceItemFailedItemNotFound(itemDescription: let itemDescription): return "MemoryStorageAnomaly.replaceItemFailedItemNotFound(\(itemDescription))"
        case .removeItemFailedItemNotFound(itemDescription: let itemDescription): return "MemoryStorageAnomaly.removeItemFailedItemNotFound(\(itemDescription))"
        case .moveItemFailedItemNotFound(indexPath: let indexPath): return "MemoryStorageAnomaly.moveItemFailedItemNotFound(\(indexPath))"
        case .moveItemFailedIndexPathTooBig(indexPath: let indexPath, countOfElementsInSection: let count): return "MemoryStorageAnomaly.moveItemFailedIndexPathTooBig(\(indexPath), \(count))"
        case .moveItemFailedInvalidIndexPaths(sourceIndexPath: let source, destinationIndexPath: let destination, sourceElementsInSection: let sourceCount, destinationElementsInSection: let destinationCount):
            return "MemoryStorageAnomaly.moveItemFailedInvalidIndexPaths(\(source), \(destination), \(sourceCount), \(destinationCount))"
        }
    }
}

/// `MemoryStorageAnomalyHandler` handles anomalies from `MemoryStorage`.
open class MemoryStorageAnomalyHandler : AnomalyHandler {
    
    /// Default action to perform when anomaly is detected. Prints debugDescription of anomaly by default.
    public static var defaultAction : (MemoryStorageAnomaly) -> Void = {
        #if DEBUG
            print($0.debugDescription)
        #endif
    }
    
    /// Action to perform when anomaly is detected. Defaults to `defaultAction`.
    open var anomalyAction: (MemoryStorageAnomaly) -> Void = MemoryStorageAnomalyHandler.defaultAction
    
    /// Creates `MemoryStorageAnomalyHandler`.
    public init() {}
}

/// This struct contains error types that can be thrown for various MemoryStorage errors
public enum MemoryStorageError: LocalizedError
{
    /// Errors that can happen when inserting items into memory storage - `insertItem(_:to:)` method
    public enum InsertionReason
    {
        case indexPathTooBig(IndexPath)
    }
    
    /// Errors that can happen when replacing item in memory storage - `replaceItem(_:with:)` method
    public enum SearchReason
    {
        case itemNotFound(item: Any)
        
        var localizedDescription: String {
            guard case let SearchReason.itemNotFound(item: item) = self else {
                return ""
            }
            return "Failed to find \(item) in MemoryStorage"
        }
    }
    
    case insertionFailed(reason: InsertionReason)
    case searchFailed(reason: SearchReason)
    
    /// Description of error 
    public var localizedDescription: String {
        switch self {
        case .insertionFailed(reason: _):
            return "IndexPath provided was bigger then existing section or item"
        case .searchFailed(reason: let reason):
            return reason.localizedDescription
        }
    }
}

/// Storage of models in memory.
///
/// `MemoryStorage` stores data models using array of `SectionModel` instances. It has various methods for changing storage contents - add, remove, insert, replace e.t.c.
/// - Note: It also notifies it's delegate about underlying changes so that delegate can update interface accordingly
/// - SeeAlso: `SectionModel`
open class MemoryStorage: BaseUpdateDeliveringStorage, Storage, SectionLocationIdentifyable
{
    /// When enabled, datasource updates are not applied immediately and saved inside `StorageUpdate` `enqueuedDatasourceUpdates` property.
    /// Call `StorageUpdate.applyDeferredDatasourceUpdates` method to apply all deferred changes.
    /// Defaults to `true`.
    /// - SeeAlso: https://github.com/DenTelezhkin/DTCollectionViewManager/issues/27
    open var defersDatasourceUpdates: Bool = true

    /// Anomaly handler, that handles reported by `MemoryStorage` anomalies.
    open var anomalyHandler : MemoryStorageAnomalyHandler = .init()

    /// sections of MemoryStorage
    open var sections: [Section] = [SectionModel]() {
        didSet {
            sections.forEach {
                ($0 as? SectionModel)?.sectionLocationDelegate = self
            }
        }
    }
    
    /// Returns number of sections in storage
    open func numberOfSections() -> Int {
        return sections.count
    }
    
    /// Returns number of items in a given section
    /// - Parameter section: given section
    open func numberOfItems(inSection section: Int) -> Int {
        guard sections.count > section else { return 0 }
        return sections[section].numberOfItems
    }
    
    func performDatasourceUpdate(_ block: @escaping (StorageUpdate) throws -> Void) {
        if defersDatasourceUpdates {
            currentUpdate?.enqueueDatasourceUpdate(block)
        } else {
            if let update = currentUpdate {
                try? block(update)
            }
        }
    }
    
    /// Returns index of `section` or nil, if section is now found
    open func sectionIndex(for section: Section) -> Int? {
        return sections.firstIndex(where: {
            return ($0 as? SectionModel) === (section as? SectionModel)
        })
    }
    
    /// Returns total number of items contained in all `MemoryStorage` sections
    ///
    /// - Complexity: O(n) where n - number of sections
    open var totalNumberOfItems: Int {
        return sections.reduce(0) { sum, section in
            return sum + section.numberOfItems
        }
    }
    
    /// Returns item at `indexPath` or nil, if it is not found.
    open func item(at indexPath: IndexPath) -> Any? {
        guard indexPath.section < sections.count else { return nil }
        guard indexPath.item < sections[indexPath.section].numberOfItems else { return nil }
        return sections[indexPath.section].item(at: indexPath.item)
    }
    
    /// Sets `items` for section at `index`.
    /// 
    /// - Note: This will reload UI after updating.
    open func setItems<T>(_ items: [T], forSection index: Int = 0)
    {
        let section = self.getValidSection(index, collectChangesIn: nil)
        section.items.removeAll(keepingCapacity: false)
        section.items = items.map { $0 }
        self.delegate?.storageNeedsReloading()
    }
    
    /// Sets `items` for sections in memory storage. This method creates all required sections, if necessary.
    ///
    /// - Note: This will reload UI after updating.
    open func setItemsForAllSections<T>(_ items: [[T]]) {
        sections.removeAll()
        for (index, array) in items.enumerated() {
            let section = getValidSection(index, collectChangesIn: nil)
            section.items.removeAll()
            section.items = array.map { $0 }
        }
        delegate?.storageNeedsReloading()
    }
    
    /// Sets `section` for `index`. This will reload UI after updating
    ///
    /// - Parameter section: SectionModel to set
    /// - Parameter index: index of section
    open func setSection(_ section: SectionModel, forSection index: Int)
    {
        _ = self.getValidSection(index, collectChangesIn: nil)
        sections.replaceSubrange(index...index, with: [section as Section])
        delegate?.storageNeedsReloading()
    }
    
    /// Inserts `section` at `sectionIndex`.
    ///
    /// - Parameter section: section to insert
    /// - Parameter sectionIndex: index of section to insert.
    /// - Discussion: this method is assumed to be used, when you need to insert section with items and supplementaries in one batch operation. If you need to simply add items, use `addItems` or `setItems` instead.
    /// - Note: If `sectionIndex` is larger than number of sections, method does nothing.
    open func insertSection(_ section: SectionModel, atIndex sectionIndex: Int) {
        guard sectionIndex <= sections.count else { return }
        startUpdate()
        performDatasourceUpdate { [weak self] update in
            self?.sections.insert(section, at: sectionIndex)
            update.sectionChanges.append((.insert, [sectionIndex]))
            for item in 0..<section.numberOfItems {
                update.objectChanges.append((.insert, [IndexPath(item: item, section: sectionIndex)]))
            }
        }
        finishUpdate()
    }
    
    /// Adds `items` to section with section `index`.
    ///
    /// This method creates all sections prior to `index`, unless they are already created.
    open func addItems<T>(_ items: [T], toSection index: Int = 0)
    {
        startUpdate()
        performDatasourceUpdate { [weak self] update in
            let section = self?.getValidSection(index, collectChangesIn: update)
            
            for item in items {
                let numberOfItems = section?.numberOfItems ?? 0
                section?.items.append(item)
                update.objectChanges.append((.insert, [IndexPath(item: numberOfItems, section: index)]))
            }
        }
        finishUpdate()
    }
    
    /// Adds `item` to section with section `index`.
    ///
    /// - Parameter item: item to add
    /// - Parameter toSection: index of section to add item
    open func addItem<T>(_ item: T, toSection index: Int = 0)
    {
        startUpdate()
        performDatasourceUpdate { [weak self] update in
            let section = self?.getValidSection(index, collectChangesIn: update)
            let numberOfItems = section?.numberOfItems ?? 0
            section?.items.append(item)
            update.objectChanges.append((.insert, [IndexPath(item: numberOfItems, section: index)]))
        }
        finishUpdate()
    }
    
    /// Inserts `item` to `indexPath`.
    ///
    /// This method creates all sections prior to indexPath.section, unless they are already created.
    /// - Throws: if indexPath is too big, will throw MemoryStorageErrors.Insertion.IndexPathTooBig
    open func insertItem<T>(_ item: T, to indexPath: IndexPath) throws
    {
        startUpdate()
        performDatasourceUpdate { [weak self] update in
            let section = self?.getValidSection(indexPath.section, collectChangesIn: update)
            
            guard (section?.items.count ?? 0) >= indexPath.item else {
                self?.anomalyHandler.reportAnomaly(MemoryStorageAnomaly.insertionIndexPathTooBig(indexPath: indexPath, countOfElementsInSection: section?.items.count ?? 0))
                throw MemoryStorageError.insertionFailed(reason: .indexPathTooBig(indexPath))
            }
            
            section?.items.insert(item, at: indexPath.item)
            update.objectChanges.append((.insert, [indexPath]))
        }
        finishUpdate()
    }
    
    /// Inserts `items` to `indexPaths`
    ///
    /// This method creates sections prior to maximum indexPath.section in `indexPaths`, unless they are already created.
    /// - Throws: if items.count is different from indexPaths.count, will throw MemoryStorageErrors.BatchInsertion.ItemsCountMismatch
    open func insertItems<T>(_ items: [T], to indexPaths: [IndexPath]) throws
    {
        if items.count != indexPaths.count {
            anomalyHandler.reportAnomaly(.batchInsertionItemCountMismatch(itemsCount: items.count, indexPathsCount: indexPaths.count))
            return
        }
        if defersDatasourceUpdates {
            performDatasourceUpdate { [weak self] update in
                indexPaths.enumerated().forEach { (arg) in
                    let (itemIndex, indexPath) = arg
                    let section = self?.getValidSection(indexPath.section, collectChangesIn: update)
                    guard (section?.items.count ?? 0) >= indexPath.item else {
                        return
                    }
                    section?.items.insert(items[itemIndex], at: indexPath.item)
                    update.objectChanges.append((.insert, [indexPath]))
                }
            }
        } else {
            performUpdates {
                indexPaths.enumerated().forEach { (arg) in
                    let (itemIndex, indexPath) = arg
                    let section = getValidSection(indexPath.section, collectChangesIn: currentUpdate)
                    guard section.items.count >= indexPath.item else {
                        return
                    }
                    section.items.insert(items[itemIndex], at: indexPath.item)
                    currentUpdate?.objectChanges.append((.insert, [indexPath]))
                }
            }
        }
    }
    
    /// Reloads `item`.
    open func reloadItem<T: Equatable>(_ item: T)
    {
        startUpdate()
        performDatasourceUpdate { [weak self] update in
            if let indexPath = self?.indexPath(forItem: item) {
                update.objectChanges.append((.update, [indexPath]))
                update.updatedObjects[indexPath] = item
            }
        }
        finishUpdate()
    }
    
    /// Replace item `itemToReplace` with `replacingItem`.
    ///
    /// - Throws: if `itemToReplace` is not found, will throw MemoryStorageErrors.Replacement.ItemNotFound
    open func replaceItem<T: Equatable>(_ itemToReplace: T, with replacingItem: Any) throws
    {
        startUpdate()
        defer { self.finishUpdate() }
        
        performDatasourceUpdate { [weak self] update in
            guard let originalIndexPath = self?.indexPath(forItem: itemToReplace) else {
                self?.anomalyHandler.reportAnomaly(MemoryStorageAnomaly.replaceItemFailedItemNotFound(itemDescription: String(describing: itemToReplace)))
                throw MemoryStorageError.searchFailed(reason: .itemNotFound(item: itemToReplace))
            }
            
            let section = self?.getValidSection(originalIndexPath.section, collectChangesIn: update)
            section?.items[originalIndexPath.item] = replacingItem
            
            update.objectChanges.append((.update, [originalIndexPath]))
            update.updatedObjects[originalIndexPath] = replacingItem
        }
    }
    
    /// Removes `item`.
    ///
    /// - Throws: if item is not found, will throw MemoryStorageErrors.Removal.ItemNotFound
    open func removeItem<T: Equatable>(_ item: T) throws
    {
        startUpdate()
        defer { self.finishUpdate() }
        
        performDatasourceUpdate { [weak self] update in
            guard let indexPath = self?.indexPath(forItem: item) else {
                self?.anomalyHandler.reportAnomaly(MemoryStorageAnomaly.removeItemFailedItemNotFound(itemDescription: String(describing: item)))
                throw MemoryStorageError.searchFailed(reason: .itemNotFound(item: item))
            }
            self?.getValidSection(indexPath.section, collectChangesIn: update).items.remove(at: indexPath.item)
            update.objectChanges.append((.delete, [indexPath]))
        }
    }
    
    /// Removes `items` from storage.
    ///
    /// Any items that were not found, will be skipped. Items are deleted in reverse order, starting from largest indexPath to prevent unintended gaps.
    /// - SeeAlso: `removeItems(at:)`
    open func removeItems<T: Equatable>(_ items: [T])
    {
        startUpdate()
        performDatasourceUpdate { [weak self] update in
            let indexPaths = self?.indexPathArray(forItems: items) ?? []
            for indexPath in MemoryStorage.sortedArrayOfIndexPaths(indexPaths, ascending: false)
            {
                self?.getValidSection(indexPath.section, collectChangesIn: update).items.remove(at: indexPath.item)
            }
            indexPaths.forEach {
                update.objectChanges.append((.delete, [$0]))
            }
        }
        finishUpdate()
    }
    
    /// Removes items at `indexPaths`.
    ///
    /// Any indexPaths that will not be found, will be skipped. Items are deleted in reverse order, starting from largest indexPath to prevent unintended gaps.
    /// - SeeAlso: `removeItems(_:)`
    open func removeItems(at indexPaths: [IndexPath])
    {
        startUpdate()
        performDatasourceUpdate { [weak self] update in
            let reverseSortedIndexPaths = MemoryStorage.sortedArrayOfIndexPaths(indexPaths, ascending: false)
            for indexPath in reverseSortedIndexPaths
            {
                if let _ = self?.item(at: indexPath)
                {
                    self?.getValidSection(indexPath.section, collectChangesIn: update).items.remove(at: indexPath.item)
                    update.objectChanges.append((.delete, [indexPath]))
                }
            }
        }
        finishUpdate()
    }
    
    /// Deletes `indexes` from storage.
    ///
    /// Sections will be deleted in backwards order, starting from the last one.
    open func deleteSections(_ indexes: IndexSet)
    {
        startUpdate()
        performDatasourceUpdate { [weak self] update in
            var markedForDeletion = [Int]()
            for section in indexes where section < (self?.sections.count ?? 0) {
                markedForDeletion.append(section)
            }
            for section in markedForDeletion.sorted().reversed() {
                self?.sections.remove(at: section)
            }
            markedForDeletion.forEach {
                update.sectionChanges.append((.delete, [$0]))
            }
        }
        finishUpdate()
    }
    
    /// Moves section from `sourceSectionIndex` to `destinationSectionIndex`.
    ///
    /// Sections prior to `sourceSectionIndex` and `destinationSectionIndex` will be automatically created, unless they already exist.
    open func moveSection(_ sourceSectionIndex: Int, toSection destinationSectionIndex: Int) {
        startUpdate()
        performDatasourceUpdate { [weak self] update in
            guard let validSectionFrom = self?.getValidSection(sourceSectionIndex, collectChangesIn: update) else { return }
            _ = self?.getValidSection(destinationSectionIndex, collectChangesIn: update)
            self?.sections.remove(at: sourceSectionIndex)
            self?.sections.insert(validSectionFrom, at: destinationSectionIndex)
            update.sectionChanges.append((.move, [sourceSectionIndex, destinationSectionIndex]))
        }
        finishUpdate()
    }
    
    /// Moves item from `source` indexPath to `destination` indexPath.
    ///
    /// Sections prior to `source`.section and `destination`.section will be automatically created, unless they already exist. If source item or destination index path are unreachable(too large), this method does nothing.
    open func moveItem(at source: IndexPath, to destination: IndexPath)
    {
        startUpdate()
        defer { self.finishUpdate() }
        
        performDatasourceUpdate { [weak self] update in
            guard let sourceItem = self?.item(at: source) else {
                self?.anomalyHandler.reportAnomaly(MemoryStorageAnomaly.moveItemFailedItemNotFound(indexPath: source))
                return
            }
            let sourceSection = self?.getValidSection(source.section, collectChangesIn: update)
            let destinationSection = self?.getValidSection(destination.section, collectChangesIn: update)
            
            let destinationSectionItemsCount = destinationSection?.items.count ?? 0
            
            let numberOfItemsInSectionAfterRemovingSource = source.section == destination.section ? destinationSectionItemsCount - 1 : destinationSectionItemsCount
            if numberOfItemsInSectionAfterRemovingSource < destination.row {
                self?.anomalyHandler.reportAnomaly(MemoryStorageAnomaly.moveItemFailedIndexPathTooBig(indexPath: destination, countOfElementsInSection: numberOfItemsInSectionAfterRemovingSource))
                return
            }
            sourceSection?.items.remove(at: source.row)
            destinationSection?.items.insert(sourceItem, at: destination.item)
            update.objectChanges.append((.move, [source, destination]))
        }
    }
    
    /// Moves item from `sourceIndexPath` to `destinationIndexPath` without animations.
    ///
    /// - Note: This method can be used inside `tableView(UITableView, moveRowAt: IndexPath, to: IndexPath)` to update datasource without UI animation since UI animation has already happened. This is also useful for iOS 11 Drop reordering, that behaves the same way.
    /// - Precondition: This method will check for existance of sections and number of items in both source and destination section prior to actually moving item. If sections do not exist, or have insufficient number of items to perform an operation, this method won't do anything.
    /// - Parameters:
    ///   - sourceIndexPath: source indexPath to move item from
    ///   - destinationIndexPath: destination indexPath to move item to.
    open func moveItemWithoutAnimation(from sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath)
    {
        if let from = section(atIndex: sourceIndexPath.section),
            let to = section(atIndex: destinationIndexPath.section)
        {
            let destinationSectionItemCountAfterRemoval = sourceIndexPath.section == destinationIndexPath.section ? to.items.count - 1: to.items.count
            if from.items.count > sourceIndexPath.row, destinationSectionItemCountAfterRemoval >= destinationIndexPath.row {
                let item = from.items[sourceIndexPath.row]
                from.items.remove(at: sourceIndexPath.row)
                to.items.insert(item, at: destinationIndexPath.row)
            } else {
                anomalyHandler.reportAnomaly(MemoryStorageAnomaly.moveItemFailedInvalidIndexPaths(sourceIndexPath: sourceIndexPath,
                                                                                                  destinationIndexPath: destinationIndexPath,
                                                                                                  sourceElementsInSection: from.items.count,
                                                                                                  destinationElementsInSection: destinationSectionItemCountAfterRemoval))
            }
        }
    }
    
    /// Removes all items from storage.
    ///
    /// - Note: method will call .storageNeedsReloading() when it finishes.
    open func removeAllItems()
    {
        for section in self.sections {
            (section as? SectionModel)?.items.removeAll(keepingCapacity: false)
        }
        delegate?.storageNeedsReloading()
    }
    
    /// Remove items from section with `sectionIndex`.
    ///
    /// If section at `sectionIndex` does not exist, this method does nothing.
    open func removeItems(fromSection sectionIndex: Int) {
        startUpdate()
        defer { finishUpdate() }
        
        performDatasourceUpdate { [weak self] update in
            guard let section = self?.section(atIndex: sectionIndex) else { return }
            
            for index in section.items.indices {
                update.objectChanges.append((.delete, [IndexPath(item: index, section: sectionIndex)]))
            }
            section.items.removeAll()
        }
    }
    
    // MARK: - Searching in storage
    
    /// Returns items in section with section `index`, or nil if section does not exist
    open func items(inSection index: Int) -> [Any]?
    {
        if sections.count > index {
            let indexes = (0...sections[index].numberOfItems)
            return indexes.reduce(into: []) { result, row in
                item(at: IndexPath(row: row, section: index)).map {
                    result?.append($0)
                }
            }
        }
        return nil
    }
    
    /// Returns indexPath of `searchableItem` in MemoryStorage or nil, if it's not found.
    open func indexPath<T: Equatable>(forItem searchableItem: T) -> IndexPath?
    {
        for sectionIndex in 0..<sections.count
        {
            let rows = items(inSection: sectionIndex) ?? []
            
            for rowIndex in 0..<rows.count {
                if let item = rows[rowIndex] as? T, item == searchableItem {
                    return IndexPath(item: rowIndex, section: sectionIndex)
                }
            }
            
        }
        return nil
    }
    
    /// Returns section at `sectionIndex` or nil, if it does not exist
    open func section(atIndex sectionIndex: Int) -> SectionModel?
    {
        if sections.count > sectionIndex {
            return sections[sectionIndex] as? SectionModel
        }
        return nil
    }
    
    /// Finds-or-creates section at `sectionIndex`
    ///
    /// - Note: This method finds or create a SectionModel. It means that if you create section 2, section 0 and 1 will be automatically created.
    /// - Returns: SectionModel
    final func getValidSection(_ sectionIndex: Int, collectChangesIn update: StorageUpdate?) -> SectionModel
    {
        if sectionIndex < self.sections.count
        {
            //swiftlint:disable:next force_cast
            return sections[sectionIndex] as! SectionModel
        } else {
            for i in sections.count...sectionIndex {
                sections.append(SectionModel())
                update?.sectionChanges.append((.insert, [i]))
            }
        }
        //swiftlint:disable:next force_cast
        return sections.last as! SectionModel
    }
    
    /// Returns index path array for `items`
    ///
    /// - Parameter items: items to find in storage
    /// - Returns: Array of IndexPaths for found items
    /// - Complexity: O(N^2*M) where N - number of items in storage, M - number of items.
    final func indexPathArray<T: Equatable>(forItems items: [T]) -> [IndexPath]
    {
        var indexPaths = [IndexPath]()
        
        for index in 0..<items.count {
            if let indexPath = self.indexPath(forItem: items[index])
            {
                indexPaths.append(indexPath)
            }
        }
        return indexPaths
    }
    
    /// Returns sorted array of index paths - useful for deletion.
    /// - Parameter indexPaths: Array of index paths to sort
    /// - Parameter ascending: sort in ascending or descending order
    /// - Note: This method is used, when you need to delete multiple index paths. Sorting them in reverse order preserves initial collection from mutation while enumerating
    static func sortedArrayOfIndexPaths(_ indexPaths: [IndexPath], ascending: Bool) -> [IndexPath]
    {
        let unsorted = NSMutableArray(array: indexPaths)
        let descriptor = NSSortDescriptor(key: "self", ascending: ascending)
        return unsorted.sortedArray(using: [descriptor]) as? [IndexPath] ?? []
    }
}
