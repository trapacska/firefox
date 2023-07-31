// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

public typealias GUID = String

/// Utilities for futzing with bytes and such.
extension Bytes {
    public class func generateGUID() -> GUID {
        // Turns the standard NSData encoding into the URL-safe variant that Sync expects.
        return generateRandomBytes(9)
            .base64EncodedString(options: [])
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
    }

    public class func decodeBase64(_ b64: String) -> Data? {
        return Data(base64Encoded: b64, options: [])
    }

    /**
     * Turn a string of base64 characters into an NSData *without decoding*.
     * This is to allow HMAC to be computed of the raw base64 string.
     */
    public class func dataFromBase64(_ b64: String) -> Data? {
        return b64.data(using: .ascii, allowLossyConversion: false)
    }
}
