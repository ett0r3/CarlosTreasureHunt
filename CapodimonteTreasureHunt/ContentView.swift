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

            ZStack {

                // Background

                LinearGradient(
                    colors: [

                        Color(
                            red: 242 / 255,
                            green: 234 / 255,
                            blue: 249 / 255
                        ),

                        Color(
                            red: 206 / 255,
                            green: 189 / 255,
                            blue: 239 / 255
                        )
                    ],

                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Home image

                Image("home")
                    .resizable()
                    .scaledToFill()
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
                    .clipped()
                    .ignoresSafeArea()

                // Clickable lens

                Button {
                    game.startHunt()
                } label: {

                    ZStack {

                        Image("lens")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 350)
                            .offset(x: 13, y: 60)

                        Text("GIOCA")
                            .font(.system(size: 42))
                            .bold()
                            .foregroundStyle(.white)
                            .offset(x: -10, y: -20)
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationDestination(for: GameRoute.self) { route in
                switch route {
                case .intro:
                    OnboardingView()
                case .target(let artworkID):
                    TargetDetailView(artworkID: artworkID)
                case .scanner(let artworkID):
                    ARScannerView(artworkID: artworkID)
                case .scanSuccess(let artworkID):
                    ScanSuccessView(artworkID: artworkID)
                case .gallery:
                    SessionGalleryView()
                case .completion:
                    CompletionView()
                }
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
