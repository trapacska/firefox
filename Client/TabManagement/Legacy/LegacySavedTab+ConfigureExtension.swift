// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
import Storage
import Shared

// This cannot be easily imported into extension targets, so we break it out here.
extension LegacySavedTab {
    convenience init?(tab: Tab, isSelected: Bool) {
        var sessionData = tab.sessionData

        ensureMainThread {
            if sessionData == nil {
                let currentItem: WKBackForwardListItem! = tab.webView?.backForwardList.currentItem

                // Freshly created web views won't have any history entries at all.
                // If we have no history, abort.
                if currentItem != nil {
                    // The back & forward list keep track of the users history within the session
                    let backList = tab.webView?.backForwardList.backList ?? []
                    let forwardList = tab.webView?.backForwardList.forwardList ?? []
                    let urls = (backList + [currentItem] + forwardList).map { $0.url }
                    let currentPage = -forwardList.count
                    sessionData = LegacySessionData(currentPage: currentPage, urls: urls, lastUsedTime: tab.lastExecutedTime ?? Date.now())
                }
            }
        }

        self.init(screenshotUUID: tab.screenshotUUID,
                  isSelected: isSelected,
                  title: tab.title ?? tab.lastTitle,
                  isPrivate: tab.isPrivate,
                  faviconURL: tab.faviconURL,
                  url: tab.url,
                  sessionData: sessionData,
                  uuid: tab.tabUUID,
                  tabGroupData: tab.metadataManager?.tabGroupData,
                  createdAt: tab.firstCreatedTime,
                  hasHomeScreenshot: tab.hasHomeScreenshot)
    }

    func configureSavedTabUsing(_ tab: Tab, imageStore: DiskImageStore? = nil) -> Tab {
        tab.url = url

        if let screenshotUUID = screenshotUUID, let imageStore = imageStore {
            tab.screenshotUUID = screenshotUUID
            if let uuidString = tab.screenshotUUID?.uuidString {
                Task {
                    let screenshot = try? await imageStore.getImageForKey(uuidString)
                    if tab.screenshotUUID == screenshotUUID {
                        tab.setScreenshot(screenshot)
                    }
                }
            }
        }

        tab.sessionData = sessionData
        tab.lastTitle = title
        tab.tabUUID = UUID ?? ""
        tab.metadataManager?.tabGroupData = tabGroupData ?? LegacyTabGroupData()
        tab.screenshotUUID = screenshotUUID
        tab.firstCreatedTime = createdAt ?? sessionData?.lastUsedTime ?? Date.now()
        tab.hasHomeScreenshot = hasHomeScreenshot
        return tab
    }
}
