// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// MARK: - ReaderModeStyleViewModelDelegate

protocol ReaderModeStyleViewModelDelegate: AnyObject {
    func readerModeStyleViewModel(_ readerModeStyleViewModel: ReaderModeStyleViewModel,
                                  didConfigureStyle style: ReaderModeStyle,
                                  isUsingUserDefinedColor: Bool)
}

// MARK: - ReaderModeStyleViewModel

class ReaderModeStyleViewModel {
    public init(isBottomPresented: Bool, readerModeStyle: ReaderModeStyle = .default) {
        self.isBottomPresented = isBottomPresented
        self.readerModeStyle = readerModeStyle
    }

    struct UX {
        static let RowHeight = 50.0
        // For top or bottom presentation
        static let PresentationSpace = 13.0

        static let SeparatorLineThickness = 1.0
        static let Width = 270.0
        static let Height = 4.0 * RowHeight + 3.0 * SeparatorLineThickness

        static let BrightnessSliderWidth = 140
        static let BrightnessIconOffset = 10
    }

    var isBottomPresented: Bool
    var readerModeStyle: ReaderModeStyle

    // Keeps user-defined reader color until reader mode is closed or reloaded
    var isUsingUserDefinedColor = false

    weak var delegate: ReaderModeStyleViewModelDelegate?

    var fontTypeOffset: CGFloat {
        return isBottomPresented ? 0 : ReaderModeStyleViewModel.UX.PresentationSpace
    }

    var brightnessRowOffset: CGFloat {
        return isBottomPresented ? -ReaderModeStyleViewModel.UX.PresentationSpace : 0
    }

    func sliderDidChange(value: CGFloat) {
        UIScreen.main.brightness = value
    }

    func selectTheme(_ theme: ReaderModeTheme) {
        readerModeStyle.theme = theme
    }

    func selectFontType(_ fontType: ReaderModeFontType) {
        readerModeStyle.fontType = fontType
    }

    func readerModeDidChangeTheme(_ theme: ReaderModeTheme) {
        selectTheme(theme)
        isUsingUserDefinedColor = true
        delegate?.readerModeStyleViewModel(
            self,
            didConfigureStyle: readerModeStyle,
            isUsingUserDefinedColor: true
        )
    }

    func fontSizeDidChangeSizeAction(_ fontSizeAction: FontSizeAction) {
        switch fontSizeAction {
        case .smaller:
            readerModeStyle.fontSize = readerModeStyle.fontSize.smaller()
        case .bigger:
            readerModeStyle.fontSize = readerModeStyle.fontSize.bigger()
        case .reset:
            readerModeStyle.fontSize = ReaderModeFontSize.defaultSize
        }

        delegate?.readerModeStyleViewModel(
            self,
            didConfigureStyle: readerModeStyle,
            isUsingUserDefinedColor: isUsingUserDefinedColor
        )
    }

    func fontTypeDidChange(_ fontType: ReaderModeFontType) {
        selectFontType(fontType)
        delegate?.readerModeStyleViewModel(
            self,
            didConfigureStyle: readerModeStyle,
            isUsingUserDefinedColor: isUsingUserDefinedColor
        )
    }
}
