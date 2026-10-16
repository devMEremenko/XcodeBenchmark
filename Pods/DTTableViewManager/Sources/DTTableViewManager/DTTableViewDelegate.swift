//
//  DTTableViewDelegate.swift
//  DTTableViewManager
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

import UIKit
import DTModelStorage

/// Object, that implements `UITableViewDelegate` for `DTTableViewManager`.
open class DTTableViewDelegate : DTTableViewDelegateWrapper, UITableViewDelegate {
    override func delegateWasReset() {
        tableView?.delegate = nil
        tableView?.delegate = self
    }
    
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        defer { (delegate as? UITableViewDelegate)?.tableView?(tableView, willDisplay: cell, forRowAt: indexPath) }
        guard let model = storage?.item(at: indexPath) else { return }
        _ = EventReaction.performReaction(from: viewFactory?.mappings ?? [], signature: EventMethodSignature.willDisplayCellForRowAtIndexPath.rawValue, view: cell, model: model, location: indexPath)
    }
    
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        defer { (delegate as? UITableViewDelegate)?.tableView?(tableView, willDisplayHeaderView: view, forSection: section) }
        guard let model = headerModel(forSection: section) else { return }
        _ = EventReaction.performReaction(from: viewFactory?.mappings ?? [], signature: EventMethodSignature.willDisplayHeaderForSection.rawValue, view: view, model: model, location: IndexPath(row: 0, section: section), supplementaryKind: DTTableViewElementSectionHeader)
    }
    
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        defer { (delegate as? UITableViewDelegate)?.tableView?(tableView, willDisplayFooterView: view, forSection: section) }
        guard let model = footerModel(forSection: section) else { return }
        _ = EventReaction.performReaction(from: viewFactory?.mappings ?? [], signature: EventMethodSignature.willDisplayFooterForSection.rawValue, view: view, model: model, location: IndexPath(row: 0, section: section), supplementaryKind: DTTableViewElementSectionFooter)
    }
    
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if configuration?.sectionHeaderStyle == .title { return nil }
        let viewKind = ViewType.supplementaryView(kind: DTTableViewElementSectionHeader)
        if let model = headerModel(forSection:section) {
            if let createdView = viewFactory?.headerFooterView(of: viewKind, model: model, atIndexPath: IndexPath(row: 0, section: section))
            {
                _ = EventReaction.performReaction(from: viewFactory?.mappings ?? [],
                                                            signature: EventMethodSignature.configureHeader.rawValue,
                                                            view: createdView, model: model,
                                                            location: IndexPath(item: 0, section: section),
                                                            supplementaryKind: DTTableViewElementSectionHeader)
                return createdView
            }
        } else {
            if let view = (delegate as? UITableViewDelegate)?.tableView?(tableView, viewForHeaderInSection: section) {
                return view
            }
            if shouldDisplayHeaderView(forSection: section) {
                manager?.anomalyHandler.reportAnomaly(.nilHeaderModel(section))
            }
        }
        return nil
    }
    
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if configuration?.sectionFooterStyle == .title { return nil }
        let viewKind = ViewType.supplementaryView(kind: DTTableViewElementSectionFooter)
        if let model = footerModel(forSection: section) {
            if let createdView = viewFactory?.headerFooterView(of: viewKind, model: model, atIndexPath: IndexPath(row: 0, section: section))
            {
                _ = EventReaction.performReaction(from: viewFactory?.mappings ?? [],
                                                            signature: EventMethodSignature.configureFooter.rawValue,
                                                            view: createdView, model: model,
                                                            location: IndexPath(item: 0, section: section),
                                                            supplementaryKind: DTTableViewElementSectionFooter)
                return createdView
            }
        } else {
            if let view = (delegate as? UITableViewDelegate)?.tableView?(tableView, viewForFooterInSection: section) {
                return view
            }
            if shouldDisplayFooterView(forSection: section) {
                manager?.anomalyHandler.reportAnomaly(.nilFooterModel(section))
            }
        }
        return nil
    }
    
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard shouldDisplayHeaderView(forSection: section) else {
            return configuration?.minimalHeaderHeightForTableView(tableView) ?? .zero
        }
        if let height = performHeaderReaction(.heightForHeaderInSection, location: section, provideView: false) as? CGFloat {
            return height
        }
        if let height = (delegate as? UITableViewDelegate)?.tableView?(tableView, heightForHeaderInSection: section) {
            return height
        }
        if configuration?.sectionHeaderStyle == .title {
            if let _ = headerModel(forSection:section)
            {
                return UITableView.automaticDimension
            }
            return configuration?.minimalHeaderHeightForTableView(tableView) ?? .zero
        }
        if let _ = headerModel(forSection:section) {
            return tableView.sectionHeaderHeight
        }
        return configuration?.minimalHeaderHeightForTableView(tableView) ?? .zero
    }
    
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        if let height = performHeaderReaction(.estimatedHeightForHeaderInSection, location: section, provideView: false) as? CGFloat {
            return height
        }
        return (delegate as? UITableViewDelegate)?.tableView?(tableView, estimatedHeightForHeaderInSection: section) ?? tableView.estimatedSectionHeaderHeight
    }
    
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if let height = performFooterReaction(.heightForFooterInSection, location: section, provideView: false) as? CGFloat {
            return height
        }
        if let height = (delegate as? UITableViewDelegate)?.tableView?(tableView, heightForFooterInSection: section) {
            return height
        }
        guard shouldDisplayFooterView(forSection: section) else {
            return configuration?.minimalFooterHeightForTableView(tableView) ?? .zero
        }
        if configuration?.sectionFooterStyle == .title {
            if let _ = footerModel(forSection:section) {
                return UITableView.automaticDimension
            }
            return configuration?.minimalFooterHeightForTableView(tableView) ?? .zero
        }
        
        if let _ = footerModel(forSection:section) {
            return tableView.sectionFooterHeight
        }
        return configuration?.minimalFooterHeightForTableView(tableView) ?? .zero
    }
    
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        if let height = performFooterReaction(.estimatedHeightForFooterInSection, location: section, provideView: false) as? CGFloat {
            return height
        }
        return (delegate as? UITableViewDelegate)?.tableView?(tableView, estimatedHeightForFooterInSection: section) ?? tableView.estimatedSectionFooterHeight
    }
    
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let eventReaction = cellReaction(.willSelectRowAtIndexPath, location: indexPath) {
            return performNillableCellReaction(eventReaction, location: indexPath, provideCell: true) as? IndexPath
        }
        return (delegate as? UITableViewDelegate)?.tableView?(tableView, willSelectRowAt: indexPath)
    }
    
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        if let eventReaction = cellReaction(.willDeselectRowAtIndexPath, location: indexPath) {
            return performNillableCellReaction(eventReaction, location: indexPath, provideCell: true) as? IndexPath
        }
        return (delegate as? UITableViewDelegate)?.tableView?(tableView, willDeselectRowAt: indexPath)
    }
    
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        _ = performCellReaction(.didSelectRowAtIndexPath, location: indexPath, provideCell: true)
        (self.delegate as? UITableViewDelegate)?.tableView?(tableView, didSelectRowAt: indexPath)
    }
    
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        _ = performCellReaction(.didDeselectRowAtIndexPath, location: indexPath, provideCell: true)
        (self.delegate as? UITableViewDelegate)?.tableView?(tableView, didDeselectRowAt: indexPath)
    }
    
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let height = performCellReaction(.heightForRowAtIndexPath, location: indexPath, provideCell: false) as? CGFloat {
            return height
        }
        return (delegate as? UITableViewDelegate)?.tableView?(tableView, heightForRowAt: indexPath) ?? tableView.rowHeight
    }
    
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if let height = performCellReaction(.estimatedHeightForRowAtIndexPath, location: indexPath, provideCell: false) as? CGFloat {
            return height
        }
        return (delegate as? UITableViewDelegate)?.tableView?(tableView, estimatedHeightForRowAt: indexPath) ?? tableView.estimatedRowHeight
    }
    
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int {
        if let level = performCellReaction(.indentationLevelForRowAtIndexPath, location: indexPath, provideCell: false) as? Int {
            return level
        }
        return (delegate as? UITableViewDelegate)?.tableView?(tableView, indentationLevelForRowAt: indexPath) ?? 0
    }
    
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        _ = performCellReaction(.accessoryButtonTappedForRowAtIndexPath, location: indexPath, provideCell: true)
        (delegate as? UITableViewDelegate)?.tableView?(tableView, accessoryButtonTappedForRowWith: indexPath)
    }
    
#if os(iOS)
    @available(iOS, deprecated: 13.0)
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        if let eventReaction = cellReaction(.editActionsForRowAtIndexPath, location: indexPath) {
            return performNillableCellReaction(eventReaction, location: indexPath, provideCell: true) as? [UITableViewRowAction]
        }
        return (delegate as? UITableViewDelegate)?.tableView?(tableView, editActionsForRowAt: indexPath)
    }

    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        _ = performCellReaction(.willBeginEditingRowAtIndexPath, location: indexPath, provideCell: true)
        (delegate as? UITableViewDelegate)?.tableView?(tableView, willBeginEditingRowAt: indexPath)
    }
    
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        defer { (delegate as? UITableViewDelegate)?.tableView?(tableView, didEndEditingRowAt: indexPath) }
        guard let indexPath = indexPath else { return }
        _ = performCellReaction(.didEndEditingRowAtIndexPath, location: indexPath, provideCell: true)
    }
    
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        if let eventReaction = cellReaction(.titleForDeleteButtonForRowAtIndexPath, location: indexPath) {
            return performNillableCellReaction(eventReaction, location: indexPath, provideCell: true) as? String
        }
        return (delegate as? UITableViewDelegate)?.tableView?(tableView, titleForDeleteConfirmationButtonForRowAt: indexPath)
    }
#endif
    
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if let editingStyle = performCellReaction(.editingStyleForRowAtIndexPath, location: indexPath, provideCell: false) as? UITableViewCell.EditingStyle {
            return editingStyle
        }
        return (delegate as? UITableViewDelegate)?.tableView?(tableView, editingStyleForRowAt: indexPath) ?? .none
    }

    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        if let should = performCellReaction(.shouldIndentWhileEditingRowAtIndexPath, location: indexPath, provideCell: true) as? Bool {
            return should
        }
        return (delegate as? UITableViewDelegate)?.tableView?(tableView, shouldIndentWhileEditingRowAt: indexPath) ?? tableView.cellForRow(at: indexPath)?.shouldIndentWhileEditing ?? true
    }
    
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        defer { (delegate as? UITableViewDelegate)?.tableView?(tableView, didEndDisplaying: cell, forRowAt: indexPath) }
        guard let model = storage?.item(at: indexPath) else { return }
        _ = EventReaction.performReaction(from: viewFactory?.mappings ?? [], signature: EventMethodSignature.didEndDisplayingCellForRowAtIndexPath.rawValue, view: cell, model: model, location: indexPath)
    }
    
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, didEndDisplayingHeaderView view: UIView, forSection section: Int) {
        defer { (delegate as? UITableViewDelegate)?.tableView?(tableView, didEndDisplayingHeaderView: view, forSection: section) }
        guard let model = headerModel(forSection: section) else { return }
        _ = EventReaction.performReaction(from: viewFactory?.mappings ?? [], signature: EventMethodSignature.didEndDisplayingHeaderViewForSection.rawValue, view: view, model: model, location: IndexPath(item: 0, section: section), supplementaryKind: DTTableViewElementSectionHeader)
    }
    
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, didEndDisplayingFooterView view: UIView, forSection section: Int) {
        defer { (delegate as? UITableViewDelegate)?.tableView?(tableView, didEndDisplayingFooterView: view, forSection: section) }
        guard let model = footerModel(forSection: section) else { return }
        _ = EventReaction.performReaction(from: viewFactory?.mappings ?? [], signature: EventMethodSignature.didEndDisplayingFooterViewForSection.rawValue, view: view, model: model, location: IndexPath(item: 0, section: section), supplementaryKind: DTTableViewElementSectionFooter)
    }
    
    @available(iOS, deprecated: 13.0)
    @available(tvOS, deprecated: 13.0)
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        if let should = performCellReaction(.shouldShowMenuForRowAtIndexPath, location: indexPath, provideCell: true) as? Bool {
            return should
        }
        return (delegate as? UITableViewDelegate)?.tableView?(tableView, shouldShowMenuForRowAt: indexPath) ?? false
    }
    
    @available(iOS, deprecated: 13.0)
    @available(tvOS, deprecated: 13.0)
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        if let canPerform = perform5ArgumentCellReaction(.canPerformActionForRowAtIndexPath,
                                                          argumentOne: action,
                                                          argumentTwo: sender as Any,
                                                          location: indexPath,
                                                          provideCell: true) as? Bool {
            return canPerform
        }
        return (delegate as? UITableViewDelegate)?.tableView?(tableView, canPerformAction: action, forRowAt: indexPath, withSender: sender) ?? false
    }
    
    @available(iOS, deprecated: 13.0)
    @available(tvOS, deprecated: 13.0)
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {
        defer { (delegate as? UITableViewDelegate)?.tableView?(tableView, performAction: action, forRowAt: indexPath, withSender: sender) }
        _ = perform5ArgumentCellReaction(.performActionForRowAtIndexPath,
                                      argumentOne: action,
                                      argumentTwo: sender as Any,
                                      location: indexPath,
                                      provideCell: true)
    }
    
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if let should = performCellReaction(.shouldHighlightRowAtIndexPath, location: indexPath, provideCell: true) as? Bool {
            return should
        }
        return (delegate as? UITableViewDelegate)?.tableView?(tableView, shouldHighlightRowAt: indexPath) ?? true
    }
    
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        defer { (delegate as? UITableViewDelegate)?.tableView?(tableView, didHighlightRowAt: indexPath) }
        _ = performCellReaction(.didHighlightRowAtIndexPath, location: indexPath, provideCell: true)
    }
    
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        defer { (delegate as? UITableViewDelegate)?.tableView?(tableView, didUnhighlightRowAt: indexPath) }
        _ = performCellReaction(.didUnhighlightRowAtIndexPath, location: indexPath, provideCell: true)
    }
    
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, canFocusRowAt indexPath: IndexPath) -> Bool {
        if let should = performCellReaction(.canFocusRowAtIndexPath, location: indexPath, provideCell: true) as? Bool {
            return should
        }
        return (delegate as? UITableViewDelegate)?.tableView?(tableView, canFocusRowAt: indexPath) ?? tableView.cellForRow(at: indexPath)?.canBecomeFocused ?? true
    }
#if os(iOS)

    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if let reaction = cellReaction(.leadingSwipeActionsConfigurationForRowAtIndexPath, location: indexPath) {
            return performNillableCellReaction(reaction, location: indexPath, provideCell: true) as? UISwipeActionsConfiguration
        }
        return (delegate as? UITableViewDelegate)?.tableView?(tableView,
                                                              leadingSwipeActionsConfigurationForRowAt: indexPath)
    }
    
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if let reaction = cellReaction(.trailingSwipeActionsConfigurationForRowAtIndexPath, location: indexPath) {
            return performNillableCellReaction(reaction, location: indexPath, provideCell: true) as? UISwipeActionsConfiguration
        }
        return (delegate as? UITableViewDelegate)?.tableView?(tableView,
                                                              trailingSwipeActionsConfigurationForRowAt: indexPath)
    }
    
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, shouldSpringLoadRowAt indexPath: IndexPath, with context: UISpringLoadedInteractionContext) -> Bool {
        if let shouldSpringLoad = perform4ArgumentCellReaction(.shouldSpringLoadRowAtIndexPathWithContext,
                                                               argument: context,
                                                               location: indexPath,
                                                               provideCell: true) as? Bool {
            return shouldSpringLoad
        }
        return (delegate as? UITableViewDelegate)?.tableView?(tableView,
                                                              shouldSpringLoadRowAt:indexPath,
                                                              with: context) ?? true
    }
#endif
    
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if let indexPath = perform4ArgumentCellReaction(.targetIndexPathForMoveFromRowAtIndexPath,
                                                        argument: proposedDestinationIndexPath,
                                                        location: sourceIndexPath,
                                                        provideCell: true) as? IndexPath {
            return indexPath
        }
        return (delegate as? UITableViewDelegate)?.tableView?(tableView,
                                                              targetIndexPathForMoveFromRowAt: sourceIndexPath,
                                                              toProposedIndexPath: proposedDestinationIndexPath) ?? IndexPath(item: 0, section: 0)
    }
    
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, shouldUpdateFocusIn context: UITableViewFocusUpdateContext) -> Bool {
        if let should = performNonCellReaction(.shouldUpdateFocusInContext, argument: context) as? Bool {
            return should
        }
        return (delegate as? UITableViewDelegate)?.tableView?(tableView, shouldUpdateFocusIn:context) ?? true
    }
    
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, didUpdateFocusIn context: UITableViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        _ = performNonCellReaction(.didUpdateFocusInContextWithAnimationCoordinator,
                                   argumentOne: context,
                                   argumentTwo: coordinator)
        (delegate as? UITableViewDelegate)?.tableView?(tableView,
                                                      didUpdateFocusIn: context,
                                                      with: coordinator)
    }
    
    /// Implementation for `UITableViewDelegate` protocol
    open func indexPathForPreferredFocusedView(in tableView: UITableView) -> IndexPath? {
        if let reaction = unmappedReactions.first(where: { $0.methodSignature == EventMethodSignature.indexPathForPreferredFocusedViewInTableView.rawValue }) {
            return reaction.performWithArguments((0, 0, 0)) as? IndexPath
        }
        return (delegate as? UITableViewDelegate)?.indexPathForPreferredFocusedView?(in: tableView)
    }
    
#if os(iOS)
    @available(iOS 13.0, *)
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        if let should = performCellReaction(.shouldBeginMultipleSelectionInteractionAtIndexPath, location: indexPath, provideCell: true) as? Bool {
            return should
        }
        return (delegate as? UITableViewDelegate)?.tableView?(tableView, shouldBeginMultipleSelectionInteractionAt: indexPath) ?? false
    }
    
    @available(iOS 13.0, *)
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        _ = performCellReaction(.didBeginMultipleSelectionInteractionAtIndexPath, location: indexPath, provideCell: true)
        (delegate as? UITableViewDelegate)?.tableView?(tableView, didBeginMultipleSelectionInteractionAt: indexPath)
    }
    
    @available(iOS 13.0, *)
    /// Implementation for `UITableViewDelegate` protocol
    open func tableViewDidEndMultipleSelectionInteraction(_ tableView: UITableView) {
        _ = performNonCellReaction(.didEndMultipleSelectionInteraction)
        (delegate as? UITableViewDelegate)?.tableViewDidEndMultipleSelectionInteraction?(tableView)
    }
    
    @available(iOS 13.0, *)
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        if let _ = cellReaction(.contextMenuConfigurationForRowAtIndexPath, location: indexPath) as? FourArgumentsEventReaction {
            return perform4ArgumentCellReaction(.contextMenuConfigurationForRowAtIndexPath,
                                                argument: point,
                                                location: indexPath,
                                                provideCell: true) as? UIContextMenuConfiguration
        }
        return (delegate as? UITableViewDelegate)?.tableView?(tableView,
                                                              contextMenuConfigurationForRowAt: indexPath,
                                                              point: point)
    }
    
    @available(iOS 13.0, *)
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        if unmappedReactions.contains(where: { $0.methodSignature == EventMethodSignature.previewForHighlightingContextMenu.rawValue }) {
            return performNonCellReaction(.previewForHighlightingContextMenu, argument: configuration) as? UITargetedPreview
        }
        return (delegate as? UITableViewDelegate)?.tableView?(tableView, previewForHighlightingContextMenuWithConfiguration: configuration)
    }
    
    @available(iOS 13.0, *)
    /// Implementation for `UITableViewDelegate` protocol
    open func tableView(_ tableView: UITableView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        if unmappedReactions.contains(where: { $0.methodSignature == EventMethodSignature.previewForDismissingContextMenu.rawValue }) {
            return performNonCellReaction(.previewForDismissingContextMenu, argument: configuration) as? UITargetedPreview
        }
        return (delegate as? UITableViewDelegate)?.tableView?(tableView, previewForDismissingContextMenuWithConfiguration: configuration)
    }
#endif
    
    #if os(iOS)
    @available(iOS 15, *)
    /// Implementation for `UITableViewDelegate` protocol
    public func tableView(_ tableView: UITableView, selectionFollowsFocusForRowAt indexPath: IndexPath) -> Bool {
        if let follows = performCellReaction(.selectionFollowsFocusForRowAtIndexPath, location: indexPath, provideCell: true) as? Bool {
            return follows
        }
        if let followsFocus = (delegate as? UITableViewDelegate)?.tableView?(tableView, selectionFollowsFocusForRowAt: indexPath) {
            return followsFocus
        }
        return tableView.selectionFollowsFocus
    }
    #endif
    
#if swift(>=5.7) && !canImport(AppKit) || (canImport(AppKit) && swift(>=5.7.1)) // Xcode 14.0 AND macCatalyst on Xcode 14.1 (which will have swift> 5.7.1)
    @available(iOS 16, tvOS 16, *)
    /// Implementation for `UITableViewDelegate` protocol
    public func tableView(_ tableView: UITableView, canPerformPrimaryActionForRowAt indexPath: IndexPath) -> Bool {
        if let canPerform = performCellReaction(.canPerformActionForRowAtIndexPath, location: indexPath, provideCell: true) as? Bool {
            return canPerform
        }
        return (delegate as? UITableViewDelegate)?.tableView?(tableView, canPerformPrimaryActionForRowAt: indexPath) ?? false
    }
    
    @available(iOS 16, tvOS 16, *)
    /// Implementation for `UITableViewDelegate` protocol
    public func tableView(_ tableView: UITableView, performPrimaryActionForRowAt indexPath: IndexPath) {
        _ = performCellReaction(.performPrimaryActionForRowAtIndexPath, location: indexPath, provideCell: true)
        (delegate as? UITableViewDelegate)?.tableView?(tableView, performPrimaryActionForRowAt: indexPath)
    }
#endif
}
