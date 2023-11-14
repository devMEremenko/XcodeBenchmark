//
//  HostingCollectionViewCell.swift
//  DTCollectionViewManager
//
//  Created by Denys Telezhkin on 24.06.2022.
//  Copyright © 2022 Denys Telezhkin. All rights reserved.
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
import SwiftUI

@available(iOS 13, tvOS 13, *)
/// Cell subclass, that allows hosting SwiftUI content inside UICollectionViewCell.
open class HostingCollectionViewCell<Content: View, Model>: UICollectionViewCell {

    private var hostingController: UIHostingController<Content>?
    
    /// Updates cell with new SwiftUI view. If the cell is being reused, it's hosting controller will also be reused.
    /// - Parameters:
    ///   - rootView: SwiftUI view
    ///   - configuration: configuration to use while updating
    open func updateWith(rootView: Content, configuration: HostingCollectionViewCellConfiguration<Content>) {
        if let existingHosting = hostingController {
            existingHosting.rootView = rootView
            hostingController?.view.invalidateIntrinsicContentSize()
            configuration.configureCell(self)
        } else {
            let hosting = configuration.hostingControllerMaker(rootView)
            hostingController = hosting
            if let backgroundColor = configuration.backgroundColor {
                self.backgroundColor = backgroundColor
            }
            if let hostingBackgroundColor = configuration.hostingViewBackgroundColor {
                hostingController?.view.backgroundColor = hostingBackgroundColor
            }
            if let contentViewBackgroundColor = configuration.contentViewBackgroundColor {
                contentView.backgroundColor = contentViewBackgroundColor
            }
            
            hostingController?.view.invalidateIntrinsicContentSize()
            
            hosting.willMove(toParent: configuration.parentController)
            configuration.parentController?.addChild(hosting)
            contentView.addSubview(hosting.view)
            
            hosting.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                hosting.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                hosting.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                hosting.view.topAnchor.constraint(equalTo: contentView.topAnchor),
                hosting.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
            
            hosting.didMove(toParent: configuration.parentController)
            
            configuration.configureCell(self)
        }
    }
}
