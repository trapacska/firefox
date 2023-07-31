// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class ShareExtensionCoordinatorTests: XCTestCase {
    private var parentCoordinator: MockParentCoordinatorDelegate!
    private var mockRouter: MockRouter!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: MockProfile())
        parentCoordinator = MockParentCoordinatorDelegate()
    }

    override func tearDown() {
        super.tearDown()
        parentCoordinator = nil
        mockRouter = nil
        DependencyHelperMock().reset()
    }

    func testStart_presentUIActivityViewController() {
        let subject = createSubject()

        subject.start(url: URL(string: "https://www.google.com")!, sourceView: UIView())

        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(mockRouter.presentedViewController is UIActivityViewController)
    }

    func testDidFinishCalled_whenDevicePickerDidCancel() {
        let subject = createSubject()

        subject.devicePickerViewControllerDidCancel(DevicePickerViewController(profile: MockProfile()))

        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
        XCTAssertEqual(mockRouter.dismissCalled, 1)
    }

    func testDidFinishedCalled_whenDevicePickerDidSelectDevices() {
        let subject = createSubject()

        subject.devicePickerViewController(DevicePickerViewController(profile: MockProfile()), didPickDevices: [])

        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
        XCTAssertEqual(mockRouter.dismissCalled, 1)
    }

    func testDidFinishedCalled_whenInstructionViewDidDismiss() {
        let subject = createSubject()

        subject.dismissInstructionsView()

        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
        XCTAssertEqual(mockRouter.dismissCalled, 1)
    }

    func testDidFinishCelled_whenDidFinishShowJSAlertPrompt() {
        let subject = createSubject()

        subject.promptAlertControllerDidDismiss(JSPromptAlertController(title: nil, message: nil, preferredStyle: .alert))

        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
    }

    private func createSubject() -> ShareExtensionCoordinator {
        mockRouter = MockRouter(navigationController: UINavigationController())
        let subject = ShareExtensionCoordinator(
            alertContainer: UIView(),
            router: mockRouter,
            profile: MockProfile(),
            parentCoordinator: parentCoordinator)
        trackForMemoryLeaks(subject)
        return subject
    }
}
