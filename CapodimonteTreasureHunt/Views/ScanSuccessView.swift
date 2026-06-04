//
//  ScanSuccessView.swift
//  CapodimonteTreasureHunt
//

import SwiftUI

struct WordRevealView: View {
    @EnvironmentObject private var game: GameStore
    let artworkID: UUID

    var body: some View {
        ZStack {
            GameBackground()

            if let artwork = game.artwork(with: artworkID), let mission = game.mission(containing: artworkID) {
                VStack(spacing: 22) {
                    Spacer()

                    Text("Parola trovata")
                        .font(.headline)
                        .foregroundStyle(Color(red: 0.49, green: 0.19, blue: 0.62))

                    Text(artwork.unlockedWord)
                        .font(.system(size: 48, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color(red: 0.18, green: 0.12, blue: 0.23))
                        .minimumScaleFactor(0.62)

                    VStack(spacing: 8) {
                        Text("Abbinata a")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)

                        Text(artwork.title)
                            .font(.title3.bold())
                            .foregroundStyle(Color(red: 0.18, green: 0.12, blue: 0.23))

                        Text(artwork.targetTitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(.white.opacity(0.78))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    PhraseProgressView(slots: game.phraseSlots(for: mission))

                    Spacer()

                    PrimaryButton(title: "Vedi il quadro", systemImage: "photo.artframe") {
                        game.continueAfterWordReveal(for: artwork)
                    }
                }
                .padding(24)
            } else {
                ContentUnavailableView("Parola non trovata", systemImage: "questionmark.circle")
            }
        }
        .navigationBarBackButtonHidden()
    }
}

struct ArtworkRevealView: View {
    @EnvironmentObject private var game: GameStore
    let artworkID: UUID

    var body: some View {
        ZStack {
            GameBackground()

            if let artwork = game.artwork(with: artworkID) {
                ScrollView {
                    VStack(spacing: 18) {
                        Text("Quadro sbloccato")
                            .font(.largeTitle.bold())
                            .foregroundStyle(Color(red: 0.18, green: 0.12, blue: 0.23))

                        UnlockedArtworkCard(artwork: artwork)

                        PrimaryButton(title: "Continua", systemImage: "arrow.right") {
                            game.continueAfterArtworkReveal(for: artwork)
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
                }
            } else {
                ContentUnavailableView("Quadro non trovato", systemImage: "questionmark.circle")
            }
        }
        .navigationBarBackButtonHidden()
    }
}

private struct UnlockedArtworkCard: View {
    let artwork: ArtworkTarget

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            FullArtworkImage(artwork: artwork)
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 6) {
                Text(artwork.title)
                    .font(.title2.bold())
                    .foregroundStyle(Color(red: 0.18, green: 0.12, blue: 0.23))

                Text(artwork.artist)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(red: 0.49, green: 0.19, blue: 0.62))

                Text(artwork.artworkDescription)
                    .font(.body)
                    .foregroundStyle(Color(red: 0.23, green: 0.21, blue: 0.25))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(.white.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct FullArtworkImage: View {
    let artwork: ArtworkTarget

    var body: some View {
        if let imageAssetName = artwork.imageAssetName {
            Image(imageAssetName)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.18, green: 0.12, blue: 0.23),
                        Color(red: 0.49, green: 0.19, blue: 0.62),
                        Color(red: 0.12, green: 0.47, blue: 0.34)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(spacing: 10) {
                    Image(systemName: "photo.artframe")
                        .font(.system(size: 52, weight: .semibold))

                    Text("Opera completa")
                        .font(.headline)

                    Text(artwork.title)
                        .font(.subheadline.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 18)
                }
                .foregroundStyle(.white)
            }
        }
    }
}
