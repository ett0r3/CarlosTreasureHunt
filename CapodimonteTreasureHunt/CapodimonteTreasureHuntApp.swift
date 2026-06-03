//
//  CapodimonteTreasureHuntApp.swift
//  CapodimonteTreasureHunt
//
//  Created by AFP FED 003 on 29/05/26.
//

import SwiftUI

@main
struct CapodimonteTreasureHuntApp: App {
    @StateObject private var game = GameStore()

    var body: some Scene {

        WindowGroup {
            ContentView()
                .environmentObject(game)
        }
    }
}
