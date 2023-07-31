// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

let url_1 = "test-example.html"
let url_2 = ["url": "test-mozilla-org.html", "bookmarkLabel": "Internet for people, not profit — Mozilla"]
let urlLabelExample_3 = "Example Domain"
let url_3 = "localhost:\(serverPort)/test-fixture/test-example.html"
let urlLabelExample_4 = "Example Login Page 2"
let url_4 = "test-password-2.html"

class BookmarkingTests: BaseTestCase {
    private func checkBookmarked() {
        navigator.goto(BrowserTabMenu)
        waitForExistence(app.tables.otherElements[StandardImageIdentifiers.Large.bookmarkSlash])
        if iPad() {
            app.otherElements["PopoverDismissRegion"].tap()
            navigator.nowAt(BrowserTab)
        } else {
            navigator.goto(BrowserTab)
        }
    }

    private func undoBookmarkRemoval() {
        navigator.goto(BrowserTabMenu)
        waitForExistence(app.tables.otherElements[StandardImageIdentifiers.Large.bookmarkSlash])
        app.otherElements[StandardImageIdentifiers.Large.bookmarkSlash].tap()
        navigator.nowAt(BrowserTab)
        waitForExistence(app.buttons["Undo"], timeout: 3)
        app.buttons["Undo"].tap()
    }

    private func checkUnbookmarked() {
        navigator.goto(BrowserTabMenu)
        waitForExistence(app.tables.otherElements[StandardImageIdentifiers.Large.bookmark])
        if iPad() {
            app.otherElements["PopoverDismissRegion"].tap()
            navigator.nowAt(BrowserTab)
        } else {
            navigator.goto(BrowserTab)
        }
    }

    func testBookmarkingUI() {
        // Go to a webpage, and add to bookmarks, check it's added
        navigator.nowAt(NewTabScreen)
        navigator.openURL(path(forTestPage: url_1))
        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        bookmark()
        waitForTabsButton()
        checkBookmarked()

        // Load a different page on a new tab, check it's not bookmarked
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.nowAt(NewTabScreen)
        navigator.openURL(path(forTestPage: url_2["url"]!))

        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        checkUnbookmarked()

        // Go back, check it's still bookmarked, check it's on bookmarks home panel
        waitForTabsButton()
        navigator.goto(TabTray)
        if iPad() {
            app.collectionViews.cells["Example Domain"].children(matching: .other).element.children(matching: .other).element.tap()
        } else {
            app.cells.staticTexts["Example Domain"].tap()
        }
        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        checkBookmarked()

        // Open it, then unbookmark it, and check it's no longer on bookmarks home panel
        unbookmark()
        waitForTabsButton()
        checkUnbookmarked()
    }

    private func checkEmptyBookmarkList() {
        waitForExistence(app.tables["Bookmarks List"], timeout: 5)
        let list = app.tables["Bookmarks List"].cells.count
        XCTAssertEqual(list, 0, "There should not be any entry in the bookmarks list")
    }

    private func checkItemInBookmarkList() {
        waitForExistence(app.tables["Bookmarks List"], timeout: 5)
        let bookmarksList = app.tables["Bookmarks List"]
        let list = bookmarksList.cells.count
        XCTAssertEqual(list, 2, "There should be an entry in the bookmarks list")
        XCTAssertTrue(bookmarksList.cells.element(boundBy: 0).staticTexts["Desktop Bookmarks"].exists)
        XCTAssertTrue(bookmarksList.cells.element(boundBy: 1).staticTexts[url_2["bookmarkLabel"]!].exists)
    }

    func testAccessBookmarksFromContextMenu() {
        // Add a bookmark
        navigator.nowAt(NewTabScreen)
        navigator.openURL(path(forTestPage: url_2["url"]!))
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton], timeout: 10)
        bookmark()

        // There should be a bookmark
        navigator.goto(LibraryPanel_Bookmarks)
        checkItemInBookmarkList()
    }

    // Smoketest
    func testBookmarksAwesomeBar() {
        XCTExpectFailure("The app was not launched", strict: false) {
            waitForExistence(app.textFields["url"], timeout: 60)
        }
        typeOnSearchBar(text: "www.google")
        waitForExistence(app.tables["SiteTable"])
        waitForExistence(app.tables["SiteTable"].cells.staticTexts["www.google"], timeout: 5)
        XCTAssertTrue(app.tables["SiteTable"].cells.staticTexts["www.google"].exists)
        app.textFields["address"].typeText(".com")
        app.textFields["address"].typeText("\r")
        navigator.nowAt(BrowserTab)

        // Clear text and enter new url
        waitForTabsButton()
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.goto(URLBarOpen)
        typeOnSearchBar(text: "https://mozilla.org")

        // Site table exists but is empty
        waitForExistence(app.tables["SiteTable"])
        XCTAssertEqual(app.tables["SiteTable"].cells.count, 0)
        app.textFields["address"].typeText("\r")
        navigator.nowAt(BrowserTab)

        // Add page to bookmarks
        waitForTabsButton()
        sleep(2)
        bookmark()

        // Now the site should be suggested
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton], timeout: 10)
        navigator.performAction(Action.AcceptClearPrivateData)
        navigator.goto(BrowserTab)
        typeOnSearchBar(text: "mozilla.org")
        waitForExistence(app.tables["SiteTable"])
        waitForExistence(app.cells.staticTexts["mozilla.org"])
        XCTAssertNotEqual(app.tables["SiteTable"].cells.count, 0)
    }
    /* Disable due to https://github.com/mozilla-mobile/firefox-ios/issues/7521
    func testAddBookmark() {
        addNewBookmark()
        // Verify that clicking on bookmark opens the website
        app.tables["Bookmarks List"].cells.element(boundBy: 0).tap()
        waitForExistence(app.textFields["url"], timeout: 5)
    }

    func testAddNewFolder() {
        navigator.goto(MobileBookmarks)
        navigator.goto(MobileBookmarksAdd)
        navigator.performAction(Action.AddNewFolder)
        waitForExistence(app.navigationBars["New Folder"])
        // XCTAssertFalse(app.buttons["Save"].isEnabled), is this a bug allowing empty folder name?
        app.tables["SiteTable"].cells.textFields.element(boundBy: 0).tap()
        app.tables["SiteTable"].cells.textFields.element(boundBy: 0).typeText("Test Folder")
        app.buttons["Save"].tap()
        app.buttons["Done"].tap()
        checkItemsInBookmarksList(items: 1)
        navigator.nowAt(MobileBookmarks)
        // Now remove the folder
        navigator.performAction(Action.RemoveItemMobileBookmarks)
        waitForExistence(app.buttons[StandardImageIdentifiers.Large.delete])
        navigator.performAction(Action.ConfirmRemoveItemMobileBookmarks)
        checkItemsInBookmarksList(items: 0)
    }

    func testAddNewMarker() {
        navigator.goto(MobileBookmarks)
        navigator.goto(MobileBookmarksAdd)
        navigator.performAction(Action.AddNewSeparator)
        app.buttons["Done"].tap()
        checkItemsInBookmarksList(items: 1)

        // Remove it
        navigator.nowAt(MobileBookmarks)
        navigator.performAction(Action.RemoveItemMobileBookmarks)
        waitForExistence(app.buttons[StandardImageIdentifiers.Large.delete])
        navigator.performAction(Action.ConfirmRemoveItemMobileBookmarks)
        checkItemsInBookmarksList(items: 0)
    }

    func testDeleteBookmarkSwiping() {
        addNewBookmark()
        // Remove by swiping
        app.tables["Bookmarks List"].staticTexts["BBC"].swipeLeft()
        app.buttons[StandardImageIdentifiers.Large.delete].tap()
        checkItemsInBookmarksList(items: 0)
    }

    func testDeleteBookmarkContextMenu() {
        addNewBookmark()
        // Remove by long press and select option from context menu
        app.tables.staticTexts.element(boundBy: 0).press(forDuration: 1)
        waitForExistence(app.tables["Context Menu"])
        app.tables["Context Menu"].cells[StandardImageIdentifiers.Large.bookmarkSlash].tap()
        checkItemsInBookmarksList(items: 0)
    }*/

    func testUndoDeleteBookmark() {
        navigator.openURL(path(forTestPage: url_1))
        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        bookmark()
        checkBookmarked()
        undoBookmarkRemoval()
        checkBookmarked()
    }

    private func addNewBookmark() {
        navigator.goto(MobileBookmarksAdd)
        navigator.performAction(Action.AddNewBookmark)
        waitForExistence(app.navigationBars["New Bookmark"], timeout: 3)
        // Enter the bookmarks details
        app.tables["SiteTable"].cells.textFields.element(boundBy: 0).tap()
        app.tables["SiteTable"].cells.textFields.element(boundBy: 0).typeText("BBC")

        app.tables["SiteTable"].cells.textFields["https://"].tap()
        app.tables["SiteTable"].cells.textFields["https://"].typeText("bbc.com")
        navigator.performAction(Action.SaveCreatedBookmark)
        app.buttons["Done"].tap()
        checkItemsInBookmarksList(items: 1)
    }

    private func checkItemsInBookmarksList(items: Int) {
        waitForExistence(app.tables["Bookmarks List"], timeout: 3)
        XCTAssertEqual(app.tables["Bookmarks List"].cells.count, items)
    }

    private func typeOnSearchBar(text: String) {
        waitForExistence(app.textFields["url"], timeout: 5)
        app.textFields["url"].tap()
        app.textFields["address"].typeText(text)
    }

    // Smoketest
    func testBookmarkLibraryAddDeleteBookmark() {
        // Verify that there are only 1 cell (desktop bookmark folder)
        XCTExpectFailure("The app was not launched", strict: false) {
            waitForExistence(app.textFields["url"], timeout: 60)
        }
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        navigator.goto(LibraryPanel_Bookmarks)
        // There is only one row in the bookmarks panel, which is the desktop folder
        waitForExistence(app.tables["Bookmarks List"], timeout: 5)
        XCTAssertEqual(app.tables["Bookmarks List"].cells.count, 1)

        // Add a bookmark
        navigator.nowAt(LibraryPanel_Bookmarks)
        navigator.goto(NewTabScreen)

        navigator.openURL(url_3)
        waitForTabsButton()
        bookmark()

        // Check that it appears in Bookmarks panel
        navigator.goto(LibraryPanel_Bookmarks)
        waitForExistence(app.tables["Bookmarks List"], timeout: 5)

        // Delete the Bookmark added, check it is removed
        if processIsTranslatedStr() == m1Rosetta {
            app.tables["Bookmarks List"].cells.staticTexts["Example Domain"].press(forDuration: 1)
            waitForExistence(app.tables["Context Menu"])
            app.tables.otherElements["Remove Bookmark"].tap()
        } else {
            app.tables["Bookmarks List"].cells.staticTexts["Example Domain"].swipeLeft()
            app.buttons[StandardImageIdentifiers.Large.delete].tap()
        }
        waitForNoExistence(app.tables["Bookmarks List"].cells.staticTexts["Example Domain"], timeoutValue: 10)
        XCTAssertFalse(app.tables["Bookmarks List"].cells.staticTexts["Example Domain"].exists, "Bookmark not removed successfully")
    }

    func testDesktopFoldersArePresent() {
        // Verify that there are only 1 cell (desktop bookmark folder)
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        navigator.goto(LibraryPanel_Bookmarks)
        // There is only one folder at the root of the bookmarks
        waitForExistence(app.tables["Bookmarks List"], timeout: 5)
        XCTAssertEqual(app.tables["Bookmarks List"].cells.count, 1)

        // There is only three folders inside the desktop bookmarks
        app.tables["Bookmarks List"].cells.firstMatch.tap()
        waitForExistence(app.tables["Bookmarks List"], timeout: 5)
        XCTAssertEqual(app.tables["Bookmarks List"].cells.count, 3)
    }
}
