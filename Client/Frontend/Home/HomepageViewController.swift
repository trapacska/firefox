// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import UIKit
import Storage
import MozillaAppServices
import Common
import ComponentLibrary

class HomepageViewController: UIViewController, FeatureFlaggable, Themeable, ContentContainable,
                                SearchBarLocationProvider {
    // MARK: - Typealiases
    private typealias a11y = AccessibilityIdentifiers.FirefoxHomepage
    typealias SendToDeviceDelegate = InstructionsViewDelegate & DevicePickerViewControllerDelegate

    // MARK: - Operational Variables
    weak var homePanelDelegate: HomePanelDelegate?
    weak var libraryPanelDelegate: LibraryPanelDelegate?
    weak var sendToDeviceDelegate: SendToDeviceDelegate? {
        didSet {
            contextMenuHelper.sendToDeviceDelegate = sendToDeviceDelegate
        }
    }

    weak var browserNavigationHandler: BrowserNavigationHandler? {
        didSet {
            contextMenuHelper.browserNavigationHandler = browserNavigationHandler
        }
    }

    weak var statusBarScrollDelegate: StatusBarScrollDelegate?

    private var viewModel: HomepageViewModel
    private var contextMenuHelper: HomepageContextMenuHelper
    private var tabManager: TabManager
    private var overlayManager: OverlayModeManager
    private var userDefaults: UserDefaultsInterface
    private lazy var wallpaperView: WallpaperBackgroundView = .build { _ in }
    private var jumpBackInContextualHintViewController: ContextualHintViewController
    private var syncTabContextualHintViewController: ContextualHintViewController
    private var collectionView: UICollectionView! = nil
    private var logger: Logger
    var contentType: ContentType = .homepage

    var themeManager: ThemeManager
    var notificationCenter: NotificationProtocol
    var themeObserver: NSObjectProtocol?

    // Content stack views contains collection view.
    lazy var contentStackView: UIStackView = .build { stackView in
        stackView.backgroundColor = .clear
        stackView.axis = .vertical
    }

    var currentTab: Tab? {
        return tabManager.selectedTab
    }

    // MARK: - Initializers
    init(profile: Profile,
         isZeroSearch: Bool = false,
         toastContainer: UIView,
         tabManager: TabManager = AppContainer.shared.resolve(),
         overlayManager: OverlayModeManager,
         userDefaults: UserDefaultsInterface = UserDefaults.standard,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         logger: Logger = DefaultLogger.shared
    ) {
        self.overlayManager = overlayManager
        self.tabManager = tabManager
        self.userDefaults = userDefaults
        let isPrivate = tabManager.selectedTab?.isPrivate ?? true
        self.viewModel = HomepageViewModel(profile: profile,
                                           isPrivate: isPrivate,
                                           tabManager: tabManager,
                                           theme: themeManager.currentTheme)

        let jumpBackInContextualViewModel = ContextualHintViewModel(forHintType: .jumpBackIn,
                                                                    with: viewModel.profile)
        self.jumpBackInContextualHintViewController = ContextualHintViewController(with: jumpBackInContextualViewModel)
        let syncTabContextualViewModel = ContextualHintViewModel(forHintType: .jumpBackInSyncedTab,
                                                                 with: viewModel.profile)
        self.syncTabContextualHintViewController = ContextualHintViewController(with: syncTabContextualViewModel)
        self.contextMenuHelper = HomepageContextMenuHelper(viewModel: viewModel, toastContainer: toastContainer)

        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.logger = logger
        super.init(nibName: nil, bundle: nil)

        viewModel.isZeroSearch = isZeroSearch

        contextMenuHelper.delegate = self
        contextMenuHelper.getPopoverSourceRect = { [weak self] popoverView in
            guard let self = self else { return CGRect() }
            return self.getPopoverSourceRect(sourceView: popoverView)
        }

        setupNotifications(forObserver: self,
                           observing: [.HomePanelPrefsChanged,
                                       .TabsPrivacyModeChanged,
                                       .WallpaperDidChange])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        jumpBackInContextualHintViewController.stopTimer()
        syncTabContextualHintViewController.stopTimer()
        notificationCenter.removeObserver(self)
    }

    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        configureWallpaperView()
        configureContentStackView()
        configureCollectionView()

        // Delay setting up the view model delegate to ensure the views have been configured first
        viewModel.delegate = self

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        setupSectionsAction()
        reloadView()

        listenForThemeChange(view)
        applyTheme()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.recordViewAppeared()

        notificationCenter.post(name: .ShowHomepage)
        notificationCenter.post(name: .HistoryUpdated)

        applyTheme()
        reloadView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.displayWallpaperSelector()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        jumpBackInContextualHintViewController.stopTimer()
        syncTabContextualHintViewController.stopTimer()
        viewModel.recordViewDisappeared()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        jumpBackInContextualHintViewController.stopTimer()
        syncTabContextualHintViewController.stopTimer()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        wallpaperView.updateImageForOrientationChange()

        if UIDevice.current.userInterfaceIdiom == .pad {
            reloadOnRotation(newSize: size)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyTheme()

        if previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass
            || previousTraitCollection?.verticalSizeClass != traitCollection.verticalSizeClass {
            reloadOnRotation(newSize: view.frame.size)
        }
    }

    // MARK: - Layout

    func configureCollectionView() {
        collectionView = UICollectionView(frame: view.bounds,
                                          collectionViewLayout: createLayout())

        HomepageSectionType.cellTypes.forEach {
            collectionView.register($0, forCellWithReuseIdentifier: $0.cellIdentifier)
        }
        collectionView.register(LabelButtonHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: LabelButtonHeaderView.cellIdentifier)
        collectionView.register(PocketFooterView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                                withReuseIdentifier: PocketFooterView.cellIdentifier)
        collectionView.keyboardDismissMode = .onDrag
        collectionView.addGestureRecognizer(longPressRecognizer)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .clear
        collectionView.accessibilityIdentifier = a11y.collectionView
        contentStackView.addArrangedSubview(collectionView)
    }

    func configureContentStackView() {
        view.addSubview(contentStackView)
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: view.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    func configureWallpaperView() {
        view.addSubview(wallpaperView)

        // Constraint so wallpaper appears under the status bar
        let window = UIApplication.shared.windows.first
        let wallpaperTopConstant: CGFloat = window?.safeAreaInsets.top ?? statusBarFrame?.height ?? 0

        NSLayoutConstraint.activate([
            wallpaperView.topAnchor.constraint(equalTo: view.topAnchor, constant: -wallpaperTopConstant),
            wallpaperView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            wallpaperView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            wallpaperView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        view.sendSubviewToBack(wallpaperView)
    }

    func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self]
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            guard let self = self,
                  let viewModel = self.viewModel.getSectionViewModel(shownSection: sectionIndex),
                  viewModel.shouldShow
            else { return nil }
            self.logger.log("Section \(viewModel.sectionType) is going to show", level: .debug, category: .homepage)
            return viewModel.section(for: layoutEnvironment.traitCollection, size: self.view.frame.size)
        }
        return layout
    }

    // MARK: Long press

    private lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(longPress))
    }()

    @objc
    fileprivate func longPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard longPressGestureRecognizer.state == .began else { return }

        let point = longPressGestureRecognizer.location(in: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: point),
              let viewModel = viewModel.getSectionViewModel(shownSection: indexPath.section) as? HomepageSectionHandler
        else { return }

        viewModel.handleLongPress(with: collectionView, indexPath: indexPath)
    }

    // MARK: - Helpers

    /// Configure isZeroSearch
    /// - Parameter isZeroSearch: IsZeroSearch is true when the homepage is created from the tab tray, a long press
    /// on the tab bar to open a new tab or by pressing the home page button on the tab bar. Inline is false when
    /// it's the zero search page, aka when the home page is shown by clicking the url bar from a loaded web page.
    /// This needs to be set properly for telemetry and the contextual pop overs that appears on homepage
    func configure(isZeroSearch: Bool) {
        viewModel.isZeroSearch = isZeroSearch
    }

    /// On iPhone, we call reloadOnRotation when the trait collection has changed, to ensure calculation
    /// is done with the new trait. On iPad, trait collection doesn't change from portrait to landscape (and vice-versa)
    /// since it's `.regular` on both. We reloadOnRotation from viewWillTransition in that case.
    private func reloadOnRotation(newSize: CGSize) {
        logger.log("Reload on rotation to new size \(newSize)", level: .info, category: .homepage)

        if presentedViewController as? PhotonActionSheet != nil {
            presentedViewController?.dismiss(animated: false, completion: nil)
        }

        // Force the entire collection view to re-layout
        viewModel.refreshData(for: traitCollection, size: newSize)
        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()

        // This pushes a reload to the end of the main queue after all the work associated with
        // rotating has been completed. This is important because some of the cells layout are
        // based on the screen state
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }

    private func adjustPrivacySensitiveSections(notification: Notification) {
        guard let dict = notification.object as? NSDictionary,
              let isPrivate = dict[Tab.privateModeKey] as? Bool
        else { return }

        let privacySectionState = isPrivate ? "Removing": "Adding"
        logger.log("\(privacySectionState) privacy sensitive sections", level: .info, category: .homepage)
        viewModel.isPrivate = isPrivate
        reloadView()
    }

    func applyTheme() {
        let theme = themeManager.currentTheme
        viewModel.theme = theme
        view.backgroundColor = theme.colors.layer1
    }

    func scrollToTop(animated: Bool = false) {
        collectionView?.setContentOffset(.zero, animated: animated)
        scrollViewDidScroll(collectionView)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        dismissKeyboard()
    }

    @objc
    private func dismissKeyboard() {
        if currentTab?.lastKnownUrl?.absoluteString.hasPrefix("internal://") ?? false {
            overlayManager.finishEditing(shouldCancelLoading: false)
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // We only handle status bar overlay alpha if there's a wallpaper applied on the homepage
        if WallpaperManager().currentWallpaper.type != .defaultWallpaper {
            statusBarScrollDelegate?.scrollViewDidScroll(scrollView,
                                                         statusBarFrame: statusBarFrame,
                                                         theme: themeManager.currentTheme)
        }
    }

    private func showSiteWithURLHandler(_ url: URL, isGoogleTopSite: Bool = false) {
        let visitType = VisitType.bookmark
        homePanelDelegate?.homePanel(didSelectURL: url, visitType: visitType, isGoogleTopSite: isGoogleTopSite)
    }

    func displayWallpaperSelector() {
        let wallpaperManager = WallpaperManager(userDefaults: userDefaults)
        guard !overlayManager.inOverlayMode,
              wallpaperManager.canOnboardingBeShown(using: viewModel.profile),
              canModalBePresented
        else { return }

        let viewModel = WallpaperSelectorViewModel(wallpaperManager: wallpaperManager, openSettingsAction: {
            self.homePanelDidRequestToOpenSettings(at: .wallpaper)
        })
        let viewController = WallpaperSelectorViewController(viewModel: viewModel)
        var bottomSheetViewModel = BottomSheetViewModel(closeButtonA11yLabel: .CloseButtonTitle)
        bottomSheetViewModel.shouldDismissForTapOutside = false
        let bottomSheetVC = BottomSheetViewController(
            viewModel: bottomSheetViewModel,
            childViewController: viewController
        )

        self.present(bottomSheetVC, animated: false, completion: nil)
        userDefaults.set(true, forKey: PrefsKeys.Wallpapers.OnboardingSeenKey)
    }

    // Check if we already present something on top of the homepage,
    // if the homepage is actually being shown to the user and if the page is shown from a loaded webpage (zero search).
    private var canModalBePresented: Bool {
        return presentedViewController == nil && !viewModel.isZeroSearch
    }

    // MARK: - Contextual hint

    private func prepareJumpBackInContextualHint(onView headerView: LabelButtonHeaderView) {
        guard jumpBackInContextualHintViewController.shouldPresentHint(),
              !viewModel.shouldDisplayHomeTabBanner,
              !headerView.frame.isEmpty
        else { return }

        // Calculate label header view frame to add as source rect for CFR
        var rect = headerView.convert(headerView.titleLabel.frame, to: collectionView)
        rect = collectionView.convert(rect, to: view)

        jumpBackInContextualHintViewController.configure(
            anchor: view,
            withArrowDirection: .down,
            andDelegate: self,
            presentedUsing: { self.presentContextualHint(contextualHintViewController: self.jumpBackInContextualHintViewController) },
            sourceRect: rect,
            andActionForButton: { self.openTabsSettings() },
            overlayState: overlayManager)
    }

    private func prepareSyncedTabContextualHint(onCell cell: SyncedTabCell) {
        guard syncTabContextualHintViewController.shouldPresentHint()
        else {
            syncTabContextualHintViewController.unconfigure()
            return
        }

        syncTabContextualHintViewController.configure(
            anchor: cell.getContextualHintAnchor(),
            withArrowDirection: .down,
            andDelegate: self,
            presentedUsing: { self.presentContextualHint(contextualHintViewController: self.syncTabContextualHintViewController) },
            overlayState: overlayManager)
    }

    @objc
    private func presentContextualHint(contextualHintViewController: ContextualHintViewController) {
        guard viewModel.viewAppeared, canModalBePresented else {
            contextualHintViewController.stopTimer()
            return
        }

        present(contextualHintViewController, animated: true, completion: nil)

        UIAccessibility.post(notification: .layoutChanged, argument: contextualHintViewController)
    }
}

// MARK: - CollectionView Data Source

extension HomepageViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        let reusableView = UICollectionReusableView()
        if kind == UICollectionView.elementKindSectionHeader {
            guard let headerView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: LabelButtonHeaderView.cellIdentifier,
                for: indexPath) as? LabelButtonHeaderView else { return reusableView }
            guard let sectionViewModel = viewModel.getSectionViewModel(shownSection: indexPath.section)
            else { return reusableView }

            // Configure header only if section is shown
            let headerViewModel = sectionViewModel.shouldShow ? sectionViewModel.headerViewModel : LabelButtonHeaderViewModel.emptyHeader
            headerView.configure(viewModel: headerViewModel, theme: themeManager.currentTheme)

            // Jump back in header specific setup
            if sectionViewModel.sectionType == .jumpBackIn {
                self.viewModel.jumpBackInViewModel.sendImpressionTelemetry()
                // Moving called after header view gets configured
                // and delaying to wait for header view layout readjust
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.prepareJumpBackInContextualHint(onView: headerView)
                }
            }
            return headerView
        }

        if kind == UICollectionView.elementKindSectionFooter {
            guard let footerView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: PocketFooterView.cellIdentifier,
                for: indexPath) as? PocketFooterView else { return reusableView }
            footerView.onTapLearnMore = {
                guard let learnMoreURL = SupportUtils.URLForPocketLearnMore else {
                    self.logger.log("Failed to retrieve learn more URL from SupportUtils.URLForPocketLearnMore",
                                    level: .debug,
                                    category: .homepage)
                    return
                }
                self.showSiteWithURLHandler(learnMoreURL)
            }
            footerView.applyTheme(theme: themeManager.currentTheme)
            return footerView
        }
        return reusableView
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.shownSections.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.getSectionViewModel(shownSection: section)?.numberOfItemsInSection() ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let viewModel = viewModel.getSectionViewModel(shownSection: indexPath.section) as? HomepageSectionHandler else {
            return UICollectionViewCell()
        }

        return viewModel.configure(collectionView, at: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let viewModel = viewModel.getSectionViewModel(shownSection: indexPath.section) as? HomepageSectionHandler else { return }
        viewModel.didSelectItem(at: indexPath, homePanelDelegate: homePanelDelegate, libraryPanelDelegate: libraryPanelDelegate)
    }
}

// MARK: - Actions Handling

private extension HomepageViewController {
    // Setup all the tap and long press actions on cells in each sections
    private func setupSectionsAction() {
        // Header view
        viewModel.headerViewModel.onTapAction = { _ in
            // No action currently set if the logo button is tapped.
        }

        // Message card
        viewModel.messageCardViewModel.dismissClosure = { [weak self] in
            self?.reloadView()
        }

        // Top sites
        viewModel.topSiteViewModel.tilePressedHandler = { [weak self] site, isGoogle in
            guard let url = site.url.asURL else { return }
            self?.showSiteWithURLHandler(url, isGoogleTopSite: isGoogle)
        }

        viewModel.topSiteViewModel.tileLongPressedHandler = { [weak self] (site, sourceView) in
            self?.contextMenuHelper.presentContextMenu(for: site, with: sourceView, sectionType: .topSites)
        }

        // Recently saved
        viewModel.recentlySavedViewModel.headerButtonAction = { [weak self] button in
            self?.openBookmarks(button)
        }

        // Jumpback in
        viewModel.jumpBackInViewModel.onTapGroup = { [weak self] tab in
            self?.homePanelDelegate?.homePanelDidRequestToOpenTabTray(withFocusedTab: tab)
        }

        viewModel.jumpBackInViewModel.headerButtonAction = { [weak self] button in
            self?.openTabTray(button)
        }

        viewModel.jumpBackInViewModel.syncedTabsShowAllAction = { [weak self] in
            self?.homePanelDelegate?.homePanelDidRequestToOpenTabTray(focusedSegment: .syncedTabs)

            var extras: [String: String]?
            if let isZeroSearch = self?.viewModel.isZeroSearch {
                extras = TelemetryWrapper.getOriginExtras(isZeroSearch: isZeroSearch)
            }
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .firefoxHomepage,
                                         value: .jumpBackInSectionSyncedTabShowAll,
                                         extras: extras)
        }

        viewModel.jumpBackInViewModel.openSyncedTabAction = { [weak self] tabURL in
            self?.homePanelDelegate?.homePanelDidRequestToOpenInNewTab(tabURL, isPrivate: false, selectNewTab: true)

            var extras: [String: String]?
            if let isZeroSearch = self?.viewModel.isZeroSearch {
                extras = TelemetryWrapper.getOriginExtras(isZeroSearch: isZeroSearch)
            }
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .firefoxHomepage,
                                         value: .jumpBackInSectionSyncedTabOpened,
                                         extras: extras)
        }

        viewModel.jumpBackInViewModel.prepareContextualHint = { [weak self] syncedTabCell in
            self?.prepareSyncedTabContextualHint(onCell: syncedTabCell)
        }

        // History highlights
        viewModel.historyHighlightsViewModel.onTapItem = { [weak self] highlight in
            guard let url = highlight.siteUrl else {
                self?.openHistoryHighlightsSearchGroup(item: highlight)
                return
            }

            self?.homePanelDelegate?.homePanel(didSelectURL: url,
                                               visitType: .link,
                                               isGoogleTopSite: false)
        }

        viewModel.historyHighlightsViewModel.historyHighlightLongPressHandler = { [weak self] (highlightItem, sourceView) in
            self?.contextMenuHelper.presentContextMenu(for: highlightItem,
                                                       with: sourceView,
                                                       sectionType: .historyHighlights)
        }

        viewModel.historyHighlightsViewModel.headerButtonAction = { [weak self] button in
            self?.openHistory(button)
        }

        // Pocket
        viewModel.pocketViewModel.onTapTileAction = { [weak self] url in
            self?.showSiteWithURLHandler(url)
        }

        viewModel.pocketViewModel.onLongPressTileAction = { [weak self] (site, sourceView) in
            self?.contextMenuHelper.presentContextMenu(for: site, with: sourceView, sectionType: .pocket)
        }

        // Customize home
        viewModel.customizeButtonViewModel.onTapAction = { [weak self] _ in
            self?.openCustomizeHomeSettings()
        }
    }

    private func openHistoryHighlightsSearchGroup(item: HighlightItem) {
        guard let groupItem = item.group else { return }

        var groupedSites = [Site]()
        for item in groupItem {
            groupedSites.append(buildSite(from: item))
        }
        let groupSite = ASGroup<Site>(searchTerm: item.displayTitle, groupedItems: groupedSites, timestamp: Date.now())

        let asGroupListViewModel = SearchGroupedItemsViewModel(asGroup: groupSite, presenter: .recentlyVisited)
        let asGroupListVC = SearchGroupedItemsViewController(viewModel: asGroupListViewModel, profile: viewModel.profile)

        let dismissableController: DismissableNavigationViewController
        dismissableController = DismissableNavigationViewController(rootViewController: asGroupListVC)

        self.present(dismissableController, animated: true, completion: nil)

        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .firefoxHomepage,
                                     value: .historyHighlightsGroupOpen,
                                     extras: nil)

        asGroupListVC.libraryPanelDelegate = libraryPanelDelegate
    }

    private func buildSite(from highlight: HighlightItem) -> Site {
        let itemURL = highlight.urlString ?? ""
        return Site(url: itemURL, title: highlight.displayTitle)
    }

    func openTabTray(_ sender: UIButton) {
        homePanelDelegate?.homePanelDidRequestToOpenTabTray(withFocusedTab: nil)

        if sender.accessibilityIdentifier == a11y.MoreButtons.jumpBackIn {
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .firefoxHomepage,
                                         value: .jumpBackInSectionShowAll,
                                         extras: TelemetryWrapper.getOriginExtras(isZeroSearch: viewModel.isZeroSearch))
        }
    }

    func openBookmarks(_ sender: UIButton) {
        homePanelDelegate?.homePanelDidRequestToOpenLibrary(panel: .bookmarks)

        if sender.accessibilityIdentifier == a11y.MoreButtons.recentlySaved {
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .firefoxHomepage,
                                         value: .recentlySavedSectionShowAll,
                                         extras: TelemetryWrapper.getOriginExtras(isZeroSearch: viewModel.isZeroSearch))
        }
    }

    func openHistory(_ sender: UIButton) {
        homePanelDelegate?.homePanelDidRequestToOpenLibrary(panel: .history)

        if sender.accessibilityIdentifier == a11y.MoreButtons.historyHighlights {
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .firefoxHomepage,
                                         value: .historyHighlightsShowAll)
        }
    }

    func openCustomizeHomeSettings() {
        homePanelDelegate?.homePanelDidRequestToOpenSettings(at: .customizeHomepage)
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .firefoxHomepage,
                                     value: .customizeHomepageButton)
    }

    func openTabsSettings() {
        homePanelDelegate?.homePanelDidRequestToOpenSettings(at: .customizeTabs)
    }

    func getPopoverSourceRect(sourceView: UIView?) -> CGRect {
        let cellRect = sourceView?.frame ?? .zero
        let cellFrameInSuperview = self.collectionView?.convert(cellRect, to: self.collectionView) ?? .zero

        return CGRect(origin: CGPoint(x: cellFrameInSuperview.size.width / 2,
                                      y: cellFrameInSuperview.height / 2),
                      size: .zero)
    }
}

// MARK: FirefoxHomeContextMenuHelperDelegate
extension HomepageViewController: HomepageContextMenuHelperDelegate {
    func homePanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool, selectNewTab: Bool) {
        homePanelDelegate?.homePanelDidRequestToOpenInNewTab(url, isPrivate: isPrivate, selectNewTab: selectNewTab)
    }

    func homePanelDidRequestToOpenSettings(at settingsPage: AppSettingsDeeplinkOption) {
        homePanelDelegate?.homePanelDidRequestToOpenSettings(at: settingsPage)
    }

    func showToast(message: String) {
        SimpleToast().showAlertWithText(message, bottomContainer: view, theme: themeManager.currentTheme)
    }
}

// MARK: - Status Bar Background

extension HomepageViewController {
    var statusBarFrame: CGRect? {
        guard let keyWindow = UIWindow.keyWindow else { return nil }

        return keyWindow.windowScene?.statusBarManager?.statusBarFrame
    }
}

// MARK: - Popover Presentation Delegate

extension HomepageViewController: UIPopoverPresentationControllerDelegate {
    // Dismiss the popover if the device is being rotated.
    // This is used by the Share UIActivityViewController action sheet on iPad
    func popoverPresentationController(
        _ popoverPresentationController: UIPopoverPresentationController,
        willRepositionPopoverTo rect: UnsafeMutablePointer<CGRect>,
        in view: AutoreleasingUnsafeMutablePointer<UIView>
    ) {
        // Do not dismiss if the popover is a CFR
        guard !jumpBackInContextualHintViewController.isPresenting &&
                !syncTabContextualHintViewController.isPresenting else { return }
        popoverPresentationController.presentedViewController.dismiss(animated: false, completion: nil)
    }

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return true
    }
}

// MARK: FirefoxHomeViewModelDelegate
extension HomepageViewController: HomepageViewModelDelegate {
    func reloadView() {
        ensureMainThread { [weak self] in
            guard let self = self else { return }

            self.viewModel.refreshData(for: self.traitCollection, size: self.view.frame.size)
            self.collectionView.reloadData()
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.logger.log("Amount of sections shown is \(self.viewModel.shownSections.count)",
                            level: .debug,
                            category: .homepage)
        }
    }
}

// MARK: - Notifiable
extension HomepageViewController: Notifiable {
    func handleNotifications(_ notification: Notification) {
        ensureMainThread { [weak self] in
            guard let self = self else { return }

            switch notification.name {
            case .TabsPrivacyModeChanged:
                self.adjustPrivacySensitiveSections(notification: notification)

            case .HomePanelPrefsChanged,
                    .WallpaperDidChange:
                self.reloadView()

            default: break
            }
        }
    }
}
