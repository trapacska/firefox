// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

class PocketFooterView: UICollectionReusableView, ReusableCell, ThemeApplicable {
    private struct UX {
        static let fontSize: CGFloat = 12
        static let mainContainerSpacing: CGFloat = 8
    }

    private let wallpaperManager: WallpaperManager
    var onTapLearnMore: (() -> Void)?

    private let pocketImageView: UIImageView = .build { imageView in
        imageView.image = UIImage(named: ImageIdentifiers.homepagePocket)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    private let titleLabel: UILabel = .build { label in
        label.text = String(format: .FirefoxHomepage.Pocket.Footer.Title,
                            PocketAppName.shortName.rawValue,
                            AppName.shortName.rawValue)
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .caption1,
                                                            size: UX.fontSize)
    }

    private let learnMoreLabel: UILabel = .build { label in
        label.text = .FirefoxHomepage.Pocket.Footer.LearnMore
        label.isUserInteractionEnabled = true
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.Pocket.footerLearnMoreLabel
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .caption1,
                                                            size: UX.fontSize)
    }

    private let labelsContainer: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.alignment = .leading
    }

    private let mainContainer: UIStackView = .build { stackView in
        stackView.axis = .horizontal
        stackView.spacing = UX.mainContainerSpacing
        stackView.distribution = .fillProportionally
        stackView.alignment = .center
        stackView.isLayoutMarginsRelativeArrangement = true
    }

    override init(frame: CGRect) {
        wallpaperManager = WallpaperManager()
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        let tapGesture = UITapGestureRecognizer(target: self,
                                                action: #selector(didTapLearnMore))
        learnMoreLabel.addGestureRecognizer(tapGesture)

        [titleLabel, learnMoreLabel].forEach(labelsContainer.addArrangedSubview)
        [pocketImageView, labelsContainer].forEach(mainContainer.addArrangedSubview)

        addSubview(mainContainer)
    }

    private func setupLayout() {
        NSLayoutConstraint.activate([
            mainContainer.topAnchor.constraint(equalTo: topAnchor),
            mainContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            mainContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainContainer.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor)
        ])
    }

    @objc
    func didTapLearnMore() {
        onTapLearnMore?()
    }

    func applyTheme(theme: Theme) {
        let colors = theme.colors
        titleLabel.textColor = wallpaperManager.featureAvailable ?
        wallpaperManager.currentWallpaper.textColor : colors.textPrimary
        learnMoreLabel.textColor = colors.textAccent
    }
}
