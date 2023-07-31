// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Storage
import Shared
import Common
@testable import Client

class HistoryPanelViewModelTests: XCTestCase {
    var subject: HistoryPanelViewModel!
    var profile: MockProfile!

    override func setUp() {
        super.setUp()

        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile(databasePrefix: "HistoryPanelViewModelTest")
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        profile.reopen()
        subject = HistoryPanelViewModel(profile: profile)
    }

    override func tearDown() {
        super.tearDown()

        AppContainer.shared.reset()
        clear(profile: profile)
        profile.shutdown()
        profile = nil
        subject = nil
    }

    func testHistorySectionTitle() {
        HistoryPanelViewModel.Sections.allCases.forEach({ section in
            switch section {
            case .today:
                XCTAssertEqual(section.title, .LibraryPanel.Sections.Today)
            case .yesterday:
                XCTAssertEqual(section.title, .LibraryPanel.Sections.Yesterday)
            case .lastWeek:
                XCTAssertEqual(section.title, .LibraryPanel.Sections.LastWeek)
            case .lastMonth:
                XCTAssertEqual(section.title, .LibraryPanel.Sections.LastMonth)
            case .older:
                XCTAssertEqual(section.title, .LibraryPanel.Sections.Older)
            case .additionalHistoryActions, .searchResults:
                XCTAssertNil(section.title)
            }
        })
    }

    func testFetchHistory_WithResults() {
        setupSiteVisits()

        fetchHistory { success in
            XCTAssertTrue(success)
            XCTAssertNotNil(self.subject.searchTermGroups)
            XCTAssertFalse(self.subject.groupedSites.isEmpty)
            XCTAssertFalse(self.subject.visibleSections.isEmpty)
        }
    }

    func testFetchHistoryFail_WithFetchInProgress() {
        subject.isFetchInProgress = true

        fetchHistory { success in
            XCTAssertFalse(success)
        }
    }

    func testPerformSearch_ForNoResults() {
        fetchSearchHistory(searchTerm: "moz") { hasResults in
            XCTAssertFalse(hasResults)
            XCTAssertEqual(self.subject.searchResultSites.count, 0)
        }
    }

    func testPerformSearch_WithResults() {
        setupSiteVisits()

        fetchSearchHistory(searchTerm: "moz") { hasResults in
            XCTAssertTrue(hasResults)
            XCTAssertEqual(self.subject.searchResultSites.count, 2)
        }
    }

    func testEmptyStateText_ForSearch() {
        subject.isSearchInProgress = true
        XCTAssertEqual(subject.emptyStateText, .LibraryPanel.History.NoHistoryResult)
    }

    func testEmptyStateText_ForHistoryResults() {
        subject.isSearchInProgress = false
        XCTAssertEqual(subject.emptyStateText, .HistoryPanelEmptyStateTitle)
    }

    func testShouldShowEmptyState_ForEmptySearch() {
        setupSiteVisits()
        subject.isSearchInProgress = true

        fetchSearchHistory(searchTerm: "") { hasResults in
            XCTAssertFalse(self.subject.shouldShowEmptyState(searchText: ""))
        }
    }

    func testShouldShowEmptyState_ForNoResultSearch() {
        setupSiteVisits()
        subject.isSearchInProgress = true

        fetchSearchHistory(searchTerm: "ui") { hasResults in
            XCTAssertTrue(self.subject.shouldShowEmptyState(searchText: "ui"))
        }
    }

    func testShouldShowEmptyState_ForNoHistory() {
        subject.isSearchInProgress = false

        fetchHistory { _ in
            XCTAssertTrue(self.subject.shouldShowEmptyState())
        }
    }

    func testCollapseSection() {
        setupSiteVisits()
        XCTAssertTrue(subject.hiddenSections.isEmpty)

        fetchHistory { _ in
            self.subject.collapseSection(sectionIndex: 1)
            XCTAssertEqual(self.subject.hiddenSections.count, 1)
            // Starts at 0, removing the Additional section
            XCTAssertTrue(self.subject.isSectionCollapsed(sectionIndex: 0))
            XCTAssertTrue(self.subject.hiddenSections.contains(where: { $0 == .today }))
        }
    }

    func testExpandSection() {
        setupSiteVisits()
        XCTAssertTrue(subject.hiddenSections.isEmpty)

        fetchHistory { _ in
            self.subject.collapseSection(sectionIndex: 1)
            XCTAssertEqual(self.subject.hiddenSections.count, 1)
            // Starts at 0, removing the Additional section
            XCTAssertTrue(self.subject.isSectionCollapsed(sectionIndex: 0))
            XCTAssertTrue(self.subject.hiddenSections.contains(where: { $0 == .today }))

            self.subject.collapseSection(sectionIndex: 1)
            XCTAssertTrue(self.subject.hiddenSections.isEmpty)
            XCTAssertFalse(self.subject.isSectionCollapsed(sectionIndex: 1))
        }
    }

    func testRemoveAllData() {
        setupSiteVisits()
        XCTAssertTrue(subject.hiddenSections.isEmpty)

        fetchHistory { _ in
            self.subject.removeAllData()

            XCTAssertEqual(self.subject.currentFetchOffset, 0)
            XCTAssertTrue(self.subject.searchTermGroups.isEmpty)
            XCTAssertTrue(self.subject.groupedSites.isEmpty)
            XCTAssertTrue(self.subject.visibleSections.isEmpty)
        }
    }

    func testShouldNotAddGroupToSections() {
        let searchTermGroup = createSearchTermGroup(timestamp: Date().toMicrosecondsSince1970())
        XCTAssertNil(self.subject.shouldAddGroupToSections(group: searchTermGroup))
    }

    func testGroupBelongToSection_ForToday() {
        let searchTermGroup = createSearchTermGroup(timestamp: Date().toMicrosecondsSince1970())

        guard let section = self.subject.groupBelongsToSection(asGroup: searchTermGroup) else {
            XCTFail("Expected to return today section")
            return
        }

        XCTAssertEqual(section, .today)
    }

    func testGroupBelongToSection_ForYesterday() {
        let yesterday = Date.yesterday
        let searchTermGroup = createSearchTermGroup(timestamp: yesterday.toMicrosecondsSince1970())

        guard let section = self.subject.groupBelongsToSection(asGroup: searchTermGroup) else {
            XCTFail("Expected to return today section")
            return
        }

        XCTAssertEqual(section, .yesterday)
    }

    func testGroupBelongToSection_ForLastWeek() {
        let yesterday = Date().lastWeek
        let searchTermGroup = createSearchTermGroup(timestamp: yesterday.toMicrosecondsSince1970())

        guard let section = self.subject.groupBelongsToSection(asGroup: searchTermGroup) else {
            XCTFail("Expected to return today section")
            return
        }

        XCTAssertEqual(section, .lastWeek)
    }

    func testGroupBelongToSection_ForTwoLastWeek() {
        let yesterday = Date().lastTwoWeek
        let searchTermGroup = createSearchTermGroup(timestamp: yesterday.toMicrosecondsSince1970())

        guard let section = self.subject.groupBelongsToSection(asGroup: searchTermGroup) else {
            XCTFail("Expected to return today section")
            return
        }

        XCTAssertEqual(section, .lastMonth)
    }

    func testShouldAddGroupToSections_ForToday() {
        let searchTermGroup = createSearchTermGroup(timestamp: Date().toMicrosecondsSince1970())
        subject.visibleSections.append(.today)

        guard let section = self.subject.shouldAddGroupToSections(group: searchTermGroup) else {
            XCTFail("Expected to return today section")
            return
        }

        XCTAssertEqual(section, .today)
    }

    // MARK: - Deletion

    func testDeleteGroup_ForToday() {
        setupSiteVisits()

        fetchHistory { _ in
            XCTAssertEqual(self.subject.visibleSections[0], .today)
            self.subject.deleteGroupsFor(dateOption: .today)
            XCTAssertEqual(self.subject.visibleSections.count, 0)
        }
    }

    // MARK: - Setup
    private func setupSiteVisits() {
        addSiteVisit(profile, url: "http://mozilla.org/", title: "Mozilla internet")
        addSiteVisit(profile, url: "http://mozilla.dev.org/", title: "Internet dev")
        addSiteVisit(profile, url: "https://apple.com/", title: "Apple")
    }

    private func addSiteVisit(_ profile: MockProfile, url: String, title: String) {
        let visitObservation = VisitObservation(url: url, title: title, visitType: VisitTransition.link)
        let result = profile.places.applyObservation(visitObservation: visitObservation)

        XCTAssertEqual(true, result.value.isSuccess, "Site added: \(url).")
    }

    private func clear(profile: MockProfile) {
        let result = profile.places.deleteEverythingHistory()
        XCTAssertTrue(result.value.isSuccess, "History cleared.")
    }

    private func fetchHistory(completion: @escaping (Bool) -> Void) {
        let expectation = self.expectation(description: "Wait for history")

        subject.reloadData { success in
            XCTAssertNotNil(success)
            completion(success)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    private func fetchSearchHistory(searchTerm: String,
                                    completion: @escaping (Bool) -> Void) {
        let expectation = self.expectation(description: "Wait for history search")

        subject.performSearch(term: searchTerm) { hasResults in
            XCTAssertNotNil(hasResults)
            completion(hasResults)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    private func createSearchTermGroup(timestamp: MicrosecondTimestamp) -> ASGroup<Site> {
        var groupSites = [Site]()
        for index in 0...3 {
            let site = Site(url: "http://site\(index).com", title: "Site \(index)")
            site.latestVisit = Visit(date: timestamp)
            let visit = VisitObservation(url: site.url, title: site.title, visitType: VisitTransition.link, at: Int64(timestamp) / 1000)
            XCTAssertTrue(profile.places.applyObservation(visitObservation: visit).value.isSuccess, "Site added: \(site.url).")
            groupSites.append(site)
        }

        return ASGroup<Site>(searchTerm: "site", groupedItems: groupSites, timestamp: timestamp)
    }
}
