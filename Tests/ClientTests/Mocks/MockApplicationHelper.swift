// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
@testable import Client

class MockApplicationHelper: ApplicationHelper {
    var openSettingsCalled = 0
    var openURLCalled = 0
    var lastOpenURL: URL?

    func openSettings() {
        openSettingsCalled += 1
    }

    func open(_ url: URL) {
        openURLCalled += 1
        lastOpenURL = url
    }
}
