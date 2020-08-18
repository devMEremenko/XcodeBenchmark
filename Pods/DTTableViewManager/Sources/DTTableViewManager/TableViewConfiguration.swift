//
//  TableViewConfiguration.swift
//  DTTableViewManager
//
//  Created by Denys Telezhkin on 20.08.15.
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

/// Style of section headers for table view. Depending on style, datasource methods will return title for section or view for section. Default is .title.
/// - Note: you don't need any mapping methods, if you use .title style, just add String objects to Storage, and that's it
/// - Note: When any mapping method for header or footer view is called, styles are automatically switched to .view
public enum SupplementarySectionStyle
{
    case title
    case view
}

/// Defines most commonly used configuration properties for UITableView
public struct TableViewConfiguration
{
    /// Section header style. Default - .Title.
    public var sectionHeaderStyle = SupplementarySectionStyle.title
    
    /// Section footer style. Default - .Title
    public var sectionFooterStyle = SupplementarySectionStyle.title
    
    /// Defines, whether to show header on a section, that does not contain any items. Default is true.
    public var displayHeaderOnEmptySection = true
    
    /// Defines, whether to show footer on a section, that does not contain any items. Default is true.
    public var displayFooterOnEmptySection = true
    
    /// Minimal header height to hide it when section is empty. This defaults to .zero if `UITableView.Style` is `.plain` and `.leastNormalMagnitude` otherwise.
    public var minimalHeaderHeightForTableView: (UITableView) -> CGFloat = {
        $0.style == .plain ? CGFloat.zero : CGFloat.leastNormalMagnitude
    }
    
    /// Minimal footer height to hide it when section is empty. This defaults to .zero if `UITableView.Style` is `.plain` and `.leastNormalMagnitude` otherwise.
    public var minimalFooterHeightForTableView: (UITableView) -> CGFloat = {
        $0.style == .plain ? CGFloat.zero : CGFloat.leastNormalMagnitude
    }
}
