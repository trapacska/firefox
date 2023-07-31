// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// This struct defines all the standard image identifiers of icons and images used in the app.
/// When adding new identifiers, please respect alphabetical order.
/// Sing the song if you must.
public struct StandardImageIdentifiers {
    public struct Medium {
        public static let cross = "crossMedium"
    }

    public struct Large {
        public static let appendUp = "appendUpLarge"
        public static let appMenu = "appMenuLarge"
        public static let avatarCircle = "avatarCircleLarge"
        public static let back = "backLarge"
        public static let bookmark = "bookmarkLarge"
        public static let bookmarkFill = "bookmarkFillLarge"
        public static let bookmarkSlash = "bookmarkSlashLarge"
        public static let bookmarkTrayFill = "bookmarkTrayFillLarge"
        public static let checkmark = "checkmarkLarge"
        public static let chevronDown = "chevronDownLarge"
        public static let chevronLeft = "chevronLeftLarge"
        public static let chevronRight = "chevronRightLarge"
        public static let chevronUp = "chevronUpLarge"
        public static let clipboard = "clipboardLarge"
        public static let creditCard = "creditCardLarge"
        public static let cross = "crossLarge"
        public static let delete = "deleteLarge"
        public static let deviceDesktop = "deviceDesktopLarge"
        public static let deviceDesktopSend = "deviceDesktopSendLarge"
        public static let deviceMobile = "deviceMobileLarge"
        public static let download = "downloadLarge"
        public static let edit = "editLarge"
        public static let folder = "folderLarge"
        public static let forward = "forwardLarge"
        public static let globe = "globeLarge"
        public static let helpCircle = "helpCircleLarge"
        public static let history = "historyLarge"
        public static let home = "homeLarge"
        public static let lock = "lockLarge"
        public static let logoFirefox = "logoFirefoxLarge"
        public static let lightbulb = "lightbulbLarge"
        public static let link = "linkLarge"
        public static let login = "loginLarge"
        public static let plus = "plusLarge"
        public static let privateMode = "privateModeLarge"
        public static let qrCode = "qrCodeLarge"
        public static let tabTray = "tabTrayLarge"
    }

    /// Those identifiers currently duplicate `ImageIndentifiers` until they are standardized with task #14633
    public struct ToMigrate {
        public static let bottomSheetClose = "bottomSheet-close"
    }
}
