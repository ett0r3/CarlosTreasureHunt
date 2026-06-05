//
//  GameTheme.swift
//  CapodimonteTreasureHunt
//

import SwiftUI

enum GameTheme {
    static let deepPurple = Color(red: 0.14, green: 0.20, blue: 0.48)
    static let royalPurple = Color(red: 0.43, green: 0.25, blue: 0.78)
    static let brightPurple = Color(red: 0.47, green: 0.28, blue: 0.80)
    static let gold = Color(red: 1.0, green: 0.74, blue: 0.0)
    static let warmGold = Color(red: 1.0, green: 0.88, blue: 0.32)
    static let amber = Color(red: 0.96, green: 0.65, blue: 0.06)
    static let cream = Color(red: 1.0, green: 0.95, blue: 0.88)
    static let ink = Color(red: 0.05, green: 0.04, blue: 0.04)
    static let wordGreen = Color(red: 0.07, green: 0.46, blue: 0.30)

    static var purpleGradient: LinearGradient {
        LinearGradient(
            colors: [royalPurple, deepPurple, brightPurple],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var goldGradient: LinearGradient {
        LinearGradient(
            colors: [warmGold, amber],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

struct PurpleGameBackground: View {
    var sparklesOpacity: Double = 0.28
    var raysOpacity: Double = 0

    var body: some View {
        GameTheme.purpleGradient
            .overlay {
                if raysOpacity > 0 {
                    RadialRays()
                        .opacity(raysOpacity)
                }
            }
            .overlay {
                GameSparkles()
                    .opacity(sparklesOpacity)
            }
            .ignoresSafeArea()
    }
}

struct GoldCircleButton: View {
    let systemImage: String
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 27, weight: .black))
                .foregroundStyle(Color(red: 0.47, green: 0.28, blue: 0.0))
                .frame(width: 64, height: 64)
                .background(
                    Circle()
                        .fill(GameTheme.gold)
                        .shadow(color: Color(red: 0.62, green: 0.32, blue: 0.0).opacity(0.22), radius: 9, y: 5)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

struct RadialRays: View {
    var body: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { index in
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 34, height: 330)
                    .offset(y: -155)
                    .rotationEffect(.degrees(Double(index) * 30))
            }
        }
        .scaleEffect(1.25)
    }
}

struct GameSparkles: View {
    private let sparkles: [(x: CGFloat, y: CGFloat, size: CGFloat)] = [
        (0.12, 0.18, 7), (0.88, 0.10, 5), (0.74, 0.35, 6),
        (0.08, 0.52, 5), (0.84, 0.68, 8), (0.22, 0.84, 5),
        (0.72, 0.90, 6)
    ]

    var body: some View {
        GeometryReader { proxy in
            ForEach(sparkles.indices, id: \.self) { index in
                let sparkle = sparkles[index]

                Image(systemName: "sparkle")
                    .font(.system(size: sparkle.size, weight: .bold))
                    .foregroundStyle(Color(red: 0.75, green: 0.68, blue: 1.0))
                    .position(
                        x: proxy.size.width * sparkle.x,
                        y: proxy.size.height * sparkle.y
                    )
            }
        }
    }
}
