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
                        ARScannerView(
                            artworkID: artworkID,
                            showsTutorial: game.shouldShowScannerTutorial
                        )
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
    @State private var showsResetConfirmation = false

    var body: some View {
        ZStack {
            Color(red: 0.10, green: 0.18, blue: 0.56)
                .ignoresSafeArea()

            GeometryReader { proxy in
                let fullWidth = proxy.size.width + proxy.safeAreaInsets.leading + proxy.safeAreaInsets.trailing
                let fullHeight = proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom

                Image("carlo-intro0")
                    .resizable()
                    .scaledToFill()
                    .frame(width: fullWidth, height: fullHeight)
                    .clipped()
                    .position(
                        x: (proxy.size.width + proxy.safeAreaInsets.trailing - proxy.safeAreaInsets.leading) / 2,
                        y: (proxy.size.height + proxy.safeAreaInsets.bottom - proxy.safeAreaInsets.top) / 2
                    )

                VStack(spacing: 0) {
                    Text("Carlo's\nTreasure\nHunt")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .multilineTextAlignment(.center)
                        .lineSpacing(-2)
                        .foregroundStyle(Color(red: 1.0, green: 0.94, blue: 0.82))
                        .shadow(color: .black.opacity(0.16), radius: 8, y: 5)
                        .padding(.top, 42)
                        .minimumScaleFactor(0.72)

                    Spacer()

                    HomeActions(showGallery: game.canAccessGallery)
                        .padding(.bottom, 30)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }

            if DeveloperToolsConfiguration.isResetButtonEnabled {
                VStack {
                    HStack {
                        Spacer()

                        Button {
                            showsResetConfirmation = true
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 40, height: 40)
                                .background(Circle().fill(.black.opacity(0.34)))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Reset test data")
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
            }
        }
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .alert("Reset all game data?", isPresented: $showsResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                game.resetAllGameDataForTesting()
            }
        } message: {
            Text("This removes the player name, mission progress and completed tutorials.")
        }
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(PreviewSupport.game)
    }
}
