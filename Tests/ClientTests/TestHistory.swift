// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import Foundation
import Storage

import XCTest

class TestHistory: ProfileTest {
    fileprivate func addSite(_ places: RustPlaces, url: String, title: String, bool: Bool = true) {
        _ = places.reopenIfClosed()
        let site = Site(url: url, title: title)
        let visit = VisitObservation(url: site.url, title: site.title, visitType: VisitTransition.link)
        let res = places.applyObservation(visitObservation: visit).value
        XCTAssertEqual(bool, res.isSuccess, "Site added: \(url)., error value: \(res.failureValue ?? "wow")")
    }

    fileprivate func innerCheckSites(_ places: RustPlaces, callback: @escaping (_ cursor: Cursor<Site>) -> Void) {
        // Retrieve the entry
        places.getSitesWithBound(limit: 100, offset: 0, excludedTypes: VisitTransitionSet(0)).upon {
            XCTAssertTrue($0.isSuccess)
            callback($0.successValue!)
        }
    }

    fileprivate func checkSites(_ places: RustPlaces, urls: [String: String]) {
        // Retrieve the entry.
        if let cursor = places.getSitesWithBound(limit: 100, offset: 0, excludedTypes: VisitTransitionSet(0)).value.successValue {
            XCTAssertEqual(cursor.status, CursorStatus.success, "Returned success \(cursor.statusMessage).")
            XCTAssertEqual(cursor.count, urls.count, "Cursor has \(urls.count) entries.")

            for index in 0..<cursor.count {
                let site = cursor[index]!
                XCTAssertNotNil(site, "Cursor has a site for entry.")
                let title = urls[site.url]
                XCTAssertNotNil(title, "Found right URL.")
                XCTAssertEqual(site.title, title!, "Found right title.")
            }
        } else {
            XCTFail("Couldn't get cursor.")
        }
    }

    fileprivate func clear(_ places: RustPlaces) {
        XCTAssertTrue(places.deleteEverythingHistory().value.isSuccess, "History cleared.")
    }

    fileprivate func checkVisits(_ places: RustPlaces, url: String) {
        let expectation = self.expectation(description: "Wait for history")
        places.getSitesWithBound(limit: 100, offset: 0, excludedTypes: VisitTransitionSet(0)).upon { result in
            XCTAssertTrue(result.isSuccess)
            places.queryAutocomplete(matchingSearchQuery: url, limit: 100).upon { result in
                XCTAssertTrue(result.isSuccess)
                // XXX - We don't allow querying much info about visits here anymore, so there isn't a lot to do
                expectation.fulfill()
            }
        }
        self.waitForExpectations(timeout: 100, handler: nil)
    }

    // This is a very basic test. Adds an entry. Retrieves it, and then clears the database
    func testHistory() {
        withTestProfile { profile -> Void in
            let places = profile.places
            self.addSite(places, url: "http://url1/", title: "title")
            self.addSite(places, url: "http://url1/", title: "title")
            self.addSite(places, url: "http://url1/", title: "title 2")
            self.addSite(places, url: "https://url2/", title: "title")
            self.addSite(places, url: "https://url2/", title: "title")
            self.checkSites(places, urls: ["http://url1/": "title 2", "https://url2/": "title"])
            self.checkVisits(places, url: "http://url1/")
            self.checkVisits(places, url: "https://url2/")
            self.clear(places)
        }
    }

    func testSearchHistory_WithResults() {
        let expectation = self.expectation(description: "Wait for search history")
        withTestProfile { profile in
            let places = profile.places

            addSite(places, url: "http://amazon.com/", title: "Amazon")
            addSite(places, url: "http://mozilla.org/", title: "Mozilla")
            addSite(places, url: "https://apple.com/", title: "Apple")
            addSite(places, url: "https://apple.developer.com/", title: "Apple Developer")

            places.queryAutocomplete(matchingSearchQuery: "App", limit: 25).upon { result in
                XCTAssertTrue(result.isSuccess)
                let results = result.successValue!
                XCTAssertEqual(results.count, 2)
                expectation.fulfill()
                self.clear(places)
            }

            self.waitForExpectations(timeout: 100, handler: nil)
        }
    }

    func testSearchHistory_WithResultsByTitle() {
        let expectation = self.expectation(description: "Wait for search history")
        withTestProfile { profile in
            let places = profile.places
            addSite(places, url: "http://amazon.com/", title: "Amazon")
            addSite(places, url: "http://mozilla.org/", title: "Mozilla internet")
            addSite(places, url: "http://mozilla.dev.org/", title: "Internet dev")
            addSite(places, url: "https://apple.com/", title: "Apple")

            places.queryAutocomplete(matchingSearchQuery: "int", limit: 25).upon { result in
                XCTAssertTrue(result.isSuccess)
                let results = result.successValue!
                XCTAssertEqual(results.count, 2)
                expectation.fulfill()
                self.clear(places)
            }

            self.waitForExpectations(timeout: 100, handler: nil)
        }
    }

    func testSearchHistory_WithResultsByUrl() {
        let expectation = self.expectation(description: "Wait for search history")
        withTestProfile { profile in
            let places = profile.places
            addSite(places, url: "http://amazon.com/", title: "Amazon")
            addSite(places, url: "http://mozilla.developer.org/", title: "Mozilla")
            addSite(places, url: "https://apple.developer.com/", title: "Apple")

            places.queryAutocomplete(matchingSearchQuery: "dev", limit: 25).upon { result in
                XCTAssertTrue(result.isSuccess)
                let results = result.successValue!
                XCTAssertEqual(results.count, 2)
                expectation.fulfill()
                self.clear(places)
            }

            self.waitForExpectations(timeout: 100, handler: nil)
        }
    }

    func testSearchHistory_NoResults() {
        let expectation = self.expectation(description: "Wait for search history")
        withTestProfile { profile in
            let places = profile.places
            addSite(places, url: "http://amazon.com/", title: "Amazon")
            addSite(places, url: "http://mozilla.org/", title: "Mozilla internet")
            addSite(places, url: "https://apple.com/", title: "Apple")

            places.queryAutocomplete(matchingSearchQuery: "red", limit: 25).upon { result in
                XCTAssertTrue(result.isSuccess)
                let results = result.successValue!
                XCTAssertEqual(results.count, 0)
                expectation.fulfill()
                self.clear(places)
            }

            self.waitForExpectations(timeout: 100, handler: nil)
        }
    }

    func testAboutUrls() {
        withTestProfile { (profile) -> Void in
            let places = profile.places
            self.addSite(places, url: "about:home", title: "About Home")
            self.clear(places)
        }
    }

    let numThreads = 5
    let numCmds = 10

    func testInsertPerformance() {
        withTestProfile { profile -> Void in
            let places = profile.places
            var index = 0

            self.measure({ () -> Void in
                for _ in 0...self.numCmds {
                    self.addSite(places, url: "https://someurl\(index).com/", title: "title \(index)")
                    index += 1
                }
                self.clear(places)
            })
        }
    }

    func testGetPerformance() {
        withTestProfile { profile -> Void in
            let places = profile.places
            var index = 0
            var urls = [String: String]()

            self.clear(places)
            for _ in 0...self.numCmds {
                self.addSite(places, url: "https://someurl\(index).com/", title: "title \(index)")
                urls["https://someurl\(index).com/"] = "title \(index)"
                index += 1
            }

            self.measure({ () -> Void in
                self.checkSites(places, urls: urls)
                return
            })

            self.clear(places)
        }
    }

    // Fuzzing tests. These fire random insert/query/clear commands into the history database from threads. The don't check
    // the results. Just look for crashes.
    func testRandomThreading() {
        withTestProfile { profile -> Void in
            let queue = DispatchQueue(label: "My Queue",
                                      qos: DispatchQoS.default,
                                      attributes: DispatchQueue.Attributes.concurrent,
                                      autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit,
                                      target: nil)
            var counter = 0

            let expectation = self.expectation(description: "Wait for history")
            for _ in 0..<self.numThreads {
                var places = profile.places
                self.runRandom(&places, queue: queue, completion: { () -> Void in
                    counter += 1
                    if counter == self.numThreads {
                        self.clear(places)
                        expectation.fulfill()
                    }
                })
            }
            self.waitForExpectations(timeout: 10, handler: nil)
        }
    }

    // Same as testRandomThreading, but uses one history connection for all threads
    func testRandomThreading2() {
        withTestProfile { profile -> Void in
            let queue = DispatchQueue(label: "My Queue",
                                      qos: DispatchQoS.default,
                                      attributes: DispatchQueue.Attributes.concurrent,
                                      autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit,
                                      target: nil)
            var places = profile.places
            var counter = 0

            let expectation = self.expectation(description: "Wait for history")
            for _ in 0..<self.numThreads {
                self.runRandom(&places, queue: queue, completion: { () -> Void in
                    counter += 1
                    if counter == self.numThreads {
                        self.clear(places)
                        expectation.fulfill()
                    }
                })
            }
            self.waitForExpectations(timeout: 10, handler: nil)
        }
    }

    // Runs a random command on a database. Calls cb when finished.
    fileprivate func runRandom(
        _ places: inout RustPlaces,
        cmdIn: Int,
        completion: @escaping () -> Void
    ) {
        var cmd = cmdIn
        if cmd < 0 {
            cmd = Int(arc4random() % 5)
        }

        switch cmd {
        case 0...1:
            let url = "https://randomurl.com/\(arc4random() % 100)"
            let title = "title \(arc4random() % 100)"
            addSite(places, url: url, title: title)
            completion()
        case 2...3:
            innerCheckSites(places) { cursor in
                for site in cursor {
                    _ = site!
                }
            }
            completion()
        default:
            places.deleteEverythingHistory().upon { success in completion() }
        }
    }

    // Calls numCmds random methods on this database. val is a counter used by this interally (i.e. always pass zero for it).
    // Calls cb when finished.
    fileprivate func runMultiRandom(
        _ places: inout RustPlaces,
        val: Int, numCmds: Int,
        completion: @escaping () -> Void
    ) {
        if val == numCmds {
            completion()
            return
        } else {
            runRandom(&places, cmdIn: -1) { [places] in
                var places = places
                self.runMultiRandom(&places, val: val+1, numCmds: numCmds, completion: completion)
            }
        }
    }

    // Helper for starting a new thread running NumCmds random methods on it. Calls cb when done.
    fileprivate func runRandom(
        _ places: inout RustPlaces,
        queue: DispatchQueue,
        completion: @escaping () -> Void
    ) {
        queue.async { [places] in
            var places = places
            // Each thread creates its own history provider
            self.runMultiRandom(&places, val: 0, numCmds: self.numCmds) {
                DispatchQueue.main.async(execute: completion)
            }
        }
    }
}
