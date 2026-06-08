//
//  PreviewSupport.swift
//  CarlosTreasureHunt
//

import Foundation

enum PreviewSupport {
    static var game: GameStore {
        GameStore(missions: MissionCollection.capodimonteDemo)
    }

    static var firstMission: MissionCollection {
        MissionCollection.capodimonteDemo[0]
    }

    static var firstArtwork: ArtworkTarget {
        firstMission.artworks[0]
    }
}
