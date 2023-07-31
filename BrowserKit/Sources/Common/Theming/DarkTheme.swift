// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public struct DarkTheme: Theme {
    public var type: ThemeType = .dark
    public var colors: ThemeColourPalette = DarkColourPalette()

    public init() {}
}

private struct DarkColourPalette: ThemeColourPalette {
    // MARK: - Layers
    var layer1: UIColor = FXColors.DarkGrey60
    var layer2: UIColor = FXColors.DarkGrey30
    var layer3: UIColor = FXColors.DarkGrey80
    var layer4: UIColor = FXColors.DarkGrey20.withAlphaComponent(0.7)
    var layer5: UIColor = FXColors.DarkGrey40
    var layer6: UIColor = FXColors.DarkGrey60
    var layer5Hover: UIColor = FXColors.DarkGrey20
    var layerScrim: UIColor = FXColors.DarkGrey90.withAlphaComponent(0.95)
    var layerGradient = Gradient(colors: [FXColors.Violet40, FXColors.Violet70])
    var layerGradientOverlay = Gradient(colors: [FXColors.DarkGrey40.withAlphaComponent(0),
                                                 FXColors.DarkGrey40.withAlphaComponent(0.4)])
    var layerAccentNonOpaque: UIColor = FXColors.Blue20.withAlphaComponent(0.2)
    var layerAccentPrivate: UIColor = FXColors.Purple60
    var layerAccentPrivateNonOpaque: UIColor = FXColors.Purple60.withAlphaComponent(0.3)
    var layerLightGrey30: UIColor = FXColors.LightGrey30
    var layerSepia: UIColor = FXColors.Orange05

    // MARK: - Actions
    var actionPrimary: UIColor = FXColors.Blue30
    var actionPrimaryHover: UIColor = FXColors.Blue20
    var actionSecondary: UIColor = FXColors.LightGrey30
    var actionSecondaryHover: UIColor = FXColors.LightGrey20
    var formSurfaceOff: UIColor = FXColors.DarkGrey05
    var formKnob: UIColor = FXColors.White
    var indicatorActive: UIColor = FXColors.LightGrey90
    var indicatorInactive: UIColor = FXColors.DarkGrey05

    // MARK: - Text
    var textPrimary: UIColor = FXColors.LightGrey05
    var textSecondary: UIColor = FXColors.LightGrey40
    var textSecondaryAction: UIColor = FXColors.DarkGrey90
    var textDisabled: UIColor = FXColors.LightGrey05.withAlphaComponent(0.4)
    var textWarning: UIColor = FXColors.Red20
    var textAccent: UIColor = FXColors.Blue30
    var textOnColor: UIColor = FXColors.LightGrey05
    var textInverted: UIColor = FXColors.DarkGrey90

    // MARK: - Icons
    var iconPrimary: UIColor = FXColors.LightGrey05
    var iconSecondary: UIColor = FXColors.LightGrey40
    var iconDisabled: UIColor = FXColors.LightGrey05.withAlphaComponent(0.4)
    var iconAction: UIColor = FXColors.Blue30
    var iconOnColor: UIColor = FXColors.LightGrey05
    var iconWarning: UIColor = FXColors.Red20
    var iconSpinner: UIColor = FXColors.White
    var iconAccentViolet: UIColor = FXColors.Violet20
    var iconAccentBlue: UIColor = FXColors.Blue30
    var iconAccentPink: UIColor = FXColors.Pink20
    var iconAccentGreen: UIColor = FXColors.Green20
    var iconAccentYellow: UIColor = FXColors.Yellow20

    // MARK: - Border
    var borderPrimary: UIColor = FXColors.DarkGrey05
    var borderAccent: UIColor = FXColors.Blue30
    var borderAccentNonOpaque: UIColor = FXColors.Blue20.withAlphaComponent(0.2)
    var borderAccentPrivate: UIColor = FXColors.Purple60
    var borderInverted: UIColor = FXColors.DarkGrey90

    // MARK: - Shadow
    var shadowDefault: UIColor = FXColors.DarkGrey90.withAlphaComponent(0.16)
}
