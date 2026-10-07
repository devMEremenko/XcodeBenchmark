//
//  DTCollectionViewManager+SwiftUIRegistration.swift
//  DTCollectionViewManager
//
//  Created by Denys Telezhkin on 24.06.2022.
//  Copyright © 2022 Denys Telezhkin. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

// swiftlint:disable line_length

@available(iOS 13, tvOS 13, *)
/// Extension for registering SwiftUI views.
public extension DTCollectionViewManager {
    
    /// Register mapping from `model` type to SwiftUI view `Content`, presented in `HostingCollectionViewCell`.
    ///
    /// When `HostingCollectionViewCell` is first dequeued, `Content` view will be created and added to view hierarchy. This will also add hosting controller, that hosts this cell, as a child view controller for parent view controller, containing collectionView. This is required for proper sizing and appearance events of SwiftUI view.
    ///
    /// However, adding SwiftUI hosting controller as a child may produce some unintended effects, for example showing navigation bar even though `Content` view has nothing to do with navigation stack. To avoid this problem, hosting controller may be customized. Read more about this in [Documentation](Documentation/SwiftUI.md)
    /// - Parameters:
    ///   - model: data model, mapped to cell
    ///   - content: SwiftUI view, rendered inside UICollectionViewCell
    ///   - mapping: mapping configuration closure, executed before any registration or dequeue is performed.
    func registerHostingCell<Content:View, Model>(for model: Model.Type, content: @escaping (Model, IndexPath) -> Content, mapping: ((HostingCellViewModelMapping<Content, Model>) -> Void)? = nil) {
        viewFactory.registerHostingCell(content, parentViewController: delegate as? UIViewController, mapping: mapping)
    }
    
#if swift(>=5.7) && !canImport(AppKit) || (canImport(AppKit) && swift(>=5.7.1)) // Xcode 14.0 AND macCatalyst on Xcode 14.1 (which will have swift> 5.7.1)
    
    @available(iOS 16, tvOS 16, *)
    /// Registers mapping from `model` to `UIHostingConfiguration`, that will be created and set to `contentConfiguration` property of `UICollectionViewCell` once dequeued.
    /// - Parameters:
    ///   - model: model type
    ///   - configuration: hosting configuration for a cell
    ///   - mapping: mapping customization closure
    func registerHostingConfiguration<Content: View, Background: View, Model, Cell: UICollectionViewCell>(
        for model: Model.Type,
        cell: Cell.Type = UICollectionViewCell.self,
        configuration: @escaping (Cell, Model, IndexPath) -> UIHostingConfiguration<Content, Background>,
        mapping: ((HostingConfigurationViewModelMapping<Content, Background, Model, Cell>) -> Void)? = nil) {
            viewFactory.registerHostingConfiguration(configuration: configuration, mapping: mapping)
    }
    
    @available(iOS 16, tvOS 16, *)
    /// Registers mapping from `model` to `UIHostingConfiguration`, that will be created and set to `contentConfiguration` property of `UICollectionViewCell` inside of `UICollectionViewCell.configurationUpdateHandler` property to manage state.
    /// - Parameters:
    ///   - model: model type
    ///   - configuration: hosting configuration for a cell
    ///   - mapping: mapping customization closure
    func registerHostingConfiguration<Content: View, Background: View, Model, Cell: UICollectionViewCell>(
        for model: Model.Type,
        cell: Cell.Type = UICollectionViewCell.self,
        configuration: @escaping (UICellConfigurationState, Cell, Model, IndexPath) -> UIHostingConfiguration<Content, Background>,
        mapping: ((HostingConfigurationViewModelMapping<Content, Background, Model, Cell>) -> Void)? = nil) {
            viewFactory.registerHostingConfiguration(configuration: configuration, mapping: mapping)
    }
#endif
}
