//
//  GameStore.swift
//  CapodimonteTreasureHunt
//

import Combine
import Foundation

final class GameStore: ObservableObject {
    @Published var path: [GameRoute] = []
    @Published var playerName: String = ""
    @Published private(set) var artworks: [ArtworkTarget]
    @Published private(set) var unlockedArtworkIDs: Set<UUID> = []

    init(artworks: [ArtworkTarget] = ArtworkTarget.capodimonteSessionDemo) {
        self.artworks = Array(artworks.sorted { $0.order < $1.order }.prefix(5))
    }

    var completedCount: Int {
        unlockedArtworkIDs.count
    }

    var progressText: String {
        "\(completedCount)/\(artworks.count)"
    }

    var displayName: String {
        let trimmedName = playerName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "esploratore" : trimmedName
    }

    var currentArtwork: ArtworkTarget? {
        artworks.first { !unlockedArtworkIDs.contains($0.id) } ?? artworks.last
    }

    var unlockedArtworks: [ArtworkTarget] {
        artworks.filter { unlockedArtworkIDs.contains($0.id) }
    }

    var unlockedWords: [String] {
        artworks.map { unlockedArtworkIDs.contains($0.id) ? $0.unlockedWord : "" }
    }

    var phraseSlots: [String?] {
        artworks.map { unlockedArtworkIDs.contains($0.id) ? $0.unlockedWord : nil }
    }

    var completedPhrase: String {
        artworks.map(\.unlockedWord).joined(separator: " ")
    }

    func startHunt() {
        path = [.intro]
    }

    func finishIntro() {
        if let currentArtwork {
            path.append(.target(currentArtwork.id))
        }
    }

    func openCurrentTarget() {
        if let currentArtwork {
            path.append(.target(currentArtwork.id))
        }
    }

    func openTarget(_ artwork: ArtworkTarget) {
        path.append(.target(artwork.id))
    }

    func openScanner(for artwork: ArtworkTarget) {
        path.append(.scanner(artwork.id))
    }

    func openGallery() {
        path.append(.gallery)
    }

    func artwork(with id: UUID) -> ArtworkTarget? {
        artworks.first { $0.id == id }
    }

    func isUnlocked(_ artwork: ArtworkTarget) -> Bool {
        unlockedArtworkIDs.contains(artwork.id)
    }

    func completeScan(for artwork: ArtworkTarget) {
        unlockedArtworkIDs.insert(artwork.id)
        path = [.scanSuccess(artwork.id)]
    }

    func continueAfterSuccess() {
        if unlockedArtworkIDs.count == artworks.count {
            path = [.completion]
        } else {
            openCurrentTarget()
        }
    }

    func restart() {
        playerName = ""
        unlockedArtworkIDs.removeAll()
        path = []
    }
}
