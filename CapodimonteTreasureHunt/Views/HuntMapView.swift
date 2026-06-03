//
//  HuntMapView.swift
//  CapodimonteTreasureHunt
//

import SwiftUI

struct HuntMapView: View {
    @EnvironmentObject private var game: GameStore

    var body: some View {
        SessionGalleryView()
    }
}

struct SessionGalleryView: View {
    @EnvironmentObject private var game: GameStore

    var body: some View {
        ZStack {
            GameBackground()

            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Galleria")
                            .font(.largeTitle.bold())

                        Text("Quadri sbloccati: \(game.progressText)")
                            .font(.headline)
                    }

                    Spacer()

                    Image(systemName: "book.pages.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(Color(red: 0.49, green: 0.19, blue: 0.62))
                }
                .foregroundStyle(Color(red: 0.18, green: 0.12, blue: 0.23))

                PhraseProgressView(slots: game.phraseSlots)

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(game.artworks) { artwork in
                            Button {
                                if game.isUnlocked(artwork) || artwork.id == game.currentArtwork?.id {
                                    game.openTarget(artwork)
                                }
                            } label: {
                                ArtworkRow(
                                    artwork: artwork,
                                    isUnlocked: game.isUnlocked(artwork),
                                    isCurrent: artwork.id == game.currentArtwork?.id
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                if game.completedCount < game.artworks.count {
                    PrimaryButton(title: "Vai al prossimo target", systemImage: "viewfinder") {
                        game.openCurrentTarget()
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PhraseProgressView: View {
    let slots: [String?]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(slots.enumerated()), id: \.offset) { _, word in
                Text(word ?? "...")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(word == nil ? Color.secondary : Color.white)
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .background(word == nil ? .white.opacity(0.72) : Color(red: 0.12, green: 0.47, blue: 0.34))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

private struct ArtworkRow: View {
    let artwork: ArtworkTarget
    let isUnlocked: Bool
    let isCurrent: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.18))
                    .frame(width: 52, height: 52)

                Image(systemName: statusIcon)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(statusColor)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Quadro \(artwork.order)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(statusColor)

                Text(isUnlocked || isCurrent ? artwork.title : "Quadro bloccato")
                    .font(.headline)
                    .foregroundStyle(Color(red: 0.16, green: 0.13, blue: 0.18))

                Text(isUnlocked ? "Parola: \(artwork.unlockedWord)" : artwork.targetTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.white.opacity(isCurrent ? 0.95 : 0.72))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var statusColor: Color {
        if isUnlocked {
            return Color(red: 0.12, green: 0.47, blue: 0.34)
        }

        return isCurrent ? Color(red: 0.49, green: 0.19, blue: 0.62) : .gray
    }

    private var statusIcon: String {
        isUnlocked ? "checkmark" : (isCurrent ? "camera.viewfinder" : "lock")
    }
}
