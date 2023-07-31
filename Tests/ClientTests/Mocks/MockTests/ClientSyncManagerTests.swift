// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Foundation

@testable import Client

final class ClientSyncManagerTests: XCTestCase {
    private var sut: ClientSyncManagerSpy!
    private let engine = "creditcards"

    override func setUp() {
        super.setUp()
        sut = ClientSyncManagerSpy()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testCheckCreditCardEngineEnablement_WhenMockDeclinedEnginesIsNilAndMockEngineEnabledIsFalse() {
        sut.setMockDeclinedEngines(nil)
        sut.setMockEngineEnabled(false)
        let result = sut.checkCreditCardEngineEnablement()
        XCTAssertEqual(result, false)
    }

    func testCheckCreditCardEngineEnablement_WhenMockDeclinedEnginesIsEmptyAndMockEngineEnabledIsFalse() {
        sut.setMockDeclinedEngines([])
        sut.setMockEngineEnabled(false)
        let result = sut.checkCreditCardEngineEnablement()
        XCTAssertEqual(result, false)
    }

    func testCheckCreditCardEngineEnablement_WhenMockDeclinedEnginesContainsCreditCardsAndMockEngineEnabledIsFalse() {
        sut.setMockDeclinedEngines([engine])
        sut.setMockEngineEnabled(false)
        let result = sut.checkCreditCardEngineEnablement()
        XCTAssertEqual(result, false)
    }

    func testCheckCreditCardEngineEnablement_WhenMockDeclinedEnginesContainsCreditCardsAndMockEngineEnabledIsTrue() {
        sut.setMockDeclinedEngines([engine])
        sut.setMockEngineEnabled(true)
        let result = sut.checkCreditCardEngineEnablement()
        XCTAssertEqual(result, false)
    }

    func testCheckCreditCardEngineEnablement_WhenMockDeclinedEnginesDoesNotContainCreditCardsAndMockEngineEnabledIsTrue() {
        sut.setMockDeclinedEngines(["someengine"])
        sut.setMockEngineEnabled(true)
        let result = sut.checkCreditCardEngineEnablement()
        XCTAssertEqual(result, true)
    }

    func testCheckCreditCardEngineEnablement_WhenMockDeclinedEnginesDoesNotContainCreditCardsAndMockEngineEnabledIsFalse() {
        sut.setMockDeclinedEngines(["someengine"])
        sut.setMockEngineEnabled(false)
        let result = sut.checkCreditCardEngineEnablement()
        XCTAssertEqual(result, false)
    }
}
