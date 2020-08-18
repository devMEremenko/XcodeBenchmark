//
//  DTCollectionViewDelegate.swift
//  DTCollectionViewManager
//
//  Created by Denys Telezhkin on 13.08.17.
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

import Foundation
import UIKit
import DTModelStorage

/// Object, that implements `UICollectionViewDelegate` and `UICollectionViewDelegateFlowLayout` methods for `DTCollectionViewManager`.
open class DTCollectionViewDelegate: DTCollectionViewDelegateWrapper, UICollectionViewDelegateFlowLayout {
    override func delegateWasReset() {
        collectionView?.delegate = nil
        collectionView?.delegate = self
    }
    
    /// Implementation of `UICollectionViewDelegateFlowLayout` and `UICollectionViewDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let size = performCellReaction(.sizeForItemAtIndexPath, location: indexPath, provideCell: false) as? CGSize {
            return size
        }
        return (delegate as? UICollectionViewDelegateFlowLayout)?.collectionView?(collectionView, layout: collectionViewLayout, sizeForItemAt: indexPath) ?? (collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize ?? .zero
    }
    
    /// Implementation of `UICollectionViewDelegateFlowLayout` and `UICollectionViewDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize
    {
        if let size = performSupplementaryReaction(forKind: UICollectionView.elementKindSectionHeader, signature: .referenceSizeForHeaderInSection, location: IndexPath(item:0, section:section), view: nil) as? CGSize {
            return size
        }
        if let size = (self.delegate as? UICollectionViewDelegateFlowLayout)?.collectionView?(collectionView, layout: collectionViewLayout, referenceSizeForHeaderInSection: section) {
            return size
        }
        if let _ = headerModel(forSection: section) {
            return (collectionViewLayout as? UICollectionViewFlowLayout)?.headerReferenceSize ?? .zero
        }
        return CGSize.zero
    }
    
    /// Implementation of `UICollectionViewDelegateFlowLayout` and `UICollectionViewDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if let size = performSupplementaryReaction(forKind: UICollectionView.elementKindSectionFooter, signature: .referenceSizeForFooterInSection, location: IndexPath(item:0, section:section), view: nil) as? CGSize {
            return size
        }
        if let size = (self.delegate as? UICollectionViewDelegateFlowLayout)?.collectionView?(collectionView, layout: collectionViewLayout, referenceSizeForFooterInSection: section) {
            return size
        }
        if let _ = footerModel(forSection: section) {
            return (collectionViewLayout as? UICollectionViewFlowLayout)?.footerReferenceSize ?? .zero
        }
        return CGSize.zero
    }
    
    /// Implementation of `UICollectionViewDelegateFlowLayout` and `UICollectionViewDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if let can = performCellReaction(.shouldSelectItemAtIndexPath, location: indexPath, provideCell: true) as? Bool {
            return can
        }
        return (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView, shouldSelectItemAt: indexPath) ?? true
    }
    
    /// Implementation of `UICollectionViewDelegateFlowLayout` and `UICollectionViewDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        _ = performCellReaction(.didSelectItemAtIndexPath, location: indexPath, provideCell: true)
        (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView, didSelectItemAt: indexPath)
    }
    
    /// Implementation of `UICollectionViewDelegateFlowLayout` and `UICollectionViewDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        if let can = performCellReaction(.shouldDeselectItemAtIndexPath, location: indexPath, provideCell: true) as? Bool {
            return can
        }
        return (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView, shouldDeselectItemAt: indexPath) ?? true
    }
    
    /// Implementation of `UICollectionViewDelegateFlowLayout` and `UICollectionViewDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath)
    {
        _ = performCellReaction(.didDeselectItemAtIndexPath, location: indexPath, provideCell: true)
        (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView, didDeselectItemAt: indexPath)
    }
    
    /// Implementation of `UICollectionViewDelegateFlowLayout` and `UICollectionViewDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath)
    {
        _ = performCellReaction(.didHighlightItemAtIndexPath, location: indexPath, provideCell: true)
        (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView, didHighlightItemAt: indexPath)
    }
    
    /// Implementation of `UICollectionViewDelegateFlowLayout` and `UICollectionViewDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath)
    {
        _ = performCellReaction(.didUnhighlightItemAtIndexPath, location: indexPath, provideCell: true)
        (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView, didUnhighlightItemAt: indexPath)
    }
    
    /// Implementation of `UICollectionViewDelegateFlowLayout` and `UICollectionViewDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        if let can = performCellReaction(.shouldHighlightItemAtIndexPath, location: indexPath, provideCell: true) as? Bool {
            return can
        }
        return (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView, shouldHighlightItemAt: indexPath) ?? true
    }
    
    /// Implementation of `UICollectionViewDelegateFlowLayout` and `UICollectionViewDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        defer { (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView, willDisplay: cell, forItemAt: indexPath) }
        guard let model = storage?.item(at: indexPath) else { return }
        _ = collectionViewReactions.performReaction(of: .cell, signature: EventMethodSignature.willDisplayCellForItemAtIndexPath.rawValue, view: cell, model: model, location: indexPath)
    }
    
    /// Implementation of `UICollectionViewDelegateFlowLayout` and `UICollectionViewDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        _ = performSupplementaryReaction(forKind: elementKind, signature: .willDisplaySupplementaryViewForElementKindAtIndexPath, location: indexPath, view: view)
        (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView, willDisplaySupplementaryView: view, forElementKind: elementKind, at: indexPath)
    }
    
    /// Implementation of `UICollectionViewDelegateFlowLayout` and `UICollectionViewDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        defer { (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView, didEndDisplaying: cell, forItemAt: indexPath) }
        guard let model = storage?.item(at: indexPath) else { return }
        _ = collectionViewReactions.performReaction(of: .cell, signature: EventMethodSignature.didEndDisplayingCellForItemAtIndexPath.rawValue, view: cell, model: model, location: indexPath)
    }
    
    /// Implementation of `UICollectionViewDelegateFlowLayout` and `UICollectionViewDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
        defer { (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView, didEndDisplayingSupplementaryView: view, forElementOfKind: elementKind, at: indexPath) }
        guard let model = supplementaryModel(ofKind: elementKind, forSectionAt: indexPath) else { return }
        _ = collectionViewReactions.performReaction(of: .supplementaryView(kind: elementKind), signature: EventMethodSignature.didEndDisplayingSupplementaryViewForElementKindAtIndexPath.rawValue, view: view, model: model, location: indexPath)
    }
    
    @available(iOS, deprecated: 13.0)
    @available(tvOS, deprecated: 13.0)
    /// Implementation of `UICollectionViewDelegateFlowLayout` and `UICollectionViewDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        if let can = performCellReaction(.shouldShowMenuForItemAtIndexPath, location: indexPath, provideCell: true) as? Bool {
            return can
        }
        return (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView, shouldShowMenuForItemAt: indexPath) ?? false
    }
    
    @available(iOS, deprecated: 13.0)
    @available(tvOS, deprecated: 13.0)
    /// Implementation of `UICollectionViewDelegateFlowLayout` and `UICollectionViewDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        if let perform = perform5ArgumentCellReaction(.canPerformActionForItemAtIndexPath, argumentOne: action, argumentTwo: sender as Any, location: indexPath, provideCell: true) as? Bool {
            return perform
        }
        return (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView, canPerformAction: action, forItemAt: indexPath, withSender: sender) ?? false
    }
    
    @available(iOS, deprecated: 13.0)
    @available(tvOS, deprecated: 13.0)
    /// Implementation of `UICollectionViewDelegateFlowLayout` and `UICollectionViewDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        _ = perform5ArgumentCellReaction(.performActionForItemAtIndexPath, argumentOne: action, argumentTwo: sender as Any, location: indexPath, provideCell: true)
        (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView, performAction: action, forItemAt: indexPath, withSender: sender)
    }
    
    /// Implementation of `UICollectionViewDelegateFlowLayout` and `UICollectionViewDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
        if let should = performCellReaction(.canFocusItemAtIndexPath, location: indexPath, provideCell: true) as? Bool {
            return should
        }
        return (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView, canFocusItemAt: indexPath) ?? true
    }
    
    /// Implementation of `UICollectionViewDelegateFlowLayout` and `UICollectionViewDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, transitionLayoutForOldLayout fromLayout: UICollectionViewLayout, newLayout toLayout: UICollectionViewLayout) -> UICollectionViewTransitionLayout {
        if let layout = performNonCellReaction(.transitionLayoutForOldLayoutNewLayout,
                                               argumentOne: fromLayout,
                                               argumentTwo: toLayout) as? UICollectionViewTransitionLayout {
            return layout
        }
        return (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView,
                                                                        transitionLayoutForOldLayout: fromLayout,
                                                                        newLayout: toLayout) ??   UICollectionViewTransitionLayout(currentLayout: fromLayout, nextLayout: toLayout)
    }
    
    /// Implementation of `UICollectionViewDelegateFlowLayout` and `UICollectionViewDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, shouldUpdateFocusIn context: UICollectionViewFocusUpdateContext) -> Bool {
        if let should = performNonCellReaction(.shouldUpdateFocusInContext, argument: context) as? Bool {
            return should
        }
        return (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView, shouldUpdateFocusIn: context) ?? true
    }
    
    /// Implementation of `UICollectionViewDelegateFlowLayout` and `UICollectionViewDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, didUpdateFocusIn context: UICollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        _ = performNonCellReaction(.didUpdateFocusInContext, argumentOne: context, argumentTwo: coordinator)
        (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView,
                                                                 didUpdateFocusIn: context,
                                                                 with: coordinator)
    }
    
    /// Implementation of `UICollectionViewDelegateFlowLayout` and `UICollectionViewDelegate` protocol.
    open func indexPathForPreferredFocusedView(in collectionView: UICollectionView) -> IndexPath? {
        if let reaction = collectionViewReactions.first(where: { $0.methodSignature == EventMethodSignature.indexPathForPreferredFocusedView.rawValue }) {
            return reaction.performWithArguments((0, 0, 0)) as? IndexPath
        }
        return (delegate as? UICollectionViewDelegate)?.indexPathForPreferredFocusedView?(in: collectionView)
    }
    
    /// Implementation of `UICollectionViewDelegateFlowLayout` and `UICollectionViewDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, targetIndexPathForMoveFromItemAt originalIndexPath: IndexPath, toProposedIndexPath proposedIndexPath: IndexPath) -> IndexPath {
        if let indexPath = perform4ArgumentCellReaction(.targetIndexPathForMoveFromItemAtTo,
                                                        argument: proposedIndexPath,
                                                        location: originalIndexPath,
                                                        provideCell: true) as? IndexPath {
            return indexPath
        }
        return (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView,
                                                                       targetIndexPathForMoveFromItemAt: originalIndexPath,
                                                                       toProposedIndexPath: proposedIndexPath) ?? IndexPath(item: 0, section: 0)
    }
    
    /// Implementation of `UICollectionViewDelegateFlowLayout` and `UICollectionViewDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, targetContentOffsetForProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        if let point = performNonCellReaction(.targetContentOffsetForProposedContentOffset, argument: proposedContentOffset) as? CGPoint {
            return point
        }
        return (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView,
                                                                targetContentOffsetForProposedContentOffset: proposedContentOffset) ?? .zero
    }
    
#if os(iOS)
    /// Implementation of `UICollectionViewDelegateFlowLayout` and `UICollectionViewDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, shouldSpringLoadItemAt indexPath: IndexPath, with context: UISpringLoadedInteractionContext) -> Bool {
        if let shouldSpringLoad = perform4ArgumentCellReaction(.shouldSpringLoadItem,
                                                               argument: context,
                                                               location: indexPath,
                                                               provideCell: true) as? Bool {
            return shouldSpringLoad
        }
        return (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView,
                                                                shouldSpringLoadItemAt: indexPath,
                                                                with: context) ?? true
    }

    #if compiler(>=5.1)
    @available(iOS 13.0, *)
    /// Implementation for `UICollectionViewDelegate` protocol
    open func collectionView(_ collectionView: UICollectionView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        if let should = performCellReaction(.shouldBeginMultipleSelectionInteractionAtIndexPath, location: indexPath, provideCell: true) as? Bool {
            return should
        }
        return (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView,
                                                                        shouldBeginMultipleSelectionInteractionAt: indexPath) ?? false
    }
    
    @available(iOS 13.0, *)
    /// Implementation for `UICollectionViewDelegate` protocol
    open func collectionView(_ collectionView: UICollectionView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        _ = performCellReaction(.didBeginMultipleSelectionInteractionAtIndexPath, location: indexPath, provideCell: true)
        (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView, didBeginMultipleSelectionInteractionAt: indexPath)
    }
    
    @available(iOS 13.0, *)
    /// Implementation for `UICollectionViewDelegate` protocol
    open func collectionViewDidEndMultipleSelectionInteraction(_ collectionView: UICollectionView) {
        _ = performNonCellReaction(.didEndMultipleSelectionInteraction)
        (delegate as? UICollectionViewDelegate)?.collectionViewDidEndMultipleSelectionInteraction?(collectionView)
    }
    
    @available(iOS 13.0, *)
    /// Implementation for `UICollectionViewDelegate` protocol
    open func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        if let configuration = perform4ArgumentCellReaction(.contextMenuConfigurationForItemAtIndexPath,
                                                            argument: point,
                                                            location: indexPath,
                                                            provideCell: true) as? UIContextMenuConfiguration {
            return configuration
        }
        return (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView,
                                                              contextMenuConfigurationForItemAt: indexPath,
                                                              point: point)
    }
    
    @available(iOS 13.0, *)
    /// Implementation for `UICollectionViewDelegate` protocol
    open func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        if let preview = performNonCellReaction(.previewForHighlightingContextMenu, argument: configuration) as? UITargetedPreview {
            return preview
        }
        return (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView, previewForHighlightingContextMenuWithConfiguration: configuration)
    }
    
    @available(iOS 13.0, *)
    /// Implementation for `UICollectionViewDelegate` protocol
    open func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        if let preview = performNonCellReaction(.previewForDismissingContextMenu, argument: configuration) as? UITargetedPreview {
            return preview
        }
        return (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView, previewForDismissingContextMenuWithConfiguration: configuration)
    }
        #if compiler(<5.1.2)
    @available(iOS 13.0, *)
    /// Implementation for `UICollectionViewDelegate` protocol
    open func collectionView(_ collectionView: UICollectionView, willCommitMenuWithAnimator animator: UIContextMenuInteractionCommitAnimating) {
        _ = performNonCellReaction(.willCommitMenuWithAnimator, argument: animator)
        (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView, willCommitMenuWithAnimator: animator)
    }
        #endif
    #endif
#endif
    
    /// Implementation of `UICollectionViewDelegateFlowLayout` and `UICollectionViewDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if let insets = performNonCellReaction(.insetForSectionAtIndex,
                                               argumentOne: collectionViewLayout,
                                               argumentTwo: section) as? UIEdgeInsets {
            return insets
        }
        let defaultInset = (collectionViewLayout as? UICollectionViewFlowLayout)?.sectionInset
        // UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)  is a workaround for Xcode 10 beta 1: https://bugs.swift.org/browse/SR-7879
        return (delegate as? UICollectionViewDelegateFlowLayout)?.collectionView?(collectionView,
                                                                          layout: collectionViewLayout,
                                                                          insetForSectionAt: section) ?? defaultInset ?? UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    /// Implementation of `UICollectionViewDelegateFlowLayout` and `UICollectionViewDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if let lineSpacing = performNonCellReaction(.minimumLineSpacingForSectionAtIndex,
                                               argumentOne: collectionViewLayout,
                                               argumentTwo: section) as? CGFloat {
            return lineSpacing
        }
        let defaultLineSpacing = (collectionViewLayout as? UICollectionViewFlowLayout)?.minimumLineSpacing
        return (delegate as? UICollectionViewDelegateFlowLayout)?.collectionView?(collectionView,
                                                                                  layout: collectionViewLayout,
                                                                                  minimumLineSpacingForSectionAt: section) ?? defaultLineSpacing ?? 0
    }
    
    /// Implementation of `UICollectionViewDelegateFlowLayout` and `UICollectionViewDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if let interItemSpacing = performNonCellReaction(.minimumInteritemSpacingForSectionAtIndex,
                                                    argumentOne: collectionViewLayout,
                                                    argumentTwo: section) as? CGFloat {
            return interItemSpacing
        }
        let defaultInterItemSpacing = (collectionViewLayout as? UICollectionViewFlowLayout)?.minimumInteritemSpacing
        return (delegate as? UICollectionViewDelegateFlowLayout)?.collectionView?(collectionView,
                                                                                  layout: collectionViewLayout,
                                                                                  minimumInteritemSpacingForSectionAt: section) ?? defaultInterItemSpacing ?? 0
    }
}
