//
//  GameStore.swift
//  CapodimonteTreasureHunt
//

import Combine
import Foundation

final class GameStore: ObservableObject {
    private enum PersistenceKey {
        static let playerName = "game.playerName"
        static let missionProgress = "game.missionProgress"
    }

    @Published var path: [GameRoute] = []
    @Published var playerName: String = "" {
        didSet {
            UserDefaults.standard.set(playerName, forKey: PersistenceKey.playerName)
        }
    }

    @Published private(set) var missions: [MissionCollection]
    @Published private(set) var activeMissionID: UUID?
    @Published private(set) var progressByMissionID: [UUID: MissionProgress] = [:] {
        didSet {
            saveMissionProgress()
        }
    }

    init(missions: [MissionCollection] = MissionCollection.capodimonteDemo) {
        self.missions = missions
        self.playerName = UserDefaults.standard.string(forKey: PersistenceKey.playerName) ?? ""
        self.progressByMissionID = Self.loadMissionProgress()
        normalizeMissionProgress()
    }

    var displayName: String {
        let trimmedName = playerName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "Explorer" : trimmedName
    }

    var hasAnyProgress: Bool {
        progressByMissionID.values.contains { !$0.unlockedArtworkIDs.isEmpty }
    }

    var activeMission: MissionCollection? {
        guard let activeMissionID else {
            return nil
        }

        return mission(with: activeMissionID)
    }

    func startHunt() {
        path = [.intro]
    }

    func finishIntro() {
        openGallery()
    }

    func openGallery() {
        path.append(.gallery)
    }

    func openMission(_ mission: MissionCollection) {
        activeMissionID = mission.id
        path.append(.mission(mission.id))
    }

    func openCurrentTarget(in mission: MissionCollection? = nil) {
        let selectedMission = mission ?? activeMission ?? missions.first

        if let selectedMission, let currentArtwork = currentArtwork(in: selectedMission) {
            openTarget(currentArtwork)
        }
    }

    func openTarget(_ artwork: ArtworkTarget) {
        activeMissionID = mission(containing: artwork.id)?.id
        path.append(.target(artwork.id))
    }

    func openScanner(for artwork: ArtworkTarget) {
        activeMissionID = mission(containing: artwork.id)?.id
        path.append(.scanner(artwork.id))
    }

    func continueAfterWordReveal(for artwork: ArtworkTarget) {
        path = [.artworkReveal(artwork.id)]
    }

    func continueAfterArtworkReveal(for artwork: ArtworkTarget) {
        guard let mission = mission(containing: artwork.id) else {
            openGallery()
            return
        }

        activeMissionID = mission.id

        if isMissionCompleted(mission) {
            path = [.completion(mission.id)]
        } else {
            path = [.mission(mission.id)]
        }
    }

    func mission(with id: UUID) -> MissionCollection? {
        missions.first { $0.id == id }
    }

    func artwork(with id: UUID) -> ArtworkTarget? {
        missions.lazy.flatMap(\.artworks).first { $0.id == id }
    }

    func mission(containing artworkID: UUID) -> MissionCollection? {
        missions.first { mission in
            mission.artworks.contains { $0.id == artworkID }
        }
    }

    func isUnlocked(_ artwork: ArtworkTarget) -> Bool {
        guard let mission = mission(containing: artwork.id) else {
            return false
        }

        return progress(for: mission).unlockedArtworkIDs.contains(artwork.id)
    }

    func completedCount(for mission: MissionCollection) -> Int {
        progress(for: mission).unlockedArtworkIDs.count
    }

    func progressText(for mission: MissionCollection) -> String {
        "\(completedCount(for: mission))/\(mission.artworks.count)"
    }

    func isMissionCompleted(_ mission: MissionCollection) -> Bool {
        completedCount(for: mission) == mission.artworks.count
    }

    func currentArtwork(in mission: MissionCollection) -> ArtworkTarget? {
        let unlockedArtworkIDs = progress(for: mission).unlockedArtworkIDs
        return mission.artworks.first { !unlockedArtworkIDs.contains($0.id) } ?? mission.artworks.last
    }

    func phraseSlots(for mission: MissionCollection) -> [String?] {
        let unlockedIndices = progress(for: mission).unlockedPhraseSlotIndices

        return mission.artworks.indices.map { index in
            unlockedIndices.contains(index) ? mission.artworks[index].unlockedWord : nil
        }
    }

    func completeScan(for artwork: ArtworkTarget) {
        guard let mission = mission(containing: artwork.id) else {
            return
        }

        activeMissionID = mission.id
        var progress = progress(for: mission)
        let wasAlreadyUnlocked = progress.unlockedArtworkIDs.contains(artwork.id)
        progress.unlockedArtworkIDs.insert(artwork.id)

        if !wasAlreadyUnlocked {
            let lockedIndices = Set(mission.artworks.indices).subtracting(progress.unlockedPhraseSlotIndices)

            if let randomIndex = lockedIndices.randomElement() {
                progress.unlockedPhraseSlotIndices.insert(randomIndex)
            }
        }

        progressByMissionID[mission.id] = progress
        path = [.wordReveal(artwork.id)]
    }

    func restart() {
        playerName = ""
        activeMissionID = nil
        progressByMissionID.removeAll()
        UserDefaults.standard.removeObject(forKey: PersistenceKey.playerName)
        UserDefaults.standard.removeObject(forKey: PersistenceKey.missionProgress)
        path = []
    }

    private func progress(for mission: MissionCollection) -> MissionProgress {
        progressByMissionID[mission.id] ?? MissionProgress()
    }

    private func normalizeMissionProgress() {
        let validMissionIDs = Set(missions.map(\.id))
        progressByMissionID = progressByMissionID.filter { validMissionIDs.contains($0.key) }

        for mission in missions {
            guard var progress = progressByMissionID[mission.id] else {
                continue
            }

            let validArtworkIDs = Set(mission.artworks.map(\.id))
            progress.unlockedArtworkIDs = progress.unlockedArtworkIDs.intersection(validArtworkIDs)
            progress.unlockedPhraseSlotIndices = progress.unlockedPhraseSlotIndices.intersection(Set(mission.artworks.indices))

            while progress.unlockedPhraseSlotIndices.count < progress.unlockedArtworkIDs.count {
                let lockedIndices = Set(mission.artworks.indices).subtracting(progress.unlockedPhraseSlotIndices)

                if let randomIndex = lockedIndices.randomElement() {
                    progress.unlockedPhraseSlotIndices.insert(randomIndex)
                } else {
                    break
                }
            }

            progressByMissionID[mission.id] = progress
        }
    }

    private func saveMissionProgress() {
        let storedProgress = progressByMissionID.map { missionID, progress in
            StoredMissionProgress(
                missionID: missionID.uuidString,
                unlockedArtworkIDs: progress.unlockedArtworkIDs.map(\.uuidString),
                unlockedPhraseSlotIndices: progress.unlockedPhraseSlotIndices.sorted()
            )
        }

        if let data = try? JSONEncoder().encode(storedProgress) {
            UserDefaults.standard.set(data, forKey: PersistenceKey.missionProgress)
        }
    }

    private static func loadMissionProgress() -> [UUID: MissionProgress] {
        guard
            let data = UserDefaults.standard.data(forKey: PersistenceKey.missionProgress),
            let storedProgress = try? JSONDecoder().decode([StoredMissionProgress].self, from: data)
        else {
            return [:]
        }

        return storedProgress.reduce(into: [:]) { result, storedProgress in
            guard let missionID = UUID(uuidString: storedProgress.missionID) else {
                return
            }

            result[missionID] = MissionProgress(
                unlockedArtworkIDs: Set(storedProgress.unlockedArtworkIDs.compactMap(UUID.init(uuidString:))),
                unlockedPhraseSlotIndices: Set(storedProgress.unlockedPhraseSlotIndices)
            )
        }
    }
}

struct MissionProgress: Equatable {
    var unlockedArtworkIDs: Set<UUID> = []
    var unlockedPhraseSlotIndices: Set<Int> = []
}

private struct StoredMissionProgress: Codable {
    let missionID: String
    let unlockedArtworkIDs: [String]
    let unlockedPhraseSlotIndices: [Int]
}
