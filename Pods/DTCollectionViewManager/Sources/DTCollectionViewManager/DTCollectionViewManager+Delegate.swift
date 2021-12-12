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

#if canImport(TVUIKit)
import TVUIKit
#endif

extension DTCollectionViewManager {
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:didSelectItemAt:)` method is called for `cellClass`.
    open func didSelect<Cell:ModelTransfer>(_ cellClass:  Cell.Type, _ closure: @escaping (Cell, Cell.ModelType, IndexPath) -> Void) where Cell:UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: Cell.self, signature: .didSelectItemAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:shouldSelectItemAt:)` method is called for `cellClass`.
    open func shouldSelect<Cell:ModelTransfer>(_ cellClass:Cell.Type, _ closure: @escaping (Cell, Cell.ModelType, IndexPath) -> Bool) where Cell: UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: Cell.self, signature: EventMethodSignature.shouldSelectItemAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:shouldDeselectItemAt:)` method is called for `cellClass`.
    open func shouldDeselect<Cell:ModelTransfer>(_ cellClass:Cell.Type, _ closure: @escaping (Cell, Cell.ModelType, IndexPath) -> Bool) where Cell: UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: Cell.self, signature: EventMethodSignature.shouldDeselectItemAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:didDeselectItemAt:)` method is called for `cellClass`.
    open func didDeselect<Cell:ModelTransfer>(_ cellClass: Cell.Type, _ closure: @escaping (Cell, Cell.ModelType, IndexPath) -> Void) where Cell:UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: Cell.self, signature: .didDeselectItemAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:shouldHighlightItemAt:)` method is called for `cellClass`.
    open func shouldHighlight<Cell:ModelTransfer>(_ cellClass:Cell.Type, _ closure: @escaping (Cell, Cell.ModelType, IndexPath) -> Bool) where Cell: UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: Cell.self, signature: EventMethodSignature.shouldHighlightItemAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:didHighlightItemAt:)` method is called for `cellClass`.
    open func didHighlight<Cell:ModelTransfer>(_ cellClass:Cell.Type, _ closure: @escaping (Cell, Cell.ModelType, IndexPath) -> Void) where Cell: UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: Cell.self, signature: EventMethodSignature.didHighlightItemAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:didUnhighlightItemAt:)` method is called for `cellClass`.
    open func didUnhighlight<Cell:ModelTransfer>(_ cellClass:Cell.Type, _ closure: @escaping (Cell, Cell.ModelType, IndexPath) -> Void) where Cell: UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: Cell.self, signature: EventMethodSignature.didUnhighlightItemAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:willDisplayCell:forItemAt:)` method is called for `cellClass`.
    open func willDisplay<Cell:ModelTransfer>(_ cellClass:Cell.Type, _ closure: @escaping (Cell, Cell.ModelType, IndexPath) -> Void) where Cell: UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: Cell.self, signature: EventMethodSignature.willDisplayCellForItemAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:willDisplaySupplementaryView:forElementKind:at:)` method is called for `supplementaryClass` of `kind`.
    open func willDisplaySupplementaryView<View:ModelTransfer>(_ supplementaryClass:View.Type, forElementKind kind: String, _ closure: @escaping (View, View.ModelType, IndexPath) -> Void) where View: UICollectionReusableView
    {
        collectionDelegate?.appendReaction(forSupplementaryKind: kind, supplementaryClass: View.self, signature: EventMethodSignature.willDisplaySupplementaryViewForElementKindAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:willDisplaySupplementaryView:forElementKind:at:)` method is called for `supplementaryClass` of `UICollectionElementKindSectionHeader`.
    open func willDisplayHeaderView<View:ModelTransfer>(_ headerClass:View.Type, _ closure: @escaping (View, View.ModelType, IndexPath) -> Void) where View: UICollectionReusableView
    {
        willDisplaySupplementaryView(View.self, forElementKind: UICollectionView.elementKindSectionHeader, closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:willDisplaySupplementaryView:forElementKind:at:)` method is called for `supplementaryClass` of `UICollectionElementKindSectionFooter`.
    open func willDisplayFooterView<View:ModelTransfer>(_ footerClass:View.Type, _ closure: @escaping (View, View.ModelType, IndexPath) -> Void) where View: UICollectionReusableView
    {
        willDisplaySupplementaryView(View.self, forElementKind: UICollectionView.elementKindSectionFooter, closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:didEndDisplaying:forItemAt:)` method is called for `cellClass`.
    open func didEndDisplaying<Cell:ModelTransfer>(_ cellClass:Cell.Type, _ closure: @escaping (Cell, Cell.ModelType, IndexPath) -> Void) where Cell: UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: Cell.self, signature: EventMethodSignature.didEndDisplayingCellForItemAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:didEndDisplayingSupplementaryView:forElementKind:at:)` method is called for `supplementaryClass` of `kind`.
    open func didEndDisplayingSupplementaryView<View:ModelTransfer>(_ supplementaryClass:View.Type, forElementKind kind: String, _ closure: @escaping (View, View.ModelType, IndexPath) -> Void) where View: UICollectionReusableView
    {
        collectionDelegate?.appendReaction(forSupplementaryKind: kind, supplementaryClass: View.self, signature: EventMethodSignature.didEndDisplayingSupplementaryViewForElementKindAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:didEndDisplayingSupplementaryView:forElementKind:at:)` method is called for `headerClass` of `UICollectionElementKindSectionHeader`.
    open func didEndDisplayingHeaderView<View:ModelTransfer>(_ headerClass:View.Type, _ closure: @escaping (View, View.ModelType, IndexPath) -> Void) where View: UICollectionReusableView
    {
        didEndDisplayingSupplementaryView(View.self, forElementKind: UICollectionView.elementKindSectionHeader, closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:didEndDisplayingSupplementaryView:forElementKind:at:)` method is called for `footerClass` of `UICollectionElementKindSectionFooter`.
    open func didEndDisplayingFooterView<View:ModelTransfer>(_ footerClass:View.Type, _ closure: @escaping (View, View.ModelType, IndexPath) -> Void) where View: UICollectionReusableView
    {
        didEndDisplayingSupplementaryView(View.self, forElementKind: UICollectionView.elementKindSectionFooter, closure)
    }
    
    @available(iOS, deprecated: 13.0)
    @available(tvOS, deprecated: 13.0)
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:shouldShowMenuForItemAt:)` method is called for `cellClass`.
    open func shouldShowMenu<Cell:ModelTransfer>(for cellClass:Cell.Type, _ closure: @escaping (Cell, Cell.ModelType, IndexPath) -> Bool) where Cell: UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: Cell.self, signature: EventMethodSignature.shouldShowMenuForItemAtIndexPath, closure: closure)
    }
    
    @available(iOS, deprecated: 13.0)
    @available(tvOS, deprecated: 13.0)
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:canPerformAction:forItemAt:withSender:)` method is called for `cellClass`.
    open func canPerformAction<Cell:ModelTransfer>(for cellClass: Cell.Type, _ closure: @escaping (Selector, Any?, Cell, Cell.ModelType, IndexPath) -> Bool) where Cell: UICollectionViewCell {
        collectionDelegate?.append5ArgumentReaction(for: Cell.self,
                                                    signature: .canPerformActionForItemAtIndexPath,
                                                    closure: closure)
    }
    
    @available(iOS, deprecated: 13.0)
    @available(tvOS, deprecated: 13.0)
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:performAction:forItemAt:withSender:)` method is called for `cellClass`.
    open func performAction<Cell:ModelTransfer>(for cellClass: Cell.Type, _ closure: @escaping (Selector, Any?, Cell, Cell.ModelType, IndexPath) -> Void) where Cell: UICollectionViewCell {
        collectionDelegate?.append5ArgumentReaction(for: Cell.self,
                                                    signature: .performActionForItemAtIndexPath,
                                                    closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:canFocusItemAt:)` method is called for `cellClass`.
    open func canFocus<Cell:ModelTransfer>(_ cellClass:Cell.Type, _ closure: @escaping (Cell, Cell.ModelType, IndexPath) -> Bool) where Cell: UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: Cell.self, signature: EventMethodSignature.canFocusItemAtIndexPath, closure: closure)
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
    open func targetIndexPathForMovingItem<Cell:ModelTransfer>(_ cellClass: Cell.Type, _ closure: @escaping (IndexPath, Cell, Cell.ModelType, IndexPath) -> IndexPath) where Cell: UICollectionViewCell {
        collectionDelegate?.append4ArgumentReaction(for: Cell.self,
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
    open func shouldSpringLoad<Cell:ModelTransfer>(_ cellClass: Cell.Type, _ closure: @escaping (UISpringLoadedInteractionContext, Cell, Cell.ModelType, IndexPath) -> Bool)
        where Cell: UICollectionViewCell
    {
        collectionDelegate?.append4ArgumentReaction(for: Cell.self,
                                                    signature: .shouldSpringLoadItem,
                                                    closure: closure)
    }
    
#if compiler(>=5.1)
    @available(iOS 13, *)
    /// Registers `closure` to be executed when `UICollectionViewDelegate.collectionView(_:shouldBeginMultipleSelectionInteractionAt:)`method is called for `cellClass`.
    /// - Parameter Type: cell class to react for event
    /// - Parameter closure: closure to run.
    open func shouldBeginMultipleSelectionInteraction<Cell:ModelTransfer>(for cellClass: Cell.Type,
                                                                       _ closure: @escaping (Cell, Cell.ModelType, IndexPath) -> Bool)
        where Cell: UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: Cell.self,
                                      signature: .shouldBeginMultipleSelectionInteractionAtIndexPath,
                                      closure: closure)
    }
    
    @available(iOS 13, *)
    /// Registers `closure` to be executed when `UICollectionViewDelegate.collectionView(_:didBeginMultipleSelectionInteractionAt:)`method is called for `cellClass`.
    /// - Parameter Type: cell class to react for event
    /// - Parameter closure: closure to run.
    open func didBeginMultipleSelectionInteraction<Cell:ModelTransfer>(for cellClass: Cell.Type,
                                                                    _ closure: @escaping (Cell, Cell.ModelType, IndexPath) -> Void)
        where Cell: UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: Cell.self,
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
    open func contextMenuConfiguration<Cell:ModelTransfer>(for cellClass: Cell.Type,
                                                        _ closure: @escaping (CGPoint, Cell, Cell.ModelType, IndexPath) -> UIContextMenuConfiguration?)
        where Cell: UICollectionViewCell
    {
        collectionDelegate?.append4ArgumentReaction(for: Cell.self,
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

    #if compiler(<5.1.2)
    @available(iOS 13.0, *)
    /// Registers `closure` to be executed when `UICollectionViewDelegate.tableView(_:willCommitMenuWithAnimator:)` method is called
    open func willCommitMenuWithAnimator(_ closure: @escaping (UIContextMenuInteractionCommitAnimating) -> Void)
    {
        collectionDelegate?.appendNonCellReaction(.willCommitMenuWithAnimator, closure: closure)
    }
    #endif

    #endif
#endif
    
    @available(iOS 14, tvOS 14, *)
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:canEditItemAt:)` method is called for `cellClass`.
    open func canEdit<Model>(_ modelType:Model.Type, _ closure: @escaping (Model, IndexPath) -> Bool)
    {
        collectionDelegate?.appendReaction(viewType: .cell, for: Model.self, signature: EventMethodSignature.canEditItemAtIndexPath, closure: closure)
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    /// Registers `closure` to be executed to determine cell size in `UICollectionViewDelegateFlowLayout.collectionView(_:sizeForItemAt:)` method, when it's called for cell which model is of `itemType`.
    open func sizeForCell<Model>(withItem: Model.Type, _ closure: @escaping (Model, IndexPath) -> CGSize)
    {
        collectionDelegate?.appendReaction(viewType: .cell, for: Model.self, signature: EventMethodSignature.sizeForItemAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed to determine header size in `UICollectionViewDelegateFlowLayout.collectionView(_:layout:referenceSizeForHeaderViewInSection:)` method, when it's called for header which model is of `itemType`.
    open func referenceSizeForHeaderView<Model>(withItem: Model.Type, _ closure: @escaping (Model, IndexPath) -> CGSize)
    {
        collectionDelegate?.appendReaction(viewType: .supplementaryView(kind: UICollectionView.elementKindSectionHeader), for: Model.self, signature: EventMethodSignature.referenceSizeForHeaderInSection, closure: closure)
    }
    
    /// Registers `closure` to be executed to determine footer size in `UICollectionViewDelegateFlowLayout.collectionView(_:layout:referenceSizeForFooterViewInSection:)` method, when it's called for footer which model is of `itemType`.
    open func referenceSizeForFooterView<Model>(withItem: Model.Type, _ closure: @escaping (Model, IndexPath) -> CGSize)
    {
        collectionDelegate?.appendReaction(viewType: .supplementaryView(kind: UICollectionView.elementKindSectionFooter), for: Model.self, signature: EventMethodSignature.referenceSizeForFooterInSection, closure: closure)
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
    
    #if os(tvOS)
    // MARK: - TVCollectionViewDelegateFullScreenLayout
    
    @available(tvOS 13, *)
    /// Registers `closure` to be executed, when `TVCollectionViewDelegateFullScreenLayout.collectionView(_:layout:willCenterCellAt:)` method is called for `cellClass`.
    open func willCenter<Cell:ModelTransfer>(_ cellClass:  Cell.Type, _ closure: @escaping (Cell, Cell.ModelType, IndexPath) -> Void) where Cell:UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: Cell.self, signature: .willCenterCellAtIndexPath, closure: closure)
    }
    
    @available(tvOS 13, *)
    /// Registers `closure` to be executed, when `TVCollectionViewDelegateFullScreenLayout.collectionView(_:layout:didCenterCellAt:)` method is called for `cellClass`.
    open func didCenter<Cell:ModelTransfer>(_ cellClass:  Cell.Type, _ closure: @escaping (Cell, Cell.ModelType, IndexPath) -> Void) where Cell:UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: Cell.self, signature: .didCenterCellAtIndexPath, closure: closure)
    }
    
    #endif
}

extension ViewModelMapping where View: UICollectionViewCell {
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:didSelectItemAt:)` method is called.
    open func didSelect(_ closure: @escaping (View, Model, IndexPath) -> Void)
    {
        reactions.append(EventReaction(viewType: View.self, modelType: Model.self, signature: EventMethodSignature.didSelectItemAtIndexPath.rawValue, closure))
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:shouldSelectItemAt:)` method is called.
    open func shouldSelect(_ closure: @escaping (View, Model, IndexPath) -> Bool)
    {
        reactions.append(EventReaction(viewType: View.self, modelType: Model.self, signature: EventMethodSignature.shouldSelectItemAtIndexPath.rawValue, closure))
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:shouldDeselectItemAt:)` method is called.
    open func shouldDeselect(_ closure: @escaping (View, Model, IndexPath) -> Bool)
    {
        reactions.append(EventReaction(viewType: View.self, modelType: Model.self, signature: EventMethodSignature.shouldDeselectItemAtIndexPath.rawValue, closure))
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:didDeselectItemAt:)` method is called.
    open func didDeselect(_ closure: @escaping (View, Model, IndexPath) -> Void)
    {
        reactions.append(EventReaction(viewType: View.self, modelType: Model.self, signature: EventMethodSignature.didDeselectItemAtIndexPath.rawValue, closure))
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:shouldHighlightItemAt:)` method is called.
    open func shouldHighlight(_ closure: @escaping (View, Model, IndexPath) -> Bool)
    {
        reactions.append(EventReaction(viewType: View.self, modelType: Model.self, signature: EventMethodSignature.shouldHighlightItemAtIndexPath.rawValue, closure))
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:didHighlightItemAt:)` method is called.
    open func didHighlight(_ closure: @escaping (View, Model, IndexPath) -> Void)
    {
        reactions.append(EventReaction(viewType: View.self, modelType: Model.self, signature: EventMethodSignature.didHighlightItemAtIndexPath.rawValue, closure))
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:didUnhighlightItemAt:)` method is called.
    open func didUnhighlight(_ closure: @escaping (View, Model, IndexPath) -> Void)
    {
        reactions.append(EventReaction(viewType: View.self, modelType: Model.self, signature: EventMethodSignature.didUnhighlightItemAtIndexPath.rawValue, closure))
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:willDisplayCell:forItemAt:)` method is called.
    open func willDisplay(_ closure: @escaping (View, Model, IndexPath) -> Void)
    {
        reactions.append(EventReaction(viewType: View.self, modelType: Model.self, signature: EventMethodSignature.willDisplayCellForItemAtIndexPath.rawValue, closure))
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:didEndDisplaying:forItemAt:)` method is called.
    open func didEndDisplaying(_ closure: @escaping (View, Model, IndexPath) -> Void)
    {
        reactions.append(EventReaction(viewType: View.self, modelType: Model.self, signature: EventMethodSignature.didEndDisplayingCellForItemAtIndexPath.rawValue, closure))
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:canFocusItemAt:)` method is called.
    open func canFocus(_ closure: @escaping (View, Model, IndexPath) -> Bool)
    {
        reactions.append(EventReaction(viewType: View.self, modelType: Model.self, signature: EventMethodSignature.canFocusItemAtIndexPath.rawValue, closure))
    }
    
    /// Registers `closure` to be executed when `UICollectionViewDelegate.targetIndexPathForMoveFromItemAt(_:toProposed:)` method is called.
    open func targetIndexPathForMovingItem(_ closure: @escaping (IndexPath, View, Model, IndexPath) -> IndexPath)  {
        reactions.append(FourArgumentsEventReaction(View.self, modelType: Model.self, argument: IndexPath.self, signature: EventMethodSignature.targetIndexPathForMoveFromItemAtTo.rawValue, closure))
    }
    
    
    /// Registers `closure` to be executed to determine cell size in `UICollectionViewDelegateFlowLayout.collectionView(_:sizeForItemAt:)` method.
    open func sizeForCell(_ closure: @escaping (Model, IndexPath) -> CGSize)
    {
        reactions.append(EventReaction(modelType: Model.self, signature: EventMethodSignature.sizeForItemAtIndexPath.rawValue, closure))
    }
    
#if os(iOS)
    /// Registers `closure` to be executed when `UICollectionViewDelegate.collectionView(_:shouldSpringLoadItemAt:)` method is called.
    open func shouldSpringLoad(_ closure: @escaping (UISpringLoadedInteractionContext, View, Model, IndexPath) -> Bool)
    {
        reactions.append(FourArgumentsEventReaction(View.self, modelType: Model.self, argument: UISpringLoadedInteractionContext.self,
                                                    signature: EventMethodSignature.shouldSpringLoadItem.rawValue, closure))
    }
    
#if compiler(>=5.1)
    @available(iOS 13, *)
    /// Registers `closure` to be executed when `UICollectionViewDelegate.collectionView(_:shouldBeginMultipleSelectionInteractionAt:)`method is called.
    /// - Parameter Type: cell class to react for event
    /// - Parameter closure: closure to run.
    open func shouldBeginMultipleSelectionInteraction(_ closure: @escaping (View, Model, IndexPath) -> Bool)
    {
        reactions.append(EventReaction(viewType: View.self, modelType: Model.self,
                                       signature: EventMethodSignature.shouldBeginMultipleSelectionInteractionAtIndexPath.rawValue,
                                       closure))
    }
    
    @available(iOS 13, *)
    /// Registers `closure` to be executed when `UICollectionViewDelegate.collectionView(_:didBeginMultipleSelectionInteractionAt:)`method is called.
    /// - Parameter Type: cell class to react for event
    /// - Parameter closure: closure to run.
    open func didBeginMultipleSelectionInteraction(_ closure: @escaping (View, Model, IndexPath) -> Void)
    {
        reactions.append(EventReaction(viewType: View.self, modelType: Model.self, signature: EventMethodSignature.didBeginMultipleSelectionInteractionAtIndexPath.rawValue, closure))
    }
    
    @available(iOS 13.0, *)
    /// Registers `closure` to be executed when `UICollectionViewDelegate.contextMenuConfigurationForItemAt(_:point:)` method is called.
    open func contextMenuConfiguration(_ closure: @escaping (CGPoint, View, Model, IndexPath) -> UIContextMenuConfiguration?)
    {
        reactions.append(FourArgumentsEventReaction(View.self, modelType: Model.self, argument: CGPoint.self, signature: EventMethodSignature.contextMenuConfigurationForItemAtIndexPath.rawValue, closure))
    }
    #endif
#endif
    
    @available(iOS 14, tvOS 14, *)
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:canEditItemAt:)` method is called.
    open func canEdit(_ closure: @escaping (Model, IndexPath) -> Bool)
    {
        reactions.append(EventReaction(modelType: Model.self, signature: EventMethodSignature.canEditItemAtIndexPath.rawValue, closure))
    }
    
    #if os(tvOS)
    // MARK: - TVCollectionViewDelegateFullScreenLayout
    
    @available(tvOS 13, *)
    /// Registers `closure` to be executed, when `TVCollectionViewDelegateFullScreenLayout.collectionView(_:layout:willCenterCellAt:)` method is called.
    open func willCenter(_ closure: @escaping (View, Model, IndexPath) -> Void)
    {
        reactions.append(EventReaction(viewType: View.self, modelType: Model.self, signature: EventMethodSignature.willCenterCellAtIndexPath.rawValue, closure))
    }
    
    @available(tvOS 13, *)
    /// Registers `closure` to be executed, when `TVCollectionViewDelegateFullScreenLayout.collectionView(_:layout:didCenterCellAt:)` method is called.
    open func didCenter(_ closure: @escaping (View, Model, IndexPath) -> Void)
    {
        reactions.append(EventReaction(viewType: View.self, modelType: Model.self, signature: EventMethodSignature.didCenterCellAtIndexPath.rawValue, closure))
    }
    #endif
}

extension ViewModelMapping where View: UICollectionReusableView {
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:willDisplaySupplementaryView:forElementKind:at:)` method is called.
    open func willDisplaySupplementaryView(_ closure: @escaping (View, Model, IndexPath) -> Void)
    {
        reactions.append(EventReaction(viewType: View.self, modelType: Model.self,
                                       signature: EventMethodSignature.willDisplaySupplementaryViewForElementKindAtIndexPath.rawValue,
                                       closure))
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:didEndDisplayingSupplementaryView:forElementKind:at:)` method is called.
    open func didEndDisplayingSupplementaryView(_ closure: @escaping (View, Model, IndexPath) -> Void)
    {
        reactions.append(EventReaction(viewType: View.self, modelType: Model.self,
                                       signature: EventMethodSignature.didEndDisplayingSupplementaryViewForElementKindAtIndexPath.rawValue,
                                       closure))
    }

    /// Registers `closure` to be executed to determine header size in `UICollectionViewDelegateFlowLayout.collectionView(_:layout:referenceSizeForHeaderViewInSection:)` method, when it's called.
    open func referenceSizeForHeaderView(_ closure: @escaping (Model, IndexPath) -> CGSize)
    {
        reactions.append(EventReaction(modelType: Model.self, signature: EventMethodSignature.referenceSizeForHeaderInSection.rawValue, closure))
    }
    
    /// Registers `closure` to be executed to determine footer size in `UICollectionViewDelegateFlowLayout.collectionView(_:layout:referenceSizeForFooterViewInSection:)` method, when it's called.
    open func referenceSizeForFooterView(_ closure: @escaping (Model, IndexPath) -> CGSize)
    {
        reactions.append(EventReaction(modelType: Model.self, signature: EventMethodSignature.referenceSizeForFooterInSection.rawValue, closure))
    }
}
