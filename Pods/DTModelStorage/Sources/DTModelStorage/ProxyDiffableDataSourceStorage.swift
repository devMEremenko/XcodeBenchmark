//
//  ProxyDiffableDatasourceStorage.swift
//  DTModelStorage
//
//  Created by Denys Telezhkin on 7/23/19.
//  Copyright © 2019 Denys Telezhkin. All rights reserved.
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

#if compiler(>=5.1)
@available(iOS 13, tvOS 13, *)
/// `ProxyDiffableDataSourceStorage` serves as a bridge between `DTTableViewManager`/`DTCollectionViewManager` and diffable datasource classes for UITableView/UICollectionView(`UITableViewDiffableDataSource`\`UICollectionViewDiffableDataSource`).
public class ProxyDiffableDataSourceStorage: BaseSupplementaryStorage, Storage {
    private let _numberOfSections: () -> Int
    private let numberOfItemsInSection: (Int) -> Int
    private let itemAtIndexPath: (IndexPath) -> Any?
    
    /// Returns number of sections in storage.
    public func numberOfSections() -> Int {
        return _numberOfSections()
    }
    
    /// Returns number of items in section.
    public func numberOfItems(inSection section: Int) -> Int {
        return numberOfItemsInSection(section)
    }
    
    /// Returns item at concrete indexPath.
    public func item(at indexPath: IndexPath) -> Any? {
        return itemAtIndexPath(indexPath)
    }
    
    /// Creates `ProxyDiffableDataSourceStorage`.
    /// - Parameter tableView: UITableView instance to use with diffable datasource
    /// - Parameter dataSource: Diffable datasource that will be queried for datasource information.
    /// - Parameter modelProvider: Closure, that provides data model for given indexPath and item identifier.
    public init<SectionIdentifier, ItemIdentifier>(tableView: UITableView, dataSource: UITableViewDiffableDataSource<SectionIdentifier, ItemIdentifier>, modelProvider: @escaping (IndexPath, ItemIdentifier) -> Any) {
        _numberOfSections = { dataSource.numberOfSections(in: tableView) }
        numberOfItemsInSection = { dataSource.tableView(tableView, numberOfRowsInSection: $0) }
        itemAtIndexPath = {
            guard let itemIdentifier = dataSource.itemIdentifier(for: $0) else {
                return nil
            }
            return modelProvider($0, itemIdentifier)
        }
    }
    
    /// Creates `ProxyDiffableDataSourceStorage`.
    /// - Parameter tableView: UITableView instance to use with diffable datasource
    /// - Parameter dataSource: Diffable datasource that will be queried for datasource information.
    /// - Parameter modelProvider: Closure, that provides data model for given indexPath and item identifier.
    public init(tableView: UITableView, dataSource: UITableViewDiffableDataSourceReference, modelProvider: @escaping (IndexPath, Any) -> Any) {
        _numberOfSections = { dataSource.numberOfSections(in: tableView) }
        numberOfItemsInSection = { dataSource.tableView(tableView, numberOfRowsInSection: $0) }
        itemAtIndexPath = {
            guard let itemIdentifier = dataSource.itemIdentifier(for: $0) else {
                return nil
            }
            return modelProvider($0, itemIdentifier)
        }
    }
    
    /// Creates `ProxyDiffableDataSourceStorage`.
    /// - Parameter collectionView: UICollectionView instance to use with diffable datasource
    /// - Parameter dataSource: Diffable datasource that will be queried for datasource information.
    /// - Parameter modelProvider: Closure, that provides data model for given indexPath and item identifier.
    public init<SectionIdentifier, ItemIdentifier>(collectionView: UICollectionView, dataSource: UICollectionViewDiffableDataSource<SectionIdentifier, ItemIdentifier>, modelProvider: @escaping (IndexPath, ItemIdentifier) -> Any) {
        _numberOfSections = { dataSource.numberOfSections(in: collectionView) }
        numberOfItemsInSection = { dataSource.collectionView(collectionView, numberOfItemsInSection: $0) }
        itemAtIndexPath = {
            guard let itemIdentifier = dataSource.itemIdentifier(for: $0) else {
                return nil
            }
            return modelProvider($0, itemIdentifier)
        }
    }
    
    /// Creates `ProxyDiffableDataSourceStorage`.
    /// - Parameter collectionView: UICollectionView instance to use with diffable datasource
    /// - Parameter dataSource: Diffable datasource that will be queried for datasource information.
    /// - Parameter modelProvider: Closure, that provides data model for given indexPath and item identifier.
    public init(collectionView: UICollectionView, dataSource: UICollectionViewDiffableDataSourceReference,
                modelProvider: @escaping (IndexPath, Any) -> Any)
    {
        _numberOfSections = { dataSource.numberOfSections(in: collectionView) }
        numberOfItemsInSection = { dataSource.collectionView(collectionView, numberOfItemsInSection: $0) }
        itemAtIndexPath = {
            guard let itemIdentifier = dataSource.itemIdentifier(for: $0) else {
                return nil
            }
            return modelProvider($0, itemIdentifier)
        }
    }
}
#endif
