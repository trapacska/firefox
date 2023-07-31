// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

class ReaderViewTest: BaseTestCase {
    // Smoketest
    func testLoadReaderContent() {
        navigator.openURL(path(forTestPage: "test-mozilla-book.html"))
        navigator.goto(BrowserTab)
        waitForNoExistence(app.staticTexts["Fennec pasted from XCUITests-Runner"])
        waitForExistence(app.buttons["Reader View"], timeout: TIMEOUT)
        app.buttons["Reader View"].tap()
        // The settings of reader view are shown as well as the content of the web site
        waitForExistence(app.buttons["Display Settings"], timeout: TIMEOUT)
        XCTAssertTrue(app.webViews.staticTexts["The Book of Mozilla"].exists)
    }

    private func checkReadingListNumberOfItems(items: Int) {
        waitForExistence(app.tables["ReadingTable"])
        let list = app.tables["ReadingTable"].cells.count
        XCTAssertEqual(list, items, "The number of items in the reading table is not correct")
    }

    // Smoketest
    func testAddToReadingList() {
        navigator.nowAt(NewTabScreen)
        // Navigate to reading list
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_ReadingList)

        // Check to make sure the reading list is empty
        checkReadingListNumberOfItems(items: 0)
        app.buttons["Done"].tap()
        // Add item to reading list and check that it appears
        addContentToReaderView()
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_ReadingList)

        // Check that there is one item
        let savedToReadingList = app.tables["ReadingTable"].cells.staticTexts["The Book of Mozilla"]
        waitForExistence(savedToReadingList)
        XCTAssertTrue(savedToReadingList.exists)
        checkReadingListNumberOfItems(items: 1)
    }

    func testAddToReadingListPrivateMode() {
        navigator.nowAt(NewTabScreen)
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        waitForExistence(app.buttons["urlBar-cancel"], timeout: TIMEOUT)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_ReadingList)

        // Initially reading list is empty
        checkReadingListNumberOfItems(items: 0)
        app.buttons["Done"].tap()
        // Add item to reading list and check that it appears
        addContentToReaderView()
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_ReadingList)

        // Check that there is one item
        let savedToReadingList = app.tables["ReadingTable"].cells.staticTexts["The Book of Mozilla"]
        waitForExistence(savedToReadingList)
        XCTAssertTrue(savedToReadingList.exists)
        checkReadingListNumberOfItems(items: 1)
        app.buttons["Done"].tap()
        updateScreenGraph()
        // Check that it appears on regular mode
        navigator.toggleOff(userState.isPrivate, withAction: Action.ToggleRegularMode)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        waitForExistence(app.buttons["urlBar-cancel"], timeout: TIMEOUT)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        navigator.goto(LibraryPanel_ReadingList)
        checkReadingListNumberOfItems(items: 1)
    }

    func testMarkAsReadAndUreadFromReaderView() {
        addContentToReaderView()

        // Mark the content as read, so the mark as unread buttons appear
        app.buttons["Mark as Read"].tap()
        waitForExistence(app.buttons["Mark as Unread"])

        // Mark the content as unread, so the mark as read button appear
        app.buttons["Mark as Unread"].tap()
        waitForExistence(app.buttons["Mark as Read"])
    }

    func testRemoveFromReadingView() {
        addContentToReaderView()
        // Once the content has been added, remove it
        waitForExistence(app.buttons["Remove from Reading List"])
        app.buttons["Remove from Reading List"].tap()

        // Check that instead of the remove icon now it is shown the add to read list
        waitForExistence(app.buttons["Add to Reading List"])

        // Go to reader list view to check that there is not any item there
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_ReadingList)
        navigator.goto(LibraryPanel_ReadingList)
        checkReadingListNumberOfItems(items: 0)
    }

    func testMarkAsReadAndUnreadFromReadingList() throws {
        addContentToReaderView()
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_ReadingList)

        waitForExistence(app.tables["ReadingTable"])
        // Check that there is one item
        let savedToReadingList = app.tables["ReadingTable"].cells.staticTexts["The Book of Mozilla"]
        XCTAssertTrue(savedToReadingList.exists)

        // Mark it as read/unread
        if processIsTranslatedStr() == m1Rosetta {
            throw XCTSkip("swipeLeft() does not work on M1")
        } else {
            savedToReadingList.swipeLeft()
            waitForExistence(app.tables.cells.buttons.staticTexts["Mark as  Read"], timeout: TIMEOUT)
            app.tables["ReadingTable"].cells.buttons.element(boundBy: 1).tap()
            savedToReadingList.swipeLeft()
            waitForExistence(app.tables.cells.buttons.staticTexts["Mark as  Unread"])
        }
    }

    func testRemoveFromReadingList() {
        addContentToReaderView()
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_ReadingList)

        let savedToReadingList = app.tables["ReadingTable"].cells.staticTexts["The Book of Mozilla"]
        waitForExistence(savedToReadingList)

        // Remove the item from reading list
        if processIsTranslatedStr() == m1Rosetta {
            savedToReadingList.press(forDuration: 2)
            waitForExistence(app.otherElements["Remove"])
            app.otherElements["Remove"].tap()
        } else {
            savedToReadingList.swipeLeft()
            waitForExistence(app.buttons["Remove"])
            app.buttons["Remove"].tap()
        }
        XCTAssertFalse(savedToReadingList.exists)

        // Reader list view should be empty
        checkReadingListNumberOfItems(items: 0)
    }

    func testAddToReadingListFromBrowserTabMenu() {
        navigator.nowAt(NewTabScreen)
        // First time Reading list is empty
        navigator.goto(LibraryPanel_ReadingList)
        checkReadingListNumberOfItems(items: 0)
        app.buttons["Done"].tap()
        // Add item to Reading List from Page Options Menu
        updateScreenGraph()
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        navigator.performAction(Action.AddToReadingListBrowserTabMenu)
        // Now there should be an item on the list
        navigator.nowAt(BrowserTab)
        navigator.goto(LibraryPanel_ReadingList)
        checkReadingListNumberOfItems(items: 1)
    }

    func testOpenSavedForReadingLongPressInNewTab() {
        let numTab = app.buttons["Show Tabs"].value as? String
        XCTAssertEqual(numTab, "1")

        // Add item to Reading List
        addContentToReaderView()
        navigator.goto(LibraryPanel_ReadingList)

        // Long tap on the item just saved
        let savedToReadingList = app.tables["ReadingTable"].cells.staticTexts["The Book of Mozilla"]
        waitForExistence(savedToReadingList)
        savedToReadingList.press(forDuration: 1)

        // Select to open in New Tab
        waitForExistence(app.tables["Context Menu"])
        app.tables.otherElements[StandardImageIdentifiers.Large.plus].tap()
        updateScreenGraph()
        // Now there should be two tabs open
        navigator.goto(HomePanelsScreen)
        let numTabAfter = app.buttons["Show Tabs"].value as? String
        XCTAssertEqual(numTabAfter, "2")
    }

    func testRemoveSavedForReadingLongPress() {
        // Add item to Reading List
        addContentToReaderView()
        navigator.goto(LibraryPanel_ReadingList)

        // Long tap on the item just saved and choose remove
        let savedToReadingList = app.tables["ReadingTable"].cells.staticTexts["The Book of Mozilla"]
        waitForExistence(savedToReadingList)
        savedToReadingList.press(forDuration: 1)
        waitForExistence(app.tables["Context Menu"])
        app.tables.otherElements[StandardImageIdentifiers.Large.cross].tap()

        // Verify the item has been removed
        waitForNoExistence(app.tables["ReadingTable"].cells.staticTexts["The Book of Mozilla"])
        XCTAssertFalse(app.tables["ReadingTable"].cells.staticTexts["The Book of Mozilla"].exists)
    }

    // Smoketest
    func testAddToReaderListOptions() throws {
        XCTExpectFailure("The app was not launched", strict: false) {
            waitForExistence(app.collectionViews["FxCollectionView"], timeout: TIMEOUT)
        }
        addContentToReaderView()
        // Check that Settings layouts options are shown
        waitForExistence(app.buttons["ReaderModeBarView.settingsButton"], timeout: TIMEOUT)
        app.buttons["ReaderModeBarView.settingsButton"].tap()
        XCTAssertTrue(app.buttons["Light"].exists)
    }
}
