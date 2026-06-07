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
            PurpleGameBackground(raysOpacity: 0.22)

            if let artwork = game.artwork(with: artworkID), let mission = game.mission(containing: artworkID) {
                GeometryReader { proxy in
                    VStack(spacing: 0) {
                        Spacer(minLength: proxy.size.height * 0.18)

                        Text(artwork.unlockedWord.uppercased())
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

                        Spacer()

                        RewardCarloBubble(
                            boldLead: "Good job, Explorer!",
                            message: "You found the \(ordinalText(for: artwork.order)) word!"
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
    let artworkID: UUID

    var body: some View {
        ZStack {
            PurpleGameBackground(raysOpacity: 0.22)

            if let artwork = game.artwork(with: artworkID) {
                GeometryReader { proxy in
                    VStack(spacing: 0) {
                        Spacer(minLength: 28)

                        Text(artwork.title)
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 28)
                            .minimumScaleFactor(0.7)

                        Text("by \(artwork.artist)")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.top, 12)

                        FullArtworkImage(artwork: artwork)
                            .scaledToFill()
                            .frame(width: min(proxy.size.width * 0.62, 260), height: min(proxy.size.height * 0.46, 360))
                            .clipShape(RoundedRectangle(cornerRadius: 9))
                            .shadow(color: .black.opacity(0.24), radius: 20, y: 12)
                            .padding(.top, 28)

                        Spacer()

                        RewardCarloBubble(
                            boldLead: "Fun fact:",
                            message: artwork.artworkDescription
                        )
                        .padding(.horizontal, 22)
                        .padding(.bottom, 22)

                        RewardNextButton {
                            game.continueAfterArtworkReveal(for: artwork)
                        }
                        .padding(.bottom, 28)
                    }
                    .frame(width: proxy.size.width, height: proxy.size.height)
                }
            } else {
                ContentUnavailableView("Artwork not found", systemImage: "questionmark.circle")
            }
        }
        .navigationBarBackButtonHidden()
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
        ZStack {
            Circle()
                .fill(Color(red: 0.96, green: 0.70, blue: 0.06))

            Circle()
                .fill(Color(red: 1.0, green: 0.92, blue: 0.82))
                .frame(width: 42, height: 42)
                .offset(y: -3)

            Circle()
                .fill(Color(red: 1.0, green: 0.66, blue: 0.36))
                .frame(width: 31, height: 31)
                .offset(y: 2)

            HStack(spacing: 8) {
                Capsule()
                    .fill(Color(red: 0.02, green: 0.05, blue: 0.08))
                    .frame(width: 5, height: 13)

                Capsule()
                    .fill(Color(red: 0.02, green: 0.05, blue: 0.08))
                    .frame(width: 5, height: 13)
            }
            .offset(y: -1)

            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.02, green: 0.28, blue: 0.78))
                .frame(width: 28, height: 18)
                .offset(y: 28)
        }
    }
}

private struct RewardNextButton: View {
    let action: () -> Void

    var body: some View {
        GoldCircleButton(systemImage: "chevron.right", accessibilityLabel: "Continue", action: action)
    }
}

private struct FullArtworkImage: View {
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
                WordRevealView(artworkID: PreviewSupport.firstArtwork.id)
            }
            .environmentObject(PreviewSupport.game)
            .previewDisplayName("Word Reveal")

            NavigationStack {
                ArtworkRevealView(artworkID: PreviewSupport.firstArtwork.id)
            }
            .environmentObject(PreviewSupport.game)
            .previewDisplayName("Artwork Reveal")

            ZStack {
                PurpleGameBackground()

                PhraseProgressView(slots: ["THE", nil, "SECRET", nil, "WORD"])
                    .padding(24)
            }
            .previewDisplayName("Phrase Progress")
        }
    }
}
