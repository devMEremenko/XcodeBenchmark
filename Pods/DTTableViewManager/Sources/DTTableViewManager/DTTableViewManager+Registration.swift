//
//  DTTableViewManager+Registration.swift
//  DTTableViewManager
//
//  Created by Denys Telezhkin on 26.08.17.
//  Copyright © 2017 Denys Telezhkin. All rights reserved.
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
import DTModelStorage

/// Extension for registering cell and supplementary views
public extension DTTableViewManager
{
    /// Registers mapping for `cellClass`. Mapping will automatically check for nib with the same name as `cellClass` and register it, if it is found. `UITableViewCell` can also be designed in storyboard.
    /// - Parameters:
    ///   - cellClass: UITableViewCell subclass type, conforming to `ModelTransfer` protocol.
    ///   - mapping: mapping configuration closure, executed before any registration or dequeue is performed.
    ///   - handler: configuration closure, that is run when cell is dequeued. Please note, that `handler` is called before `update(with:)` method.
    func register<Cell:ModelTransfer>(_ cellClass:Cell.Type,
                                        mapping: ((TableViewCellModelMapping<Cell, Cell.ModelType>) -> Void)? = nil,
                                        handler: @escaping (Cell, Cell.ModelType, IndexPath) -> Void = { _, _, _ in }) where Cell: UITableViewCell
    {
        self.viewFactory.registerCellClass(cellClass, handler: handler, mapping: mapping)
    }
    
    /// Registers mapping from `modelType` to `cellClass`. Mapping will automatically check for nib with the same name as `cellClass` and register it, if it is found. `UITableViewCell` can also be designed in storyboard.
    /// - Parameters:
    ///   - cellClass: UITableViewCell to register
    ///   - modelType: Model type, which is mapped to `cellClass`.
    ///   - mapping: mapping configuration closure, executed before any registration or dequeue is performed.
    ///   - handler: configuration closure, that is run when cell is dequeued.
    func register<Cell: UITableViewCell, Model>(_ cellClass: Cell.Type, for modelType: Model.Type,
                                                     mapping: ((TableViewCellModelMapping<Cell, Model>) -> Void)? = nil,
                                                     handler: @escaping (Cell, Model, IndexPath) -> Void)
    {
        viewFactory.registerCellClass(cellClass, modelType, handler: handler, mapping: mapping)
    }
    
    /// Registers mapping from model class to header view of `headerClass` type.
    ///
    /// Method will automatically check for nib with the same name as `headerClass`. If it exists - nib will be registered instead of class.
    /// This method also sets TableViewConfiguration.sectionHeaderStyle property to .view.
    /// - Note: Views does not need to be `UITableViewHeaderFooterView`, if it's a `UIView` subclass, it also will be created from XIB. In the latter case, events defined inside mapping closure are not supported.
    /// - Note: `handler` closure is called before `update(with:)` method.
    func registerHeader<View:ModelTransfer>(_ headerClass : View.Type,
                                              mapping: ((TableViewHeaderFooterViewModelMapping<View, View.ModelType>) -> Void)? = nil,
                                              handler: @escaping (View, View.ModelType, Int) -> Void = { _, _, _ in }) where View: UIView
    {
        configuration.sectionHeaderStyle = .view
        viewFactory.registerSupplementaryClass(View.self, ofKind: DTTableViewElementSectionHeader, handler: handler, mapping: mapping)
    }
    
    /// Registers mapping from model class to header view of `headerClass` type.
    ///
    /// Method will automatically check for nib with the same name as `headerClass`. If it exists - nib will be registered instead of class.
    /// This method also sets TableViewConfiguration.sectionHeaderStyle property to .view.
    /// - Note: Views does not need to be `UITableViewHeaderFooterView`, if it's a `UIView` subclass, it also will be created from XIB. In the latter case, events defined inside mapping closure are not supported.
    func registerHeader<View: UIView, Model>(_ headerClass : View.Type,
                                                  for: Model.Type,
                                                  mapping: ((TableViewHeaderFooterViewModelMapping<View, Model>) -> Void)? = nil,
                                                  handler: @escaping (View, Model, Int) -> Void)
    {
        configuration.sectionHeaderStyle = .view
        viewFactory.registerSupplementaryClass(View.self, ofKind: DTTableViewElementSectionHeader, handler: handler, mapping: mapping)
    }
    
    /// Registers mapping from model class to footerView view of `footerClass` type.
    ///
    /// Method will automatically check for nib with the same name as `footerClass`. If it exists - nib will be registered instead of class.
    /// This method also sets TableViewConfiguration.sectionFooterStyle property to .view.
    /// - Note: Views does not need to be `UITableViewHeaderFooterView`, if it's a `UIView` subclass, it also will be created from XIB. In the latter case, events defined inside mapping closure are not supported.
    /// - Note: `handler` closure is called before `update(with:)` method.
    func registerFooter<View:ModelTransfer>(_ footerClass: View.Type,
                                              mapping: ((TableViewHeaderFooterViewModelMapping<View, View.ModelType>) -> Void)? = nil,
                                              handler: @escaping (View, View.ModelType, Int) -> Void = { _, _, _ in }) where View:UIView
    {
        configuration.sectionFooterStyle = .view
        viewFactory.registerSupplementaryClass(View.self, ofKind: DTTableViewElementSectionFooter, handler: handler, mapping: mapping)
    }
    
    /// Registers mapping from model class to footer view of `footerClass` type.
    ///
    /// Method will automatically check for nib with the same name as `footerClass`. If it exists - nib will be registered instead of class.
    /// This method also sets TableViewConfiguration.sectionFooterStyle property to .view.
    /// - Note: Views does not need to be `UITableViewHeaderFooterView`, if it's a `UIView` subclass, it will be created from XIB. In the latter case, events defined inside mapping closure are not supported.
    func registerFooter<View: UIView, Model>(_ footerClass : View.Type,
                                           for: Model.Type,
                                           mapping: ((TableViewHeaderFooterViewModelMapping<View, Model>) -> Void)? = nil,
                                           handler: @escaping (View, Model, Int) -> Void)
    {
        configuration.sectionFooterStyle = .view
        viewFactory.registerSupplementaryClass(View.self, ofKind: DTTableViewElementSectionFooter, handler: handler, mapping: mapping)
    }
    
    /// Unregisters `cellClass` from `DTTableViewManager` and `UITableView`.
    func unregister<Cell:ModelTransfer>(_ cellClass: Cell.Type) where Cell:UITableViewCell {
        viewFactory.unregisterCellClass(Cell.self)
    }
    
    /// Unregisters `headerClass` from `DTTableViewManager` and `UITableView`.
    func unregisterHeader<View:ModelTransfer>(_ headerClass: View.Type) where View: UIView {
        viewFactory.unregisterHeaderClass(View.self)
    }
    
    /// Unregisters `footerClass` from `DTTableViewManager` and `UITableView`.
    func unregisterFooter<View:ModelTransfer>(_ footerClass: View.Type) where View: UIView {
        viewFactory.unregisterFooterClass(View.self)
    }
}
