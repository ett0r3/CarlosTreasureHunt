//
//  ClueDetailView.swift
//  CapodimonteTreasureHunt
//

import SwiftUI

struct ClueDetailView: View {
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
            if let artwork = game.artwork(with: artworkID) {
                TargetReferenceSurface(artwork: artwork)
                    .ignoresSafeArea()

                TargetReferenceOverlay(artwork: artwork) {
                    game.openScanner(for: artwork)
                }
                .ignoresSafeArea()
            } else {
                GameBackground()
                ContentUnavailableView("Target non trovato", systemImage: "questionmark.circle")
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct TargetReferenceSurface: View {
    let artwork: ArtworkTarget

    var body: some View {
        ZStack {
            TargetReferenceImage(artwork: artwork)
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .blur(radius: 18)
                .opacity(0.42)

            LinearGradient(
                colors: [
                    Color(red: 0.34, green: 0.08, blue: 0.50).opacity(0.82),
                    Color(red: 0.56, green: 0.20, blue: 0.82).opacity(0.74)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

private struct TargetReferenceOverlay: View {
    let artwork: ArtworkTarget
    let openCameraAction: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let lensSize = min(proxy.size.width * 0.96, proxy.size.height * 0.54)
            let lensCenterY = proxy.size.height * 0.48
            let buttonSize: CGFloat = 92
            let buttonCenterY = lensCenterY + (lensSize / 2) - (buttonSize * 0.2)

            ZStack {
                TargetReferenceImage(artwork: artwork)
                    .scaledToFill()
                    .frame(width: lensSize * 0.88, height: lensSize * 0.88)
                    .clipShape(Circle())
                    .position(x: proxy.size.width / 2, y: lensCenterY)

                PurpleLensChrome(lensSize: lensSize, lensCenterY: lensCenterY)
                    .allowsHitTesting(false)

                Button(action: openCameraAction) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.78, green: 0.36, blue: 1.0),
                                        Color(red: 0.56, green: 0.16, blue: 0.92)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Color(red: 0.60, green: 0.18, blue: 1.0).opacity(0.38), radius: 14, y: 8)

                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 38, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
                .frame(width: buttonSize, height: buttonSize)
                .position(x: proxy.size.width / 2, y: buttonCenterY)

                VStack(spacing: 4) {
                    Text(artwork.targetTitle)
                        .font(.headline)
                    Text(artwork.galleryName)
                        .font(.subheadline)
                }
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .position(x: proxy.size.width / 2, y: max(70, lensCenterY - (lensSize / 2) - 34))
            }
        }
    }
}

private struct PurpleLensChrome: View {
    let lensSize: CGFloat
    let lensCenterY: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let centerX = proxy.size.width / 2
            let handleWidth = lensSize * 0.17
            let handleHeight = lensSize * 0.56

            ZStack {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.86, green: 0.42, blue: 1.0),
                                Color(red: 0.54, green: 0.12, blue: 0.88)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: handleWidth, height: handleHeight)
                    .rotationEffect(.degrees(32))
                    .shadow(color: Color(red: 0.65, green: 0.18, blue: 1.0).opacity(0.42), radius: 18)
                    .position(x: centerX - lensSize * 0.43, y: lensCenterY + lensSize * 0.55)

                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color(red: 0.90, green: 0.52, blue: 1.0),
                                Color(red: 0.54, green: 0.12, blue: 0.88)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 24
                    )
                    .frame(width: lensSize, height: lensSize)
                    .shadow(color: Color(red: 0.64, green: 0.18, blue: 1.0).opacity(0.48), radius: 18)
                    .position(x: centerX, y: lensCenterY)
            }
        }
    }
}

private struct TargetReferenceImage: View {
    let artwork: ArtworkTarget

    var body: some View {
        if let targetAssetName = artwork.targetAssetName {
            Image(targetAssetName)
                .resizable()
        } else {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.18, green: 0.34, blue: 0.48),
                        Color(red: 0.56, green: 0.73, blue: 0.64),
                        Color(red: 0.94, green: 0.86, blue: 0.44)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(spacing: 10) {
                    Image(systemName: "photo.artframe")
                        .font(.system(size: 52, weight: .semibold))

                    Text(artwork.targetTitle)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .foregroundStyle(.white)
            }
        }
    }
}
