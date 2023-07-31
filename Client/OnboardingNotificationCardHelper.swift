// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct OnboardingNotificationCardHelper {
    private func notificationCardIsInOnboarding(
        from featureLayer: NimbusOnboardingFeatureLayer = NimbusOnboardingFeatureLayer()
    ) -> Bool {
        return featureLayer
            .getOnboardingModel(for: .freshInstall)
            .cards
            .contains {
                return $0.buttons.primary.action == .requestNotifications
                || $0.buttons.secondary?.action == .requestNotifications
            }
    }

    func askForPermissionDuringSync(isOnboarding: Bool) -> Bool {
        if notificationCardIsInOnboarding() { return false }

        return isOnboarding
    }
}
