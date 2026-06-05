//
//  OnboardingView.swift
//  CapodimonteTreasureHunt
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var game: GameStore
    @FocusState private var isNameFocused: Bool
    @State private var pageIndex = 0

    private let pages: [IntroPage] = [
        IntroPage(
            assetName: "carlo-intro1",
            text: "Hello Explorer! I am Carlo di Borbone. Welcome to Museo di Capodimonte. What's your name?",
            textFrame: CGRect(x: 0.22, y: 0.10, width: 0.56, height: 0.22),
            fontSize: 15
        ),
        IntroPage(
            assetName: nil,
            text: "Enter your name!",
            textFrame: .zero,
            fontSize: 0
        ),
        IntroPage(
            assetName: "carlo-intro2",
            text: "My mother, Elisabetta Farnese left me an important message, but it got lost and now I need your help to find it!",
            textFrame: CGRect(x: 0.12, y: 0.15, width: 0.76, height: 0.22),
            fontSize: 14
        ),
        IntroPage(
            assetName: "carlo-intro3",
            text: "To find it, you'll need to look carefully at the paintings and scan the hidden details you discover along the way...",
            textFrame: CGRect(x: 0.17, y: 0.12, width: 0.66, height: 0.22),
            fontSize: 14
        ),
        IntroPage(
            assetName: "carlo-intro4",
            text: "...With this magic magnifying glass!",
            textFrame: CGRect(x: 0.17, y: 0.16, width: 0.66, height: 0.18),
            fontSize: 17
        ),
        IntroPage(
            assetName: "carlo-intro5",
            text: "Let me show you how it works...",
            textFrame: CGRect(x: 0.19, y: 0.16, width: 0.62, height: 0.18),
            fontSize: 14
        )
    ]

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
                HStack {
                    if pageIndex > 0 {
                        IntroBackButton {
                            withAnimation(.spring(response: 0.36, dampingFraction: 0.86)) {
                                pageIndex -= 1
                            }
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)

                Spacer()

                HStack {
                    Spacer()

                    IntroNextButton {
                        advance()
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            isNameFocused = pageIndex == 1
        }
        .onChange(of: pageIndex) { _, newValue in
            isNameFocused = newValue == 1
        }
    }

    private func advance() {
        if pageIndex == pages.count - 1 {
            isNameFocused = false
            game.finishIntro()
            return
        }

        withAnimation(.spring(response: 0.38, dampingFraction: 0.88)) {
            pageIndex += 1
        }
    }
}

private struct IntroPage {
    let assetName: String?
    let text: String
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

                Text(page.text)
                    .font(.system(size: page.fontSize, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.72)
                    .foregroundStyle(Color(red: 0.06, green: 0.05, blue: 0.05))
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

            TextField("Maria", text: $playerName)
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

private struct IntroBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color(red: 0.16, green: 0.14, blue: 0.12))
                .frame(width: 34, height: 34)
                .background(Circle().fill(.white.opacity(0.88)))
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back")
    }
}

private struct IntroNextButton: View {
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
