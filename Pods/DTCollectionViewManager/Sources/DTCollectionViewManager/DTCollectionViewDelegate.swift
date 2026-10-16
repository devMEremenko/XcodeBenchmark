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
        if let size = performSupplementaryReaction(ofKind: UICollectionView.elementKindSectionHeader, signature: .referenceSizeForHeaderInSection, location: IndexPath(item:0, section: section), view: nil) as? CGSize {
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
        if let size = performSupplementaryReaction(ofKind: UICollectionView.elementKindSectionFooter, signature: .referenceSizeForFooterInSection, location: IndexPath(item: 0, section: section), view: nil) as? CGSize {
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
        _ = EventReaction.performReaction(from: viewFactory?.mappings ?? [], signature: EventMethodSignature.willDisplayCellForItemAtIndexPath.rawValue, view: cell, model: model, location: indexPath)
    }
    
    /// Implementation of `UICollectionViewDelegateFlowLayout` and `UICollectionViewDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        _ = performSupplementaryReaction(ofKind: elementKind, signature: .willDisplaySupplementaryViewForElementKindAtIndexPath, location: indexPath, view: view)
        (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView, willDisplaySupplementaryView: view, forElementKind: elementKind, at: indexPath)
    }
    
    /// Implementation of `UICollectionViewDelegateFlowLayout` and `UICollectionViewDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        defer { (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView, didEndDisplaying: cell, forItemAt: indexPath) }
        guard let model = storage?.item(at: indexPath) else { return }
        _ = EventReaction.performReaction(from: viewFactory?.mappings ?? [], signature: EventMethodSignature.didEndDisplayingCellForItemAtIndexPath.rawValue, view: cell, model: model, location: indexPath)
    }
    
    /// Implementation of `UICollectionViewDelegateFlowLayout` and `UICollectionViewDelegate` protocol.
    open func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
        defer { (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView, didEndDisplayingSupplementaryView: view, forElementOfKind: elementKind, at: indexPath) }
        guard let model = supplementaryModel(ofKind: elementKind, forSectionAt: indexPath) else { return }
        _ = EventReaction.performReaction(from: viewFactory?.mappings ?? [], signature: EventMethodSignature.didEndDisplayingSupplementaryViewForElementKindAtIndexPath.rawValue, view: view, model: model, location: indexPath, supplementaryKind: elementKind)
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
        if let reaction = unmappedReactions.first(where: { $0.methodSignature == EventMethodSignature.indexPathForPreferredFocusedView.rawValue }) {
            return reaction.performWithArguments((0, 0, 0)) as? IndexPath
        }
        return (delegate as? UICollectionViewDelegate)?.indexPathForPreferredFocusedView?(in: collectionView)
    }
    
    @available(iOS, deprecated: 15.0, message: "Use targetIndexPathForMoveFromItem: instead")
    @available(tvOS, deprecated: 15.0, message: "Use targetIndexPathForMoveFromItem: instead")
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
    
    @available(iOS 14, tvOS 14, *)
    /// Implementation of `UICollectionViewDelegate` protocol.
    public func collectionView(_ collectionView: UICollectionView, canEditItemAt indexPath: IndexPath) -> Bool {
        if let canEdit = performCellReaction(.canEditItemAtIndexPath, location: indexPath, provideCell: false) as? Bool {
            return canEdit
        }
        return (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView, canEditItemAt: indexPath) ?? false
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
    @available(iOS, deprecated: 16.0)
    /// Implementation for `UICollectionViewDelegate` protocol
    open func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        if let _ = cellReaction(.contextMenuConfigurationForItemAtIndexPath, location: indexPath) as? FourArgumentsEventReaction {
            return perform4ArgumentCellReaction(.contextMenuConfigurationForItemAtIndexPath,
                                                argument: point,
                                                location: indexPath,
                                                provideCell: true) as? UIContextMenuConfiguration
        }
        return (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView,
                                                              contextMenuConfigurationForItemAt: indexPath,
                                                              point: point)
    }
    
    @available(iOS 13.0, *)
    @available(iOS, deprecated: 16.0)
    /// Implementation for `UICollectionViewDelegate` protocol
    open func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        if unmappedReactions.contains(where: { $0.methodSignature == EventMethodSignature.previewForHighlightingContextMenu.rawValue }) {
            return performNonCellReaction(.previewForHighlightingContextMenu, argument: configuration) as? UITargetedPreview
        }
        return (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView, previewForHighlightingContextMenuWithConfiguration: configuration)
    }
    
    @available(iOS 13.0, *)
    @available(iOS, deprecated: 16.0)
    /// Implementation for `UICollectionViewDelegate` protocol
    open func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        if unmappedReactions.contains(where: { $0.methodSignature == EventMethodSignature.previewForDismissingContextMenu.rawValue }) {
            return performNonCellReaction(.previewForDismissingContextMenu, argument: configuration) as? UITargetedPreview
        }
        return (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView, previewForDismissingContextMenuWithConfiguration: configuration)
    }
    
    @available(iOS 15, *)
    /// Implementation for `UICollectionViewDelegate` protocol
    public func collectionView(_ collectionView: UICollectionView, selectionFollowsFocusForItemAt indexPath: IndexPath) -> Bool {
        if let follows = performCellReaction(.selectionFollowsFocusForItemAtIndexPath, location: indexPath, provideCell: true) as? Bool {
            return follows
        }
        if let followsFocus = (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView, selectionFollowsFocusForItemAt: indexPath) {
            return followsFocus
        }
        return collectionView.selectionFollowsFocus
    }
#endif
    
    @available(iOS 15, tvOS 15, *)
    /// Implementation for `UICollectionViewDelegate` protocol
    public func collectionView(_ collectionView: UICollectionView, targetIndexPathForMoveOfItemFromOriginalIndexPath originalIndexPath: IndexPath, atCurrentIndexPath currentIndexPath: IndexPath, toProposedIndexPath proposedIndexPath: IndexPath) -> IndexPath
    {
        if let indexPath = perform5ArgumentCellReaction(.targetIndexPathForMoveOfItemFromOriginalIndexPath, argumentOne: currentIndexPath, argumentTwo: proposedIndexPath, location: originalIndexPath, provideCell: true) as? IndexPath {
            return indexPath
        }
        return (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView, targetIndexPathForMoveOfItemFromOriginalIndexPath: originalIndexPath, atCurrentIndexPath: currentIndexPath, toProposedIndexPath: proposedIndexPath) ?? proposedIndexPath
    }
    
#if swift(>=5.7) && !canImport(AppKit) || (canImport(AppKit) && swift(>=5.7.1)) // Xcode 14.0 AND macCatalyst on Xcode 14.1 (which will have swift> 5.7.1)
    @available(iOS 16, tvOS 16, *)
    /// Implementation for `UICollectionViewDelegate` protocol
    public func collectionView(_ collectionView: UICollectionView, canPerformPrimaryActionForRowAt indexPath: IndexPath) -> Bool {
        if let canPerform = performCellReaction(.canPerformActionForItemAtIndexPath, location: indexPath, provideCell: true) as? Bool {
            return canPerform
        }
        return (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView, canPerformPrimaryActionForItemAt: indexPath) ?? false
    }
    
    @available(iOS 16, tvOS 16, *)
    /// Implementation for `UICollectionViewDelegate` protocol
    public func collectionView(_ collectionView: UICollectionView, performPrimaryActionForItemAt indexPath: IndexPath) {
        _ = performCellReaction(.performPrimaryActionForItemAtIndexPath, location: indexPath, provideCell: true)
        (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView, performPrimaryActionForItemAt: indexPath)
    }
    
    #if os(iOS)
    @available(iOS 16, *)
    /// Implementation for `UICollectionViewDelegate` protocol
    public func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemsAt indexPaths: [IndexPath], point: CGPoint) -> UIContextMenuConfiguration? {
        if unmappedReactions.contains(where: { $0.methodSignature == EventMethodSignature.contextMenuConfigurationForItemsAtIndexPaths.rawValue }) {
            return performNonCellReaction(.contextMenuConfigurationForItemsAtIndexPaths, argumentOne: indexPaths, argumentTwo: point) as? UIContextMenuConfiguration
        }
        return (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView, contextMenuConfigurationForItemsAt: indexPaths, point: point)
    }
    
    @available(iOS 16, *)
    /// Implementation for `UICollectionViewDelegate` protocol
    public func collectionView(_ collectionView: UICollectionView, contextMenuConfiguration configuration: UIContextMenuConfiguration, highlightPreviewForItemAt indexPath: IndexPath) -> UITargetedPreview? {
        if let _ = cellReaction(.highlightPreviewForItemAtIndexPath, location: indexPath) as? FourArgumentsEventReaction {
            return perform4ArgumentCellReaction(.highlightPreviewForItemAtIndexPath, argument: configuration, location: indexPath, provideCell: true) as? UITargetedPreview
        }
        return (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView, contextMenuConfiguration: configuration, highlightPreviewForItemAt: indexPath)
    }
    
    @available(iOS 16, *)
    /// Implementation for `UICollectionViewDelegate` protocol
    public func collectionView(_ collectionView: UICollectionView, contextMenuConfiguration configuration: UIContextMenuConfiguration, dismissalPreviewForItemAt indexPath: IndexPath) -> UITargetedPreview? {
        if let _ = cellReaction(.dismissalPreviewForItemAtIndexPath, location: indexPath) as? FourArgumentsEventReaction {
            return perform4ArgumentCellReaction(.dismissalPreviewForItemAtIndexPath, argument: configuration, location: indexPath, provideCell: true) as? UITargetedPreview
        }
        return (delegate as? UICollectionViewDelegate)?.collectionView?(collectionView, contextMenuConfiguration: configuration, dismissalPreviewForItemAt: indexPath)
    }
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
        return (delegate as? UICollectionViewDelegateFlowLayout)?.collectionView?(collectionView,
                                                                          layout: collectionViewLayout,
                                                                          insetForSectionAt: section) ?? defaultInset ?? .zero
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

#if canImport(TVUIKit)
import TVUIKit

@available(tvOS 13.0, *)
extension DTCollectionViewDelegate : TVCollectionViewDelegateFullScreenLayout {
    /// Implementation of `TVCollectionViewDelegateFullScreenLayout` protocol.
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, willCenterCellAt indexPath: IndexPath) {
        _ = performCellReaction(.willCenterCellAtIndexPath, location: indexPath, provideCell: true)
        (delegate as? TVCollectionViewDelegateFullScreenLayout)?.collectionView?(collectionView, layout: collectionViewLayout, willCenterCellAt: indexPath)
    }
    
    /// Implementation of `TVCollectionViewDelegateFullScreenLayout` protocol.
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, didCenterCellAt indexPath: IndexPath) {
        _ = performCellReaction(.didCenterCellAtIndexPath, location: indexPath, provideCell: true)
        (delegate as? TVCollectionViewDelegateFullScreenLayout)?.collectionView?(collectionView, layout: collectionViewLayout, didCenterCellAt: indexPath)
    }
}
#endif
