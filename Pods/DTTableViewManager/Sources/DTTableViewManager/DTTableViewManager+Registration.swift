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

extension DTTableViewManager
{
    /// Registers mapping from model class to `cellClass`.
    ///
    /// Method will automatically check for nib with the same name as `cellClass`. If it exists - nib will be registered instead of class.
    open func register<T:ModelTransfer>(_ cellClass:T.Type, mapping: ((ViewModelMapping) -> Void)? = nil) where T: UITableViewCell
    {
        self.viewFactory.registerCellClass(cellClass, mappingBlock: mapping)
    }
    
    /// Registers nib with `nibName` mapping from model class to `cellClass`.
    open func registerNibNamed<T:ModelTransfer>(_ nibName: String, for cellClass: T.Type, mapping: ((ViewModelMapping) -> Void)? = nil) where T: UITableViewCell
    {
        self.viewFactory.registerNibNamed(nibName, forCellClass: cellClass, mappingBlock: mapping)
    }
    
    /// Registers mapping from model class to header view of `headerClass` type.
    ///
    /// Method will automatically check for nib with the same name as `headerClass`. If it exists - nib will be registered instead of class.
    /// This method also sets TableViewConfiguration.sectionHeaderStyle property to .view.
    /// - Note: Views does not need to be `UITableViewHeaderFooterView`, if it's a `UIView` subclass, it also will be created from XIB.
    /// - SeeAlso: `UIView+XibLoading`.
    open func registerHeader<T:ModelTransfer>(_ headerClass : T.Type, mapping: ((ViewModelMapping) -> Void)? = nil) where T: UIView
    {
        configuration.sectionHeaderStyle = .view
        self.viewFactory.registerHeaderClass(headerClass, mappingBlock: mapping)
    }
    
    /// Registers mapping from model class to header view of `headerClass` type.
    ///
    /// This method is intended to be used for headers created from code - without UI made in XIB.
    /// This method also sets TableViewConfiguration.sectionHeaderStyle property to .view.
    open func registerNiblessHeader<T:ModelTransfer>(_ headerClass : T.Type, mapping: ((ViewModelMapping) -> Void)? = nil) where T: UITableViewHeaderFooterView
    {
        configuration.sectionHeaderStyle = .view
        self.viewFactory.registerNiblessHeaderClass(headerClass, mappingBlock: mapping)
    }
    
    /// Registers mapping from model class to footer view of `footerClass` type.
    ///
    /// This method is intended to be used for footers created from code - without UI made in XIB.
    /// This method also sets TableViewConfiguration.sectionFooterStyle property to .view.
    open func registerNiblessFooter<T:ModelTransfer>(_ footerClass : T.Type, mapping: ((ViewModelMapping) -> Void)? = nil) where T: UITableViewHeaderFooterView
    {
        configuration.sectionFooterStyle = .view
        self.viewFactory.registerNiblessFooterClass(footerClass, mappingBlock: mapping)
    }
    
    /// Registers mapping from model class to footerView view of `footerClass` type.
    ///
    /// Method will automatically check for nib with the same name as `footerClass`. If it exists - nib will be registered instead of class.
    /// This method also sets TableViewConfiguration.sectionFooterStyle property to .view.
    /// - Note: Views does not need to be `UITableViewHeaderFooterView`, if it's a `UIView` subclass, it also will be created from XIB.
    /// - SeeAlso: `UIView+XibLoading`.
    open func registerFooter<T:ModelTransfer>(_ footerClass: T.Type, mapping: ((ViewModelMapping) -> Void)? = nil) where T:UIView
    {
        configuration.sectionFooterStyle = .view
        viewFactory.registerFooterClass(footerClass, mappingBlock: mapping)
    }
    
    /// Registers mapping from model class to headerView view of `headerClass` type with `nibName`.
    ///
    /// This method also sets TableViewConfiguration.sectionHeaderStyle property to .view.
    /// - Note: Views does not need to be `UITableViewHeaderFooterView`, if it's a `UIView` subclass, it also will be created from XIB.
    /// - SeeAlso: `UIView+XibLoading`.
    open func registerNibNamed<T:ModelTransfer>(_ nibName: String, forHeader headerClass: T.Type, mapping: ((ViewModelMapping) -> Void)? = nil) where T:UIView
    {
        configuration.sectionHeaderStyle = .view
        viewFactory.registerNibNamed(nibName, forHeaderClass: headerClass, mappingBlock: mapping)
    }
    
    /// Registers mapping from model class to headerView view of `footerClass` type with `nibName`.
    ///
    /// This method also sets TableViewConfiguration.sectionFooterStyle property to .view.
    /// - Note: Views does not need to be `UITableViewHeaderFooterView`, if it's a `UIView` subclass, it also will be created from XIB.
    /// - SeeAlso: `UIView+XibLoading`.
    open func registerNibNamed<T:ModelTransfer>(_ nibName: String, forFooter footerClass: T.Type, mapping: ((ViewModelMapping) -> Void)? = nil) where T:UIView
    {
        configuration.sectionFooterStyle = .view
        viewFactory.registerNibNamed(nibName, forFooterClass: footerClass, mappingBlock: mapping)
    }
    
    /// Unregisters `cellClass` from `DTTableViewManager` and `UITableView`.
    open func unregister<T:ModelTransfer>(_ cellClass: T.Type) where T:UITableViewCell {
        viewFactory.unregisterCellClass(T.self)
    }
    
    /// Unregisters `headerClass` from `DTTableViewManager` and `UITableView`.
    open func unregisterHeader<T:ModelTransfer>(_ headerClass: T.Type) where T: UIView {
        viewFactory.unregisterHeaderClass(T.self)
    }
    
    /// Unregisters `footerClass` from `DTTableViewManager` and `UITableView`.
    open func unregisterFooter<T:ModelTransfer>(_ footerClass: T.Type) where T: UIView {
        viewFactory.unregisterFooterClass(T.self)
    }
}
