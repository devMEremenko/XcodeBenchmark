//
//  TableViewCellFactory.swift
//  DTTableViewManager
//
//  Created by Denys Telezhkin on 13.07.15.
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

import UIKit
import Foundation
import DTModelStorage
import SwiftUI

/// Internal class, that is used to create table view cells, headers and footers.
final class TableViewFactory
{
    fileprivate let tableView: UITableView
    
    var mappings = [ViewModelMappingProtocol]() {
        didSet {
            resetDelegates?()
        }
    }
    
    weak var anomalyHandler : DTTableViewManagerAnomalyHandler?
    
    var resetDelegates : (() -> Void)?
    
    init(tableView: UITableView)
    {
        self.tableView = tableView
    }
    
#if swift(>=5.7) && !canImport(AppKit) || (canImport(AppKit) && swift(>=5.7.1)) // Xcode 14.0 AND macCatalyst on Xcode 14.1 (which will have swift> 5.7.1)
    @available(iOS 16, tvOS 16, *)
    func registerHostingConfiguration<Content: View, Background: View, Model>(
        configuration: @escaping (UITableViewCell, Model, IndexPath) -> UIHostingConfiguration<Content, Background>,
        mapping: ((HostingConfigurationViewModelMapping<Content, Background, Model>) -> Void)?
    ) {
        let mapping = HostingConfigurationViewModelMapping(cellConfiguration: configuration, mapping: mapping)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: mapping.reuseIdentifier)
        mappings.append(mapping)
    }
    
    @available(iOS 16, tvOS 16, *)
    func registerHostingConfiguration<Content: View, Background: View, Model>(
        configuration: @escaping (UICellConfigurationState, UITableViewCell, Model, IndexPath) -> UIHostingConfiguration<Content, Background>,
        mapping: ((HostingConfigurationViewModelMapping<Content, Background, Model>) -> Void)?
    ) {
        let mapping = HostingConfigurationViewModelMapping(cellConfiguration: configuration, mapping: mapping)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: mapping.reuseIdentifier)
        mappings.append(mapping)
    }
#endif
    
    @available(iOS 13, tvOS 13, *)
    func registerHostingCell<Content: View, Model>(_ content: @escaping (Model, IndexPath) -> Content, parentViewController: UIViewController?,
                                                   mapping: ((HostingCellViewModelMapping<Content, Model>) -> Void)?) {
        let mapping = HostingCellViewModelMapping<Content, Model>(cellContent: content, parentViewController: parentViewController, mapping: mapping)
        if mapping.configuration.parentController == nil {
            assertionFailure("HostingTableViewCellConfiguration.parentController is nil. This will prevent HostingCell from sizing and appearing correctly. Please set parentController to controller, that contains managed table view.")
        }
        tableView.register(mapping.hostingCellSubclass.self, forCellReuseIdentifier: mapping.reuseIdentifier)
        mappings.append(mapping)
    }
    
    func registerCellClass<Cell:ModelTransfer>(_ cellClass : Cell.Type, handler: @escaping (Cell, Cell.ModelType, IndexPath) -> Void, mapping: ((TableViewCellModelMapping<Cell, Cell.ModelType>) -> Void)?) where Cell: UITableViewCell
    {
        let mapping = TableViewCellModelMapping<Cell, Cell.ModelType>(cellConfiguration: handler, mapping: mapping)
        if let cell = tableView.dequeueReusableCell(withIdentifier: mapping.reuseIdentifier) {
            // Storyboard prototype cell
            if let cellReuseIdentifier = cell.reuseIdentifier, cellReuseIdentifier != mapping.reuseIdentifier {
                anomalyHandler?.reportAnomaly(.differentCellReuseIdentifier(mappingReuseIdentifier: mapping.reuseIdentifier, cellReuseIdentifier: cellReuseIdentifier))
            }
        } else {
            if let xibName = mapping.xibName, UINib.nibExists(withNibName: xibName, inBundle: mapping.bundle) {
                let nib = UINib(nibName: xibName, bundle: mapping.bundle)
                tableView.register(nib, forCellReuseIdentifier: mapping.reuseIdentifier)
            } else {
                tableView.register(Cell.self, forCellReuseIdentifier: mapping.reuseIdentifier)
            }
        }
        mappings.append(mapping)
        verifyCell(Cell.self, nibName: mapping.xibName, withReuseIdentifier: mapping.reuseIdentifier, in: mapping.bundle)
    }
    
    func registerCellClass<Cell: UITableViewCell, Model>(_ cellType: Cell.Type, _ modelType: Model.Type, handler: @escaping (Cell, Model, IndexPath) -> Void, mapping: ((TableViewCellModelMapping<Cell, Model>) -> Void)? = nil)
    {
        let mapping = TableViewCellModelMapping<Cell, Model>(cellConfiguration: handler, mapping: mapping)
        if let cell = tableView.dequeueReusableCell(withIdentifier: mapping.reuseIdentifier) {
            // Storyboard prototype cell
            if let cellReuseIdentifier = cell.reuseIdentifier, cellReuseIdentifier != mapping.reuseIdentifier {
                anomalyHandler?.reportAnomaly(.differentCellReuseIdentifier(mappingReuseIdentifier: mapping.reuseIdentifier, cellReuseIdentifier: cellReuseIdentifier))
            }
        } else {
            if let xibName = mapping.xibName, UINib.nibExists(withNibName: xibName, inBundle: mapping.bundle) {
                let nib = UINib(nibName: xibName, bundle: mapping.bundle)
                tableView.register(nib, forCellReuseIdentifier: mapping.reuseIdentifier)
            } else {
                tableView.register(Cell.self, forCellReuseIdentifier: mapping.reuseIdentifier)
            }
        }
        mappings.append(mapping)
        verifyCell(Cell.self, nibName: mapping.xibName, withReuseIdentifier: mapping.reuseIdentifier, in: mapping.bundle)
    }
    
    func verifyCell<Cell:UITableViewCell>(_ cell: Cell.Type,
                                       nibName: String?,
                                       withReuseIdentifier reuseIdentifier: String,
                                       in bundle: Bundle) {
        var cell = Cell(frame: .zero)
        if let nibName = nibName, UINib.nibExists(withNibName: nibName, inBundle: bundle) {
            let nib = UINib(nibName: nibName, bundle: bundle)
            let objects = nib.instantiate(withOwner: cell, options: nil)
            if let instantiatedCell = objects.first as? Cell {
                cell = instantiatedCell
            } else {
                if let first = objects.first {
                    anomalyHandler?.reportAnomaly(.differentCellClass(xibName: nibName,
                                                                      cellClass: String(describing: type(of: first)),
                                                                      expectedCellClass: String(describing: Cell.self)))
                } else {
                    anomalyHandler?.reportAnomaly(.emptyXibFile(xibName: nibName, expectedViewClass: String(describing: Cell.self)))
                }
            }
        }
        if let cellReuseIdentifier = cell.reuseIdentifier, cellReuseIdentifier != reuseIdentifier {
            anomalyHandler?.reportAnomaly(.differentCellReuseIdentifier(mappingReuseIdentifier: reuseIdentifier, cellReuseIdentifier: cellReuseIdentifier))
        }
    }
    
    func verifyHeaderFooterView<View:UIView>(_ view: View.Type, nibName: String?, in bundle: Bundle) {
        var view = View(frame: .zero)
        if let nibName = nibName, UINib.nibExists(withNibName: nibName, inBundle: bundle) {
            let nib = UINib(nibName: nibName, bundle: bundle)
            let objects = nib.instantiate(withOwner: view, options: nil)
            if let instantiatedView = objects.first as? View {
                view = instantiatedView
            } else {
                if let first = objects.first {
                    anomalyHandler?.reportAnomaly(.differentHeaderFooterClass(xibName: nibName,
                                                                              viewClass: String(describing: type(of: first)),
                                                                              expectedViewClass: String(describing: View.self)))
                } else {
                    anomalyHandler?.reportAnomaly(.emptyXibFile(xibName: nibName, expectedViewClass: String(describing: View.self)))
                }
            }
        }
    }
    
    func registerSupplementaryClass<View:ModelTransfer>(_ supplementaryClass: View.Type, ofKind kind: String, handler: @escaping (View, View.ModelType, Int) -> Void, mapping: ((TableViewHeaderFooterViewModelMapping<View, View.ModelType>) -> Void)?) where View:UIView
    {
        let mapping = TableViewHeaderFooterViewModelMapping<View, View.ModelType>(kind: kind, headerFooterConfiguration: handler, mapping: mapping)
        
        if View.isSubclass(of: UITableViewHeaderFooterView.self) {
            if let nibName = mapping.xibName, UINib.nibExists(withNibName: nibName, inBundle: mapping.bundle) {
                let nib = UINib(nibName: nibName, bundle: mapping.bundle)
                tableView.register(nib, forHeaderFooterViewReuseIdentifier: mapping.reuseIdentifier)
            } else {
                tableView.register(View.self, forHeaderFooterViewReuseIdentifier: mapping.reuseIdentifier)
            }
        }
        mappings.append(mapping)
        verifyHeaderFooterView(View.self, nibName: mapping.xibName, in: mapping.bundle)
    }
    
    func registerSupplementaryClass<View, Model>(_ supplementaryClass: View.Type, ofKind kind: String, handler: @escaping (View, Model, Int) -> Void, mapping: ((TableViewHeaderFooterViewModelMapping<View, Model>) -> Void)?) where View:UIView
    {
        let mapping = TableViewHeaderFooterViewModelMapping<View, Model>(kind: kind, headerFooterConfiguration: handler, mapping: mapping)
        
        if View.isSubclass(of: UITableViewHeaderFooterView.self) {
            if let nibName = mapping.xibName, UINib.nibExists(withNibName: nibName, inBundle: mapping.bundle) {
                let nib = UINib(nibName: nibName, bundle: mapping.bundle)
                tableView.register(nib, forHeaderFooterViewReuseIdentifier: mapping.reuseIdentifier)
            } else {
                tableView.register(View.self, forHeaderFooterViewReuseIdentifier: mapping.reuseIdentifier)
            }
        }
        mappings.append(mapping)
        verifyHeaderFooterView(View.self, nibName: mapping.xibName, in: mapping.bundle)
    }
    
    func unregisterCellClass<Cell:ModelTransfer>(_ cellClass: Cell.Type) where Cell: UITableViewCell {
        mappings = mappings.filter({ (mapping) -> Bool in
            if mapping.viewClass is Cell.Type && mapping.viewType == .cell { return false }
            return true
        })
        tableView.register(nil as AnyClass?, forCellReuseIdentifier: String(describing: Cell.self))
        tableView.register(nil as UINib?, forCellReuseIdentifier: String(describing: Cell.self))
    }
    
    func unregisterHeaderClass<View:ModelTransfer>(_ headerClass: View.Type) where View: UIView {
        mappings = mappings.filter({ mapping in
            if mapping.viewClass is View.Type && mapping.viewType == .supplementaryView(kind: DTTableViewElementSectionHeader) { return false }
            return true
        })
        tableView.register(nil as AnyClass?, forHeaderFooterViewReuseIdentifier: String(describing: View.self))
        tableView.register(nil as UINib?, forHeaderFooterViewReuseIdentifier: String(describing: self))
    }
    
    func unregisterFooterClass<View:ModelTransfer>(_ footerClass: View.Type) where View: UIView {
        mappings = mappings.filter({ mapping in
            if mapping.viewClass is View.Type && mapping.viewType == .supplementaryView(kind: DTTableViewElementSectionFooter) { return false }
            return true
        })
        tableView.register(nil as AnyClass?, forHeaderFooterViewReuseIdentifier: String(describing: View.self))
        tableView.register(nil as UINib?, forHeaderFooterViewReuseIdentifier: String(describing: self))
    }
    
    func viewModelMapping(for viewType: ViewType, model: Any, indexPath: IndexPath) -> ViewModelMappingProtocol?
    {
        guard let unwrappedModel = RuntimeHelper.recursivelyUnwrapAnyValue(model) else {
            return nil
        }
        return viewType.mappingCandidates(for: mappings, withModel: unwrappedModel, at: indexPath).first
    }
    
    func cellForModel(_ model: Any, atIndexPath indexPath:IndexPath) -> UITableViewCell?
    {
        if let mapping = viewModelMapping(for: .cell, model: model, indexPath: indexPath) as? CellViewModelMappingProtocol
        {
            return mapping.dequeueConfiguredReusableCell(for: tableView, model: model, indexPath: indexPath)
        }
        anomalyHandler?.reportAnomaly(.noCellMappingFound(modelDescription: String(describing: model), indexPath: indexPath))
        return nil
    }
    
    func updateCellAt(_ indexPath : IndexPath, with model: Any) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        guard let unwrappedModel = RuntimeHelper.recursivelyUnwrapAnyValue(model) else { return }
        if let mapping = viewModelMapping(for: .cell, model: unwrappedModel, indexPath: indexPath) as? CellViewModelMappingProtocol {
            mapping.updateCell(cell: cell, at: indexPath, with: unwrappedModel)
        }
    }
    
    func headerFooterView(of type: ViewType, model : Any, atIndexPath indexPath: IndexPath) -> UIView?
    {
        guard let mapping = viewModelMapping(for: type, model: model, indexPath: indexPath) as? SupplementaryViewModelMappingProtocol else {
            anomalyHandler?.reportAnomaly(.noHeaderFooterMappingFound(modelDescription: String(describing: model), indexPath: indexPath))
            return nil
        }
      
        return mapping.dequeueConfiguredReusableSupplementaryView(for: tableView, kind: type.supplementaryKind() ?? "", model: model, indexPath: indexPath)
    }
}
