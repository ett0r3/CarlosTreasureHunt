//
//  HuntMapView.swift
//  CarlosTreasureHunt
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

            if game.canAccessGallery {
                VStack(spacing: 14) {
                    GalleryHeader(
                        title: "My Missions\nCollection",
                        subtitle: nil,
                        showsBackButton: true
                    ) {
                        dismiss()
                    }

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
            } else {
                ContentUnavailableView(
                    "Gallery locked",
                    systemImage: "lock.fill",
                    description: Text("Complete Mission 1 to unlock your collections.")
                )
                .foregroundStyle(.white)
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
    let isGalleryMode: Bool

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
                        subtitle: game.discoveredPhraseText(for: mission),
                        showsBackButton: !isGalleryMode
                    ) {
                        dismiss()
                    }

                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 18) {
                            ForEach(mission.artworks) { artwork in
                                Button {
                                    if isGalleryMode, game.isUnlocked(artwork) {
                                        game.openGalleryArtwork(artwork)
                                    } else if !isGalleryMode, game.isUnlocked(artwork) {
                                        game.reopenUnlockedArtwork(artwork)
                                    } else if
                                        !isGalleryMode,
                                        artwork.id == game.currentArtwork(in: mission)?.id
                                    {
                                        game.openTarget(artwork)
                                    }
                                } label: {
                                    MissionArtworkCard(
                                        artwork: artwork,
                                        isUnlocked: game.isUnlocked(artwork),
                                        isCurrent: !isGalleryMode &&
                                            !game.isMissionCompleted(mission) &&
                                            artwork.id == game.currentArtwork(in: mission)?.id
                                    )
                                }
                                .buttonStyle(.plain)
                                .disabled(
                                    isGalleryMode
                                        ? !game.isUnlocked(artwork)
                                        : !game.isUnlocked(artwork) &&
                                            artwork.id != game.currentArtwork(in: mission)?.id
                                )
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
        .toolbar(isGalleryMode ? .visible : .hidden, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .tint(.white)
    }
}

struct GalleryArtworkDetailView: View {
    @EnvironmentObject private var game: GameStore
    @Environment(\.dismiss) private var dismiss
    @State private var showsFullScreenArtwork = false
    let artworkID: UUID

    var body: some View {
        ZStack {
            PurpleGameBackground(raysOpacity: 0.12)

            if
                let artwork = game.artwork(with: artworkID),
                game.isUnlocked(artwork)
            {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        GalleryHeader(
                            title: artwork.title,
                            subtitle: artwork.galleryName,
                            showsBackButton: true
                        ) {
                            dismiss()
                        }

                        Button {
                            showsFullScreenArtwork = true
                        } label: {
                            FullArtworkImage(artwork: artwork)
                                .scaledToFit()
                                .frame(maxWidth: 350, maxHeight: 420)
                                .shadow(color: .black.opacity(0.28), radius: 20, y: 12)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("View \(artwork.title) full screen")
                        .padding(.horizontal, 24)

                        VStack(alignment: .leading, spacing: 18) {
                            ArtworkInformationRow(
                                label: "Artist",
                                value: artwork.artist
                            )

                            ArtworkInformationRow(
                                label: "Date",
                                value: artwork.creationDate
                            )

                            VStack(alignment: .leading, spacing: 8) {
                                Text("About the artwork")
                                    .font(.system(size: 13, weight: .black, design: .rounded))
                                    .foregroundStyle(GameTheme.royalPurple)

                                Text(artwork.detailedDescription)
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundStyle(GameTheme.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(GameTheme.cream)
                                .shadow(color: .black.opacity(0.14), radius: 16, y: 8)
                        )
                        .padding(.horizontal, 22)
                        .padding(.bottom, 32)
                    }
                }
                .fullScreenCover(isPresented: $showsFullScreenArtwork) {
                    FullScreenArtworkViewer(artwork: artwork)
                        .presentationBackground(.clear)
                }
            } else {
                ContentUnavailableView("Artwork unavailable", systemImage: "lock.fill")
                    .foregroundStyle(.white)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct ArtworkInformationRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(GameTheme.royalPurple)

            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(GameTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
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
                AppBackButton(action: backAction)
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
                            colors: isAvailable && !isCompleted ? [
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

                if isCompleted {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 50, weight: .black))
                        .foregroundStyle(Color(red: 1.0, green: 0.72, blue: 0.0))
                } else if isAvailable {
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

            Text(isAvailable ? mission.title : "Coming soon")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .padding(.bottom, -5)

            Text(
                isAvailable
                    ? (isCompleted ? "Complete" : (isStarted ? progressText : "Ready"))
                    : "Locked"
            )
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

                    if isUnlocked {
                        GalleryArtworkImage(artwork: artwork)
                            .scaledToFill()
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .clipped()
                    } else if isCurrent {
                        VStack(spacing: 10) {
                            Image(systemName: "viewfinder")
                                .font(.system(size: 42, weight: .black))

                            Text("Find the next detail")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .multilineTextAlignment(.center)
                        }
                        .foregroundStyle(Color(red: 1.0, green: 0.76, blue: 0.08))
                        .padding(16)
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

            Text(isUnlocked ? artwork.title : (isCurrent ? "Next target" : "Locked"))
                .font(.system(size: 13, weight: .black, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .lineLimit(3)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, minHeight: 48, maxHeight: 48, alignment: .top)
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
            .previewDisplayName("Mission Gallery - Locked")

            NavigationStack {
                MissionGalleryView()
            }
            .environmentObject(PreviewSupport.completedGame)
            .previewDisplayName("Mission Gallery - Unlocked")

            NavigationStack {
                MissionDetailView(
                    missionID: PreviewSupport.firstMission.id,
                    isGalleryMode: false
                )
            }
            .environmentObject(PreviewSupport.inProgressGame)
            .previewDisplayName("Mission Detail - Hunt")

            NavigationStack {
                MissionDetailView(
                    missionID: PreviewSupport.firstMission.id,
                    isGalleryMode: true
                )
            }
            .environmentObject(PreviewSupport.completedGame)
            .previewDisplayName("Mission Detail - Gallery")

            NavigationStack {
                GalleryArtworkDetailView(
                    artworkID: PreviewSupport.firstArtwork.id
                )
            }
            .environmentObject(PreviewSupport.completedGame)
            .previewDisplayName("Gallery Artwork Detail")
        }
    }
}
