//
//  GameRoute.swift
//  CapodimonteTreasureHunt
//

import Foundation

enum GameRoute: Hashable {
    case intro
    case target(UUID)
    case scanner(UUID)
    case scanSuccess(UUID)
    case gallery
    case completion
}
