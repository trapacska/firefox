// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Storage
import Common

/// A folder class that enables us to have local folder presented to the user
/// We can use this folder class for:
/// - Have the menu, unfiled and toolbar folders all under a desktop folder that doesn't exists in the backend
/// - Present the menu, unfiled and toolbar folders to the users without making a backend call. Desktop folder content is fetched when folder is selected.
class LocalDesktopFolder: FxBookmarkNode {
    // Guid used locally, but never synced to Firefox Sync accounts
    static let localDesktopFolderGuid = "localDesktopFolder"

    // The space a local desktop folder takes in a certain folder
    static let numberOfRowsTaken = 1

    private let forcedGuid: Guid

    init(forcedGuid: Guid = LocalDesktopFolder.localDesktopFolderGuid) {
        self.forcedGuid = forcedGuid
    }

    var type: BookmarkNodeType {
        return .folder
    }

    var guid: String {
        return forcedGuid
    }

    var parentGUID: String? {
        return nil
    }

    var position: UInt32 {
        return 0
    }

    var isRoot: Bool {
        return false
    }

    var title: String {
        return ""
    }
}

extension LocalDesktopFolder: BookmarksFolderCell {
    func getViewModel() -> OneLineTableViewCellViewModel {
        return OneLineTableViewCellViewModel(title: LocalizedRootBookmarkFolderStrings[guid],
                                             leftImageView: leftImageView,
                                             accessoryView: UIImageView(image: chevronImage),
                                             accessoryType: .disclosureIndicator)
    }

    func didSelect(profile: Profile,
                   libraryPanelDelegate: LibraryPanelDelegate?,
                   navigationController: UINavigationController?,
                   logger: Logger) {
        let viewModel = BookmarksPanelViewModel(profile: profile,
                                                bookmarkFolderGUID: guid)
        let nextController = BookmarksPanel(viewModel: viewModel)
        nextController.title = .Bookmarks.Menu.DesktopBookmarks
        if let localizedString = LocalizedRootBookmarkFolderStrings[guid] {
            nextController.title = localizedString
        }
        nextController.libraryPanelDelegate = libraryPanelDelegate
        navigationController?.pushViewController(nextController, animated: true)
    }
}
