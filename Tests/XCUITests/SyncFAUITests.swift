// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

let getEndPoint = "http://restmail.net/mail/test-256a5b5b18"
let postEndPoint = "https://api-accounts.stage.mozaws.net/v1/recovery_email/verify_code"
let deleteEndPoint = "http://restmail.net/mail/test-256a5b5b18@restmail.net"

let userMail = "test-256a5b5b18@restmail.net"
let password = "nPuPEcoj"

var uid: String!
var code: String!

class SyncUITests: BaseTestCase {
    func testUIFromSettings () {
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        navigator.goto(FxASigninScreen)
        verifyFxASigninScreen()
    }

    func testSyncUIFromBrowserTabMenu() {
        // Check menu available from HomeScreenPanel
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        navigator.goto(BrowserTabMenu)
        waitForExistence(app.tables["Context Menu"].otherElements[ImageIdentifiers.sync])
        navigator.goto(Intro_FxASignin)
        navigator.performAction(Action.OpenEmailToSignIn)
        verifyFxASigninScreen()
    }

    private func verifyFxASigninScreen() {
        waitForExistence(app.navigationBars[AccessibilityIdentifiers.Settings.FirefoxAccount.fxaNavigationBar], timeout: 30)
        waitForExistence(app.webViews.textFields[AccessibilityIdentifiers.Settings.FirefoxAccount.emailTextField], timeout: 10)
        XCTAssertTrue(app.webViews.textFields[AccessibilityIdentifiers.Settings.FirefoxAccount.emailTextField].exists)

        // Verify the placeholdervalues here for the textFields
        let mailPlaceholder = "Enter your email"
        let defaultMailPlaceholder = app.webViews.textFields["Enter your email"].placeholderValue!
        XCTAssertEqual(mailPlaceholder, defaultMailPlaceholder, "The mail placeholder does not show the correct value")
        XCTAssertTrue(app.webViews.buttons[AccessibilityIdentifiers.Settings.FirefoxAccount.continueButton].exists)
    }

    func testTypeOnGivenFields() {
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        navigator.goto(FxASigninScreen)
        waitForExistence(app.navigationBars[AccessibilityIdentifiers.Settings.FirefoxAccount.fxaNavigationBar], timeout: 60)

        // Tap Sign in without any value in email Password focus on Email
        waitForExistence(app.webViews.buttons[AccessibilityIdentifiers.Settings.FirefoxAccount.continueButton], timeout: 20)
        navigator.performAction(Action.FxATapOnContinueButton)
        waitForExistence(app.webViews.staticTexts["Valid email required"])

        // Enter only email, wrong and correct and tap sign in
        userState.fxaUsername = "foo1bar2baz3@gmail.com"
        navigator.performAction(Action.FxATypeEmail)
        navigator.performAction(Action.FxATapOnSignInButton)

        // Enter invalid (too short, it should be at least 8 chars) and incorrect password
        userState.fxaPassword = "foo"
        navigator.performAction(Action.FxATypePassword)
        navigator.performAction(Action.FxATapOnSignInButton)
        waitForExistence(app.webViews.staticTexts["At least 8 characters"])

        // Enter valid but incorrect, it does not exists, password
        userState.fxaPassword = "atleasteight"
        navigator.performAction(Action.FxATypePassword)
        waitForExistence(app.secureTextFields["Repeat password"], timeout: 10)
    }

    func testCreateAnAccountLink() {
        navigator.nowAt(NewTabScreen)
        navigator.goto(FxASigninScreen)
        waitForExistence(app.webViews.firstMatch, timeout: 20)
        waitForExistence(app.webViews.textFields[AccessibilityIdentifiers.Settings.FirefoxAccount.emailTextField], timeout: 40)
        userState.fxaUsername = "foo1bar2@gmail.com"
        navigator.performAction(Action.FxATypeEmail)
        navigator.performAction(Action.FxATapOnContinueButton)
        waitForExistence(app.webViews.buttons["Create account"])
    }

    func testShowPassword() {
        // The aim of this test is to check if the option to show password is shown when user starts typing and dissapears when no password is typed
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        navigator.goto(FxASigninScreen)
        waitForExistence(app.webViews.textFields[AccessibilityIdentifiers.Settings.FirefoxAccount.emailTextField], timeout: 20)
        // Typing on Email should not show Show (password) option
        userState.fxaUsername = "iosmztest@gmail.com"
        navigator.performAction(Action.FxATypeEmail)
        navigator.performAction(Action.FxATapOnContinueButton)
        // Typing on Password should show Show (password) option
        userState.fxaPassword = "f"
        navigator.performAction(Action.FxATypePassword)
        waitForExistence(app.webViews.otherElements["Show password"], timeout: 3)
        // Remove the password typed, Show (password) option should not be shown
        app.secureTextFields.element(boundBy: 0).typeText(XCUIKeyboardKey.delete.rawValue)
        waitForNoExistence(app.webViews.staticTexts["Show password"])
    }

    func testQRPairing() {
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        navigator.goto(Intro_FxASignin)
        // QR does not work on sim but checking that the button works, no crash
        navigator.performAction(Action.OpenEmailToQR)
        waitForExistence(app.navigationBars[AccessibilityIdentifiers.Settings.FirefoxAccount.fxaNavigationBar], timeout: 5)
        app.navigationBars[AccessibilityIdentifiers.Settings.FirefoxAccount.fxaNavigationBar].buttons["Close"].tap()
        waitForExistence(app.collectionViews.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell])
    }
}
