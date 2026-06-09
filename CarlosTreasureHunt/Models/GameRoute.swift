//
//  GameRoute.swift
//  CarlosTreasureHunt
//

import Foundation

enum GameRoute: Hashable {
    case intro
    case gallery
    case mission(UUID)
    case galleryMission(UUID)
    case galleryArtwork(UUID)
    case target(UUID)
    case scanner(UUID)
    case detailFound(UUID)
    case wordReveal(UUID)
    case artworkReveal(UUID)
    case reopenedArtwork(UUID)
    case completion(UUID)
}
