//
//  ContentView.swift
//  CapodimonteTreasureHunt
//
//  Created by AFP FED 003 on 29/05/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var game: GameStore

    var body: some View {
        NavigationStack(path: $game.path) {
            HomeView()
                .navigationDestination(for: GameRoute.self) { route in
                    switch route {
                    case .intro:
                        OnboardingView()
                    case .gallery:
                        MissionGalleryView()
                    case .mission(let missionID):
                        MissionDetailView(missionID: missionID)
                    case .target(let artworkID):
                        TargetDetailView(artworkID: artworkID)
                    case .scanner(let artworkID):
                        ARScannerView(artworkID: artworkID)
                    case .wordReveal(let artworkID):
                        WordRevealView(artworkID: artworkID)
                    case .artworkReveal(let artworkID):
                        ArtworkRevealView(artworkID: artworkID)
                    case .completion(let missionID):
                        CompletionView(missionID: missionID)
                    }
                }
        }
    }
}

private struct HomeView: View {
    @EnvironmentObject private var game: GameStore

    var body: some View {
        ZStack {
            HomeBackground()

            GeometryReader { proxy in
                let width = proxy.size.width
                let artSize = min(width * 1.34, 560)

                VStack(spacing: 0) {
                    Text("Carlo's\nTreasure\nHunt")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .multilineTextAlignment(.center)
                        .lineSpacing(-2)
                        .foregroundStyle(Color(red: 1.0, green: 0.94, blue: 0.82))
                        .shadow(color: .black.opacity(0.16), radius: 8, y: 5)
                        .padding(.top, 42)
                        .minimumScaleFactor(0.72)

                    Spacer(minLength: 8)

                    ZStack {
                        Circle()
                            .fill(Color(red: 1.0, green: 0.93, blue: 0.80))
                            .frame(width: artSize * 0.56, height: artSize * 0.56)
                            .offset(x: artSize * 0.12, y: -artSize * 0.06)

                        HomeCarloPlaceholder()
                            .frame(width: artSize, height: artSize * 0.88)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, -28)

                    HomeActions(showGallery: game.hasAnyProgress)
                        .padding(.bottom, 30)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct HomeActions: View {
    @EnvironmentObject private var game: GameStore
    let showGallery: Bool

    var body: some View {
        HStack(spacing: showGallery ? 18 : 0) {
            HomeCircleButton(title: "PLAY", systemImage: "play.fill") {
                game.startHunt()
            }

            if showGallery {
                HomeCircleButton(title: "GALLERY", systemImage: "photo.on.rectangle.angled") {
                    game.openGallery()
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct HomeCircleButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 28, weight: .bold))

                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }
            .foregroundStyle(Color(red: 0.30, green: 0.23, blue: 0.06))
            .frame(width: 92, height: 92)
            .background(
                Circle()
                    .fill(Color(red: 1.0, green: 0.75, blue: 0.02))
                    .shadow(color: Color(red: 0.50, green: 0.22, blue: 0.0).opacity(0.28), radius: 9, y: 5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

private struct HomeBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.42, green: 0.25, blue: 0.78),
                Color(red: 0.10, green: 0.18, blue: 0.56),
                Color(red: 0.02, green: 0.20, blue: 0.76)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay {
            SparkleField()
                .opacity(0.55)
        }
        .ignoresSafeArea()
    }
}

private struct HomeCarloPlaceholder: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(red: 0.10, green: 0.12, blue: 0.16), lineWidth: 12)
                .frame(width: 250, height: 250)
                .rotationEffect(.degrees(-8))
                .offset(x: -12, y: -46)

            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.10, green: 0.12, blue: 0.16))
                .frame(width: 22, height: 150)
                .rotationEffect(.degrees(-34))
                .offset(x: -116, y: 118)

            Circle()
                .fill(Color(red: 1.0, green: 0.67, blue: 0.36))
                .frame(width: 206, height: 206)
                .overlay(alignment: .topLeading) {
                    Circle()
                        .fill(.white.opacity(0.25))
                        .frame(width: 74, height: 74)
                        .offset(x: 28, y: 18)
                }
                .offset(x: -14, y: -48)

            HStack(spacing: 62) {
                Capsule()
                    .fill(Color(red: 0.02, green: 0.05, blue: 0.08))
                    .frame(width: 26, height: 58)

                Capsule()
                    .fill(Color(red: 0.02, green: 0.05, blue: 0.08))
                    .frame(width: 30, height: 70)
            }
            .offset(x: -8, y: -55)

            Capsule()
                .fill(Color(red: 0.99, green: 0.92, blue: 0.80))
                .frame(width: 300, height: 106)
                .offset(x: -8, y: -164)

            RoundedRectangle(cornerRadius: 34)
                .fill(Color(red: 0.02, green: 0.28, blue: 0.78))
                .frame(width: 254, height: 220)
                .overlay(alignment: .trailing) {
                    Rectangle()
                        .fill(Color(red: 0.94, green: 0.12, blue: 0.09))
                        .frame(width: 54)
                }
                .clipShape(RoundedRectangle(cornerRadius: 34))
                .offset(x: 62, y: 188)

            Circle()
                .fill(Color(red: 1.0, green: 0.78, blue: 0.02))
                .frame(width: 28, height: 28)
                .offset(x: 72, y: 146)

            Circle()
                .fill(Color(red: 1.0, green: 0.78, blue: 0.02))
                .frame(width: 20, height: 20)
                .offset(x: 112, y: 188)
        }
    }
}

private struct SparkleField: View {
    private let sparkles: [(x: CGFloat, y: CGFloat, size: CGFloat)] = [
        (0.12, 0.17, 7), (0.86, 0.12, 5), (0.22, 0.33, 4),
        (0.74, 0.39, 7), (0.13, 0.55, 5), (0.89, 0.61, 4),
        (0.20, 0.78, 7), (0.78, 0.82, 5), (0.50, 0.20, 4)
    ]

    var body: some View {
        GeometryReader { proxy in
            ForEach(sparkles.indices, id: \.self) { index in
                let sparkle = sparkles[index]

                Image(systemName: "sparkle")
                    .font(.system(size: sparkle.size, weight: .bold))
                    .foregroundStyle(Color(red: 1.0, green: 0.95, blue: 0.78))
                    .position(
                        x: proxy.size.width * sparkle.x,
                        y: proxy.size.height * sparkle.y
                    )
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(GameStore())
    }
}
