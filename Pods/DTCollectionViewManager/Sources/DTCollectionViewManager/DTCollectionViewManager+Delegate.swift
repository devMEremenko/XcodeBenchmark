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

/// Extension for UICollectionViewDelegate events. Please note that cell / view methods in this extension are soft-deprecated, and it's recommended to migrate to methods extending `CellViewModelMappingProtocolGeneric` and `SupplementaryViewModelMappingProtocolGeneric`:
///
/// Deprecated:
/// ```swift
///     manager.register(PostCell.self)
///     manager.didSelect(PostCell.self) { postCell, post, indexPath in }
/// ```
/// Recommended:
/// ```swift
///     manager.register(PostCell.self) { mapping in
///         mapping.didSelect { postCell, post, indexPath in }
///     }
/// ```
/// While previously main benefits for second syntax were mostly syntactic, now with support for SwiftUI it will be hard to actually specialize hosting cells, so only second syntax will work for all kinds of cells, and first syntax can only work for non-SwiftUI cells.
/// New delegate methods for UICollectionView (starting with iOS 16 / tvO 16 SDK) will be added only as extension to mapping protocols, not DTCollectionViewManager itself.
public extension DTCollectionViewManager {
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:didSelectItemAt:)` method is called for `cellClass`.
    func didSelect<Cell:ModelTransfer>(_ cellClass:  Cell.Type, _ closure: @escaping (Cell, Cell.ModelType, IndexPath) -> Void) where Cell:UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: Cell.self, signature: .didSelectItemAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:shouldSelectItemAt:)` method is called for `cellClass`.
    func shouldSelect<Cell:ModelTransfer>(_ cellClass:Cell.Type, _ closure: @escaping (Cell, Cell.ModelType, IndexPath) -> Bool) where Cell: UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: Cell.self, signature: EventMethodSignature.shouldSelectItemAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:shouldDeselectItemAt:)` method is called for `cellClass`.
    func shouldDeselect<Cell:ModelTransfer>(_ cellClass:Cell.Type, _ closure: @escaping (Cell, Cell.ModelType, IndexPath) -> Bool) where Cell: UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: Cell.self, signature: EventMethodSignature.shouldDeselectItemAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:didDeselectItemAt:)` method is called for `cellClass`.
    func didDeselect<Cell:ModelTransfer>(_ cellClass: Cell.Type, _ closure: @escaping (Cell, Cell.ModelType, IndexPath) -> Void) where Cell:UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: Cell.self, signature: .didDeselectItemAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:shouldHighlightItemAt:)` method is called for `cellClass`.
    func shouldHighlight<Cell:ModelTransfer>(_ cellClass:Cell.Type, _ closure: @escaping (Cell, Cell.ModelType, IndexPath) -> Bool) where Cell: UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: Cell.self, signature: EventMethodSignature.shouldHighlightItemAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:didHighlightItemAt:)` method is called for `cellClass`.
    func didHighlight<Cell:ModelTransfer>(_ cellClass:Cell.Type, _ closure: @escaping (Cell, Cell.ModelType, IndexPath) -> Void) where Cell: UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: Cell.self, signature: EventMethodSignature.didHighlightItemAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:didUnhighlightItemAt:)` method is called for `cellClass`.
    func didUnhighlight<Cell:ModelTransfer>(_ cellClass:Cell.Type, _ closure: @escaping (Cell, Cell.ModelType, IndexPath) -> Void) where Cell: UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: Cell.self, signature: EventMethodSignature.didUnhighlightItemAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:willDisplayCell:forItemAt:)` method is called for `cellClass`.
    func willDisplay<Cell:ModelTransfer>(_ cellClass:Cell.Type, _ closure: @escaping (Cell, Cell.ModelType, IndexPath) -> Void) where Cell: UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: Cell.self, signature: EventMethodSignature.willDisplayCellForItemAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:willDisplaySupplementaryView:forElementKind:at:)` method is called for `supplementaryClass` of `kind`.
    func willDisplaySupplementaryView<View:ModelTransfer>(_ supplementaryClass:View.Type, forElementKind kind: String, _ closure: @escaping (View, View.ModelType, IndexPath) -> Void) where View: UICollectionReusableView
    {
        collectionDelegate?.appendReaction(forSupplementaryKind: kind, supplementaryClass: View.self, signature: EventMethodSignature.willDisplaySupplementaryViewForElementKindAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:willDisplaySupplementaryView:forElementKind:at:)` method is called for `supplementaryClass` of `UICollectionElementKindSectionHeader`.
    func willDisplayHeaderView<View:ModelTransfer>(_ headerClass:View.Type, _ closure: @escaping (View, View.ModelType, IndexPath) -> Void) where View: UICollectionReusableView
    {
        willDisplaySupplementaryView(View.self, forElementKind: UICollectionView.elementKindSectionHeader, closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:willDisplaySupplementaryView:forElementKind:at:)` method is called for `supplementaryClass` of `UICollectionElementKindSectionFooter`.
    func willDisplayFooterView<View:ModelTransfer>(_ footerClass:View.Type, _ closure: @escaping (View, View.ModelType, IndexPath) -> Void) where View: UICollectionReusableView
    {
        willDisplaySupplementaryView(View.self, forElementKind: UICollectionView.elementKindSectionFooter, closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:didEndDisplaying:forItemAt:)` method is called for `cellClass`.
    func didEndDisplaying<Cell:ModelTransfer>(_ cellClass:Cell.Type, _ closure: @escaping (Cell, Cell.ModelType, IndexPath) -> Void) where Cell: UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: Cell.self, signature: EventMethodSignature.didEndDisplayingCellForItemAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:didEndDisplayingSupplementaryView:forElementKind:at:)` method is called for `supplementaryClass` of `kind`.
    func didEndDisplayingSupplementaryView<View:ModelTransfer>(_ supplementaryClass:View.Type, forElementKind kind: String, _ closure: @escaping (View, View.ModelType, IndexPath) -> Void) where View: UICollectionReusableView
    {
        collectionDelegate?.appendReaction(forSupplementaryKind: kind, supplementaryClass: View.self, signature: EventMethodSignature.didEndDisplayingSupplementaryViewForElementKindAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:didEndDisplayingSupplementaryView:forElementKind:at:)` method is called for `headerClass` of `UICollectionElementKindSectionHeader`.
    func didEndDisplayingHeaderView<View:ModelTransfer>(_ headerClass:View.Type, _ closure: @escaping (View, View.ModelType, IndexPath) -> Void) where View: UICollectionReusableView
    {
        didEndDisplayingSupplementaryView(View.self, forElementKind: UICollectionView.elementKindSectionHeader, closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:didEndDisplayingSupplementaryView:forElementKind:at:)` method is called for `footerClass` of `UICollectionElementKindSectionFooter`.
    func didEndDisplayingFooterView<View:ModelTransfer>(_ footerClass:View.Type, _ closure: @escaping (View, View.ModelType, IndexPath) -> Void) where View: UICollectionReusableView
    {
        didEndDisplayingSupplementaryView(View.self, forElementKind: UICollectionView.elementKindSectionFooter, closure)
    }
    
    @available(iOS, deprecated: 13.0)
    @available(tvOS, deprecated: 13.0)
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:shouldShowMenuForItemAt:)` method is called for `cellClass`.
    func shouldShowMenu<Cell:ModelTransfer>(for cellClass:Cell.Type, _ closure: @escaping (Cell, Cell.ModelType, IndexPath) -> Bool) where Cell: UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: Cell.self, signature: EventMethodSignature.shouldShowMenuForItemAtIndexPath, closure: closure)
    }
    
    @available(iOS, deprecated: 13.0)
    @available(tvOS, deprecated: 13.0)
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:canPerformAction:forItemAt:withSender:)` method is called for `cellClass`.
    func canPerformAction<Cell:ModelTransfer>(for cellClass: Cell.Type, _ closure: @escaping (Selector, Any?, Cell, Cell.ModelType, IndexPath) -> Bool) where Cell: UICollectionViewCell {
        collectionDelegate?.append5ArgumentReaction(for: Cell.self,
                                                    signature: .canPerformActionForItemAtIndexPath,
                                                    closure: closure)
    }
    
    @available(iOS, deprecated: 13.0)
    @available(tvOS, deprecated: 13.0)
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:performAction:forItemAt:withSender:)` method is called for `cellClass`.
    func performAction<Cell:ModelTransfer>(for cellClass: Cell.Type, _ closure: @escaping (Selector, Any?, Cell, Cell.ModelType, IndexPath) -> Void) where Cell: UICollectionViewCell {
        collectionDelegate?.append5ArgumentReaction(for: Cell.self,
                                                    signature: .performActionForItemAtIndexPath,
                                                    closure: closure)
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:canFocusItemAt:)` method is called for `cellClass`.
    func canFocus<Cell:ModelTransfer>(_ cellClass:Cell.Type, _ closure: @escaping (Cell, Cell.ModelType, IndexPath) -> Bool) where Cell: UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: Cell.self, signature: EventMethodSignature.canFocusItemAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed when `UICollectionViewDelegate.collectionView(_:shouldUpdateFocusInContext:)` method is called.
    func shouldUpdateFocus(_ closure: @escaping (UICollectionViewFocusUpdateContext) -> Bool) {
        collectionDelegate?.appendNonCellReaction(.shouldUpdateFocusInContext, closure: closure)
    }
    
    /// Registers `closure` tp be executed when `UICollectionViewDelegate.collectionView(_:didUpdateFocusIn:with:)` method is called.
    func didUpdateFocus(_ closure: @escaping (UICollectionViewFocusUpdateContext, UIFocusAnimationCoordinator) -> Void) {
        collectionDelegate?.appendNonCellReaction(.didUpdateFocusInContext, closure: closure)
    }
    
    /// Registers `closure` to be executed when `UICollectionViewDelegate.indexPathForPreferredFocusedView(in:)` method is called
    func indexPathForPreferredFocusedView(_ closure: @escaping () -> IndexPath?) {
        collectionDelegate?.appendNonCellReaction(.indexPathForPreferredFocusedView, closure: closure)
    }
    
    @available(iOS, deprecated: 15.0, message: "Use targetIndexPathForMoveFromItem: instead")
    @available(tvOS, deprecated: 15.0, message: "Use targetIndexPathForMoveFromItem: instead")
    /// Registers `closure` to be executed when `UICollectionViewDelegate.targetIndexPathForMoveFromItemAt(_:toProposed:)` method is called for `cellClass`
    func targetIndexPathForMovingItem<Cell:ModelTransfer>(_ cellClass: Cell.Type, _ closure: @escaping (IndexPath, Cell, Cell.ModelType, IndexPath) -> IndexPath) where Cell: UICollectionViewCell {
        collectionDelegate?.append4ArgumentReaction(for: Cell.self,
                                                    signature: .targetIndexPathForMoveFromItemAtTo,
                                                    closure: closure)
    }
    
    /// Registers `closure` to be executed when `UICollectionViewDelegate.collectionView(_:targetContentOffsetForProposedContentOffset:)` method is called.
    func targetContentOffsetForProposedContentOffset(_ closure: @escaping (CGPoint) -> CGPoint) {
        collectionDelegate?.appendNonCellReaction(.targetContentOffsetForProposedContentOffset,
                                                  closure: closure)
    }
    
#if os(iOS)
    /// Registers `closure` to be executed when `UICollectionViewDelegate.collectionView(_:shouldSpringLoadItemAt:)` method is called for `cellClass`.
    func shouldSpringLoad<Cell:ModelTransfer>(_ cellClass: Cell.Type, _ closure: @escaping (UISpringLoadedInteractionContext, Cell, Cell.ModelType, IndexPath) -> Bool)
        where Cell: UICollectionViewCell
    {
        collectionDelegate?.append4ArgumentReaction(for: Cell.self,
                                                    signature: .shouldSpringLoadItem,
                                                    closure: closure)
    }
    
    @available(iOS 13, *)
    /// Registers `closure` to be executed when `UICollectionViewDelegate.collectionView(_:shouldBeginMultipleSelectionInteractionAt:)`method is called for `cellClass`.
    /// - Parameter Type: cell class to react for event
    /// - Parameter closure: closure to run.
    func shouldBeginMultipleSelectionInteraction<Cell:ModelTransfer>(for cellClass: Cell.Type,
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
    func didBeginMultipleSelectionInteraction<Cell:ModelTransfer>(for cellClass: Cell.Type,
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
    func didEndMultipleSelectionInteraction(_ closure: @escaping () -> Void)
    {
        collectionDelegate?.appendNonCellReaction(.didEndMultipleSelectionInteraction, closure: closure)
    }
    
    @available(iOS 13.0, *)
    @available(iOS, deprecated: 16.0, message: "Please use contextMenuConuConfigurationForItemsAtIndexPaths: method instead")
    /// Registers `closure` to be executed when `UICollectionViewDelegate.contextMenuConfigurationForItemAt(_:point:)` method is called
    func contextMenuConfiguration<Cell:ModelTransfer>(for cellClass: Cell.Type,
                                                        _ closure: @escaping (CGPoint, Cell, Cell.ModelType, IndexPath) -> UIContextMenuConfiguration?)
        where Cell: UICollectionViewCell
    {
        collectionDelegate?.append4ArgumentReaction(for: Cell.self,
                                               signature: .contextMenuConfigurationForItemAtIndexPath,
                                               closure: closure)
    }
    
    @available(iOS 16, *)
    func contextMenuConfigurationForItemsAtIndexPaths(_ closure: @escaping ([IndexPath], CGPoint) -> UIContextMenuConfiguration?) {
        collectionDelegate?.appendNonCellReaction(.contextMenuConfigurationForItemsAtIndexPaths, closure: closure)
    }
    
    @available(iOS 13.0, *)
    @available(iOS, deprecated: 16.0, message: "Please use highlightPreview: method instead")
    /// Registers `closure` to be executed when `UICollectionViewDelegate.collectionView(_:previewForHighlightingContextMenuWithConfiguration:)` method is called
    func previewForHighlightingContextMenu(_ closure: @escaping (UIContextMenuConfiguration) -> UITargetedPreview?)
    {
        collectionDelegate?.appendNonCellReaction(.previewForHighlightingContextMenu, closure: closure)
    }
    
    @available(iOS 13.0, *)
    @available(iOS, deprecated: 16.0, message: "Please use dismissalPreview: method instead")
    /// Registers `closure` to be executed when `UICollectionViewDelegate.collectionView(_:previewForDismissingContextMenuWithConfiguration:)` method is called
    func previewForDismissingContextMenu(_ closure: @escaping (UIContextMenuConfiguration) -> UITargetedPreview?)
    {
        collectionDelegate?.appendNonCellReaction(.previewForDismissingContextMenu, closure: closure)
    }
    
    #if os(iOS)
    @available(iOS 15, *)
    /// Registers `closure` to be executed when `UICollectionViewDelegate.collectionView(_:selectionFollowsFocusForRowAt:)`method is called for `cellClass`.
    /// - Parameter Type: cell class to react for event
    /// - Parameter closure: closure to run.
    func selectionFollowsFocus<Cell:ModelTransfer>(for cellClass: Cell.Type,
                                                                    _ closure: @escaping (Cell, Cell.ModelType, IndexPath) -> Bool)
        where Cell: UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: Cell.self,
                                      signature: .selectionFollowsFocusForItemAtIndexPath,
                                      closure: closure)
    }
    #endif
#endif
    
    @available(iOS 14, tvOS 14, *)
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:canEditItemAt:)` method is called for `cellClass`.
    func canEdit<Model>(_ modelType:Model.Type, _ closure: @escaping (Model, IndexPath) -> Bool)
    {
        collectionDelegate?.appendReaction(viewType: .cell, for: Model.self, signature: EventMethodSignature.canEditItemAtIndexPath, closure: closure)
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    /// Registers `closure` to be executed to determine cell size in `UICollectionViewDelegateFlowLayout.collectionView(_:sizeForItemAt:)` method, when it's called for cell which model is of `itemType`.
    func sizeForCell<Model>(withItem: Model.Type, _ closure: @escaping (Model, IndexPath) -> CGSize)
    {
        collectionDelegate?.appendReaction(viewType: .cell, for: Model.self, signature: EventMethodSignature.sizeForItemAtIndexPath, closure: closure)
    }
    
    /// Registers `closure` to be executed to determine header size in `UICollectionViewDelegateFlowLayout.collectionView(_:layout:referenceSizeForHeaderViewInSection:)` method, when it's called for header which model is of `itemType`.
    func referenceSizeForHeaderView<Model>(withItem: Model.Type, _ closure: @escaping (Model, IndexPath) -> CGSize)
    {
        collectionDelegate?.appendReaction(viewType: .supplementaryView(kind: UICollectionView.elementKindSectionHeader), for: Model.self, signature: EventMethodSignature.referenceSizeForHeaderInSection, closure: closure)
    }
    
    /// Registers `closure` to be executed to determine footer size in `UICollectionViewDelegateFlowLayout.collectionView(_:layout:referenceSizeForFooterViewInSection:)` method, when it's called for footer which model is of `itemType`.
    func referenceSizeForFooterView<Model>(withItem: Model.Type, _ closure: @escaping (Model, IndexPath) -> CGSize)
    {
        collectionDelegate?.appendReaction(viewType: .supplementaryView(kind: UICollectionView.elementKindSectionFooter), for: Model.self, signature: EventMethodSignature.referenceSizeForFooterInSection, closure: closure)
    }
    
    /// Registers `closure` to be executed when `UICollectionViewDelegate.collectionView(_:transitionLayoutForOldLayout:toNewLayout:`) method is called
    func transitionLayout(_ closure: @escaping (_ oldLayout: UICollectionViewLayout, _ newLayout: UICollectionViewLayout) -> UICollectionViewTransitionLayout) {
        collectionDelegate?.appendNonCellReaction(.transitionLayoutForOldLayoutNewLayout,
                                                  closure: closure)
    }
    
    /// Registers `closure` to be executed when `UICollectionViewDelegateFlowLayout.collectionView(_:layout:insetForSectionAt:)` method is called.
    func insetForSectionAtIndex(_ closure: @escaping (UICollectionViewLayout, Int) -> UIEdgeInsets) {
        collectionDelegate?.appendNonCellReaction(.insetForSectionAtIndex, closure: closure)
    }
    
    /// Registers `closure` to be executed when `UICollectionViewDelegateFlowLayout.collectionView(_:layout:minimumLineSpacingForSectionAt:)` method is called.
    func minimumLineSpacingForSectionAtIndex(_ closure: @escaping (UICollectionViewLayout, Int) -> CGFloat) {
        collectionDelegate?.appendNonCellReaction(.minimumLineSpacingForSectionAtIndex, closure: closure)
    }
    
    /// Registers `closure` to be executed when `UICollectionViewDelegateFlowLayout.collectionView(_:layout:insetForSectionAt:)` method is called.
    func minimumInteritemSpacingForSectionAtIndex(_ closure: @escaping (UICollectionViewLayout, Int) -> CGFloat) {
        collectionDelegate?.appendNonCellReaction(.minimumInteritemSpacingForSectionAtIndex, closure: closure)
    }
    
    #if os(tvOS)
    // MARK: - TVCollectionViewDelegateFullScreenLayout
    
    @available(tvOS 13, *)
    /// Registers `closure` to be executed, when `TVCollectionViewDelegateFullScreenLayout.collectionView(_:layout:willCenterCellAt:)` method is called for `cellClass`.
    func willCenter<Cell:ModelTransfer>(_ cellClass:  Cell.Type, _ closure: @escaping (Cell, Cell.ModelType, IndexPath) -> Void) where Cell:UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: Cell.self, signature: .willCenterCellAtIndexPath, closure: closure)
    }
    
    @available(tvOS 13, *)
    /// Registers `closure` to be executed, when `TVCollectionViewDelegateFullScreenLayout.collectionView(_:layout:didCenterCellAt:)` method is called for `cellClass`.
    func didCenter<Cell:ModelTransfer>(_ cellClass:  Cell.Type, _ closure: @escaping (Cell, Cell.ModelType, IndexPath) -> Void) where Cell:UICollectionViewCell
    {
        collectionDelegate?.appendReaction(for: Cell.self, signature: .didCenterCellAtIndexPath, closure: closure)
    }
    
    #endif
    
    @available(iOS 15, tvOS 15, *)
    /// Registers `closure` to be executed when `UICollectionViewDelegate.collectionView(_:selectionFollowsFocusForRowAt:)`method is called for `cellClass`.
    /// - Parameter Type: cell class to react for event
    /// - Parameter closure: closure to run.
    /// Closure parameters:
    /// 1. Current IndexPath
    /// 2. Proposed IndexPath
    /// 3. Cell at original indexPath
    /// 4. Model at original indexPath
    /// 5. Original indexPath
    /// If closure / delegate method are not implemented, returns proposed indexPath.
    func targetIndexPathForMoveFromItem<Cell:ModelTransfer>(_ cellClass:  Cell.Type, _ closure: @escaping (IndexPath, IndexPath, Cell, Cell.ModelType, IndexPath) -> IndexPath) where Cell:UICollectionViewCell
    {
        collectionDelegate?.append5ArgumentReaction(for: Cell.self, signature: .targetIndexPathForMoveOfItemFromOriginalIndexPath, closure: closure)
    }
}

/// Extension for UICollectionViewDelegate events
public extension CellViewModelMappingProtocolGeneric where Cell: UICollectionViewCell {
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:didSelectItemAt:)` method is called.
    func didSelect(_ closure: @escaping (Cell, Model, IndexPath) -> Void)
    {
        reactions.append(EventReaction(viewType: Cell.self, modelType: Model.self, signature: EventMethodSignature.didSelectItemAtIndexPath.rawValue, closure))
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:shouldSelectItemAt:)` method is called.
    func shouldSelect(_ closure: @escaping (Cell, Model, IndexPath) -> Bool)
    {
        reactions.append(EventReaction(viewType: Cell.self, modelType: Model.self, signature: EventMethodSignature.shouldSelectItemAtIndexPath.rawValue, closure))
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:shouldDeselectItemAt:)` method is called.
    func shouldDeselect(_ closure: @escaping (Cell, Model, IndexPath) -> Bool)
    {
        reactions.append(EventReaction(viewType: Cell.self, modelType: Model.self, signature: EventMethodSignature.shouldDeselectItemAtIndexPath.rawValue, closure))
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:didDeselectItemAt:)` method is called.
    func didDeselect(_ closure: @escaping (Cell, Model, IndexPath) -> Void)
    {
        reactions.append(EventReaction(viewType: Cell.self, modelType: Model.self, signature: EventMethodSignature.didDeselectItemAtIndexPath.rawValue, closure))
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:shouldHighlightItemAt:)` method is called.
    func shouldHighlight(_ closure: @escaping (Cell, Model, IndexPath) -> Bool)
    {
        reactions.append(EventReaction(viewType: Cell.self, modelType: Model.self, signature: EventMethodSignature.shouldHighlightItemAtIndexPath.rawValue, closure))
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:didHighlightItemAt:)` method is called.
    func didHighlight(_ closure: @escaping (Cell, Model, IndexPath) -> Void)
    {
        reactions.append(EventReaction(viewType: Cell.self, modelType: Model.self, signature: EventMethodSignature.didHighlightItemAtIndexPath.rawValue, closure))
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:didUnhighlightItemAt:)` method is called.
    func didUnhighlight(_ closure: @escaping (Cell, Model, IndexPath) -> Void)
    {
        reactions.append(EventReaction(viewType: Cell.self, modelType: Model.self, signature: EventMethodSignature.didUnhighlightItemAtIndexPath.rawValue, closure))
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:willDisplayCell:forItemAt:)` method is called.
    func willDisplay(_ closure: @escaping (Cell, Model, IndexPath) -> Void)
    {
        reactions.append(EventReaction(viewType: Cell.self, modelType: Model.self, signature: EventMethodSignature.willDisplayCellForItemAtIndexPath.rawValue, closure))
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:didEndDisplaying:forItemAt:)` method is called.
    func didEndDisplaying(_ closure: @escaping (Cell, Model, IndexPath) -> Void)
    {
        reactions.append(EventReaction(viewType: Cell.self, modelType: Model.self, signature: EventMethodSignature.didEndDisplayingCellForItemAtIndexPath.rawValue, closure))
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:canFocusItemAt:)` method is called.
    func canFocus(_ closure: @escaping (Cell, Model, IndexPath) -> Bool)
    {
        reactions.append(EventReaction(viewType: Cell.self, modelType: Model.self, signature: EventMethodSignature.canFocusItemAtIndexPath.rawValue, closure))
    }
    
    @available(iOS, deprecated: 15.0, message: "Use targetIndexPathForMoveFromItem: instead")
    @available(tvOS, deprecated: 15.0, message: "Use targetIndexPathForMoveFromItem: instead")
    /// Registers `closure` to be executed when `UICollectionViewDelegate.targetIndexPathForMoveFromItemAt(_:toProposed:)` method is called.
    func targetIndexPathForMovingItem(_ closure: @escaping (IndexPath, Cell, Model, IndexPath) -> IndexPath)  {
        reactions.append(FourArgumentsEventReaction(Cell.self, modelType: Model.self, argument: IndexPath.self, signature: EventMethodSignature.targetIndexPathForMoveFromItemAtTo.rawValue, closure))
    }
    
    
    /// Registers `closure` to be executed to determine cell size in `UICollectionViewDelegateFlowLayout.collectionView(_:sizeForItemAt:)` method.
    func sizeForCell(_ closure: @escaping (Model, IndexPath) -> CGSize)
    {
        reactions.append(EventReaction(modelType: Model.self, signature: EventMethodSignature.sizeForItemAtIndexPath.rawValue, closure))
    }
    
#if os(iOS)
    /// Registers `closure` to be executed when `UICollectionViewDelegate.collectionView(_:shouldSpringLoadItemAt:)` method is called.
    func shouldSpringLoad(_ closure: @escaping (UISpringLoadedInteractionContext, Cell, Model, IndexPath) -> Bool)
    {
        reactions.append(FourArgumentsEventReaction(Cell.self, modelType: Model.self, argument: UISpringLoadedInteractionContext.self,
                                                    signature: EventMethodSignature.shouldSpringLoadItem.rawValue, closure))
    }
    
    @available(iOS 13, *)
    /// Registers `closure` to be executed when `UICollectionViewDelegate.collectionView(_:shouldBeginMultipleSelectionInteractionAt:)`method is called.
    /// - Parameter Type: cell class to react for event
    /// - Parameter closure: closure to run.
    func shouldBeginMultipleSelectionInteraction(_ closure: @escaping (Cell, Model, IndexPath) -> Bool)
    {
        reactions.append(EventReaction(viewType: Cell.self, modelType: Model.self,
                                       signature: EventMethodSignature.shouldBeginMultipleSelectionInteractionAtIndexPath.rawValue,
                                       closure))
    }
    
    @available(iOS 13, *)
    /// Registers `closure` to be executed when `UICollectionViewDelegate.collectionView(_:didBeginMultipleSelectionInteractionAt:)`method is called.
    /// - Parameter Type: cell class to react for event
    /// - Parameter closure: closure to run.
    func didBeginMultipleSelectionInteraction(_ closure: @escaping (Cell, Model, IndexPath) -> Void)
    {
        reactions.append(EventReaction(viewType: Cell.self, modelType: Model.self, signature: EventMethodSignature.didBeginMultipleSelectionInteractionAtIndexPath.rawValue, closure))
    }
    
    @available(iOS 13.0, *)
    /// Registers `closure` to be executed when `UICollectionViewDelegate.contextMenuConfigurationForItemAt(_:point:)` method is called.
    func contextMenuConfiguration(_ closure: @escaping (CGPoint, Cell, Model, IndexPath) -> UIContextMenuConfiguration?)
    {
        reactions.append(FourArgumentsEventReaction(Cell.self, modelType: Model.self, argument: CGPoint.self, signature: EventMethodSignature.contextMenuConfigurationForItemAtIndexPath.rawValue, closure))
    }
    
    @available(iOS 16, *)
    func highlightPreview(_ closure: @escaping (UIContextMenuConfiguration, Cell, Model, IndexPath) -> UITargetedPreview?) {
        reactions.append(FourArgumentsEventReaction(Cell.self, modelType: Model.self, argument: UIContextMenuConfiguration.self, signature: EventMethodSignature.highlightPreviewForItemAtIndexPath.rawValue, closure))
    }
    
    @available(iOS 16, *)
    func dismissalPreview(_ closure: @escaping (UIContextMenuConfiguration, Cell, Model, IndexPath) -> UITargetedPreview?) {
        reactions.append(FourArgumentsEventReaction(Cell.self, modelType: Model.self, argument: UIContextMenuConfiguration.self, signature: EventMethodSignature.dismissalPreviewForItemAtIndexPath.rawValue, closure))
    }
#endif
    
    #if os(iOS)
    @available(iOS 15, *)
    /// Registers `closure` to be executed when `UICollectionViewDelegate.collectionView(_:selectionFollowsFocusForRowAt:)`method is called for `cellClass`.
    /// - Parameter Type: cell class to react for event
    /// - Parameter closure: closure to run.
    func selectionFollowsFocus(_ closure: @escaping (Cell, Model, IndexPath) -> Bool)
    {
        reactions.append(EventReaction(viewType: Cell.self, modelType: Model.self, signature: EventMethodSignature.selectionFollowsFocusForItemAtIndexPath.rawValue, closure))
    }
    
    #endif
    
    @available(iOS 15, tvOS 15, *)
    /// Registers `closure` to be executed when `UICollectionViewDelegate.collectionView(_:selectionFollowsFocusForRowAt:)`method is called for `cellClass`.
    /// - Parameter Type: cell class to react for event
    /// - Parameter closure: closure to run.
    /// Closure parameters:
    /// 1. Current IndexPath
    /// 2. Proposed IndexPath
    /// 3. Cell at original indexPath
    /// 4. Model at original indexPath
    /// 5. Original indexPath
    /// If closure / delegate method are not implemented, returns proposed indexPath.
    func targetIndexPathForMoveFromItem(_ closure: @escaping (IndexPath, IndexPath, Cell, Model, IndexPath) -> IndexPath)
    {
        reactions.append(FiveArgumentsEventReaction(Cell.self, modelType: Model.self, argumentOne: IndexPath.self, argumentTwo: IndexPath.self, signature: EventMethodSignature.targetIndexPathForMoveOfItemFromOriginalIndexPath.rawValue, closure))
    }
    
#if swift(>=5.7) && !canImport(AppKit) || (canImport(AppKit) && swift(>=5.7.1)) // Xcode 14.0 AND macCatalyst on Xcode 14.1 (which will have swift> 5.7.1)
    @available(iOS 16, tvOS 16, *)
    func canPerformPrimaryAction(_ closure: @escaping (Cell, Model, IndexPath) -> Bool) {
        reactions.append(EventReaction(viewType: Cell.self, modelType: Model.self, signature: EventMethodSignature.canPerformActionForItemAtIndexPath.rawValue, closure))
    }
    
    @available(iOS 16, tvOS 16, *)
    func performPrimaryAction(_ closure: @escaping (Cell, Model, IndexPath) -> Void) {
        reactions.append(EventReaction(viewType: Cell.self, modelType: Model.self, signature: EventMethodSignature.performPrimaryActionForItemAtIndexPath.rawValue, closure))
    }
#endif
    
    @available(iOS 14, tvOS 14, *)
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:canEditItemAt:)` method is called.
    func canEdit(_ closure: @escaping (Model, IndexPath) -> Bool)
    {
        reactions.append(EventReaction(modelType: Model.self, signature: EventMethodSignature.canEditItemAtIndexPath.rawValue, closure))
    }
    
    #if os(tvOS)
    // MARK: - TVCollectionViewDelegateFullScreenLayout
    
    @available(tvOS 13, *)
    /// Registers `closure` to be executed, when `TVCollectionViewDelegateFullScreenLayout.collectionView(_:layout:willCenterCellAt:)` method is called.
    func willCenter(_ closure: @escaping (Cell, Model, IndexPath) -> Void)
    {
        reactions.append(EventReaction(viewType: Cell.self, modelType: Model.self, signature: EventMethodSignature.willCenterCellAtIndexPath.rawValue, closure))
    }
    
    @available(tvOS 13, *)
    /// Registers `closure` to be executed, when `TVCollectionViewDelegateFullScreenLayout.collectionView(_:layout:didCenterCellAt:)` method is called.
    func didCenter(_ closure: @escaping (Cell, Model, IndexPath) -> Void)
    {
        reactions.append(EventReaction(viewType: Cell.self, modelType: Model.self, signature: EventMethodSignature.didCenterCellAtIndexPath.rawValue, closure))
    }
    #endif
}

/// Extension for UICollectionViewDelegate events
public extension SupplementaryViewModelMappingProtocolGeneric where View: UICollectionReusableView {
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:willDisplaySupplementaryView:forElementKind:at:)` method is called.
    func willDisplaySupplementaryView(_ closure: @escaping (View, Model, IndexPath) -> Void)
    {
        reactions.append(EventReaction(viewType: View.self, modelType: Model.self,
                                       signature: EventMethodSignature.willDisplaySupplementaryViewForElementKindAtIndexPath.rawValue,
                                       closure))
    }
    
    /// Registers `closure` to be executed, when `UICollectionViewDelegate.collectionView(_:didEndDisplayingSupplementaryView:forElementKind:at:)` method is called.
    func didEndDisplayingSupplementaryView(_ closure: @escaping (View, Model, IndexPath) -> Void)
    {
        reactions.append(EventReaction(viewType: View.self, modelType: Model.self,
                                       signature: EventMethodSignature.didEndDisplayingSupplementaryViewForElementKindAtIndexPath.rawValue,
                                       closure))
    }

    /// Registers `closure` to be executed to determine header size in `UICollectionViewDelegateFlowLayout.collectionView(_:layout:referenceSizeForHeaderViewInSection:)` method, when it's called.
    func referenceSizeForHeaderView(_ closure: @escaping (Model, IndexPath) -> CGSize)
    {
        reactions.append(EventReaction(modelType: Model.self, signature: EventMethodSignature.referenceSizeForHeaderInSection.rawValue, closure))
    }
    
    /// Registers `closure` to be executed to determine footer size in `UICollectionViewDelegateFlowLayout.collectionView(_:layout:referenceSizeForFooterViewInSection:)` method, when it's called.
    func referenceSizeForFooterView(_ closure: @escaping (Model, IndexPath) -> CGSize)
    {
        reactions.append(EventReaction(modelType: Model.self, signature: EventMethodSignature.referenceSizeForFooterInSection.rawValue, closure))
    }
}
