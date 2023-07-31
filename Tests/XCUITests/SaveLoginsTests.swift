// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

let domain = "http://localhost:\(serverPort)"
let domainLogin = "test@example.com"
let domainSecondLogin = "test2@example.com"
let testLoginPage = path(forTestPage: "test-password.html")
let testSecondLoginPage = path(forTestPage: "test-password-2.html")
let savedLoginEntry = "test@example.com, http://localhost:\(serverPort)"
let urlLogin = path(forTestPage: "empty-login-form.html")
let mailLogin = "iosmztest@mailinator.com"
// The following seem to be labels that change a lot and make the tests break; aka volatile. Let's keep them in one place.
let loginsListURLLabel = "Website, \(domain)"
let loginsListUsernameLabel = "Username, test@example.com"
let loginsListPasswordLabel = "Password"
let defaultNumRowsLoginsList = 2
let defaultNumRowsEmptyFilterList = 0

class SaveLoginTest: BaseTestCase {
    private func saveLogin(givenUrl: String) {
        navigator.openURL(givenUrl)
        waitUntilPageLoad()
        waitForExistence(app.buttons["submit"], timeout: 10)
        app.buttons["submit"].tap()
        waitForExistence(app.buttons["SaveLoginPrompt.saveLoginButton"], timeout: 10)
        app.buttons["SaveLoginPrompt.saveLoginButton"].tap()
    }

    private func openLoginsSettings() {
        navigator.goto(SettingsScreen)
        waitForExistence(app.cells["SignInToSync"], timeout: 5)
        app.cells["SignInToSync"].swipeUp()
        navigator.goto(LoginsSettings)

        unlockLoginsView()
        waitForExistence(app.tables["Login List"])
    }

    private func unlockLoginsView() {
        let passcodeInput = springboard.otherElements.secureTextFields.firstMatch
        waitForExistence(passcodeInput, timeout: 20)
        passcodeInput.tap()
        passcodeInput.typeText("foo\n")

        // This biometric screen only appears the first time.
        // The location of this if-statement is a temporary workaround for FXIOS-7033.
        // This if-statement is supposed to be located before the passcode is entered.
        // https://github.com/mozilla-mobile/firefox-ios/issues/15642
        sleep(2)
        if app.otherElements.buttons["Continue"].exists {
            app.otherElements.buttons["Continue"].tap()
        }
    }

    func testLoginsListFromBrowserTabMenu() {
        closeURLBar()
        // Make sure you can access empty Login List from Browser Tab Menu
        navigator.goto(LoginsSettings)
        unlockLoginsView()
        waitForExistence(app.tables["Login List"])
        XCTAssertTrue(app.searchFields["Filter"].exists)
        XCTAssertEqual(app.tables["Login List"].cells.count, defaultNumRowsLoginsList)
        app.buttons["Settings"].tap()
        navigator.performAction(Action.OpenNewTabFromTabTray)
        saveLogin(givenUrl: testLoginPage)
        // Make sure you can access populated Login List from Browser Tab Menu
        navigator.goto(LoginsSettings)
        unlockLoginsView()
        waitForExistence(app.tables["Login List"])
        XCTAssertTrue(app.searchFields["Filter"].exists)
        XCTAssertTrue(app.staticTexts[domain].exists)
        XCTAssertTrue(app.staticTexts[domainLogin].exists)
        XCTAssertEqual(app.tables["Login List"].cells.count, defaultNumRowsLoginsList + 1)
    }

    // Smoketest
    func testSaveLogin() {
        closeURLBar()
        // Initially the login list should be empty
        openLoginsSettings()
        XCTAssertEqual(app.tables["Login List"].cells.count, defaultNumRowsLoginsList)
        // Save a login and check that it appears on the list
        saveLogin(givenUrl: testLoginPage)
        openLoginsSettings()
        waitForExistence(app.tables["Login List"])
        XCTAssertTrue(app.staticTexts[domain].exists)
        // XCTAssertTrue(app.staticTexts[domainLogin].exists)
        XCTAssertEqual(app.tables["Login List"].cells.count, defaultNumRowsLoginsList + 1)
        // Check to see how it works with multiple entries in the list- in this case, two for now
        saveLogin(givenUrl: testSecondLoginPage)
        openLoginsSettings()
        waitForExistence(app.tables["Login List"])
        XCTAssertTrue(app.staticTexts[domain].exists)
        // XCTAssertTrue(app.staticTexts[domainSecondLogin].exists)
        // Workaround for Bitrise specific issue. "vagrant" user is used in Bitrise.
        if (ProcessInfo.processInfo.environment["HOME"]!).contains(String("vagrant")) {
            XCTAssertEqual(app.tables["Login List"].cells.count, defaultNumRowsLoginsList + 1)
        } else {
            XCTAssertEqual(app.tables["Login List"].cells.count, defaultNumRowsLoginsList + 2)
        }
    }

    func testDoNotSaveLogin() {
        navigator.openURL(testLoginPage)
        waitUntilPageLoad()
        app.buttons["submit"].tap()
        app.buttons["SaveLoginPrompt.dontSaveButton"].tap()
        // There should not be any login saved
        openLoginsSettings()
        XCTAssertFalse(app.staticTexts[domain].exists)
        XCTAssertFalse(app.staticTexts[domainLogin].exists)
        XCTAssertEqual(app.tables["Login List"].cells.count, defaultNumRowsLoginsList)
    }

    // Smoketest
    func testSavedLoginSelectUnselect() {
        saveLogin(givenUrl: testLoginPage)
        navigator.goto(SettingsScreen)
        openLoginsSettings()
        XCTAssertTrue(app.staticTexts[domain].exists)
        XCTAssertTrue(app.staticTexts[domainLogin].exists)
        app.buttons["Edit"].tap()

        XCTAssertTrue(app.buttons["Select All"].exists)
        XCTAssertTrue(app.staticTexts[domain].exists)
        XCTAssertTrue(app.staticTexts[domainLogin].exists)

        app.staticTexts[domain].tap()
        waitForExistence(app.buttons["Deselect All"])

        XCTAssertTrue(app.buttons["Deselect All"].exists)
        XCTAssertTrue(app.buttons["Delete"].exists)
    }

    func testDeleteLogin() {
        saveLogin(givenUrl: testLoginPage)
        openLoginsSettings()
        app.staticTexts[domain].tap()
        app.cells.staticTexts["Delete"].tap()
        waitForExistence(app.alerts["Are you sure?"])
        app.alerts.buttons["Delete"].tap()
        waitForExistence(app.tables["Login List"])
        XCTAssertFalse(app.staticTexts[domain].exists)
        XCTAssertFalse(app.staticTexts[domainLogin].exists)
        XCTAssertEqual(app.tables["Login List"].cells.count, defaultNumRowsLoginsList)
    }

//    func testEditOneLoginEntry() {
//        saveLogin(givenUrl: testLoginPage)
//        openLoginsSettings()
//        XCTAssertTrue(app.staticTexts[domain].exists)
//        XCTAssertTrue(app.staticTexts[domainLogin].exists)
//        app.staticTexts[domain].tap()
//        waitForExistence(app.tables["Login Detail List"])
//        XCTAssertTrue(app.tables.cells[loginsListURLLabel].exists)
//        XCTAssertTrue(app.tables.cells[loginsListUsernameLabel].exists)
//        XCTAssertTrue(app.tables.cells[loginsListPasswordLabel].exists)
//        XCTAssertTrue(app.tables.cells.staticTexts["Delete"].exists)
//    }

    func testSearchLogin() {
        saveLogin(givenUrl: testLoginPage)
        openLoginsSettings()
        // Enter on Search mode
        app.searchFields["Filter"].tap()
        // Type Text that matches user, website
        app.searchFields["Filter"].typeText("test")
        XCTAssertEqual(app.tables["Login List"].cells.count, defaultNumRowsLoginsList + 1)

        // Type Text that does not match
        app.typeText("b")
        XCTAssertEqual(app.tables["Login List"].cells.count, defaultNumRowsEmptyFilterList)
        // waitForExistence(app.tables["No logins found"])

        // Clear Text
        app.buttons["Clear text"].tap()
        XCTAssertEqual(app.tables["Login List"].cells.count, defaultNumRowsLoginsList + 1)
    }

    // Smoketest
    func testSavedLoginAutofilled() {
        navigator.openURL(urlLogin)
        waitUntilPageLoad()
        // Provided text fields are completely empty
        waitForExistence(app.webViews.staticTexts["Username:"], timeout: 15)

        // Fill in the username text box
        app.webViews.textFields.element(boundBy: 0).tap()
        app.webViews.textFields.element(boundBy: 0).typeText(mailLogin)
        // Fill in the password text box
        app.webViews.secureTextFields.element(boundBy: 0).tap()
        app.webViews.secureTextFields.element(boundBy: 0).typeText("test15mz")

        // Submit form and choose to save the logins
        app.buttons["submit"].tap()
        waitForExistence(app.buttons["SaveLoginPrompt.saveLoginButton"], timeout: 5)
        app.buttons["SaveLoginPrompt.saveLoginButton"].tap()

        // Clear Data and go to test page, fields should be filled in
        navigator.goto(SettingsScreen)
        navigator.performAction(Action.AcceptClearPrivateData)

        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.openURL(urlLogin)
        waitUntilPageLoad()
        waitForExistence(app.webViews.textFields.element(boundBy: 0), timeout: 3)
        // let emailValue = app.webViews.textFields.element(boundBy: 0).value!
        // XCTAssertEqual(emailValue as! String, mailLogin)
        // let passwordValue = app.webViews.secureTextFields.element(boundBy: 0).value!
        // XCTAssertEqual(passwordValue as! String, "••••••••")
    }

    // Smoketest
    func testCreateLoginManually() {
        closeURLBar()
        navigator.goto(LoginsSettings)
        unlockLoginsView()
        waitForExistence(app.tables["Login List"], timeout: 15)
        app.buttons["Add"].tap()
        waitForExistence(app.tables["Add Credential"], timeout: 15)
        XCTAssertTrue(app.tables["Add Credential"].cells.staticTexts["Website"].exists)
        XCTAssertTrue(app.tables["Add Credential"].cells.staticTexts["Username"].exists)
        XCTAssertTrue(app.tables["Add Credential"].cells.staticTexts["Password"].exists)

        app.tables["Add Credential"].cells["Website, "].tap()
        enterTextInField(typedText: "testweb")

        app.tables["Add Credential"].cells["Username, "].tap()
        enterTextInField(typedText: "foo")

        app.tables["Add Credential"].cells["Password"].tap()
        enterTextInField(typedText: "bar")

        app.buttons["Save"].tap()
        waitForExistence(app.tables["Login List"].otherElements["SAVED LOGINS"])
        // XCTAssertTrue(app.cells.staticTexts["foo"].exists)
    }

    func enterTextInField(typedText: String) {
        for letter in typedText {
            print("\(letter)")
            app.keyboards.keys["\(letter)"].tap()
        }
    }

    func closeURLBar () {
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
    }
}
