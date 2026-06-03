//
//  CompletionView.swift
//  CapodimonteTreasureHunt
//

import SwiftUI

struct CompletionView: View {
    @EnvironmentObject private var game: GameStore

    var body: some View {
        ZStack {
            GameBackground()

            VStack(spacing: 22) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 84))
                    .foregroundStyle(Color(red: 0.84, green: 0.48, blue: 0.08))

                Text("Tesoro trovato")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color(red: 0.18, green: 0.12, blue: 0.23))

                Text("\(game.displayName), hai completato il libro della sessione. La frase segreta e:")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color(red: 0.23, green: 0.21, blue: 0.25))

                Text(game.completedPhrase)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color(red: 0.49, green: 0.19, blue: 0.62))
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(.white.opacity(0.86))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Button {
                    game.openGallery()
                } label: {
                    Label("Guarda la galleria", systemImage: "book.pages")
                        .font(.headline)
                        .foregroundStyle(Color(red: 0.49, green: 0.19, blue: 0.62))
                }
                .buttonStyle(.plain)

                PrimaryButton(title: "Ricomincia", systemImage: "arrow.clockwise") {
                    game.restart()
                }
            }
            .padding(24)
        }
        .navigationBarBackButtonHidden()
    }
}
