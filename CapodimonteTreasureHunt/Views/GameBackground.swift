//
//  GameBackground.swift
//  CapodimonteTreasureHunt
//

import SwiftUI

struct GameBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.96, green: 0.91, blue: 0.98),
                Color(red: 0.82, green: 0.92, blue: 0.90),
                Color(red: 0.98, green: 0.86, blue: 0.63)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct GameBackground_Previews: PreviewProvider {
    static var previews: some View {
        GameBackground()
    }
}
