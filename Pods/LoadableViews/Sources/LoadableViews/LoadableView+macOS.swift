//
//  LoadableView+macOS.swift
//  LoadableViews
//
//  Created by Denys Telezhkin on 07.05.2021.
//  Copyright © 2021 Denys Telezhkin. All rights reserved.
//

import Foundation

#if !targetEnvironment(macCatalyst) && canImport(AppKit)
import AppKit

extension NibLoadableProtocol {
    
    /// Method that loads view from single view xib with `nibName`.
    ///
    /// - returns: loaded from xib view
    public func loadNib() -> NSView {
        var topLevelArray: NSArray? = nil
        bundle.loadNibNamed(NSNib.Name(nibName), owner: self, topLevelObjects: &topLevelArray)
        return topLevelArray?.filter { $0 is NSView }.first as! NSView
    }
    
    public func setupView(_ view: NSView, inContainer container: NSView) {
        container.wantsLayer = true
        container.layer?.backgroundColor = .clear
        container.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        let bindings = ["view": view]
        container.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options:[], metrics:nil, views: bindings))
        container.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options:[], metrics:nil, views: bindings))
    }
}

#endif
