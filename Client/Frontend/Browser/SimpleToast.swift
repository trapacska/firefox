// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

struct SimpleToast: ThemeApplicable {
    private let toastLabel: UILabel = .build { label in
        label.font = DefaultDynamicFontHelper.preferredBoldFont(withTextStyle: .body,
                                                                size: Toast.UX.fontSize)
        label.numberOfLines = 0
        label.textAlignment = .center
    }

    private let heightConstraint: NSLayoutConstraint

    init() {
        heightConstraint = toastLabel.heightAnchor
            .constraint(equalToConstant: Toast.UX.toastHeight)
    }

    func showAlertWithText(_ text: String,
                           bottomContainer: UIView,
                           theme: Theme,
                           bottomConstraintPadding: CGFloat = 0) {
        toastLabel.text = text
        bottomContainer.addSubview(toastLabel)
        NSLayoutConstraint.activate([
            heightConstraint,
            toastLabel.widthAnchor.constraint(equalTo: bottomContainer.widthAnchor),
            toastLabel.leadingAnchor.constraint(equalTo: bottomContainer.leadingAnchor),
            toastLabel.bottomAnchor.constraint(equalTo: bottomContainer.safeAreaLayoutGuide.bottomAnchor,
                                               constant: bottomConstraintPadding)
        ])
        applyTheme(theme: theme)
        animate(toastLabel)
    }

    func applyTheme(theme: Theme) {
        toastLabel.textColor = theme.colors.textInverted
        toastLabel.backgroundColor = theme.colors.actionPrimary
    }

    private func dismiss(_ toast: UIView) {
        UIView.animate(
            withDuration: Toast.UX.toastAnimationDuration,
            animations: {
                heightConstraint.constant = 0
                toast.superview?.layoutIfNeeded()
            },
            completion: { finished in
                toast.removeFromSuperview()
            }
        )
    }

    private func animate(_ toast: UIView) {
        UIView.animate(
            withDuration: Toast.UX.toastAnimationDuration,
            animations: {
                var frame = toast.frame
                frame.origin.y = frame.origin.y - Toast.UX.toastHeight
                frame.size.height = Toast.UX.toastHeight
                toast.frame = frame
            },
            completion: { finished in
                let dispatchTime = DispatchTime.now() + Toast.UX.toastDismissAfter

                DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: {
                    self.dismiss(toast)
                })
            }
        )
    }
}
