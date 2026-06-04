//
//  CompletionView.swift
//  CapodimonteTreasureHunt
//

import SwiftUI

struct CompletionView: View {
    @EnvironmentObject private var game: GameStore
    let missionID: UUID

    var body: some View {
        ZStack {
            GameBackground()

            if let mission = game.mission(with: missionID) {
                VStack(spacing: 22) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 84))
                        .foregroundStyle(Color(red: 0.84, green: 0.48, blue: 0.08))

                    Text("Missione completata")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color(red: 0.18, green: 0.12, blue: 0.23))

                    Text("\(game.displayName), hai completato \(mission.title). La frase segreta e:")
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color(red: 0.23, green: 0.21, blue: 0.25))

                    Text(mission.completedPhrase)
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color(red: 0.49, green: 0.19, blue: 0.62))
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(.white.opacity(0.86))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    Button {
                        game.openGallery()
                    } label: {
                        Label("Guarda la galleria", systemImage: "book.pages")
                            .font(.headline)
                            .foregroundStyle(Color(red: 0.49, green: 0.19, blue: 0.62))
                    }
                    .buttonStyle(.plain)

                    PrimaryButton(title: "Ricomincia", systemImage: "arrow.clockwise") {
                        game.restart()
                    }
                }
                .padding(24)
            } else {
                ContentUnavailableView("Missione non trovata", systemImage: "questionmark.circle")
            }
        }
        .navigationBarBackButtonHidden()
    }
}
