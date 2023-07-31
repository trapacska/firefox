// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

protocol HomePanelDelegate: AnyObject {
    func homePanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool, selectNewTab: Bool)
    func homePanel(didSelectURL url: URL, visitType: VisitType, isGoogleTopSite: Bool)
    func homePanelDidRequestToOpenLibrary(panel: LibraryPanelType)
    func homePanelDidRequestToOpenTabTray(withFocusedTab tabToFocus: Tab?, focusedSegment: TabTrayViewModel.Segment?)
    func homePanelDidRequestToOpenSettings(at settingsPage: AppSettingsDeeplinkOption)
}

extension HomePanelDelegate {
    func homePanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool, selectNewTab: Bool = false) {
        homePanelDidRequestToOpenInNewTab(url, isPrivate: isPrivate, selectNewTab: selectNewTab)
    }

    func homePanelDidRequestToOpenTabTray(withFocusedTab tabToFocus: Tab? = nil,
                                          focusedSegment: TabTrayViewModel.Segment? = nil) {
        homePanelDidRequestToOpenTabTray(withFocusedTab: tabToFocus, focusedSegment: focusedSegment)
    }
}
