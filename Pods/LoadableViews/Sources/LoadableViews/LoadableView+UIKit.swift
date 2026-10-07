//
//  LoadableView+UIKit.swift
//  LoadableViews
//
//  Created by Denys Telezhkin on 07.05.2021.
//  Copyright © 2021 Denys Telezhkin. All rights reserved.
//

import Foundation

#if canImport(UIKit)
import UIKit

extension NibLoadableProtocol {
    
    /// Method that loads view from single view xib with `nibName`.
    ///
    /// - returns: loaded from xib view
    public func loadNib() -> PlatformView {
        let nib = UINib(nibName: nibName, bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil).first as! UIView
        return view
    }
    
    public func setupView(_ view: UIView, inContainer container: UIView) {
        container.backgroundColor = .clear
        container.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        let bindings = ["view": view]
        container.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options:[], metrics:nil, views: bindings))
        container.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options:[], metrics:nil, views: bindings))
    }
}

extension NibLoadableProtocol where Self: UIView {
    
    /// Sets the frame of the view to result of `systemLayoutSizeFitting` method call with `UIView.layoutFittingCompressedSize` parameter.
    ///
    /// - Returns: loadable view
    public func compressedLayout() -> Self {
        frame.size = systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        return self
    }
    
    /// Sets the frame of the view to result of `systemLayoutSizeFitting` method call with `UIView.layoutFittingExpandedSize` parameter.
    ///
    /// - Returns: loadable view
    public func expandedLayout() -> Self {
        frame.size = systemLayoutSizeFitting(UIView.layoutFittingExpandedSize)
        return self
    }
    
    /// Sets the frame of the view to result of `systemLayoutSizeFitting` method call with provided parameters.
    ///
    /// - Parameters:
    ///   - fittingSize: fittingSize to be passed to `systemLayoutSizeFitting` method.
    ///   - horizontalPriority: horizontal priority to be passed to `systemLayoutSizeFitting` method.
    ///   - verticalPriority: vertical priority to be passed to `systemLayoutSizeFitting` method.
    /// - Returns: loadable view
    public func systemLayout(fittingSize: CGSize,
                             horizontalPriority: UILayoutPriority,
                             verticalPriority: UILayoutPriority) -> Self {
        frame.size = systemLayoutSizeFitting(fittingSize,
                                             withHorizontalFittingPriority: horizontalPriority,
                                             verticalFittingPriority: verticalPriority)
        return self
    }
}

/// UITableViewCell subclass, which subview can be used as a container to loadable view. By default, xib with the same name is loaded and added as a subview to cell's contentView.
open class LoadableTableViewCell: UITableViewCell, NibLoadableProtocol {
    open override var nibContainerView: UIView {
        return contentView
    }
    
    #if swift(>=4.2)
    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupNib()
    }
    #else
    override public init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupNib()
    }
    #endif
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupNib()
    }
    
    open func setupNib() {
        setupView(loadNib(), inContainer: nibContainerView)
    }
}

/// UICollectionReusableView subclass, which subview can be used as a container to loadable view. By default, xib with the same name is loaded and added as a subview.
open class LoadableCollectionReusableView: UICollectionReusableView, NibLoadableProtocol {
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupNib()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupNib()
    }
    
    open func setupNib() {
        setupView(loadNib(), inContainer: nibContainerView)
    }
}

/// UICollectionViewCell subclass, which subview can be used as a container to loadable view. By default, xib with the same name is loaded and added as a subview to cell's contentView.
open class LoadableCollectionViewCell: UICollectionViewCell, NibLoadableProtocol {
    open override var nibContainerView: UIView {
        return contentView
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupNib()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupNib()
    }
    
    open func setupNib() {
        setupView(loadNib(), inContainer: nibContainerView)
    }
}

/// UITextField subclass, which subview can be used as a container to loadable view. By default, xib with the same name is loaded and added as a subview.
open class LoadableTextField: UITextField, NibLoadableProtocol {
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupNib()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupNib()
    }
    
    open func setupNib() {
        setupView(loadNib(), inContainer: nibContainerView)
    }
}

open class LoadableControl: UIControl, NibLoadableProtocol {
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupNib()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupNib()
    }
    
    open func setupNib() {
        setupView(loadNib(), inContainer: nibContainerView)
    }
}

#endif
