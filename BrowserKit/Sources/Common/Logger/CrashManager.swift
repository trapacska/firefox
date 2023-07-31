// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Sentry

// MARK: - CrashManager
public protocol CrashManager {
    var crashedLastLaunch: Bool { get }

    func setup(sendUsageData: Bool)
    func send(message: String,
              category: LoggerCategory,
              level: LoggerLevel,
              extraEvents: [String: String]?)
}

public class DefaultCrashManager: CrashManager {
    enum Environment: String {
        case nightly = "Nightly"
        case production = "Production"
    }

    // MARK: - Properties
    private let deviceAppHashKey = "SentryDeviceAppHash"
    private let defaultDeviceAppHash = "0000000000000000000000000000000000000000"
    private let deviceAppHashLength = UInt(20)

    private var enabled = false

    private var shouldSetup: Bool {
        return !enabled && !isSimulator
    }

    private var environment: Environment {
        var environment = Environment.production
        if AppInfo.appVersion == appInfo.nightlyAppVersion, appInfo.buildChannel == .beta {
            environment = Environment.nightly
        }
        return environment
    }

    private var releaseName: String {
        return "\(AppInfo.bundleIdentifier)@\(AppInfo.appVersion)+(\(AppInfo.buildNumber))"
    }

    // MARK: - Init
    private var appInfo: BrowserKitInformation
    private var sentryWrapper: SentryWrapper
    private var isSimulator: Bool

    // Only enable app hang tracking in Beta for now
    private var shouldEnableAppHangTracking: Bool {
        return appInfo.buildChannel == .beta
    }

    private var shouldEnableMetricKit: Bool {
        return appInfo.buildChannel == .beta
    }

    public init(appInfo: BrowserKitInformation = BrowserKitInformation.shared,
                sentryWrapper: SentryWrapper = DefaultSentry(),
                isSimulator: Bool = DeviceInfo.isSimulator()) {
        self.appInfo = appInfo
        self.sentryWrapper = sentryWrapper
        self.isSimulator = isSimulator
    }

    // MARK: - CrashManager protocol
    public var crashedLastLaunch: Bool {
        return sentryWrapper.crashedInLastRun
    }

    public func setup(sendUsageData: Bool) {
        guard shouldSetup, sendUsageData, let dsn = sentryWrapper.dsn else { return }

        sentryWrapper.startWithConfigureOptions(configure: { options in
            options.dsn = dsn
            options.environment = self.environment.rawValue
            options.releaseName = self.releaseName
            options.enableFileIOTracing = false
            options.enableNetworkTracking = false
            options.enableAppHangTracking = self.shouldEnableAppHangTracking
            if #available(iOS 15.0, *) {
                options.enableMetricKit = self.shouldEnableMetricKit
            }
            options.enableCaptureFailedRequests = false
            options.enableSwizzling = false
            options.beforeBreadcrumb = { crumb in
                if crumb.type == "http" || crumb.category == "http" {
                    return nil
                }
                return crumb
            }
            // Turn Sentry breadcrumbs off since we have our own log swizzling
            options.enableAutoBreadcrumbTracking = false
        })
        enabled = true

        configureScope()
        configureIdentifier()
        setupIgnoreException()
    }

    public func send(message: String,
                     category: LoggerCategory,
                     level: LoggerLevel,
                     extraEvents: [String: String]?) {
        guard enabled else { return }

        guard shouldSendEventFor(level) else {
            addBreadcrumb(message: message,
                          category: category,
                          level: level)
            return
        }

        let event = makeEvent(message: message,
                              category: category,
                              level: level,
                              extra: extraEvents)
        captureEvent(event: event)
    }

    // MARK: - Private

    private func captureEvent(event: Event) {
        // Capture event if Sentry is enabled and a message is available
        guard let message = event.message?.formatted else { return }

        sentryWrapper.captureMessage(message: message, with: { scope in
            scope.setEnvironment(event.environment)
            scope.setExtras(event.extra)
        })
    }

    private func addBreadcrumb(message: String, category: LoggerCategory, level: LoggerLevel) {
        let breadcrumb = Breadcrumb(level: level.sentryLevel,
                                    category: category.rawValue)
        breadcrumb.message = message
        sentryWrapper.addBreadcrumb(crumb: breadcrumb)
    }

    private func makeEvent(message: String,
                           category: LoggerCategory,
                           level: LoggerLevel,
                           extra: [String: Any]?) -> Event {
        let event = Event(level: level.sentryLevel)
        event.message = SentryMessage(formatted: message)
        event.tags = ["tag": category.rawValue]
        if let extra = extra {
            event.extra = extra
        }
        return event
    }

    /// Do not send messages to Sentry if disabled OR if we are not on beta and the severity isnt severe
    /// This is the behaviour we want for Sentry logging
    ///       .info .warning .fatal
    /// Debug      n        n          n
    /// Beta         n         n          y
    /// Release   n         n          y
    private func shouldSendEventFor(_ level: LoggerLevel) -> Bool {
        let shouldSendRelease = appInfo.buildChannel == .release && level.isGreaterOrEqualThanLevel(.fatal)
        let shouldSendBeta = appInfo.buildChannel == .beta && level.isGreaterOrEqualThanLevel(.fatal)

        return shouldSendBeta || shouldSendRelease
    }

    private func configureScope() {
        let deviceAppHash = UserDefaults(suiteName: appInfo.sharedContainerIdentifier)?
            .string(forKey: self.deviceAppHashKey)
        sentryWrapper.configureScope(scope: { scope in
            scope.setContext(value: [
                "device_app_hash": deviceAppHash ?? self.defaultDeviceAppHash
            ], key: "appContext")
        })
    }

    /// If we have not already for this install, generate a completely random identifier for this device.
    /// It is stored in the app group so that the same value will be used for both the main application and the app extensions.
    private func configureIdentifier() {
        guard let defaults = UserDefaults(suiteName: appInfo.sharedContainerIdentifier),
              defaults.string(forKey: deviceAppHashKey) == nil else { return }

        defaults.set(Bytes.generateRandomBytes(deviceAppHashLength).hexEncodedString,
                     forKey: deviceAppHashKey)
    }

    /// Ignore SIGPIPE exceptions globally.
    /// https://stackoverflow.com/questions/108183/how-to-prevent-sigpipes-or-handle-them-properly
    private func setupIgnoreException() {
        signal(SIGPIPE, SIG_IGN)
    }
}
