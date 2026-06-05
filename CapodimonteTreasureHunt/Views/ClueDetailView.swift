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
    @State private var tutorialPhase: TargetTutorialPhase = .find
    let artworkID: UUID

    var body: some View {
        ZStack {
            if let artwork = game.artwork(with: artworkID) {
                TargetReferenceSurface(artwork: artwork)
                    .ignoresSafeArea()

                TargetReferenceOverlay(
                    artwork: artwork,
                    tutorialPhase: tutorialPhase,
                    advanceTutorial: advanceTutorial
                ) {
                    game.openScanner(for: artwork)
                }
                .ignoresSafeArea()
            } else {
                GameBackground()
                ContentUnavailableView("Target not found", systemImage: "questionmark.circle")
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func advanceTutorial() {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
            switch tutorialPhase {
            case .find:
                tutorialPhase = .camera
            case .camera:
                tutorialPhase = .ready
            case .ready:
                break
            }
        }
    }
}

private enum TargetTutorialPhase {
    case find
    case camera
    case ready
}

private struct TargetReferenceSurface: View {
    let artwork: ArtworkTarget

    var body: some View {
        ZStack {
            TargetReferenceImage(artwork: artwork)
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .blur(radius: 18)
                .opacity(0.24)

            LinearGradient(
                colors: [
                    Color(red: 0.20, green: 0.18, blue: 0.54).opacity(0.96),
                    Color(red: 0.18, green: 0.16, blue: 0.44).opacity(0.92),
                    Color(red: 0.36, green: 0.23, blue: 0.74).opacity(0.88)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

private struct TargetReferenceOverlay: View {
    let artwork: ArtworkTarget
    let tutorialPhase: TargetTutorialPhase
    let advanceTutorial: () -> Void
    let openCameraAction: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let lensSize = min(proxy.size.width * 1.08, proxy.size.height * 0.56)
            let lensCenterY = proxy.size.height * 0.46
            let buttonSize: CGFloat = 76
            let buttonCenterY = lensCenterY + (lensSize / 2) - (buttonSize * 0.18)

            ZStack {
                TargetReferenceImage(artwork: artwork)
                    .scaledToFill()
                    .frame(width: lensSize * 0.86, height: lensSize * 0.86)
                    .clipShape(Circle())
                    .overlay {
                        if tutorialPhase != .ready {
                            Color(red: 0.14, green: 0.12, blue: 0.44)
                                .opacity(0.22)
                                .clipShape(Circle())
                        }
                    }
                    .position(x: proxy.size.width / 2, y: lensCenterY)

                YellowLensChrome(lensSize: lensSize, lensCenterY: lensCenterY)
                    .allowsHitTesting(false)

                TargetCameraButton(
                    isHighlighted: tutorialPhase == .camera,
                    action: openCameraAction
                )
                .frame(width: buttonSize, height: buttonSize)
                .position(x: proxy.size.width / 2, y: buttonCenterY)
                .disabled(tutorialPhase == .find)
                .opacity(tutorialPhase == .find ? 0.42 : 1)

                if tutorialPhase == .find {
                    FindElementStar {
                        advanceTutorial()
                    }
                    .frame(width: min(proxy.size.width * 0.96, 410))
                    .position(x: proxy.size.width / 2, y: lensCenterY)
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
                }

                if tutorialPhase == .camera {
                    CameraInstructionBubble {
                        advanceTutorial()
                    }
                    .frame(width: min(proxy.size.width - 48, 300))
                    .position(x: proxy.size.width / 2, y: proxy.size.height * 0.50)
                    .transition(.scale(scale: 0.94).combined(with: .opacity))
                }
            }
        }
    }
}

private struct FindElementStar: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Image("star")
                    .resizable()
                    .scaledToFit()

                Text("Find and frame\nthis element!")
                    .font(.system(size: 25, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color(red: 0.13, green: 0.16, blue: 0.60))
                    .minimumScaleFactor(0.72)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Find and frame this element")
    }
}

private struct CameraInstructionBubble: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Tap this button to open\nthe camera and scan\nthe hidden detail.")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(red: 0.05, green: 0.04, blue: 0.04))
                .padding(.horizontal, 24)
                .padding(.vertical, 28)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 1.0, green: 0.95, blue: 0.88))
                        .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Tap this button to open the camera and scan the hidden detail")
    }
}

private struct TargetCameraButton: View {
    let isHighlighted: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.66, green: 0.58, blue: 0.96),
                                Color(red: 0.33, green: 0.28, blue: 0.72)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(red: 0.75, green: 0.68, blue: 1.0).opacity(isHighlighted ? 0.72 : 0.28), radius: isHighlighted ? 24 : 10, y: 8)

                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 31, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open camera")
    }
}

private struct YellowLensChrome: View {
    let lensSize: CGFloat
    let lensCenterY: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let centerX = proxy.size.width / 2
            let handleWidth = lensSize * 0.18
            let handleHeight = lensSize * 0.54

            ZStack {
                Capsule()
                    .fill(lensGradient)
                    .frame(width: handleWidth, height: handleHeight)
                    .rotationEffect(.degrees(34))
                    .shadow(color: Color(red: 0.64, green: 0.47, blue: 0.08).opacity(0.32), radius: 14)
                    .position(x: centerX - lensSize * 0.43, y: lensCenterY + lensSize * 0.54)

                Circle()
                    .strokeBorder(lensGradient, lineWidth: 20)
                    .frame(width: lensSize, height: lensSize)
                    .shadow(color: Color(red: 0.64, green: 0.47, blue: 0.08).opacity(0.34), radius: 16)
                    .position(x: centerX, y: lensCenterY)

                Circle()
                    .strokeBorder(Color.white.opacity(0.30), lineWidth: 3)
                    .frame(width: lensSize - 18, height: lensSize - 18)
                    .position(x: centerX, y: lensCenterY)
            }
        }
    }

    private var lensGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.88, blue: 0.32),
                Color(red: 0.96, green: 0.65, blue: 0.06)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
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
