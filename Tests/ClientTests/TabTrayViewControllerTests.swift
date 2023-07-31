// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client

import XCTest
import Common
import Shared

class TabTrayViewControllerTests: XCTestCase {
    var profile: TabManagerMockProfile!
    var manager: TabManager!
    var tabTray: TabTrayViewController!
    var gridTab: GridTabViewController!
    var overlayManager: MockOverlayModeManager!
    var urlBar: MockURLBarView!

    override func setUp() {
        super.setUp()

        DependencyHelperMock().bootstrapDependencies()
        profile = TabManagerMockProfile()
        manager = LegacyTabManager(profile: profile, imageStore: nil)
        urlBar = MockURLBarView()
        overlayManager = MockOverlayModeManager()
        overlayManager.setURLBar(urlBarView: urlBar)
        tabTray = TabTrayViewController(tabTrayDelegate: nil,
                                        profile: profile,
                                        tabToFocus: nil,
                                        tabManager: manager,
                                        overlayManager: overlayManager)
        gridTab = GridTabViewController(tabManager: manager, profile: profile)
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
    }

    override func tearDown() {
        super.tearDown()

        AppContainer.shared.reset()
        profile = nil
        manager = nil
        urlBar = nil
        overlayManager = nil
        tabTray = nil
        gridTab = nil
    }

    func testCountUpdatesAfterTabRemoval() {
        let tabToRemove = manager.addTab()
        manager.addTab()

        XCTAssertEqual(tabTray.viewModel.normalTabsCount, "2")
        XCTAssertEqual(tabTray.countLabel.text, "2")

        gridTab.tabDisplayManager.performCloseAction(for: tabToRemove)
        // Wait for notification of .TabClosed when tab is removed
        weak var expectation = self.expectation(description: "notificationReceived")
        NotificationCenter.default.addObserver(forName: .UpdateLabelOnTabClosed, object: nil, queue: nil) { notification in
            expectation?.fulfill()

            XCTAssertEqual(self.tabTray.viewModel.normalTabsCount, "1")
            XCTAssertEqual(self.tabTray.countLabel.text, "1")
        }

        waitForExpectations(timeout: 3.0, handler: nil)
    }

    func testTabTrayInPrivateMode_WhenTabIsCreated() {
        tabTray.viewModel.segmentToFocus = TabTrayViewModel.Segment.privateTabs
        tabTray.viewDidLoad()
        tabTray.didTapAddTab(UIBarButtonItem())
        tabTray.didTapDone()

        let privateState = UserDefaults.standard.bool(forKey: PrefsKeys.LastSessionWasPrivate)
        XCTAssertTrue(privateState)
    }

    func testTabTrayRevertToRegular_ForNoPrivateTabSelected() {
        // If the user selects Private mode but doesn't focus or creates a new tab
        // we considered that regular is actually active
        tabTray.viewModel.segmentToFocus = TabTrayViewModel.Segment.privateTabs
        tabTray.viewDidLoad()
        tabTray.didTapDone()

        let privateState = UserDefaults.standard.bool(forKey: PrefsKeys.LastSessionWasPrivate)
        XCTAssertFalse(privateState)
    }

    func testInOverlayMode_ForHomepageNewTabSettings() {
        tabTray.viewModel.segmentToFocus = TabTrayViewModel.Segment.privateTabs
        tabTray.viewDidLoad()
        profile.prefs.setString(NewTabPage.topSites.rawValue, forKey: NewTabAccessors.NewTabPrefKey)
        tabTray.viewModel.didTapAddTab(UIBarButtonItem())

        XCTAssertTrue(tabTray.viewModel.overlayManager.inOverlayMode)
    }
}
