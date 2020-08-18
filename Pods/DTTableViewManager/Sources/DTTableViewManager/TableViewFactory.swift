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

/// Internal class, that is used to create table view cells, headers and footers.
final class TableViewFactory
{
    fileprivate let tableView: UITableView
    
    var mappings = [ViewModelMapping]()
    
    weak var anomalyHandler : DTTableViewManagerAnomalyHandler?
    
    init(tableView: UITableView)
    {
        self.tableView = tableView
    }
    
    func registerCellClass<T:ModelTransfer>(_ cellClass : T.Type, mappingBlock: ((ViewModelMapping) -> Void)?) where T: UITableViewCell
    {
        let mapping = ViewModelMapping(viewType: .cell, viewClass: T.self, mappingBlock: mappingBlock)
        if let cell = tableView.dequeueReusableCell(withIdentifier: mapping.reuseIdentifier) {
            // Storyboard prototype cell
            mappings.append(mapping)
            if let cellReuseIdentifier = cell.reuseIdentifier, cellReuseIdentifier != mapping.reuseIdentifier {
                anomalyHandler?.reportAnomaly(.differentCellReuseIdentifier(mappingReuseIdentifier: mapping.reuseIdentifier, cellReuseIdentifier: cellReuseIdentifier))
            }
        } else {
            tableView.register(T.self, forCellReuseIdentifier: mapping.reuseIdentifier)
            
            if UINib.nibExists(withNibName: String(describing: T.self), inBundle: mapping.bundle) {
                registerNibNamed(String(describing: T.self), forCellClass: T.self, mappingBlock: mappingBlock)
            } else {
                mappings.append(mapping)
                verifyCell(T.self, nibName: nil, withReuseIdentifier: mapping.reuseIdentifier, in: mapping.bundle)
            }
        }
    }
    
    func verifyCell<T:UITableViewCell>(_ cell: T.Type,
                                       nibName: String?,
                                       withReuseIdentifier reuseIdentifier: String,
                                       in bundle: Bundle) {
        var cell = T(frame: .zero)
        if let nibName = nibName, UINib.nibExists(withNibName: nibName, inBundle: bundle) {
            let nib = UINib(nibName: nibName, bundle: bundle)
            let objects = nib.instantiate(withOwner: cell, options: nil)
            if let instantiatedCell = objects.first as? T {
                cell = instantiatedCell
            } else {
                if let first = objects.first {
                    anomalyHandler?.reportAnomaly(.differentCellClass(xibName: nibName,
                                                                      cellClass: String(describing: type(of: first)),
                                                                      expectedCellClass: String(describing: T.self)))
                } else {
                    anomalyHandler?.reportAnomaly(.emptyXibFile(xibName: nibName, expectedViewClass: String(describing: T.self)))
                }
            }
        }
        if let cellReuseIdentifier = cell.reuseIdentifier, cellReuseIdentifier != reuseIdentifier {
            anomalyHandler?.reportAnomaly(.differentCellReuseIdentifier(mappingReuseIdentifier: reuseIdentifier, cellReuseIdentifier: cellReuseIdentifier))
        }
    }
    
    func verifyHeaderFooterView<T:UIView>(_ view: T.Type, nibName: String?, in bundle: Bundle) {
        var view = T(frame: .zero)
        if let nibName = nibName, UINib.nibExists(withNibName: nibName, inBundle: bundle) {
            let nib = UINib(nibName: nibName, bundle: bundle)
            let objects = nib.instantiate(withOwner: view, options: nil)
            if let instantiatedView = objects.first as? T {
                view = instantiatedView
            } else {
                if let first = objects.first {
                    anomalyHandler?.reportAnomaly(.differentHeaderFooterClass(xibName: nibName,
                                                                              viewClass: String(describing: type(of: first)),
                                                                              expectedViewClass: String(describing: T.self)))
                } else {
                    anomalyHandler?.reportAnomaly(.emptyXibFile(xibName: nibName, expectedViewClass: String(describing: T.self)))
                }
            }
        }
    }
    
    func registerNibNamed<T:ModelTransfer>(_ nibName : String, forCellClass cellClass: T.Type, mappingBlock: ((ViewModelMapping) -> Void)?) where T: UITableViewCell
    {
        let mapping = ViewModelMapping(viewType: .cell, viewClass: T.self, xibName: nibName, mappingBlock: mappingBlock)
        assert(UINib.nibExists(withNibName: nibName, inBundle: mapping.bundle), "Register cell nib method should be called only if nib exists")
        let nib = UINib(nibName: nibName, bundle: mapping.bundle)
        tableView.register(nib, forCellReuseIdentifier: mapping.reuseIdentifier)
        mappings.append(mapping)
        verifyCell(T.self, nibName: nibName, withReuseIdentifier: mapping.reuseIdentifier, in: mapping.bundle)
    }
    
    func registerNiblessHeaderClass<T:ModelTransfer>(_ headerClass : T.Type, mappingBlock: ((ViewModelMapping) -> Void)?) where T: UIView
    {
        let mapping = ViewModelMapping(viewType: .supplementaryView(kind: DTTableViewElementSectionHeader), viewClass: T.self, mappingBlock: mappingBlock)
        tableView.register(headerClass, forHeaderFooterViewReuseIdentifier: mapping.reuseIdentifier)
        mappings.append(mapping)
    }
    
    func registerNiblessFooterClass<T:ModelTransfer>(_ footerClass : T.Type, mappingBlock: ((ViewModelMapping) -> Void)?) where T: UIView
    {
        let mapping = ViewModelMapping(viewType: .supplementaryView(kind: DTTableViewElementSectionFooter), viewClass: T.self, mappingBlock: mappingBlock)
        tableView.register(footerClass, forHeaderFooterViewReuseIdentifier: mapping.reuseIdentifier)
        mappings.append(mapping)
    }
    
    func registerHeaderClass<T:ModelTransfer>(_ headerClass : T.Type, mappingBlock: ((ViewModelMapping) -> Void)?) where T: UIView
    {
        registerNibNamed(String(describing: T.self), forHeaderClass: headerClass, mappingBlock: mappingBlock)
    }
    
    func registerFooterClass<T:ModelTransfer>(_ footerClass: T.Type, mappingBlock: ((ViewModelMapping) -> Void)?) where T:UIView
    {
        registerNibNamed(String(describing: T.self), forFooterClass: footerClass, mappingBlock: mappingBlock)
    }
    
    func registerNibNamed<T:ModelTransfer>(_ nibName: String, forHeaderClass headerClass: T.Type, mappingBlock: ((ViewModelMapping) -> Void)?) where T:UIView
    {
        let mapping = ViewModelMapping(viewType: .supplementaryView(kind: DTTableViewElementSectionHeader),
                                       viewClass: T.self,
                                       xibName: nibName,
                                       mappingBlock: mappingBlock)
        
        assert(UINib.nibExists(withNibName: nibName, inBundle: mapping.bundle), "Register header nib method should be called only if nib exists. If you need to register header without nib, please call `registerNiblessHeader` method.")
        
        if T.isSubclass(of: UITableViewHeaderFooterView.self) {
            self.tableView.register(UINib(nibName: nibName, bundle: mapping.bundle), forHeaderFooterViewReuseIdentifier: mapping.reuseIdentifier)
        }
        mappings.append(mapping)
        verifyHeaderFooterView(T.self, nibName: nibName, in: mapping.bundle)
    }
    
    func registerNibNamed<T:ModelTransfer>(_ nibName: String, forFooterClass footerClass: T.Type, mappingBlock: ((ViewModelMapping) -> Void)?) where T:UIView
    {
        let mapping = ViewModelMapping(viewType: .supplementaryView(kind: DTTableViewElementSectionFooter),
                                       viewClass: T.self,
                                       xibName: nibName,
                                       mappingBlock: mappingBlock)
        
        assert(UINib.nibExists(withNibName: nibName, inBundle: mapping.bundle), "Register footer nib method should be called only if nib exists. If you need to register footer without nib, please call `registerNiblessHeader` method.")
        
        if T.isSubclass(of: UITableViewHeaderFooterView.self) {
            tableView.register(UINib(nibName: nibName, bundle: mapping.bundle), forHeaderFooterViewReuseIdentifier: mapping.reuseIdentifier)
        }
        mappings.append(mapping)
        verifyHeaderFooterView(T.self, nibName: nibName, in: mapping.bundle)
    }
    
    func unregisterCellClass<T:ModelTransfer>(_ cellClass: T.Type) where T: UITableViewCell {
        mappings = mappings.filter({ (mapping) -> Bool in
            if mapping.viewClass is T.Type && mapping.viewType == .cell { return false }
            return true
        })
        tableView.register(nil as AnyClass?, forCellReuseIdentifier: String(describing: T.self))
        tableView.register(nil as UINib?, forCellReuseIdentifier: String(describing: T.self))
    }
    
    func unregisterHeaderClass<T:ModelTransfer>(_ headerClass: T.Type) where T: UIView {
        mappings = mappings.filter({ mapping in
            if mapping.viewClass is T.Type && mapping.viewType == .supplementaryView(kind: DTTableViewElementSectionHeader) { return false }
            return true
        })
        tableView.register(nil as AnyClass?, forHeaderFooterViewReuseIdentifier: String(describing: T.self))
        tableView.register(nil as UINib?, forHeaderFooterViewReuseIdentifier: String(describing: self))
    }
    
    func unregisterFooterClass<T:ModelTransfer>(_ footerClass: T.Type) where T: UIView {
        mappings = mappings.filter({ mapping in
            if mapping.viewClass is T.Type && mapping.viewType == .supplementaryView(kind: DTTableViewElementSectionFooter) { return false }
            return true
        })
        tableView.register(nil as AnyClass?, forHeaderFooterViewReuseIdentifier: String(describing: T.self))
        tableView.register(nil as UINib?, forHeaderFooterViewReuseIdentifier: String(describing: self))
    }
    
    func viewModelMapping(for viewType: ViewType, model: Any, indexPath: IndexPath) -> ViewModelMapping?
    {
        guard let unwrappedModel = RuntimeHelper.recursivelyUnwrapAnyValue(model) else {
            return nil
        }
        return mappings.mappingCandidates(for: viewType, withModel: unwrappedModel, at: indexPath).first
    }
    
    func cellForModel(_ model: Any, atIndexPath indexPath:IndexPath) -> UITableViewCell?
    {
        if let mapping = viewModelMapping(for: .cell, model: model, indexPath: indexPath)
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: mapping.reuseIdentifier, for: indexPath)
            mapping.updateBlock(cell, model)
            return cell
        }
        anomalyHandler?.reportAnomaly(.noCellMappingFound(modelDescription: String(describing: model), indexPath: indexPath))
        return nil
    }
    
    func updateCellAt(_ indexPath : IndexPath, with model: Any) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        guard let unwrappedModel = RuntimeHelper.recursivelyUnwrapAnyValue(model) else { return }
        if let mapping = viewModelMapping(for: .cell, model: unwrappedModel, indexPath: indexPath) {
            mapping.updateBlock(cell, unwrappedModel)
        }
    }
    
    func headerFooterView(of type: ViewType, model : Any, atIndexPath indexPath: IndexPath) -> UIView?
    {
        guard let mapping = viewModelMapping(for: type, model: model, indexPath: indexPath) else {
            anomalyHandler?.reportAnomaly(.noHeaderFooterMappingFound(modelDescription: String(describing: model), indexPath: indexPath))
            return nil
        }
      
        if let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: mapping.reuseIdentifier) {
            mapping.updateBlock(view, model)
            return view
        } else {
            var view : UIView?
            
            if let type = mapping.viewClass as? UIView.Type {
                view = type.dt_loadFromXib()
            }
            
            if let view = view {
                mapping.updateBlock(view, model)
            }
            return view
        }
    }
}
