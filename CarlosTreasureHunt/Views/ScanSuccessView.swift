//
//  ScanSuccessView.swift
//  CarlosTreasureHunt
//

import SwiftUI

struct DetailFoundView: View {
    @EnvironmentObject private var game: GameStore
    let artworkID: UUID

    var body: some View {
        ZStack {
            if
                let artwork = game.artwork(with: artworkID),
                game.isUnlocked(artwork)
            {
                GeometryReader { proxy in
                    let compact = proxy.size.height < 760
                    let lensDiameter = min(proxy.size.width * 1.42, proxy.size.height * 0.76)
                    let lensCenterY = proxy.size.height * 0.47

                    ZStack {
                        detailImage(for: artwork)
                            .scaledToFill()
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .clipped()

                        LinearGradient(
                            colors: [
                                Color(red: 0.24, green: 0.15, blue: 0.64).opacity(0.78),
                                Color(red: 0.12, green: 0.18, blue: 0.50).opacity(0.72),
                                Color(red: 0.38, green: 0.22, blue: 0.72).opacity(0.80)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )

                        Circle()
                            .stroke(
                                Color(red: 0.72, green: 0.63, blue: 0.87).opacity(0.42),
                                lineWidth: compact ? 38 : 46
                            )
                            .frame(width: lensDiameter, height: lensDiameter)
                            .position(x: proxy.size.width / 2, y: lensCenterY)

                        Capsule()
                            .fill(Color(red: 0.72, green: 0.63, blue: 0.87).opacity(0.42))
                            .frame(width: compact ? 48 : 58, height: proxy.size.height * 0.28)
                            .rotationEffect(.degrees(32))
                            .position(
                                x: proxy.size.width * 0.12,
                                y: lensCenterY + lensDiameter * 0.50
                            )

                        VStack(spacing: compact ? 22 : 30) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: compact ? 150 : 185, weight: .black))
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(
                                    Color(red: 0.20, green: 0.17, blue: 0.38),
                                    GameTheme.goldGradient
                                )
                                .shadow(color: GameTheme.gold.opacity(0.22), radius: 22, y: 10)

                            Text("Detail Found!")
                                .font(.system(
                                    size: compact ? 42 : 50,
                                    weight: .black,
                                    design: .rounded
                                ))
                                .foregroundStyle(.white)
                                .minimumScaleFactor(0.72)
                                .lineLimit(1)
                        }
                        .position(
                            x: proxy.size.width / 2,
                            y: proxy.size.height * (compact ? 0.46 : 0.45)
                        )

                        detailImage(for: artwork)
                            .scaledToFill()
                            .frame(width: compact ? 96 : 112, height: compact ? 96 : 112)
                            .clipShape(Circle())
                            .overlay {
                                Circle()
                                    .stroke(
                                        Color(red: 0.55, green: 0.42, blue: 0.84).opacity(0.72),
                                        lineWidth: 6
                                    )
                            }
                            .position(
                                x: proxy.size.width / 2,
                                y: min(
                                    proxy.size.height * 0.79,
                                    lensCenterY + lensDiameter * 0.48
                                )
                            )

                        VStack {
                            Spacer()

                            GoldCircleButton(
                                systemImage: "chevron.right",
                                accessibilityLabel: "Continue"
                            ) {
                                game.continueAfterDetailFound(for: artwork)
                            }
                            .padding(.bottom, compact ? 14 : 24)
                        }
                    }
                    .frame(width: proxy.size.width, height: proxy.size.height)
                }
            } else {
                ContentUnavailableView("Detail not found", systemImage: "questionmark.circle")
            }
        }
        .background(GameTheme.deepPurple)
        .ignoresSafeArea()
        .navigationBarBackButtonHidden()
    }

    @ViewBuilder
    private func detailImage(for artwork: ArtworkTarget) -> some View {
        if let targetAssetName = artwork.targetAssetName {
            Image(targetAssetName)
                .resizable()
        } else {
            Color(red: 0.18, green: 0.16, blue: 0.38)
        }
    }
}

struct WordRevealView: View {
    @EnvironmentObject private var game: GameStore
    let artworkID: UUID

    var body: some View {
        ZStack {
            PurpleGameBackground(raysOpacity: 0.22)

            if
                let artwork = game.artwork(with: artworkID),
                let mission = game.mission(containing: artworkID),
                game.isUnlocked(artwork)
            {
                GeometryReader { proxy in
                    ZStack {
                        Text(game.unlockedWord(for: artwork).uppercased())
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundStyle(Color(red: 0.55, green: 0.35, blue: 0.02))
                            .minimumScaleFactor(0.64)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(GameTheme.goldGradient)
                                    .shadow(color: Color(red: 0.96, green: 0.74, blue: 0.20).opacity(0.42), radius: 24, y: 10)
                            )
                            .position(
                                x: proxy.size.width / 2,
                                y: proxy.size.height / 2
                            )

                        VStack(spacing: 0) {
                            Spacer()

                            RewardCarloBubble(
                                boldLead: "Good job, \(game.displayName)!",
                                message: "You found the \(ordinalText(for: game.unlockedWordPosition(for: artwork))) word!"
                            )
                            .padding(.horizontal, 22)
                            .padding(.bottom, 18)

                            PhraseProgressView(slots: game.phraseSlots(for: mission))
                                .padding(.horizontal, 24)
                                .padding(.bottom, 28)

                            RewardNextButton {
                                game.continueAfterWordReveal(for: artwork)
                            }
                            .padding(.bottom, 28)
                        }
                    }
                    .frame(width: proxy.size.width, height: proxy.size.height)
                }
            } else {
                ContentUnavailableView("Word not found", systemImage: "questionmark.circle")
            }
        }
        .navigationBarBackButtonHidden()
    }

    private func ordinalText(for order: Int) -> String {
        switch order {
        case 1:
            return "first"
        case 2:
            return "second"
        case 3:
            return "third"
        case 4:
            return "fourth"
        default:
            return "fifth"
        }
    }
}

struct ArtworkRevealView: View {
    @EnvironmentObject private var game: GameStore
    @State private var showsFullScreenArtwork = false
    let artworkID: UUID
    var continuesToWordReveal = true

    var body: some View {
        ZStack {
            PurpleGameBackground(raysOpacity: 0.22)

            if
                let artwork = game.artwork(with: artworkID),
                game.isUnlocked(artwork)
            {
                GeometryReader { proxy in
                    let compact = proxy.size.height < 760
                    let imageHeight = min(
                        proxy.size.height * (compact ? 0.25 : 0.31),
                        compact ? 190 : 270
                    )
                    let buttonAreaHeight: CGFloat = compact ? 82 : 96

                    VStack(spacing: 0) {
                        VStack(spacing: compact ? 8 : 12) {
                            Text(artwork.title)
                                .font(.system(
                                    size: compact ? 21 : 24,
                                    weight: .black,
                                    design: .rounded
                                ))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white)
                                .lineLimit(3)
                                .minimumScaleFactor(0.7)
                                .padding(.horizontal, 24)

                            Text("by \(artwork.artist)")
                                .font(.system(
                                    size: compact ? 12 : 13,
                                    weight: .black,
                                    design: .rounded
                                ))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                                .minimumScaleFactor(0.75)
                                .padding(.horizontal, 24)

                            Button {
                                showsFullScreenArtwork = true
                            } label: {
                                FullArtworkImage(artwork: artwork)
                                    .scaledToFit()
                                    .frame(
                                        maxWidth: min(proxy.size.width - 48, 340),
                                        maxHeight: imageHeight
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .shadow(color: .black.opacity(0.24), radius: 20, y: 12)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("View \(artwork.title) full screen")

                            RewardCarloBubble(
                                boldLead: "Fun fact:",
                                message: artwork.artworkDescription
                            )
                            .padding(.horizontal, compact ? 16 : 22)
                        }
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: .center
                        )

                        RewardNextButton {
                            if continuesToWordReveal {
                                game.continueAfterArtworkReveal(for: artwork)
                            } else {
                                game.finishReopenedArtwork(for: artwork)
                            }
                        }
                        .frame(height: buttonAreaHeight)
                    }
                    .frame(width: proxy.size.width, height: proxy.size.height)
                }
                .fullScreenCover(isPresented: $showsFullScreenArtwork) {
                    FullScreenArtworkViewer(artwork: artwork)
                        .presentationBackground(.clear)
                }
            } else {
                ContentUnavailableView("Artwork not found", systemImage: "questionmark.circle")
            }
        }
        .navigationBarBackButtonHidden()
    }
}

struct FullScreenArtworkViewer: View {
    @Environment(\.dismiss) private var dismiss
    @State private var zoomScale: CGFloat = 1
    @State private var lastZoomScale: CGFloat = 1
    @State private var panOffset: CGSize = .zero
    @State private var lastPanOffset: CGSize = .zero
    @State private var dismissalOffset: CGSize = .zero
    @State private var isDismissing = false
    @State private var isChromeVisible = true

    let artwork: ArtworkTarget

    private var dragDistance: CGFloat {
        hypot(dismissalOffset.width, dismissalOffset.height)
    }

    private var dismissalScale: CGFloat {
        max(0.82, 1 - dragDistance / 1_100)
    }

    private var backdropOpacity: Double {
        max(0, 1 - Double(dragDistance / 430))
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black
                    .opacity(backdropOpacity)
                    .ignoresSafeArea()

                FullArtworkImage(artwork: artwork)
                    .scaledToFit()
                    .frame(
                        maxWidth: max(0, proxy.size.width - 24),
                        maxHeight: max(0, proxy.size.height - 48)
                    )
                    .scaleEffect(zoomScale * dismissalScale)
                    .offset(
                        x: panOffset.width + dismissalOffset.width,
                        y: panOffset.height + dismissalOffset.height
                    )
                    .gesture(dragGesture(in: proxy.size))
                    .simultaneousGesture(zoomGesture)
                    .onTapGesture(count: 2) {
                        toggleZoom()
                    }
                    .accessibilityAction(.escape) {
                        dismissWithFade()
                    }

                VStack {
                    HStack {
                        AppBackButton(
                            foregroundColor: .white,
                            backgroundColor: .black.opacity(0.42)
                        ) {
                            dismissWithFade()
                        }

                        Spacer()
                    }

                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.top, 6)
                .opacity(isChromeVisible ? max(0, 1 - dragDistance / 90) : 0)
            }
            .contentShape(Rectangle())
        }
        .statusBarHidden()
    }

    private var zoomGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                guard !isDismissing else {
                    return
                }

                zoomScale = min(max(lastZoomScale * value.magnification, 1), 5)
            }
            .onEnded { _ in
                lastZoomScale = zoomScale

                if zoomScale <= 1.01 {
                    resetZoom()
                }
            }
    }

    private func dragGesture(in viewportSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .global)
            .onChanged { value in
                guard !isDismissing else {
                    return
                }

                if zoomScale > 1.01 {
                    panOffset = CGSize(
                        width: lastPanOffset.width + value.translation.width,
                        height: lastPanOffset.height + value.translation.height
                    )
                } else {
                    dismissalOffset = value.translation
                }
            }
            .onEnded { value in
                if zoomScale > 1.01 {
                    lastPanOffset = panOffset
                    return
                }

                let predictedDistance = hypot(
                    value.predictedEndTranslation.width,
                    value.predictedEndTranslation.height
                )

                guard dragDistance > 120 || predictedDistance > 220 else {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                        dismissalOffset = .zero
                    }
                    return
                }

                isDismissing = true
                withAnimation(.easeOut(duration: 0.12)) {
                    isChromeVisible = false
                }
                let direction = dismissalDirection(
                    translation: value.predictedEndTranslation,
                    fallback: value.translation
                )
                let travel = max(viewportSize.width, viewportSize.height) * 1.25

                withAnimation(.easeIn(duration: 0.20)) {
                    dismissalOffset = CGSize(
                        width: direction.width * travel,
                        height: direction.height * travel
                    )
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
                    dismiss()
                }
            }
    }

    private func toggleZoom() {
        guard !isDismissing else {
            return
        }

        if zoomScale > 1.01 {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                resetZoom()
            }
        } else {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                zoomScale = 2.5
                lastZoomScale = 2.5
            }
        }
    }

    private func resetZoom() {
        zoomScale = 1
        lastZoomScale = 1
        panOffset = .zero
        lastPanOffset = .zero
    }

    private func dismissWithFade() {
        guard !isDismissing else {
            return
        }

        isDismissing = true
        withAnimation(.easeOut(duration: 0.16)) {
            isChromeVisible = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            dismiss()
        }
    }

    private func dismissalDirection(translation: CGSize, fallback: CGSize) -> CGSize {
        let candidate = hypot(translation.width, translation.height) > 1 ? translation : fallback
        let magnitude = max(hypot(candidate.width, candidate.height), 1)

        return CGSize(
            width: candidate.width / magnitude,
            height: candidate.height / magnitude
        )
    }
}

struct PhraseProgressView: View {
    let slots: [String?]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(slots.enumerated()), id: \.offset) { _, word in
                Text(word ?? "...")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(word == nil ? Color(red: 0.52, green: 0.50, blue: 0.56) : .white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
                    .frame(maxWidth: .infinity, minHeight: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .fill(word == nil ? Color.white.opacity(0.90) : GameTheme.wordGreen)
                    )
            }
        }
    }
}

private struct RewardCarloBubble: View {
    let boldLead: String
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            CarloBadge()
                .frame(width: 58, height: 58)

            Text(attributedMessage)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(GameTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(GameTheme.cream)
                )
        }
    }

    private var attributedMessage: AttributedString {
        var result = AttributedString("\(boldLead) \(message)")
        if let range = result.range(of: boldLead) {
            result[range].font = .system(size: 13, weight: .black, design: .rounded)
        }
        return result
    }
}

private struct CarloBadge: View {
    var body: some View {
        Image("carlo-finger")
            .resizable()
            .scaledToFill()
            .frame(width: 58, height: 58)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(Color(red: 1.0, green: 0.78, blue: 0.18), lineWidth: 3)
            }
            .background {
                Circle()
                    .fill(Color(red: 0.96, green: 0.70, blue: 0.06))
            }
            .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
    }
}

private struct RewardNextButton: View {
    let action: () -> Void

    var body: some View {
        GoldCircleButton(systemImage: "chevron.right", accessibilityLabel: "Continue", action: action)
    }
}

struct FullArtworkImage: View {
    let artwork: ArtworkTarget

    var body: some View {
        if let imageAssetName = artwork.imageAssetName {
            Image(imageAssetName)
                .resizable()
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

                    Text("Artwork")
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

struct ScanSuccessView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationStack {
                DetailFoundView(artworkID: PreviewSupport.firstArtwork.id)
            }
            .environmentObject(PreviewSupport.inProgressGame)
            .previewDisplayName("Detail Found")

            NavigationStack {
                WordRevealView(artworkID: PreviewSupport.firstArtwork.id)
            }
            .environmentObject(PreviewSupport.inProgressGame)
            .previewDisplayName("Word Reveal")

            NavigationStack {
                ArtworkRevealView(artworkID: PreviewSupport.firstArtwork.id)
            }
            .environmentObject(PreviewSupport.inProgressGame)
            .previewDisplayName("Artwork Reveal")

            FullScreenArtworkViewer(artwork: PreviewSupport.firstArtwork)
                .previewDisplayName("Full Screen Artwork")

            ZStack {
                PurpleGameBackground()

                PhraseProgressView(slots: ["THE", nil, "SECRET", nil, "WORD"])
                    .padding(24)
            }
            .previewDisplayName("Phrase Progress")
        }
    }
}
