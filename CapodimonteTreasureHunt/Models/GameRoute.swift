//
//  GameRoute.swift
//  CapodimonteTreasureHunt
//

import Foundation

enum GameRoute: Hashable {
    case intro
    case gallery
    case mission(UUID)
    case target(UUID)
    case scanner(UUID)
    case wordReveal(UUID)
    case artworkReveal(UUID)
    case completion(UUID)
}
