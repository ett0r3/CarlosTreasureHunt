//
//  PrimaryButton.swift
//  CarlosTreasureHunt
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.47, green: 0.28, blue: 0.0))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(GameTheme.gold)
                        .shadow(
                            color: Color(red: 0.62, green: 0.32, blue: 0.0).opacity(0.24),
                            radius: 9,
                            y: 5
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

struct PrimaryButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            PurpleGameBackground()

            PrimaryButton(title: "Continue", systemImage: "arrow.right") {}
                .padding(24)
        }
    }
}
