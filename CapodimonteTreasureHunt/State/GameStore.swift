//
//  GameStore.swift
//  CapodimonteTreasureHunt
//

import Combine
import Foundation

final class GameStore: ObservableObject {
    private enum PersistenceKey {
        static let playerName = "game.playerName"
        static let unlockedArtworkIDs = "game.unlockedArtworkIDs"
    }

    @Published var path: [GameRoute] = []
    @Published var playerName: String = "" {
        didSet {
            UserDefaults.standard.set(playerName, forKey: PersistenceKey.playerName)
        }
    }
    @Published private(set) var artworks: [ArtworkTarget]
    @Published private(set) var unlockedArtworkIDs: Set<UUID> = [] {
        didSet {
            saveUnlockedArtworkIDs()
        }
    }

    init(artworks: [ArtworkTarget] = ArtworkTarget.capodimonteSessionDemo) {
        self.artworks = Array(artworks.sorted { $0.order < $1.order }.prefix(5))
        self.playerName = UserDefaults.standard.string(forKey: PersistenceKey.playerName) ?? ""
        self.unlockedArtworkIDs = Self.loadUnlockedArtworkIDs()
            .intersection(Set(self.artworks.map(\.id)))
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
        UserDefaults.standard.removeObject(forKey: PersistenceKey.playerName)
        UserDefaults.standard.removeObject(forKey: PersistenceKey.unlockedArtworkIDs)
        path = []
    }

    private func saveUnlockedArtworkIDs() {
        let storedIDs = unlockedArtworkIDs.map(\.uuidString)
        UserDefaults.standard.set(storedIDs, forKey: PersistenceKey.unlockedArtworkIDs)
    }

    private static func loadUnlockedArtworkIDs() -> Set<UUID> {
        let storedIDs = UserDefaults.standard.stringArray(forKey: PersistenceKey.unlockedArtworkIDs) ?? []
        return Set(storedIDs.compactMap(UUID.init(uuidString:)))
    }
}
