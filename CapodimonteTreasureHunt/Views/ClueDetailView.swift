//
//  ClueDetailView.swift
//  CapodimonteTreasureHunt
//

import SwiftUI

struct ClueDetailView: View {
    @EnvironmentObject private var game: GameStore
    let clueID: UUID

    var body: some View {
        TargetDetailView(artworkID: clueID)
    }
}

struct TargetDetailView: View {
    @EnvironmentObject private var game: GameStore
    let artworkID: UUID

    var body: some View {
        ZStack {
            GameBackground()

            if let artwork = game.artwork(with: artworkID) {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Target \(artwork.order)")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color(red: 0.18, green: 0.12, blue: 0.23))

                    Label(artwork.targetTitle, systemImage: "viewfinder")
                        .font(.headline)
                        .foregroundStyle(Color(red: 0.49, green: 0.19, blue: 0.62))

                    Text("\(game.displayName), \(artwork.narratorPrompt)")
                        .font(.title3)
                        .foregroundStyle(Color(red: 0.23, green: 0.21, blue: 0.25))

                    TargetPreviewCard(artwork: artwork)

                    VStack(alignment: .leading, spacing: 10) {
                        Label("Cosa fare", systemImage: "camera.viewfinder")
                            .font(.headline)

                        Text(artwork.targetDescription)
                            .font(.body)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.78))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    Spacer()

                    if game.isUnlocked(artwork) {
                        Label("Quadro gia sbloccato nella galleria.", systemImage: "checkmark.seal.fill")
                            .font(.headline)
                            .foregroundStyle(Color(red: 0.12, green: 0.47, blue: 0.34))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        PrimaryButton(title: "Apri fotocamera", systemImage: "camera.viewfinder") {
                            game.openScanner(for: artwork)
                        }
                    }
                }
                .padding(20)
            } else {
                ContentUnavailableView("Target non trovato", systemImage: "questionmark.circle")
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct TargetPreviewCard: View {
    let artwork: ArtworkTarget

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: 0.18, green: 0.12, blue: 0.23))
                    .frame(height: 180)

                if let targetAssetName = artwork.targetAssetName {
                    Image(targetAssetName)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "photo.artframe")
                            .font(.system(size: 44))
                        Text("Anteprima dettaglio")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                }
            }

            Text(artwork.title)
                .font(.headline)
                .foregroundStyle(Color(red: 0.18, green: 0.12, blue: 0.23))
        }
        .padding(14)
        .background(.white.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
