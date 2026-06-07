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
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        ZStack {
            PurpleGameBackground()

            VStack(spacing: 14) {
                GalleryHeader(
                    title: "My Missions\nCollection",
                    subtitle: nil,
                    showsBackButton: true
                ) {
                    dismiss()
                }

                MissionStars(
                    filledCount: game.missions.filter { game.completedCount(for: $0) > 0 }.count,
                    totalCount: game.missions.count
                )

                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(game.missions) { mission in
                            Button {
                                game.openMission(mission)
                            } label: {
                                MissionCollectionCard(
                                    mission: mission,
                                    progressText: game.progressText(for: mission),
                                    isAvailable: game.canOpenMission(mission),
                                    isStarted: game.completedCount(for: mission) > 0,
                                    isCompleted: game.isMissionCompleted(mission)
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(!game.canOpenMission(mission))
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 4)
                    .padding(.bottom, 34)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct MissionDetailView: View {
    @EnvironmentObject private var game: GameStore
    @Environment(\.dismiss) private var dismiss
    let missionID: UUID

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        ZStack {
            PurpleGameBackground()

            if
                let mission = game.mission(with: missionID),
                game.canOpenMission(mission)
            {
                VStack(spacing: 16) {
                    GalleryHeader(
                        title: mission.title,
                        subtitle: "\"History comes alive with you!\"",
                        showsBackButton: true
                    ) {
                        dismiss()
                    }

                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 18) {
                            ForEach(mission.artworks) { artwork in
                                Button {
                                    if game.isUnlocked(artwork) || artwork.id == game.currentArtwork(in: mission)?.id {
                                        game.openTarget(artwork)
                                    }
                                } label: {
                                    MissionArtworkCard(
                                        artwork: artwork,
                                        isUnlocked: game.isUnlocked(artwork),
                                        isCurrent: artwork.id == game.currentArtwork(in: mission)?.id
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 104)
                    }
                }

                if !game.isMissionCompleted(mission) {
                    VStack {
                        Spacer()

                        PrimaryButton(title: "Go to next target", systemImage: "viewfinder") {
                            game.openCurrentTarget(in: mission)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                }
            } else {
                ContentUnavailableView("Mission unavailable", systemImage: "lock.fill")
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct GalleryHeader: View {
    let title: String
    let subtitle: String?
    let showsBackButton: Bool
    let backAction: () -> Void

    var body: some View {
        ZStack(alignment: .leading) {
            if showsBackButton {
                Button(action: backAction) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.white.opacity(0.22)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
            }

            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)
                    .lineSpacing(-2)
                    .foregroundStyle(.white)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .italic()
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.92))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 42)
        }
        .padding(.horizontal, 22)
        .padding(.top, 22)
    }
}

private struct MissionStars: View {
    let filledCount: Int
    let totalCount: Int

    var body: some View {
        HStack(spacing: -2) {
            ForEach(0..<totalCount, id: \.self) { index in
                ZStack {
                    Circle()
                        .fill(index < filledCount ? Color(red: 1.0, green: 0.72, blue: 0.0) : Color(red: 0.53, green: 0.45, blue: 0.96))
                        .frame(width: 28, height: 28)

                    Image(systemName: "star.fill")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

private struct MissionCollectionCard: View {
    let mission: MissionCollection
    let progressText: String
    let isAvailable: Bool
    let isStarted: Bool
    let isCompleted: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(
                        LinearGradient(
                            colors: isAvailable ? [
                                Color(red: 1.0, green: 0.82, blue: 0.12),
                                Color(red: 0.86, green: 0.62, blue: 0.08)
                            ] : [
                                Color(red: 0.34, green: 0.42, blue: 0.84),
                                Color(red: 0.54, green: 0.38, blue: 0.92)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                if isAvailable {
                    GalleryThumbnailPlaceholder(title: mission.title)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .padding(6)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 42, weight: .black))
                        .foregroundStyle(Color(red: 0.08, green: 0.10, blue: 0.70))
                }
            }
            .aspectRatio(1.02, contentMode: .fit)

            Text(mission.title)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(isCompleted ? "Complete" : (isStarted ? progressText : "Ready"))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.78))
        }
    }
}

private struct MissionArtworkCard: View {
    let artwork: ArtworkTarget
    let isUnlocked: Bool
    let isCurrent: Bool

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { proxy in
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Color.white.opacity(isUnlocked || isCurrent ? 0.18 : 0.12))

                    if isUnlocked || isCurrent {
                        GalleryArtworkImage(artwork: artwork)
                            .scaledToFill()
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .clipped()
                            .saturation(isUnlocked ? 1 : 0.15)
                            .opacity(isUnlocked ? 1 : 0.72)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 42, weight: .black))
                            .foregroundStyle(Color(red: 0.30, green: 0.12, blue: 0.88))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 7))
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(0.84, contentMode: .fit)
            .overlay(alignment: .topLeading) {
                if isCurrent {
                    Image(systemName: "viewfinder")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(.white)
                        .padding(7)
                        .background(Circle().fill(Color(red: 1.0, green: 0.72, blue: 0.0)))
                        .offset(x: -8, y: -8)
                }
            }
            .overlay {
                if isCurrent {
                    RoundedRectangle(cornerRadius: 7)
                        .strokeBorder(Color(red: 1.0, green: 0.72, blue: 0.0), lineWidth: 4)
                }
            }

            Text(isUnlocked || isCurrent ? artwork.title : "Locked")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, minHeight: 18, maxHeight: 18)
        }
    }
}

private struct GalleryThumbnailPlaceholder: View {
    let title: String

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.87, blue: 0.70),
                    Color(red: 0.60, green: 0.52, blue: 0.42)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: "photo.artframe")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(Color(red: 0.25, green: 0.20, blue: 0.18).opacity(0.60))
        }
    }
}

private struct GalleryArtworkImage: View {
    let artwork: ArtworkTarget

    var body: some View {
        if let imageAssetName = artwork.imageAssetName {
            Image(imageAssetName)
                .resizable()
        } else if let targetAssetName = artwork.targetAssetName {
            Image(targetAssetName)
                .resizable()
        } else {
            GalleryThumbnailPlaceholder(title: artwork.title)
        }
    }
}

struct HuntMapView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationStack {
                MissionGalleryView()
            }
            .environmentObject(PreviewSupport.game)
            .previewDisplayName("Mission Gallery")

            NavigationStack {
                MissionDetailView(missionID: PreviewSupport.firstMission.id)
            }
            .environmentObject(PreviewSupport.game)
            .previewDisplayName("Mission Detail")
        }
    }
}
