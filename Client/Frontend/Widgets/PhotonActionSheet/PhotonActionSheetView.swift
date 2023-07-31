// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Storage
import Shared

// MARK: - PhotonActionSheetViewDelegate
protocol PhotonActionSheetViewDelegate: AnyObject {
    func didClick(item: SingleActionViewModel?)
    func layoutChanged(item: SingleActionViewModel)
}

// This is the view contained in PhotonActionSheetContainerCell in the PhotonActionSheet table view.
// More than one PhotonActionSheetView can be in the parent container cell.
class PhotonActionSheetView: UIView, UIGestureRecognizerDelegate, ThemeApplicable {
    // MARK: - PhotonActionSheetViewUX
    struct UX {
        static let StatusIconSize = CGSize(width: 24, height: 24)
        static let SelectedOverlayColor = UIColor(white: 0.0, alpha: 0.25)
        static let CornerRadius: CGFloat = 3
        static let Padding: CGFloat = 16
        static let InBetweenPadding: CGFloat = 8
        static let topBottomPadding: CGFloat = 10
        static let VerticalPadding: CGFloat = 2
    }

    // MARK: - Variables
    private var badgeOverlay: BadgeWithBackdrop?
    private var item: SingleActionViewModel?
    weak var delegate: PhotonActionSheetViewDelegate?

    // MARK: - UI Elements
    // TODO: Needs refactoring using the `.build` style. All PhotonActionSheetViews should be tested at that point.
    private func createLabel() -> UILabel {
        let label = UILabel()
        label.setContentHuggingPriority(.required, for: .vertical)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    private func createIconImageView() -> UIImageView {
        let icon = UIImageView()
        icon.contentMode = .scaleAspectFit
        icon.clipsToBounds = true
        icon.layer.cornerRadius = UX.CornerRadius
        icon.setContentHuggingPriority(.required, for: .horizontal)
        icon.setContentCompressionResistancePriority(.required, for: .horizontal)
        return icon
    }

    private lazy var titleLabel: UILabel = {
        let label = createLabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.font = LegacyDynamicFontHelper.defaultHelper.LargeSizeRegularWeightAS
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = createLabel()
        label.numberOfLines = 0
        label.font = LegacyDynamicFontHelper.defaultHelper.SmallSizeRegularWeightAS
        return label
    }()

    private lazy var statusIcon: UIImageView = .build { icon in
        icon.contentMode = .scaleAspectFit
        icon.clipsToBounds = true
        icon.layer.cornerRadius = UX.CornerRadius
        icon.setContentHuggingPriority(.required, for: .horizontal)
        icon.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private lazy var disclosureLabel: UILabel = {
        let label = UILabel()
        return label
    }()

    private lazy var selectedOverlay: UIView = .build { selectedOverlay in
        selectedOverlay.backgroundColor = UX.SelectedOverlayColor
        selectedOverlay.isHidden = true
    }

    private lazy var disclosureIndicator: UIImageView = {
        let disclosureIndicator = createIconImageView()
        disclosureIndicator.image = UIImage(named: StandardImageIdentifiers.Large.chevronRight)?.withRenderingMode(.alwaysTemplate)
        return disclosureIndicator
    }()

    private lazy var stackView: UIStackView = .build { stackView in
        stackView.spacing = UX.InBetweenPadding
        stackView.alignment = .center
        stackView.axis = .horizontal
        stackView.distribution = .fillProportionally
    }

    private lazy var textStackView: UIStackView = .build { textStackView in
        textStackView.spacing = UX.VerticalPadding
        textStackView.setContentHuggingPriority(.required, for: .vertical)
        textStackView.alignment = .fill
        textStackView.axis = .vertical
        textStackView.distribution = .fill
    }

    private lazy var tabsLabel: UILabel = .build { label in
        label.font = UIFont.boldSystemFont(ofSize: UIConstants.DefaultChromeSmallSize)
    }

    lazy var bottomBorder: UIView = .build { _ in }
    lazy var verticalBorder: UIView = .build { _ in }

    // MARK: - Initializers

    override init(frame: CGRect) {
        self.isSelected = false
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Gesture recognizer

    private lazy var tapRecognizer: UITapGestureRecognizer = {
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.addTarget(self, action: #selector(didClick))
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.cancelsTouchesInView = false
        tapRecognizer.delegate = self
        return tapRecognizer
    }()

    var isSelected: Bool {
        didSet {
            selectedOverlay.isHidden = !isSelected
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        isSelected = true
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        isSelected = false
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        if let touch = touches.first {
            isSelected = frame.contains(touch.location(in: self))
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        isSelected = false
    }

    @objc
    private func didClick(_ gestureRecognizer: UITapGestureRecognizer?) {
        guard let item = item,
              let handler = item.tapHandler
        else { return }

        isSelected = (gestureRecognizer?.state == .began) || (gestureRecognizer?.state == .changed)

        item.isEnabled = !item.isEnabled
        handler(item)
        self.delegate?.didClick(item: item)
    }

    // MARK: Setup

    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)

        // The layout changes when there's multiple items in a row,
        // and there's not enough space in one row to show the labels without truncating
        if let item = item,
           item.multipleItemsSetup.isMultiItems,
           item.multipleItemsSetup.axis != .vertical,
           titleLabel.isTruncated {
            // Disabling this multipleItemsSetup feature for now - will rework to improve
//            item.multipleItemsSetup.axis = .vertical
//            delegate?.layoutChanged(item: item)
        }
    }

    func configure(with item: SingleActionViewModel, theme: Theme) {
        self.item = item
        setupViews()

        titleLabel.text = item.currentTitle

        if item.bold {
            titleLabel.font = DefaultDynamicFontHelper.preferredBoldFont(withTextStyle: .headline,
                                                                         size: 19)
        } else {
            titleLabel.font = LegacyDynamicFontHelper.defaultHelper.SemiMediumRegularWeightAS
        }

        item.customRender?(titleLabel, self)

        subtitleLabel.text = item.text
        subtitleLabel.isHidden = item.text == nil

        accessibilityIdentifier = item.accessibilityId ?? item.iconString
        accessibilityLabel = item.currentTitle

        if item.isFlipped {
            transform = CGAffineTransform(scaleX: 1, y: -1)
        }

        if let iconName = item.iconString {
            setupActionName(action: item, name: iconName)
        } else {
            statusIcon.removeFromSuperview()
        }

        setupBadgeOverlay(action: item)
        addSubBorder(action: item)
        applyTheme(theme: theme)
    }

    func addVerticalBorder(ifShouldBeShown: Bool) {
        guard ifShouldBeShown else { return }

        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        textStackView.setContentHuggingPriority(.required, for: .horizontal)

        addSubview(verticalBorder)

        NSLayoutConstraint.activate([
            verticalBorder.topAnchor.constraint(equalTo: topAnchor),
            verticalBorder.bottomAnchor.constraint(equalTo: bottomAnchor),
            verticalBorder.leadingAnchor.constraint(equalTo: leadingAnchor),
            verticalBorder.widthAnchor.constraint(equalToConstant: 1)
        ])
    }

    func applyTheme(theme: Theme) {
        tintColor = theme.colors.textPrimary
        titleLabel.textColor = theme.colors.textPrimary
        subtitleLabel.textColor = theme.colors.textPrimary
        tabsLabel.textColor = theme.colors.textPrimary

        verticalBorder.backgroundColor = theme.colors.layer4
        bottomBorder.backgroundColor = theme.colors.layer4

        badgeOverlay?.badge.tintBackground(color: theme.colors.layer1)
        disclosureIndicator.tintColor = theme.colors.iconSecondary

        let iconTint: UIColor? = item?.needsIconActionableTint ?? false ? theme.colors.iconAccentYellow : tintColor
        statusIcon.tintColor = iconTint
    }

    // MARK: - Private
    private func setupViews() {
        isAccessibilityElement = true
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        addGestureRecognizer(tapRecognizer)

        // Setup our StackViews
        textStackView.addArrangedSubview(titleLabel)
        textStackView.addArrangedSubview(subtitleLabel)
        stackView.addArrangedSubview(textStackView)
        stackView.addArrangedSubview(statusIcon)
        addSubview(stackView)

        addSubview(selectedOverlay)
        setupConstraints()
    }

    private func setupConstraints() {
        let padding = UX.Padding
        let topBottomPadding = UX.topBottomPadding

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: topBottomPadding),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -topBottomPadding),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),

            selectedOverlay.topAnchor.constraint(equalTo: topAnchor),
            selectedOverlay.bottomAnchor.constraint(equalTo: bottomAnchor),
            selectedOverlay.trailingAnchor.constraint(equalTo: trailingAnchor),
            selectedOverlay.leadingAnchor.constraint(equalTo: leadingAnchor),

            statusIcon.widthAnchor.constraint(equalToConstant: UX.StatusIconSize.width),
            statusIcon.heightAnchor.constraint(equalToConstant: UX.StatusIconSize.height),
        ])
    }

    private func addSubBorder(action: SingleActionViewModel) {
        addSubview(bottomBorder)

        // Determine if border should be at top or bottom when flipping
        let top = bottomBorder.topAnchor.constraint(equalTo: topAnchor)
        let bottom = bottomBorder.bottomAnchor.constraint(equalTo: bottomAnchor)
        let anchor = action.isFlipped ? top : bottom

        NSLayoutConstraint.activate([
            anchor,
            bottomBorder.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomBorder.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomBorder.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    private func setupActionName(action: SingleActionViewModel, name: String) {
        switch action.iconType {
        case .Image:
            let image = UIImage(named: name)?.withRenderingMode(.alwaysTemplate)
            statusIcon.image = image

        case .URL:
            let image = UIImage(named: name)?
                .createScaled(PhotonActionSheet.UX.iconSize)
                .withRenderingMode(.alwaysTemplate)
            statusIcon.layer.cornerRadius = PhotonActionSheet.UX.iconSize.width / 2
            statusIcon.image = image
            if let actionIconUrl = action.iconURL {
                GeneralizedImageFetcher().getImageFor(
                    url: actionIconUrl) { image in
                        guard let image = image else { return }

                        self.statusIcon.image = image.createScaled(PhotonActionSheet.UX.iconSize)
                            .withRenderingMode(.alwaysOriginal)
                        self.statusIcon.layer.cornerRadius = PhotonActionSheet.UX.iconSize.width / 2
                    }
            }
        case .TabsButton:
            tabsLabel.text = action.tabCount

            let image = UIImage(named: name)?.withRenderingMode(.alwaysTemplate)
            statusIcon.image = image
            statusIcon.addSubview(tabsLabel)

            NSLayoutConstraint.activate([
                tabsLabel.centerXAnchor.constraint(equalTo: statusIcon.centerXAnchor),
                tabsLabel.centerYAnchor.constraint(equalTo: statusIcon.centerYAnchor),
            ])

        case .None:
            break
        }

        if statusIcon.superview == nil {
            if action.iconAlignment == .right {
                stackView.addArrangedSubview(statusIcon)
            } else {
                stackView.insertArrangedSubview(statusIcon, at: 0)
            }
        } else {
            if action.iconAlignment == .right {
                statusIcon.removeFromSuperview()
                stackView.addArrangedSubview(statusIcon)
            }
        }
    }

    private func setupBadgeOverlay(action: SingleActionViewModel) {
        guard let name = action.badgeIconName,
              action.isEnabled,
              let parent = statusIcon.superview
        else { return }

        badgeOverlay = BadgeWithBackdrop(imageName: name)
        badgeOverlay?.add(toParent: parent)
        badgeOverlay?.layout(onButton: statusIcon)
        badgeOverlay?.show(true)
    }
}
