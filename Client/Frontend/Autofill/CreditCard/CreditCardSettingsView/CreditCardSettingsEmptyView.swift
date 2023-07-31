// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import SwiftUI
import Shared

struct CreditCardSettingsEmptyView: View {
    // Theming
    @Environment(\.themeType)
    var themeVal
    @State var titleTextColor: Color = .clear
    @State var subTextColor: Color = .clear
    @State var toggleTextColor: Color = .clear
    @State var imageColor: Color = .clear

    @ObservedObject var toggleModel: ToggleModel

    var body: some View {
        ZStack {
            UIColor.clear.color
                .edgesIgnoringSafeArea(.all)
            GeometryReader { proxy in
                ScrollView {
                    VStack {
                        CreditCardAutofillToggle(
                            textColor: toggleTextColor,
                            model: toggleModel)
                        .background(Color.white)
                        .padding(.top, 25)
                        Spacer()
                        Image(StandardImageIdentifiers.Large.creditCard)
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(imageColor)
                            .frame(width: 200, height: 200)
                            .aspectRatio(contentMode: .fit)
                            .fixedSize()
                            .padding([.top], 10)
                            .accessibility(hidden: true)
                        Text(String(format: .CreditCard.Settings.EmptyListTitle,
                                    AppName.shortName.rawValue))
                            .preferredBodyFont(size: 22)
                            .foregroundColor(titleTextColor)
                            .multilineTextAlignment(.center)
                            .padding(.leading, 10)
                            .padding(.trailing, 10)
                        Text(String.CreditCard.Settings.EmptyListDescription)
                            .preferredBodyFont(size: 16)
                            .foregroundColor(subTextColor)
                            .multilineTextAlignment(.center)
                            .padding(.leading, 10)
                            .padding(.trailing, 10)
                            .padding([.top], -5)
                        Spacer()
                        Spacer()
                    }
                    .frame(minHeight: proxy.size.height)
                }
                .frame(maxWidth: .infinity)
            }
        }.onAppear {
            applyTheme(theme: themeVal.theme)
        }
        .onChange(of: themeVal) { newThemeValue in
            applyTheme(theme: newThemeValue.theme)
        }
    }

    func applyTheme(theme: Theme) {
        let color = theme.colors
        titleTextColor = Color(color.textPrimary)
        subTextColor = Color(color.textSecondary)
        toggleTextColor = Color(color.textPrimary)
        imageColor = Color(color.iconSecondary)
    }
}

struct CreditCardSettingsEmptyView_Previews: PreviewProvider {
    static var previews: some View {
        let toggleModel = ToggleModel(isEnabled: true)
        CreditCardSettingsEmptyView(toggleModel: toggleModel)
    }
}
