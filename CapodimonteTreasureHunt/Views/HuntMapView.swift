//
//  HuntMapView.swift
//  CapodimonteTreasureHunt
//

import SwiftUI

struct HuntMapView: View {
    var body: some View {
        MissionGalleryView()
    }
}

struct MissionGalleryView: View {
    @EnvironmentObject private var game: GameStore

    var body: some View {
        ZStack {
            GameBackground()

            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Galleria")
                        .font(.largeTitle.bold())

                    Text("Scegli una delle 6 missioni.")
                        .font(.headline)
                }
                .foregroundStyle(Color(red: 0.18, green: 0.12, blue: 0.23))

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(game.missions) { mission in
                            Button {
                                game.openMission(mission)
                            } label: {
                                MissionRow(
                                    mission: mission,
                                    progressText: game.progressText(for: mission),
                                    isCompleted: game.isMissionCompleted(mission)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(20)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MissionDetailView: View {
    @EnvironmentObject private var game: GameStore
    let missionID: UUID

    var body: some View {
        ZStack {
            GameBackground()

            if let mission = game.mission(with: missionID) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mission.title)
                            .font(.largeTitle.bold())

                        Text("Quadri sbloccati: \(game.progressText(for: mission))")
                            .font(.headline)
                    }
                    .foregroundStyle(Color(red: 0.18, green: 0.12, blue: 0.23))

                    Text(mission.summary)
                        .font(.body)
                        .foregroundStyle(Color(red: 0.23, green: 0.21, blue: 0.25))

                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(mission.artworks) { artwork in
                                Button {
                                    if game.isUnlocked(artwork) || artwork.id == game.currentArtwork(in: mission)?.id {
                                        game.openTarget(artwork)
                                    }
                                } label: {
                                    ArtworkRow(
                                        artwork: artwork,
                                        isUnlocked: game.isUnlocked(artwork),
                                        isCurrent: artwork.id == game.currentArtwork(in: mission)?.id
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    if !game.isMissionCompleted(mission) {
                        PrimaryButton(title: "Vai al prossimo target", systemImage: "viewfinder") {
                            game.openCurrentTarget(in: mission)
                        }
                    }
                }
                .padding(20)
            } else {
                ContentUnavailableView("Missione non trovata", systemImage: "questionmark.circle")
            }
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

private struct MissionRow: View {
    let mission: MissionCollection
    let progressText: String
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.16))
                    .frame(width: 52, height: 52)

                Image(systemName: isCompleted ? "checkmark" : "book.pages")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(statusColor)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(progressText)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(statusColor)

                Text(mission.title)
                    .font(.headline)
                    .foregroundStyle(Color(red: 0.16, green: 0.13, blue: 0.18))

                Text(mission.summary)
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.white.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var statusColor: Color {
        isCompleted ? Color(red: 0.12, green: 0.47, blue: 0.34) : Color(red: 0.49, green: 0.19, blue: 0.62)
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

                Text(isUnlocked ? "Sbloccato" : artwork.targetTitle)
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
