//
//  GameStore.swift
//  CarlosTreasureHunt
//

import Combine
import Foundation

final class GameStore: ObservableObject {
    private enum PersistenceKey {
        static let playerName = "game.playerName"
        static let missionProgress = "game.missionProgress"
        static let activeMissionID = "game.activeMissionID"
        static let hasCompletedOnboarding = "game.hasCompletedOnboarding"
        static let hasCompletedScannerTutorial = "game.hasCompletedScannerTutorial"
    }

    @Published var path: [GameRoute] = []
    @Published var playerName: String = "" {
        didSet {
            UserDefaults.standard.set(playerName, forKey: PersistenceKey.playerName)
        }
    }

    @Published private(set) var missions: [MissionCollection]
    @Published private(set) var activeMissionID: UUID? {
        didSet {
            if let activeMissionID {
                UserDefaults.standard.set(activeMissionID.uuidString, forKey: PersistenceKey.activeMissionID)
            } else {
                UserDefaults.standard.removeObject(forKey: PersistenceKey.activeMissionID)
            }
        }
    }
    @Published private(set) var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: PersistenceKey.hasCompletedOnboarding)
        }
    }
    @Published private(set) var hasCompletedScannerTutorial: Bool {
        didSet {
            UserDefaults.standard.set(
                hasCompletedScannerTutorial,
                forKey: PersistenceKey.hasCompletedScannerTutorial
            )
        }
    }
    @Published private(set) var progressByMissionID: [UUID: MissionProgress] = [:] {
        didSet {
            saveMissionProgress()
        }
    }

    init(missions: [MissionCollection] = MissionCollection.capodimonteDemo) {
        let defaults = UserDefaults.standard
        self.missions = missions
        self.playerName = defaults.string(forKey: PersistenceKey.playerName) ?? ""
        self.hasCompletedOnboarding = defaults.bool(forKey: PersistenceKey.hasCompletedOnboarding)
        self.hasCompletedScannerTutorial = defaults.bool(forKey: PersistenceKey.hasCompletedScannerTutorial)
        self.progressByMissionID = Self.loadMissionProgress()

        if
            let storedMissionID = defaults.string(forKey: PersistenceKey.activeMissionID),
            let missionID = UUID(uuidString: storedMissionID),
            missions.contains(where: { $0.id == missionID })
        {
            self.activeMissionID = missionID
        } else {
            self.activeMissionID = nil
        }

        normalizeMissionProgress()
    }

    var displayName: String {
        let trimmedName = playerName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "Explorer" : trimmedName
    }

    var hasCompletedFirstMission: Bool {
        guard let firstMission = missions.first else {
            return false
        }

        return isMissionCompleted(firstMission)
    }

    var canAccessGallery: Bool {
        hasCompletedFirstMission
    }

    var shouldShowScannerTutorial: Bool {
        !hasCompletedScannerTutorial
    }

    var activeMission: MissionCollection? {
        guard let activeMissionID else {
            return nil
        }

        return mission(with: activeMissionID)
    }

    func startHunt() {
        guard hasCompletedOnboarding else {
            path = [.intro]
            return
        }

        guard let mission = missionToResume() else {
            if canAccessGallery {
                path = [.gallery]
            }
            return
        }

        activeMissionID = mission.id

        if let artwork = currentArtwork(in: mission) {
            path = [.target(artwork.id)]
        }
    }

    func finishIntro() {
        hasCompletedOnboarding = true

        guard
            let firstMission = missions.first,
            let firstArtwork = currentArtwork(in: firstMission)
        else {
            return
        }

        activeMissionID = firstMission.id
        path = [.target(firstArtwork.id)]
    }

    func completeScannerTutorial() {
        hasCompletedScannerTutorial = true
    }

    func openGallery() {
        guard canAccessGallery else {
            return
        }

        path = [.gallery]
    }

    func openMission(_ mission: MissionCollection) {
        guard canOpenMission(mission) else {
            return
        }

        activeMissionID = mission.id
        path.append(.mission(mission.id))
    }

    func canOpenMission(_ mission: MissionCollection) -> Bool {
        mission.id == missions.first?.id
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

        if
            !wasAlreadyUnlocked,
            let artworkIndex = mission.artworks.firstIndex(where: { $0.id == artwork.id })
        {
            progress.unlockedPhraseSlotIndices.insert(artworkIndex)
        }

        progressByMissionID[mission.id] = progress
        path = [.wordReveal(artwork.id)]
    }

    func returnHome() {
        path = []
    }

    func resetAllGameDataForTesting() {
        playerName = ""
        activeMissionID = nil
        hasCompletedOnboarding = false
        hasCompletedScannerTutorial = false
        progressByMissionID.removeAll()
        UserDefaults.standard.removeObject(forKey: PersistenceKey.playerName)
        UserDefaults.standard.removeObject(forKey: PersistenceKey.missionProgress)
        UserDefaults.standard.removeObject(forKey: PersistenceKey.activeMissionID)
        UserDefaults.standard.removeObject(forKey: PersistenceKey.hasCompletedOnboarding)
        UserDefaults.standard.removeObject(forKey: PersistenceKey.hasCompletedScannerTutorial)
        path = []
    }

    private func missionToResume() -> MissionCollection? {
        guard let firstMission = missions.first else {
            return nil
        }

        if !isMissionCompleted(firstMission) {
            return firstMission
        }

        if let activeMission, !isMissionCompleted(activeMission) {
            return activeMission
        }

        return missions.dropFirst().first { mission in
            completedCount(for: mission) > 0 && !isMissionCompleted(mission)
        }
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
            progress.unlockedPhraseSlotIndices = Set(
                mission.artworks.indices.filter { index in
                    progress.unlockedArtworkIDs.contains(mission.artworks[index].id)
                }
            )

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
