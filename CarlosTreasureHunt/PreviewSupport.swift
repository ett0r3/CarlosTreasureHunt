//
//  PreviewSupport.swift
//  CarlosTreasureHunt
//

import Foundation

enum PreviewSupport {
    static var game: GameStore {
        makeGame()
    }

    static var inProgressGame: GameStore {
        makeGame(unlockedArtworkCount: 2)
    }

    static var completedGame: GameStore {
        makeGame(unlockedArtworkCount: firstMission.artworks.count)
    }

    static var firstMission: MissionCollection {
        MissionCollection.capodimonteDemo[0]
    }

    static var firstArtwork: ArtworkTarget {
        firstMission.artworks[0]
    }

    static func makeGame(unlockedArtworkCount: Int = 0) -> GameStore {
        let game = GameStore(
            missions: MissionCollection.capodimonteDemo,
            persistsState: false
        )
        game.playerName = "Carlo"

        for artwork in firstMission.artworks.prefix(unlockedArtworkCount) {
            game.completeScan(for: artwork)
        }

        game.returnHome()
        return game
    }
}
