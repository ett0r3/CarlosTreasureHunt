//
//  MissionCollection.swift
//  CarlosTreasureHunt
//

import Foundation

struct MissionCollection: Identifiable, Hashable {
    let id: UUID
    let title: String
    let summary: String
    let artworks: [ArtworkTarget]

    var completedPhrase: String {
        artworks.map(\.unlockedWord).joined(separator: " ")
    }
}
