// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Storage
import Shared
import Common

class DependencyHelper {
    func bootstrapDependencies() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            // Fatal error here so we can gather info as this would cause a crash down the line anyway
            fatalError("Failed to register any dependencies")
        }

        let profile: Profile = appDelegate.profile
        AppContainer.shared.register(service: profile)

        let tabManager: TabManager = appDelegate.tabManager
        AppContainer.shared.register(service: tabManager)

        let appSessionProvider: AppSessionProvider = appDelegate.appSessionManager
        AppContainer.shared.register(service: appSessionProvider)

        let themeManager: ThemeManager = appDelegate.themeManager
        AppContainer.shared.register(service: themeManager)

        let ratingPromptManager: RatingPromptManager = appDelegate.ratingPromptManager
        AppContainer.shared.register(service: ratingPromptManager)

        let downloadQueue: DownloadQueue = appDelegate.appSessionManager.downloadQueue
        AppContainer.shared.register(service: downloadQueue)

        // Tell the container we are done registering
        AppContainer.shared.bootstrap()
    }
}
