// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared

class MockPocketSponsoredStoriesProvider: PocketSponsoredStoriesProviding {
    func fetchSponsoredStories(timestamp: Timestamp = Date.now(), completion: @escaping (Result<[PocketSponsoredStory], Error>) -> Void) {
        let path = Bundle(for: type(of: self)).path(forResource: "pocketsponsoredfeed", ofType: "json")
        let data = try! Data(contentsOf: URL(fileURLWithPath: path!))
        let response = try! JSONDecoder().decode(PocketSponsoredRequest.self, from: data)
        completion(.success(response.spocs))
    }
}
