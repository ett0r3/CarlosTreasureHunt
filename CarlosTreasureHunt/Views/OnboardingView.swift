//
//  OnboardingView.swift
//  CarlosTreasureHunt
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var game: GameStore
    @FocusState private var isNameFocused: Bool
    @State private var pageIndex: Int

    private var pages: [IntroPage] {
        [
            IntroPage(
                assetName: "carlo-intro1",
                text: "Hello! I am Carlo Di Borbone.\nWelcome to Museo di Capodimonte.\nWhat's your name?",
                boldPhrases: ["Carlo Di Borbone"],
                textFrame: CGRect(x: 0.22, y: 0.085, width: 0.56, height: 0.22),
                fontSize: 20
            ),
            IntroPage(
                assetName: nil,
                text: "Enter your name!",
                boldPhrases: [],
                textFrame: .zero,
                fontSize: 0
            ),
            IntroPage(
                assetName: "carlo-intro2",
                text: "My mother,\nElisabetta Farnese,\nleft me important messages, but they got lost. \(game.displayName),\nI need your help\nto find them!",
                boldPhrases: [
                    "Elisabetta Farnese",
                    "important messages",
                    game.displayName
                ],
                textFrame: CGRect(x: 0.22, y: 0.08, width: 0.56, height: 0.22),
                fontSize: 20
            ),
            IntroPage(
                assetName: "carlo-intro3",
                text: "To find them, you'll need to look carefully at the paintings and scan the hidden details you discover along the way...",
                boldPhrases: ["scan the hidden details"],
                textFrame: CGRect(x: 0.22, y: 0.095, width: 0.56, height: 0.22),
                fontSize: 20
            ),
            IntroPage(
                assetName: "carlo-intro4",
                text: "...With this magic\nmagnifying glass!",
                boldPhrases: ["magnifying glass!"],
                textFrame: CGRect(x: 0.22, y: 0.12, width: 0.56, height: 0.22),
                fontSize: 20
            ),
            IntroPage(
                assetName: "carlo-intro5",
                text: "So, \(game.displayName),\nlet me show you\nhow it works...",
                boldPhrases: [game.displayName],
                textFrame: CGRect(x: 0.22, y: 0.09, width: 0.56, height: 0.22),
                fontSize: 20
            )
        ]
    }

    init(initialPageIndex: Int = 0) {
        _pageIndex = State(initialValue: min(max(initialPageIndex, 0), 5))
    }

    var body: some View {
        ZStack {
            IntroBackground()

            if pageIndex == 1 {
                NameEntryPage(playerName: $game.playerName, isFocused: $isNameFocused)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                IntroArtworkPage(page: pages[pageIndex])
                    .transition(.opacity.combined(with: .scale(scale: 1.02)))
            }

            VStack {
                Spacer()

                IntroNextButton(isEnabled: canAdvance) {
                    advance()
                }
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if pageIndex > 0 {
                    Button {
                        withAnimation(.spring(response: 0.36, dampingFraction: 0.86)) {
                            pageIndex -= 1
                        }
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                            .labelStyle(.iconOnly)
                    }
                    .tint(Color(red: 0.16, green: 0.14, blue: 0.12))
                }
            }
        }
        .onAppear {
            isNameFocused = pageIndex == 1
        }
        .onChange(of: pageIndex) { _, newValue in
            isNameFocused = newValue == 1
        }
    }

    private func advance() {
        guard canAdvance else {
            return
        }

        if pageIndex == pages.count - 1 {
            isNameFocused = false
            game.finishIntro()
            return
        }

        withAnimation(.spring(response: 0.38, dampingFraction: 0.88)) {
            pageIndex += 1
        }
    }

    private var canAdvance: Bool {
        pageIndex != 1 ||
            !game.playerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

private struct IntroPage {
    let assetName: String?
    let text: String
    let boldPhrases: [String]
    let textFrame: CGRect
    let fontSize: CGFloat
}

private struct IntroArtworkPage: View {
    let page: IntroPage

    var body: some View {
        GeometryReader { proxy in
            if let assetName = page.assetName {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)

                TypewriterBubbleText(
                    text: page.text,
                    boldPhrases: page.boldPhrases,
                    fontSize: page.fontSize
                )
                    .padding(.horizontal, 8)
                    .frame(
                        width: proxy.size.width * page.textFrame.width,
                        height: proxy.size.height * page.textFrame.height
                    )
                    .position(
                        x: proxy.size.width * (page.textFrame.minX + page.textFrame.width / 2),
                        y: proxy.size.height * (page.textFrame.minY + page.textFrame.height / 2)
                    )
            }
        }
        .ignoresSafeArea()
    }
}

struct TypewriterBubbleText: View {
    let text: String
    var boldPhrases: [String] = []
    let fontSize: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var visibleCharacterCount = 0

    private let ink = Color(red: 0.06, green: 0.05, blue: 0.05)

    private var animatedText: AttributedString {
        var result = AttributedString(text)
        result.foregroundColor = ink

        for phrase in boldPhrases {
            guard let range = result.range(of: phrase) else {
                continue
            }

            result[range].font = .system(
                size: fontSize,
                weight: .black,
                design: .rounded
            )
        }

        let hiddenStart = result.characters.index(
            result.startIndex,
            offsetBy: min(visibleCharacterCount, result.characters.count)
        )
        if hiddenStart < result.endIndex {
            result[hiddenStart..<result.endIndex].foregroundColor = .clear
        }

        return result
    }

    var body: some View {
        Text(animatedText)
            .font(.system(size: fontSize, weight: .semibold, design: .rounded))
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.72)
            .accessibilityLabel(text)
            .task(id: text) {
                visibleCharacterCount = reduceMotion ? text.count : 0
                guard !reduceMotion else { return }

                let characters = Array(text)
                for index in characters.indices {
                    guard !Task.isCancelled else { return }
                    visibleCharacterCount = index + 1

                    let pause: UInt64 = characters[index].isTypewriterPunctuation
                        ? 72_000_000
                        : 24_000_000
                    try? await Task.sleep(nanoseconds: pause)
                }
            }
    }
}

private extension Character {
    var isTypewriterPunctuation: Bool {
        ".,!?;:…".contains(self)
    }
}

private struct NameEntryPage: View {
    @Binding var playerName: String
    @FocusState.Binding var isFocused: Bool

    var body: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 82)

            Text("Enter your name!")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.04, green: 0.04, blue: 0.04))
                .multilineTextAlignment(.center)

            TextField("Your Name", text: $playerName)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .focused($isFocused)
                .font(.system(size: 42, weight: .black, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(red: 0.05, green: 0.04, blue: 0.04))
                .padding(.horizontal, 22)
                .frame(height: 104)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.74))
                )
                .padding(.horizontal, 28)

            Spacer()
        }
        .padding(.horizontal, 18)
    }
}

private struct IntroNextButton: View {
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.right")
                .font(.system(size: 25, weight: .black))
                .foregroundStyle(Color(red: 0.47, green: 0.28, blue: 0.0))
                .frame(width: 66, height: 66)
                .background(
                    Circle()
                        .fill(Color(red: 1.0, green: 0.74, blue: 0.0))
                        .shadow(color: Color(red: 0.62, green: 0.32, blue: 0.0).opacity(0.22), radius: 9, y: 5)
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
        .accessibilityLabel("Continue")
    }
}

private struct IntroBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.98, green: 0.90, blue: 0.77),
                Color(red: 0.95, green: 0.85, blue: 0.68)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            onboardingPreview(page: 0, name: "A-2")
            onboardingPreview(page: 1, name: "A-3 Name")
            onboardingPreview(page: 2, name: "A-4")
            onboardingPreview(page: 3, name: "A-5")
            onboardingPreview(page: 4, name: "A-6")
            onboardingPreview(page: 5, name: "A-7")
        }
    }

    private static func onboardingPreview(page: Int, name: String) -> some View {
        NavigationStack {
            OnboardingView(initialPageIndex: page)
        }
        .environmentObject(PreviewSupport.game)
        .previewDisplayName(name)
    }
}
