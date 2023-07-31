// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

class CollapsibleCardContainer: CardContainer, UIGestureRecognizerDelegate {
    private struct UX {
        static let verticalPadding: CGFloat = 8
        static let horizontalPadding: CGFloat = 8
        static let titleHorizontalPadding: CGFloat = 16
        static let titleTopPadding: CGFloat = 16
        static let chevronSize = CGSize(width: 20, height: 20)
    }

    enum ExpandButtonState {
        case collapsed
        case expanded

        var image: UIImage? {
            switch self {
            case .expanded:
                return UIImage(named: StandardImageIdentifiers.Large.chevronUp)?.withRenderingMode(.alwaysTemplate)
            case .collapsed:
                return UIImage(named: StandardImageIdentifiers.Large.chevronDown)?.withRenderingMode(.alwaysTemplate)
            }
        }

        var toggle: ExpandButtonState {
            switch self {
            case .expanded:
                return .collapsed
            case .collapsed:
                return .expanded
            }
        }
    }

    // MARK: - Properties
    private var state: ExpandButtonState = .expanded

    // UI
    private lazy var rootView: UIView = .build { _ in }
    private lazy var headerView: UIView = .build { _ in }
    private lazy var containerView: UIView = .build { _ in }
    private var containerHeightConstraint: NSLayoutConstraint?
    private var tapRecognizer: UITapGestureRecognizer!

    lazy var titleLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .headline, size: 17.0)
        label.numberOfLines = 0
    }

    private lazy var chevronButton: ResizableButton = .build { view in
        view.setImage(self.state.image, for: .normal)
        view.buttonEdgeSpacing = 0
        view.addTarget(self, action: #selector(self.toggleExpand), for: .touchUpInside)
    }

    // MARK: - Inits
    override init(frame: CGRect) {
        super.init(frame: frame)

        setupLayout()

        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapHeader))
        tapRecognizer.delegate = self
        headerView.addGestureRecognizer(tapRecognizer)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configure(_ view: UIView) {
        configure(title: "", contentView: view, titleA11yId: "", closeButtonA11yId: "", expandState: .collapsed)
    }

    func configure(title: String,
                   contentView: UIView,
                   titleA11yId: String? = AccessibilityIdentifiers.Components.collapseButton,
                   closeButtonA11yId: String? = AccessibilityIdentifiers.Components.cardTitleLabel,
                   expandState: ExpandButtonState) {
        containerView.subviews.forEach { $0.removeFromSuperview() }
        containerView.addSubview(contentView)

        titleLabel.text = title
        titleLabel.accessibilityIdentifier = titleA11yId
        chevronButton.accessibilityIdentifier = closeButtonA11yId

        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            contentView.topAnchor.constraint(equalTo: containerView.topAnchor),
            contentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])

        updateCardState(expandState: expandState)

        super.configure(rootView)
    }

    override func applyTheme(theme: Theme) {
        super.applyTheme(theme: theme)

        titleLabel.textColor = theme.colors.textPrimary
        chevronButton.tintColor = theme.colors.iconPrimary
    }

    private func setupLayout() {
        configure(rootView)

        headerView.addSubview(titleLabel)
        headerView.addSubview(chevronButton)
        rootView.addSubview(headerView)
        rootView.addSubview(containerView)

        containerHeightConstraint = containerView.heightAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            headerView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor,
                                                constant: UX.titleHorizontalPadding),
            headerView.topAnchor.constraint(equalTo: rootView.topAnchor,
                                            constant: UX.titleTopPadding),
            headerView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor,
                                                 constant: -UX.titleHorizontalPadding),
            headerView.bottomAnchor.constraint(equalTo: containerView.topAnchor,
                                               constant: -UX.verticalPadding),

            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: chevronButton.leadingAnchor,
                                                 constant: -UX.horizontalPadding),
            titleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: UX.chevronSize.height),

            chevronButton.topAnchor.constraint(greaterThanOrEqualTo: headerView.topAnchor),
            chevronButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            chevronButton.bottomAnchor.constraint(lessThanOrEqualTo: headerView.bottomAnchor),
            chevronButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            chevronButton.widthAnchor.constraint(equalToConstant: UX.chevronSize.width),
            chevronButton.heightAnchor.constraint(equalToConstant: UX.chevronSize.height),

            containerView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor,
                                                   constant: UX.horizontalPadding),
            containerView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor,
                                                    constant: -UX.horizontalPadding),
            containerView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor,
                                                  constant: -UX.verticalPadding),
        ])
    }

    private func updateCardState(expandState: ExpandButtonState) {
        chevronButton.setImage(state.image, for: .normal)
        containerHeightConstraint?.isActive = expandState == .collapsed
    }

    @objc
    private func toggleExpand(_ sender: UIButton) {
        updateCardState(expandState: state.toggle)
    }

    @objc
    func tapHeader(_ recognizer: UITapGestureRecognizer) {
        updateCardState(expandState: state.toggle)
    }
}
