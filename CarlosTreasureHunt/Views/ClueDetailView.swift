//
//  ClueDetailView.swift
//  CarlosTreasureHunt
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
    let artworkID: UUID

    var body: some View {
        ARScannerView(
            artworkID: artworkID,
            showsTutorial: game.shouldShowScannerTutorial
        )
    }
}

struct TargetDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TargetDetailView(artworkID: PreviewSupport.firstArtwork.id)
        }
        .environmentObject(PreviewSupport.game)
    }
}
