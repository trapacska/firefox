// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SnapKit

private let ToolbarBaseAnimationDuration: CGFloat = 0.2
class TabScrollingController: NSObject, FeatureFlaggable, SearchBarLocationProvider {
    enum ScrollDirection {
        case up
        case down
    }

    enum ToolbarState {
        case collapsed
        case visible
        case animating
    }

    weak var tab: Tab? {
        willSet {
            self.scrollView?.delegate = nil
            self.scrollView?.removeGestureRecognizer(panGesture)
        }

        didSet {
            self.scrollView?.addGestureRecognizer(panGesture)
            scrollView?.delegate = self
            scrollView?.keyboardDismissMode = .onDrag
            configureRefreshControl(isEnabled: true)
        }
    }

    weak var header: BaseAlphaStackView?
    weak var overKeyboardContainer: BaseAlphaStackView?
    weak var bottomContainer: BaseAlphaStackView?

    weak var zoomPageBar: ZoomPageBar?

    var overKeyboardContainerConstraint: Constraint?
    var bottomContainerConstraint: Constraint?
    var headerTopConstraint: Constraint?

    private var lastContentOffset: CGFloat = 0
    private var scrollDirection: ScrollDirection = .down
    var toolbarState: ToolbarState = .visible

    private var toolbarsShowing: Bool {
        let bottomShowing = overKeyboardContainerOffset == 0 && bottomContainerOffset == 0
        return isBottomSearchBar ? bottomShowing : headerTopOffset == 0
    }

    private var isZoomedOut = false
    private var lastZoomedScale: CGFloat = 0
    private var isUserZoom = false

    private var headerTopOffset: CGFloat = 0 {
        didSet {
            headerTopConstraint?.update(offset: headerTopOffset)
            header?.superview?.setNeedsLayout()
        }
    }

    private var overKeyboardContainerOffset: CGFloat = 0 {
        didSet {
            overKeyboardContainerConstraint?.update(offset: overKeyboardContainerOffset)
            overKeyboardContainer?.superview?.setNeedsLayout()
        }
    }

    private var bottomContainerOffset: CGFloat = 0 {
        didSet {
            bottomContainerConstraint?.update(offset: bottomContainerOffset)
            bottomContainer?.superview?.setNeedsLayout()
        }
    }

    private lazy var panGesture: UIPanGestureRecognizer = {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        panGesture.maximumNumberOfTouches = 1
        // Note: Setting this mask enables the pan gesture to recognize scroll events,
        // like a mouse scroll movement or a two-finger scroll on a track pad.
        panGesture.allowedScrollTypesMask = .continuous
        panGesture.delegate = self
        return panGesture
    }()

    private var scrollView: UIScrollView? { return tab?.webView?.scrollView }
    private var contentOffset: CGPoint { return scrollView?.contentOffset ?? .zero }
    private var scrollViewHeight: CGFloat { return scrollView?.frame.height ?? 0 }
    private var topScrollHeight: CGFloat { header?.frame.height ?? 0 }
    private var contentSize: CGSize { return scrollView?.contentSize ?? .zero }

    // Over keyboard content and bottom content
    private var overKeyboardScrollHeight: CGFloat {
        let overKeyboardHeight = overKeyboardContainer?.frame.height ?? 0
        return overKeyboardHeight
    }

    private var bottomContainerScrollHeight: CGFloat {
        let bottomContainerHeight = bottomContainer?.frame.height ?? 0
        return bottomContainerHeight
    }

    // If scrollview contentSize height is bigger that device height plus delta
    var isAbleToScroll: Bool {
        return (UIScreen.main.bounds.size.height + 2 * UIConstants.ToolbarHeight) <
            contentSize.height
    }

    override init() {
        super.init()
    }

    @objc
    func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard gesture.state != .ended, gesture.state != .cancelled else {
            lastContentOffset = 0
            return
        }

        guard !tabIsLoading() else { return }

        if let containerView = scrollView?.superview {
            let translation = gesture.translation(in: containerView)
            let delta = lastContentOffset - translation.y

            if delta > 0 {
                scrollDirection = .down
            } else if delta < 0 {
                scrollDirection = .up
            }

            lastContentOffset = translation.y
            if checkRubberbandingForDelta(delta) && isAbleToScroll {
                let bottomIsNotRubberbanding = contentOffset.y + scrollViewHeight < contentSize.height
                let topIsRubberbanding = contentOffset.y <= 0

                if shouldAllowScroll(with: topIsRubberbanding, and: bottomIsNotRubberbanding) {
                    scrollWithDelta(delta)
                }
                updateToolbarState()
            }
        }
    }

    func showToolbars(animated: Bool) {
        guard toolbarState != .visible else { return }
        toolbarState = .visible

        let actualDuration = TimeInterval(ToolbarBaseAnimationDuration * showDurationRatio)
        self.animateToolbarsWithOffsets(
            animated,
            duration: actualDuration,
            headerOffset: 0,
            bottomContainerOffset: 0,
            overKeyboardOffset: 0,
            alpha: 1,
            completion: nil)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentSize" {
            guard isAbleToScroll, toolbarsShowing else { return }

            showToolbars(animated: true)
        }
    }

    // MARK: - Zoom
    func updateMinimumZoom() {
        guard let scrollView = scrollView else { return }
        self.isZoomedOut = roundNum(scrollView.zoomScale) == roundNum(scrollView.minimumZoomScale)
        self.lastZoomedScale = self.isZoomedOut ? 0 : scrollView.zoomScale
    }

    func setMinimumZoom() {
        guard let scrollView = scrollView else { return }
        if self.isZoomedOut && roundNum(scrollView.zoomScale) != roundNum(scrollView.minimumZoomScale) {
            scrollView.zoomScale = scrollView.minimumZoomScale
        }
    }

    func resetZoomState() {
        self.isZoomedOut = false
        self.lastZoomedScale = 0
    }
}

// MARK: - Private
private extension TabScrollingController {
    func hideToolbars(animated: Bool) {
        guard toolbarState != .collapsed else { return }
        toolbarState = .collapsed

        let actualDuration = TimeInterval(ToolbarBaseAnimationDuration * hideDurationRation)
        self.animateToolbarsWithOffsets(
            animated,
            duration: actualDuration,
            headerOffset: -topScrollHeight,
            bottomContainerOffset: bottomContainerScrollHeight,
            overKeyboardOffset: overKeyboardScrollHeight,
            alpha: 0,
            completion: nil)
    }

    func configureRefreshControl(isEnabled: Bool) {
        let pullToRefreshEnabled = featureFlags.isFeatureEnabled(.pullToRefresh, checking: .buildOnly)

        scrollView?.refreshControl = pullToRefreshEnabled ?
        (isEnabled ? UIRefreshControl() : nil) : nil

        scrollView?.refreshControl?.addTarget(self, action: #selector(reload), for: .valueChanged)
    }

    @objc
    func reload() {
        guard let tab = tab else { return }
        tab.reloadPage()
        TelemetryWrapper.recordEvent(category: .action, method: .pull, object: .reload)
    }

    func roundNum(_ num: CGFloat) -> CGFloat {
        return round(100 * num) / 100
    }

    func tabIsLoading() -> Bool {
        return tab?.loading ?? true
    }

    func isBouncingAtBottom() -> Bool {
        guard let scrollView = scrollView else { return false }
        return contentOffset.y > (contentSize.height - scrollView.frame.size.height) && contentSize.height > scrollView.frame.size.height
    }

    func shouldAllowScroll(with topIsRubberbanding: Bool,
                           and bottomIsNotRubberbanding: Bool) -> Bool {
        return (toolbarState != .collapsed || topIsRubberbanding) && bottomIsNotRubberbanding
    }

    func updateToolbarState() {
        let bottomContainerCollapsed = bottomContainerOffset == bottomContainerScrollHeight
        let overKeyboardContainerCollapsed = overKeyboardContainerOffset == overKeyboardScrollHeight

        if headerTopOffset == -topScrollHeight && bottomContainerCollapsed && overKeyboardContainerCollapsed {
            setToolbarState(state: .collapsed)
        } else if toolbarsShowing {
            setToolbarState(state: .visible)
        } else {
            setToolbarState(state: .animating)
        }
    }

    func setToolbarState(state: ToolbarState) {
        guard toolbarState != state else { return }

        toolbarState = state
    }

    func checkRubberbandingForDelta(_ delta: CGFloat) -> Bool {
        return !((delta < 0 && contentOffset.y + scrollViewHeight > contentSize.height &&
                scrollViewHeight < contentSize.height) ||
                contentOffset.y < delta)
    }

    func scrollWithDelta(_ delta: CGFloat) {
        if scrollViewHeight >= contentSize.height {
            return
        }

        let updatedOffset = headerTopOffset - delta
        headerTopOffset = clamp(updatedOffset, min: -topScrollHeight, max: 0)
        if isHeaderDisplayedForGivenOffset(headerTopOffset) {
            scrollView?.contentOffset = CGPoint(x: contentOffset.x, y: contentOffset.y - delta)
        }

        let bottomUpdatedOffset = bottomContainerOffset + delta
        bottomContainerOffset = clamp(bottomUpdatedOffset, min: 0, max: bottomContainerScrollHeight)

        let overKeyboardUpdatedOffset = overKeyboardContainerOffset + delta
        overKeyboardContainerOffset = clamp(overKeyboardUpdatedOffset, min: 0, max: overKeyboardScrollHeight)

        header?.updateAlphaForSubviews(scrollAlpha)
        zoomPageBar?.updateAlphaForSubviews(scrollAlpha)
    }

    func isHeaderDisplayedForGivenOffset(_ offset: CGFloat) -> Bool {
        return offset > -topScrollHeight && offset < 0
    }

    func clamp(_ y: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
        if y >= max {
            return max
        } else if y <= min {
            return min
        }
        return y
    }

    func animateToolbarsWithOffsets(_ animated: Bool,
                                    duration: TimeInterval,
                                    headerOffset: CGFloat,
                                    bottomContainerOffset: CGFloat,
                                    overKeyboardOffset: CGFloat,
                                    alpha: CGFloat,
                                    completion: ((_ finished: Bool) -> Void)?) {
        guard let scrollView = scrollView else { return }
        let initialContentOffset = scrollView.contentOffset

        // If this function is used to fully animate the toolbar from hidden to shown, keep the page from scrolling by adjusting contentOffset,
        // Otherwise when the toolbar is hidden and a link navigated, showing the toolbar will scroll the page and
        // produce a ~50px page jumping effect in response to tap navigations.
        let isShownFromHidden = headerTopOffset == -topScrollHeight && headerOffset == 0

        let animation: () -> Void = {
            if isShownFromHidden {
                scrollView.contentOffset = CGPoint(x: initialContentOffset.x, y: initialContentOffset.y + self.topScrollHeight)
            }
            self.headerTopOffset = headerOffset
            self.bottomContainerOffset = bottomContainerOffset
            self.overKeyboardContainerOffset = overKeyboardOffset
            self.header?.updateAlphaForSubviews(alpha)
            self.header?.superview?.layoutIfNeeded()
            self.zoomPageBar?.updateAlphaForSubviews(alpha)
            self.zoomPageBar?.superview?.layoutIfNeeded()
        }

        if animated {
            UIView.animate(withDuration: duration,
                           delay: 0,
                           options: .allowUserInteraction,
                           animations: animation,
                           completion: completion)
        } else {
            animation()
            completion?(true)
        }
    }

    // Duration for hiding bottom containers is taken from overKeyboard since it's longer to hide
    // That way we ensure animation has proper timing
    var showDurationRatio: CGFloat {
        var durationRatio: CGFloat
        if isBottomSearchBar {
            durationRatio = abs(overKeyboardContainerOffset / overKeyboardScrollHeight)
        } else {
            durationRatio = abs(headerTopOffset / topScrollHeight)
        }
        return durationRatio
    }

    var hideDurationRation: CGFloat {
        var durationRatio: CGFloat
        if isBottomSearchBar {
            durationRatio = abs((overKeyboardScrollHeight + overKeyboardContainerOffset) / overKeyboardScrollHeight)
        } else {
            durationRatio = abs((topScrollHeight + headerTopOffset) / topScrollHeight)
        }
        return durationRatio
    }

    // Scroll alpha is only for header views since status bar has an overlay
    // Bottom content doesn't have alpha since it's completely hidden
    // Besides the zoom bar, to hide the gradient
    var scrollAlpha: CGFloat {
        if zoomPageBar != nil,
           isBottomSearchBar {
            return 1 - abs(overKeyboardContainerOffset / overKeyboardScrollHeight)
        }
        return 1 - abs(headerTopOffset / topScrollHeight)
    }
}

extension TabScrollingController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension TabScrollingController: UIScrollViewDelegate {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !tabIsLoading(), !isBouncingAtBottom(), isAbleToScroll else { return }

        if decelerate || (toolbarState == .animating && !decelerate) {
            if scrollDirection == .up {
                showToolbars(animated: true)
            } else if scrollDirection == .down {
                hideToolbars(animated: true)
            }
        }
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // Only mess with the zoom level if the user did not initiate the zoom via a zoom gesture
        if self.isUserZoom {
            return
        }

        // scrollViewDidZoom will be called multiple times when a rotation happens.
        // In that case ALWAYS reset to the minimum zoom level if the previous state was zoomed out (isZoomedOut=true)
        if isZoomedOut {
            scrollView.zoomScale = scrollView.minimumZoomScale
        } else if roundNum(scrollView.zoomScale) > roundNum(self.lastZoomedScale) && self.lastZoomedScale != 0 {
            // When we have manually zoomed in we want to preserve that scale.
            // But sometimes when we rotate a larger zoomScale is applied. In that case apply the lastZoomedScale
            scrollView.zoomScale = self.lastZoomedScale
        }
    }

    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        configureRefreshControl(isEnabled: false)
        self.isUserZoom = true
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        configureRefreshControl(isEnabled: true)
        self.isUserZoom = false
    }

    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        if toolbarState == .collapsed {
            showToolbars(animated: true)
            return false
        }
        return true
    }
}
