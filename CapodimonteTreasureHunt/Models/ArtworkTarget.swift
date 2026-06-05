//
//  ArtworkTarget.swift
//  CapodimonteTreasureHunt
//

import Foundation

struct ArtworkTarget: Identifiable, Hashable {
    let id: UUID
    let title: String
    let artist: String
    let galleryName: String
    let artworkDescription: String
    let targetTitle: String
    let targetDescription: String
    let narratorPrompt: String
    let unlockedWord: String
    let order: Int
    let imageAssetName: String?
    let targetAssetName: String?
    let coreMLLabel: String
}

extension ArtworkTarget {
    static let capodimonteSessionDemo: [ArtworkTarget] = [
        MissionCollection.capodimonteDemo[0].artworks
    ].flatMap { $0 }
}

extension MissionCollection {
    static let capodimonteDemo: [MissionCollection] = [
        demoMission(
            idNumber: 1,
            title: "Missione 1",
            summary: "Cinque dettagli per imparare a guardare un'opera come un esploratore.",
            words: ["L'arte", "rivela", "segreti", "a", "te"]
        ),
        demoMission(
            idNumber: 2,
            title: "Missione 2",
            summary: "Una collezione dedicata alla luce, ai passaggi e ai piccoli segnali.",
            words: ["Ogni", "quadro", "nasconde", "una", "luce"]
        ),
        demoMission(
            idNumber: 3,
            title: "Missione 3",
            summary: "Un percorso tra gesti, sguardi e indizi lasciati nelle figure.",
            words: ["Guarda", "bene", "troverai", "la", "chiave"]
        ),
        demoMission(
            idNumber: 4,
            title: "Missione 4",
            summary: "Cinque opere per scoprire come i dettagli cambiano una storia.",
            words: ["I", "dettagli", "aprono", "nuove", "storie"]
        ),
        demoMission(
            idNumber: 5,
            title: "Missione 5",
            summary: "Una caccia visiva fatta di colori, simboli e tracce nascoste.",
            words: ["Segui", "il", "colore", "senza", "fretta"]
        ),
        demoMission(
            idNumber: 6,
            title: "Missione 6",
            summary: "La collezione finale collega tutte le scoperte del museo.",
            words: ["Capodimonte", "custodisce", "tesori", "per", "tutti"]
        )
    ]

    private static func demoMission(
        idNumber: Int,
        title: String,
        summary: String,
        words: [String]
    ) -> MissionCollection {
        MissionCollection(
            id: demoUUID(idNumber * 1000),
            title: title,
            summary: summary,
            artworks: words.enumerated().map { index, word in
                let order = index + 1

                let artworkAssetName = idNumber == 1 ? "Artwork\(order)" : nil
                let detailAssetName = idNumber == 1 ? "Detail\(order)" : nil
                let coreMLLabel = idNumber == 1 ? "Artwork\(order)" : "target"

                return ArtworkTarget(
                    id: demoUUID(idNumber * 100 + order),
                    title: "Opera \(order)",
                    artist: "Capodimonte",
                    galleryName: title,
                    artworkDescription: "Opera placeholder della \(title.lowercased()). Quando avrai i contenuti reali, qui andra la descrizione completa del quadro sbloccato.",
                    targetTitle: "Dettaglio \(order)",
                    targetDescription: "Inquadra il dettaglio \(order) con la fotocamera per sbloccare il quadro e una parola della frase.",
                    narratorPrompt: "Cerca il dettaglio \(order): e il prossimo passo della collezione.",
                    unlockedWord: word,
                    order: order,
                    imageAssetName: artworkAssetName,
                    targetAssetName: detailAssetName,
                    coreMLLabel: coreMLLabel
                )
            }
        )
    }

    private static func demoUUID(_ number: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", number))!
    }
}
