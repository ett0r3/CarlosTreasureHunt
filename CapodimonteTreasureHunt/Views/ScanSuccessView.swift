//
//  ScanSuccessView.swift
//  CapodimonteTreasureHunt
//

import SwiftUI

struct ScanSuccessView: View {
    @EnvironmentObject private var game: GameStore
    let artworkID: UUID

    var body: some View {
        ZStack {
            GameBackground()

            if let artwork = game.artwork(with: artworkID) {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 82))
                        .foregroundStyle(Color(red: 0.12, green: 0.47, blue: 0.34))

                    Text("Bravo, \(game.displayName)!")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color(red: 0.18, green: 0.12, blue: 0.23))

                    Text("Hai scansionato il dettaglio e sbloccato un nuovo quadro nella galleria.")
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color(red: 0.23, green: 0.21, blue: 0.25))

                    VStack(spacing: 8) {
                        Text(artwork.title)
                            .font(.title2.bold())

                        Text("Parola sbloccata")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)

                        Text(artwork.unlockedWord)
                            .font(.title.bold())
                            .foregroundStyle(Color(red: 0.49, green: 0.19, blue: 0.62))
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity)
                    .background(.white.opacity(0.86))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    PhraseProgressView(slots: game.phraseSlots)

                    Spacer()

                    PrimaryButton(title: "Continua", systemImage: "arrow.right") {
                        game.continueAfterSuccess()
                    }

                    Button {
                        game.openGallery()
                    } label: {
                        Label("Apri galleria", systemImage: "book.pages")
                            .font(.headline)
                            .foregroundStyle(Color(red: 0.49, green: 0.19, blue: 0.62))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                }
                .padding(24)
            } else {
                ContentUnavailableView("Risultato non trovato", systemImage: "questionmark.circle")
            }
        }
        .navigationBarBackButtonHidden()
    }
}
