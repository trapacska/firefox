// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

protocol BookmarksCoordinatorDelegate: AnyObject {
    func start(from folder: FxBookmarkNode)

    /// Shows the bookmark detail to modify a bookmark folder
    func showBookmarkDetail(for node: FxBookmarkNode, folder: FxBookmarkNode)

    /// Shows the bookmark detail to create a new bookmark or folder in the parent folder
    func showBookmarkDetail(bookmarkType: BookmarkNodeType, parentBookmarkFolder: FxBookmarkNode, updatePanelState: ((LibraryPanelSubState) -> Void)?)
}

extension BookmarksCoordinatorDelegate {
    func showBookmarkDetail(bookmarkType: BookmarkNodeType, parentBookmarkFolder: FxBookmarkNode, updatePanelState: ((LibraryPanelSubState) -> Void)? = nil) {
        showBookmarkDetail(bookmarkType: bookmarkType, parentBookmarkFolder: parentBookmarkFolder, updatePanelState: updatePanelState)
    }
}

class BookmarksCoordinator: BaseCoordinator, BookmarksCoordinatorDelegate {
    // MARK: - Properties

    private let profile: Profile
    private weak var parentCoordinator: LibraryCoordinatorDelegate?

    // MARK: - Initializers

    init(
        router: Router,
        profile: Profile,
        parentCoordinator: LibraryCoordinatorDelegate?
    ) {
        self.profile = profile
        self.parentCoordinator = parentCoordinator
        super.init(router: router)
    }

    // MARK: - BookmarksCoordinatorDelegate

    func start(from folder: FxBookmarkNode) {
        let viewModel = BookmarksPanelViewModel(profile: profile, bookmarkFolderGUID: folder.guid)
        let controller = BookmarksPanel(viewModel: viewModel)
        controller.bookmarkCoordinatorDelegate = self
        controller.libraryPanelDelegate = parentCoordinator
        router.push(controller)
    }

    func showBookmarkDetail(for node: FxBookmarkNode, folder: FxBookmarkNode) {
        TelemetryWrapper.recordEvent(category: .action, method: .change, object: .bookmark, value: .bookmarksPanel)
        let detailController = BookmarkDetailPanel(profile: profile,
                                                   bookmarkNode: node,
                                                   parentBookmarkFolder: folder)
        router.push(detailController)
    }

    func showBookmarkDetail(bookmarkType: BookmarkNodeType, parentBookmarkFolder: FxBookmarkNode, updatePanelState: ((LibraryPanelSubState) -> Void)? = nil) {
        let detailController = BookmarkDetailPanel(
            profile: profile,
            withNewBookmarkNodeType: bookmarkType,
            parentBookmarkFolder: parentBookmarkFolder
        ) {
            updatePanelState?($0)
        }
        router.push(detailController)
    }
}
