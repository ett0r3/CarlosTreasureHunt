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
        ArtworkTarget(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            title: "Ritratto misterioso",
            artist: "Capodimonte",
            galleryName: "Libro 1",
            targetTitle: "Dettaglio dello sguardo",
            targetDescription: "Punta la fotocamera sul dettaglio indicato: quando il modello lo riconosce, il quadro entra nella tua galleria.",
            narratorPrompt: "Il primo segno e negli occhi. Avvicinati con calma e lascia che il dettaglio ti risponda.",
            unlockedWord: "L'arte",
            order: 1,
            imageAssetName: nil,
            targetAssetName: nil,
            coreMLLabel: "portrait_eye_detail"
        ),
        ArtworkTarget(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            title: "Il colore nascosto",
            artist: "Capodimonte",
            galleryName: "Libro 1",
            targetTitle: "Dettaglio del colore",
            targetDescription: "Cerca la pennellata giusta nel quadro e tienila al centro dell'inquadratura.",
            narratorPrompt: "Ogni colore ha una voce. Questa volta devi trovare quella piu silenziosa.",
            unlockedWord: "rivela",
            order: 2,
            imageAssetName: nil,
            targetAssetName: nil,
            coreMLLabel: "hidden_color_detail"
        ),
        ArtworkTarget(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            title: "La mano del pittore",
            artist: "Capodimonte",
            galleryName: "Libro 1",
            targetTitle: "Dettaglio della mano",
            targetDescription: "Osserva la posizione della mano e cerca la stessa forma davanti a te.",
            narratorPrompt: "Una mano puo indicare, proteggere o nascondere. Qui fa tutte e tre le cose.",
            unlockedWord: "segreti",
            order: 3,
            imageAssetName: nil,
            targetAssetName: nil,
            coreMLLabel: "painter_hand_detail"
        ),
        ArtworkTarget(
            id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
            title: "La luce sulla veste",
            artist: "Capodimonte",
            galleryName: "Libro 1",
            targetTitle: "Dettaglio della luce",
            targetDescription: "Trova il punto in cui la luce cambia il colore della veste.",
            narratorPrompt: "La luce non illumina soltanto: a volte lascia una parola per chi sa seguirla.",
            unlockedWord: "a",
            order: 4,
            imageAssetName: nil,
            targetAssetName: nil,
            coreMLLabel: "robe_light_detail"
        ),
        ArtworkTarget(
            id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
            title: "Il simbolo finale",
            artist: "Capodimonte",
            galleryName: "Libro 1",
            targetTitle: "Dettaglio del simbolo",
            targetDescription: "Questo e l'ultimo dettaglio: scansionarlo completa la frase della sessione.",
            narratorPrompt: "Se sei arrivato fin qui, sai gia guardare come un esploratore del museo.",
            unlockedWord: "te",
            order: 5,
            imageAssetName: nil,
            targetAssetName: nil,
            coreMLLabel: "final_symbol_detail"
        )
    ]
}
