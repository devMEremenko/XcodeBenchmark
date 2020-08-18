//
//  DTCollectionViewManager+Delegate.swift
//  DTCollectionViewManager
//
//  Created by Denys Telezhkin on 27.08.17.
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
import DTModelStorage
import UIKit

extension DTCollectionViewManager {
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:didSelectItemAt:)` method is called for `cellClass`.
    open func didSelect<T:ModelTransfer>(_ cellClass:  T.Type, _ closure: @escaping (T, T.ModelType, IndexPath) -> Void) where T:UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: T.self, signature: .didSelectItemAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:shouldSelectItemAt:)` method is called for `cellClass`.
    open func shouldSelect<T:ModelTransfer>(_ cellClass:T.Type, _ closure: @escaping (T, T.ModelType, IndexPath) -> Bool) where T: UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: T.self, signature: EventMethodSignature.shouldSelectItemAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:shouldDeselectItemAt:)` method is called for `cellClass`.
    open func shouldDeselect<T:ModelTransfer>(_ cellClass:T.Type, _ closure: @escaping (T, T.ModelType, IndexPath) -> Bool) where T: UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: T.self, signature: EventMethodSignature.shouldDeselectItemAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:didDeselectItemAt:)` method is called for `cellClass`.
    open func didDeselect<T:ModelTransfer>(_ cellClass:  T.Type, _ closure: @escaping (T, T.ModelType, IndexPath) -> Void) where T:UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: T.self, signature: .didDeselectItemAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:shouldHighlightItemAt:)` method is called for `cellClass`.
    open func shouldHighlight<T:ModelTransfer>(_ cellClass:T.Type, _ closure: @escaping (T, T.ModelType, IndexPath) -> Bool) where T: UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: T.self, signature: EventMethodSignature.shouldHighlightItemAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:didHighlightItemAt:)` method is called for `cellClass`.
    open func didHighlight<T:ModelTransfer>(_ cellClass:T.Type, _ closure: @escaping (T, T.ModelType, IndexPath) -> Void) where T: UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: T.self, signature: EventMethodSignature.didHighlightItemAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:didUnhighlightItemAt:)` method is called for `cellClass`.
    open func didUnhighlight<T:ModelTransfer>(_ cellClass:T.Type, _ closure: @escaping (T, T.ModelType, IndexPath) -> Void) where T: UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: T.self, signature: EventMethodSignature.didUnhighlightItemAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:willDisplayCell:forItemAt:)` method is called for `cellClass`.
    open func willDisplay<T:ModelTransfer>(_ cellClass:T.Type, _ closure: @escaping (T, T.ModelType, IndexPath) -> Void) where T: UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: T.self, signature: EventMethodSignature.willDisplayCellForItemAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:willDisplaySupplementaryView:forElementKind:at:)` method is called for `supplementaryClass` of `kind`.
    open func willDisplaySupplementaryView<T:ModelTransfer>(_ supplementaryClass:T.Type, forElementKind kind: String, _ closure: @escaping (T, T.ModelType, IndexPath) -> Void) where T: UICollectionReusableView
    {
        collectionDelegate?.appendReaction(forSupplementaryKind: kind, supplementaryClass: T.self, signature: EventMethodSignature.willDisplaySupplementaryViewForElementKindAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:willDisplaySupplementaryView:forElementKind:at:)` method is called for `supplementaryClass` of `UICollectionElementKindSectionHeader`.
    open func willDisplayHeaderView<T:ModelTransfer>(_ headerClass:T.Type, _ closure: @escaping (T, T.ModelType, IndexPath) -> Void) where T: UICollectionReusableView
    {
        willDisplaySupplementaryView(T.self, forElementKind: UICollectionView.elementKindSectionHeader, closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:willDisplaySupplementaryView:forElementKind:at:)` method is called for `supplementaryClass` of `UICollectionElementKindSectionFooter`.
    open func willDisplayFooterView<T:ModelTransfer>(_ footerClass:T.Type, _ closure: @escaping (T, T.ModelType, IndexPath) -> Void) where T: UICollectionReusableView
    {
        willDisplaySupplementaryView(T.self, forElementKind: UICollectionView.elementKindSectionFooter, closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:didEndDisplaying:forItemAt:)` method is called for `cellClass`.
    open func didEndDisplaying<T:ModelTransfer>(_ cellClass:T.Type, _ closure: @escaping (T, T.ModelType, IndexPath) -> Void) where T: UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: T.self, signature: EventMethodSignature.didEndDisplayingCellForItemAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:didEndDisplayingSupplementaryView:forElementKind:at:)` method is called for `supplementaryClass` of `kind`.
    open func didEndDisplayingSupplementaryView<T:ModelTransfer>(_ supplementaryClass:T.Type, forElementKind kind: String, _ closure: @escaping (T, T.ModelType, IndexPath) -> Void) where T: UICollectionReusableView
    {
        collectionDelegate?.appendReaction(forSupplementaryKind: kind, supplementaryClass: T.self, signature: EventMethodSignature.didEndDisplayingSupplementaryViewForElementKindAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:didEndDisplayingSupplementaryView:forElementKind:at:)` method is called for `headerClass` of `UICollectionElementKindSectionHeader`.
    open func didEndDisplayingHeaderView<T:ModelTransfer>(_ headerClass:T.Type, _ closure: @escaping (T, T.ModelType, IndexPath) -> Void) where T: UICollectionReusableView
    {
        didEndDisplayingSupplementaryView(T.self, forElementKind: UICollectionView.elementKindSectionHeader, closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:didEndDisplayingSupplementaryView:forElementKind:at:)` method is called for `footerClass` of `UICollectionElementKindSectionFooter`.
    open func didEndDisplayingFooterView<T:ModelTransfer>(_ footerClass:T.Type, _ closure: @escaping (T, T.ModelType, IndexPath) -> Void) where T: UICollectionReusableView
    {
        didEndDisplayingSupplementaryView(T.self, forElementKind: UICollectionView.elementKindSectionFooter, closure)
    }
    
    @available(iOS, deprecated: 13.0)
    @available(tvOS, deprecated: 13.0)
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:shouldShowMenuForItemAt:)` method is called for `cellClass`.
    open func shouldShowMenu<T:ModelTransfer>(for cellClass:T.Type, _ closure: @escaping (T, T.ModelType, IndexPath) -> Bool) where T: UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: T.self, signature: EventMethodSignature.shouldShowMenuForItemAtIndexPath, closure: closure)
    }
    
    @available(iOS, deprecated: 13.0)
    @available(tvOS, deprecated: 13.0)
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:canPerformAction:forItemAt:withSender:)` method is called for `cellClass`.
    open func canPerformAction<T:ModelTransfer>(for cellClass: T.Type, _ closure: @escaping (Selector, Any?, T, T.ModelType, IndexPath) -> Bool) where T: UICollectionViewCell {
        collectionDelegate?.append5ArgumentReaction(for: T.self,
                                                    signature: .canPerformActionForItemAtIndexPath,
                                                    closure: closure)
    }
    
    @available(iOS, deprecated: 13.0)
    @available(tvOS, deprecated: 13.0)
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:performAction:forItemAt:withSender:)` method is called for `cellClass`.
    open func performAction<T:ModelTransfer>(for cellClass: T.Type, _ closure: @escaping (Selector, Any?, T, T.ModelType, IndexPath) -> Void) where T: UICollectionViewCell {
        collectionDelegate?.append5ArgumentReaction(for: T.self,
                                                    signature: .performActionForItemAtIndexPath,
                                                    closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:canFocusItemAt:)` method is called for `cellClass`.
    open func canFocus<T:ModelTransfer>(_ cellClass:T.Type, _ closure: @escaping (T, T.ModelType, IndexPath) -> Bool) where T: UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: T.self, signature: EventMethodSignature.canFocusItemAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed when `UICollectionViewDelegate.collectionView(_:shouldUpdateFocusInContext:)` method is called.
    open func shouldUpdateFocus(_ closure: @escaping (UICollectionViewFocusUpdateContext) -> Bool) {
        collectionDelegate?.appendNonCellReaction(.shouldUpdateFocusInContext, closure: closure)
    }
    
    /// Registers `closure` tp be executed when `UICollectionViewDelegate.collectionView(_:didUpdateFocusIn:with:)` method is called.
    open func didUpdateFocus(_ closure: @escaping (UICollectionViewFocusUpdateContext, UIFocusAnimationCoordinator) -> Void) {
        collectionDelegate?.appendNonCellReaction(.didUpdateFocusInContext, closure: closure)
    }
    
    /// Registers `closure` to be executed when `UICollectionViewDelegate.indexPathForPreferredFocusedView(in:)` method is called
    open func indexPathForPreferredFocusedView(_ closure: @escaping () -> IndexPath?) {
        collectionDelegate?.appendNonCellReaction(.indexPathForPreferredFocusedView, closure: closure)
    }
    
    /// Registers `closure` to be executed when `UICollectionViewDelegate.targetIndexPathForMoveFromItemAt(_:toProposed:)` method is called for `cellClass`
    open func targetIndexPathForMovingItem<T:ModelTransfer>(_ cellClass: T.Type, _ closure: @escaping (IndexPath, T, T.ModelType, IndexPath) -> IndexPath) where T: UICollectionViewCell {
        collectionDelegate?.append4ArgumentReaction(for: T.self,
                                                    signature: .targetIndexPathForMoveFromItemAtTo,
                                                    closure: closure)
    }
    
    /// Registers `closure` to be executed when `UICollectionViewDelegate.collectionView(_:targetContentOffsetForProposedContentOffset:)` method is called.
    open func targetContentOffsetForProposedContentOffset(_ closure: @escaping (CGPoint) -> CGPoint) {
        collectionDelegate?.appendNonCellReaction(.targetContentOffsetForProposedContentOffset,
                                                  closure: closure)
    }
    
    #if os(iOS)
    /// Registers `closure` to be executed when `UICollectionViewDelegate.collectionView(_:shouldSpringLoadItemAt:)` method is called for `cellClass`.
    open func shouldSpringLoad<T:ModelTransfer>(_ cellClass: T.Type, _ closure: @escaping (UISpringLoadedInteractionContext, T, T.ModelType, IndexPath) -> Bool)
        where T: UICollectionViewCell
    {
        collectionDelegate?.append4ArgumentReaction(for: T.self,
                                                    signature: .shouldSpringLoadItem,
                                                    closure: closure)
    }
    
#if compiler(>=5.1)
    @available(iOS 13, *)
    /// Registers `closure` to be executed when `UICollectionViewDelegate.collectionView(_:shouldBeginMultipleSelectionInteractionAt:)`method is called for `cellClass`.
    /// - Parameter Type: cell class to react for event
    /// - Parameter closure: closure to run.
    open func shouldBeginMultipleSelectionInteraction<T:ModelTransfer>(for cellClass: T.Type,
                                                                       _ closure: @escaping (T, T.ModelType, IndexPath) -> Bool)
        where T: UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: T.self,
                                      signature: .shouldBeginMultipleSelectionInteractionAtIndexPath,
                                      closure: closure)
    }
    
    @available(iOS 13, *)
    /// Registers `closure` to be executed when `UICollectionViewDelegate.collectionView(_:didBeginMultipleSelectionInteractionAt:)`method is called for `cellClass`.
    /// - Parameter Type: cell class to react for event
    /// - Parameter closure: closure to run.
    open func didBeginMultipleSelectionInteraction<T:ModelTransfer>(for cellClass: T.Type,
                                                                    _ closure: @escaping (T, T.ModelType, IndexPath) -> Void)
        where T: UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: T.self,
                                      signature: .didBeginMultipleSelectionInteractionAtIndexPath,
                                      closure: closure)
    }
    
    @available(iOS 13, *)
    /// Registers `closure` to be executed when `UICollectionViewDelegate.collectionViewDidEndMultipleSelectionInteraction(_:)`method is called.
    /// - Parameter closure: closure to run.
    open func didEndMultipleSelectionInteraction(_ closure: @escaping () -> Void)
    {
        collectionDelegate?.appendNonCellReaction(.didEndMultipleSelectionInteraction, closure: closure)
    }
    
    @available(iOS 13.0, *)
    /// Registers `closure` to be executed when `UICollectionViewDelegate.contextMenuConfigurationForItemAt(_:point:)` method is called
    open func contextMenuConfiguration<T:ModelTransfer>(for cellClass: T.Type,
                                                        _ closure: @escaping (CGPoint, T, T.ModelType, IndexPath) -> UIContextMenuConfiguration?)
        where T: UICollectionViewCell
    {
        collectionDelegate?.append4ArgumentReaction(for: T.self,
                                               signature: .contextMenuConfigurationForItemAtIndexPath,
                                               closure: closure)
    }
    
    @available(iOS 13.0, *)
    /// Registers `closure` to be executed when `UICollectionViewDelegate.collectionView(_:previewForHighlightingContextMenuWithConfiguration:)` method is called
    open func previewForHighlightingContextMenu(_ closure: @escaping (UIContextMenuConfiguration) -> UITargetedPreview?)
    {
        collectionDelegate?.appendNonCellReaction(.previewForHighlightingContextMenu, closure: closure)
    }
    
    @available(iOS 13.0, *)
    /// Registers `closure` to be executed when `UICollectionViewDelegate.collectionView(_:previewForDismissingContextMenuWithConfiguration:)` method is called
    open func previewForDismissingContextMenu(_ closure: @escaping (UIContextMenuConfiguration) -> UITargetedPreview?)
    {
        collectionDelegate?.appendNonCellReaction(.previewForDismissingContextMenu, closure: closure)
    }
    
    @available(iOS 13.0, *)
    /// Registers `closure` to be executed when `UICollectionViewDelegate.tableView(_:willCommitMenuWithAnimator:)` method is called
    open func willCommitMenuWithAnimator(_ closure: @escaping (UIContextMenuInteractionCommitAnimating) -> Void)
    {
        collectionDelegate?.appendNonCellReaction(.willCommitMenuWithAnimator, closure: closure)
    }
    #endif
#endif
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    /// Registers `closure` to be executed to determine cell size in `UICollectionViewDelegateFlowLayout.collectionView(_:sizeForItemAt:)` method, when it's called for cell which model is of `itemType`.
    open func sizeForCell<T>(withItem: T.Type, _ closure: @escaping (T, IndexPath) -> CGSize)
    {
        collectionDelegate?.appendReaction(for: T.self, signature: EventMethodSignature.sizeForItemAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed to determine header size in `UICollectionViewDelegateFlowLayout.collectionView(_:layout:referenceSizeForHeaderViewInSection:)` method, when it's called for header which model is of `itemType`.
    open func referenceSizeForHeaderView<T>(withItem: T.Type, _ closure: @escaping (T, IndexPath) -> CGSize)
    {
        collectionDelegate?.appendReaction(forSupplementaryKind: UICollectionView.elementKindSectionHeader, modelClass: T.self, signature: EventMethodSignature.referenceSizeForHeaderInSection, closure: closure)
    }
    
    /// Registers `closure` to be executed to determine footer size in `UICollectionViewDelegateFlowLayout.collectionView(_:layout:referenceSizeForFooterViewInSection:)` method, when it's called for footer which model is of `itemType`.
    open func referenceSizeForFooterView<T>(withItem: T.Type, _ closure: @escaping (T, IndexPath) -> CGSize)
    {
        collectionDelegate?.appendReaction(forSupplementaryKind: UICollectionView.elementKindSectionFooter, modelClass: T.self, signature: EventMethodSignature.referenceSizeForFooterInSection, closure: closure)
    }
    
    /// Registers `closure` to be executed when `UICollectionViewDelegate.collectionView(_:transitionLayoutForOldLayout:toNewLayout:`) method is called
    open func transitionLayout(_ closure: @escaping (_ oldLayout: UICollectionViewLayout, _ newLayout: UICollectionViewLayout) -> UICollectionViewTransitionLayout) {
        collectionDelegate?.appendNonCellReaction(.transitionLayoutForOldLayoutNewLayout,
                                                  closure: closure)
    }
    
    /// Registers `closure` to be executed when `UICollectionViewDelegateFlowLayout.collectionView(_:layout:insetForSectionAt:)` method is called.
    open func insetForSectionAtIndex(_ closure: @escaping (UICollectionViewLayout, Int) -> UIEdgeInsets) {
        collectionDelegate?.appendNonCellReaction(.insetForSectionAtIndex, closure: closure)
    }
    
    /// Registers `closure` to be executed when `UICollectionViewDelegateFlowLayout.collectionView(_:layout:minimumLineSpacingForSectionAt:)` method is called.
    open func minimumLineSpacingForSectionAtIndex(_ closure: @escaping (UICollectionViewLayout, Int) -> CGFloat) {
        collectionDelegate?.appendNonCellReaction(.minimumLineSpacingForSectionAtIndex, closure: closure)
    }
    
    /// Registers `closure` to be executed when `UICollectionViewDelegateFlowLayout.collectionView(_:layout:insetForSectionAt:)` method is called.
    open func minimumInteritemSpacingForSectionAtIndex(_ closure: @escaping (UICollectionViewLayout, Int) -> CGFloat) {
        collectionDelegate?.appendNonCellReaction(.minimumInteritemSpacingForSectionAtIndex, closure: closure)
    }
}
