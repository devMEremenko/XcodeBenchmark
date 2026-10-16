//
//  LoadableView.swift
//  LoadableView
//
//  Created by Denys Telezhkin on 05.03.16.
//  Copyright © 2018 MLSDev Inc(https://mlsdev.com).
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

#if !targetEnvironment(macCatalyst) && canImport(AppKit)
import AppKit
public typealias PlatformView = NSView
#elseif canImport(UIKit)
import UIKit
public typealias PlatformView = UIView
#endif

/// Protocol to define family of loadable views
public protocol NibLoadableProtocol : NSObjectProtocol {
    
    /// View that serves as a container for loadable view. Loadable views are added to container view in `setupNib(_:)` method.
    var nibContainerView: PlatformView { get }
    
    /// Method that loads view from single view xib with `nibName`.
    ///
    /// - returns: loaded from xib view
    func loadNib() -> PlatformView
    
    /// Method that is used to load and configure loadableView. It is then added to `nibContainerView` as a subview. This view receives constraints of same width and height as container view.
    func setupNib()
    
    /// Name of .xib file to load view from.
    var nibName : String { get }
    
    /// Bundle to load nib from
    var bundle: Bundle { get }
}

extension PlatformView {
    /// View usually serves itself as a default container for loadable views
    @objc dynamic open var nibContainerView : PlatformView { return self }
    
    /// Default nibName for all UIViews, equal to name of the class.
    @objc dynamic open var nibName : String { return String(describing: type(of: self)) }
    
    /// Bundle to load nib from. Defaults to Bundle(for: type(of: self)).
    @objc dynamic open var bundle: Bundle {
        return Bundle(for: type(of: self))
    }
}

/// UIView subclass, that can be loaded into different xib or storyboard by simply referencing it's class.
open class LoadableView: PlatformView, NibLoadableProtocol {

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupNib()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupNib()
    }
    
    open func setupNib() {
        setupView(loadNib(), inContainer: nibContainerView)
    }
}
