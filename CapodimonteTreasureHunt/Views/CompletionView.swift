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
            PurpleGameBackground(sparklesOpacity: 0.24)

            if let mission = game.mission(with: missionID) {
                VStack(spacing: 20) {
                    Spacer()

                    Image(systemName: "trophy.fill")
                        .font(.system(size: 84, weight: .black))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.84, blue: 0.22),
                                    Color(red: 0.93, green: 0.46, blue: 0.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color(red: 1.0, green: 0.70, blue: 0.0).opacity(0.34), radius: 18, y: 8)

                    Text("Mission completed")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)

                    Text("\(game.displayName), you completed \(mission.title). The secret phrase is:")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.88))
                        .padding(.horizontal, 28)

                    Text(mission.completedPhrase)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color(red: 0.55, green: 0.35, blue: 0.02))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(red: 1.0, green: 0.92, blue: 0.46))
                                .shadow(color: Color(red: 0.96, green: 0.74, blue: 0.20).opacity(0.24), radius: 18, y: 8)
                        )
                        .padding(.horizontal, 24)

                    Button {
                        game.openGallery()
                    } label: {
                        Label("View gallery", systemImage: "book.pages")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)

                    Button {
                        game.returnHome()
                    } label: {
                        Label("Back to home", systemImage: "house.fill")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(Color(red: 0.47, green: 0.28, blue: 0.0))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(GameTheme.gold)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)

                    Spacer()
                }
            } else {
                ContentUnavailableView("Mission not found", systemImage: "questionmark.circle")
            }
        }
        .navigationBarBackButtonHidden()
    }
}

struct CompletionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CompletionView(missionID: PreviewSupport.firstMission.id)
        }
        .environmentObject(PreviewSupport.game)
    }
}
