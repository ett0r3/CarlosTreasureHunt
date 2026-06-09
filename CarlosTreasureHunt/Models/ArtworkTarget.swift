//
//  ArtworkTarget.swift
//  CarlosTreasureHunt
//

import Foundation

struct ArtworkTarget: Identifiable, Hashable {
    let id: UUID
    let title: String
    let artist: String
    let creationDate: String
    let galleryName: String
    let artworkDescription: String
    let detailedDescription: String
    let targetTitle: String
    let targetDescription: String
    let narratorPrompt: String
    let hintText: String
    let hintEmphasis: String
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
            title: "Mission 1",
            summary: "Five details that teach you to observe an artwork carefully.",
            words: ["Art", "reveals", "secrets", "to", "you"]
        ),
        demoMission(
            idNumber: 2,
            title: "Mission 2",
            summary: "A collection dedicated to light, passages and subtle clues.",
            words: ["Every", "painting", "hides", "a", "light"]
        ),
        demoMission(
            idNumber: 3,
            title: "Mission 3",
            summary: "A journey through gestures, glances and clues hidden among the figures.",
            words: ["Look", "closely", "find", "the", "key"]
        ),
        demoMission(
            idNumber: 4,
            title: "Mission 4",
            summary: "Five artworks that reveal how details can change a story.",
            words: ["Details", "open", "up", "new", "stories"]
        ),
        demoMission(
            idNumber: 5,
            title: "Mission 5",
            summary: "A visual hunt through colors, symbols and hidden traces.",
            words: ["Follow", "the", "colors", "without", "rushing"]
        ),
        demoMission(
            idNumber: 6,
            title: "Mission 6",
            summary: "The final collection connects all the discoveries in the museum.",
            words: ["Capodimonte", "keeps", "treasures", "for", "everyone"]
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
                let artworkContent = idNumber == 1
                    ? firstMissionArtworkContent[order - 1]
                    : DemoArtworkContent(
                        title: "Artwork \(order)",
                        artist: "Capodimonte",
                        creationDate: "Coming soon",
                        detailedDescription: "The complete description of this artwork will be added when the mission becomes available.",
                        funFact: "Placeholder artwork for \(title.lowercased()). The complete description of the unlocked artwork will appear here when the final museum content is available."
                    )

                return ArtworkTarget(
                    id: demoUUID(idNumber * 100 + order),
                    title: artworkContent.title,
                    artist: artworkContent.artist,
                    creationDate: artworkContent.creationDate,
                    galleryName: title,
                    artworkDescription: artworkContent.funFact,
                    detailedDescription: artworkContent.detailedDescription,
                    targetTitle: "Detail \(order)",
                    targetDescription: "Frame detail \(order) with the camera to unlock the artwork and one word of the secret phrase.",
                    narratorPrompt: "Find detail \(order): it is the next step in this collection.",
                    hintText: artworkContent.hintText,
                    hintEmphasis: artworkContent.hintEmphasis,
                    unlockedWord: word,
                    order: order,
                    imageAssetName: artworkAssetName,
                    targetAssetName: detailAssetName,
                    coreMLLabel: coreMLLabel
                )
            }
        )
    }

    private static let firstMissionArtworkContent: [DemoArtworkContent] = [
        DemoArtworkContent(
            title: "Madonna col Bambino e due angeli",
            artist: "Sandro Botticelli",
            creationDate: "c. 1468-1469",
            detailedDescription: "The Virgin holds the Child while two angels gather closely around them. Botticelli combines delicate faces, graceful gestures and richly patterned fabrics to create an intimate devotional scene.",
            funFact: "Did you know? Botticelli was not his real last name: the painter's name was Alessandro Filipepi! \"Botticelli\" was a family nickname.",
            hintText: "The next clue is hidden near a king!",
            hintEmphasis: "near a king!"
        ),
        DemoArtworkContent(
            title: "Ritratto del cardinale Alessandro Farnese, futuro papa Paolo III",
            artist: "Raffaello Sanzio",
            creationDate: "c. 1511",
            detailedDescription: "Raffaello portrays the young Alessandro Farnese with a composed expression and direct presence. The restrained pose and carefully rendered red garments communicate both his rank and his growing influence in Renaissance Rome.",
            funFact: "Alessandro Farnese became cardinal at just 14 years old!",
            hintText: "Look for the detail near a hand.",
            hintEmphasis: "near a hand."
        ),
        DemoArtworkContent(
            title: "Flowers, Fruit with a Woman Picking Grapes",
            artist: "Christian Berentz and Carlo Maratta",
            creationDate: "1689",
            detailedDescription: "A monumental arrangement of flowers and fruit surrounds a woman gathering grapes. Berentz's detailed still life and Maratta's figure painting work together to transform abundance into a theatrical Baroque scene.",
            funFact: "This painting is the work of two artists: Berentz painted the fruit and flowers, while the woman was created by Carlo Maratta!",
            hintText: "Look among the fruit and flowers.",
            hintEmphasis: "fruit and flowers."
        ),
        DemoArtworkContent(
            title: "Misantropo",
            artist: "Pieter Bruegel il Vecchio",
            creationDate: "1568",
            detailedDescription: "A hooded man walks absorbed in his distrust of the world while a small figure secretly cuts away his purse. Bruegel turns the scene into a warning: withdrawing from others does not protect us from deception.",
            funFact: "Look closely: the misanthrope thinks he is wise, but he is the only one who doesn't notice the theft.",
            hintText: "Search close to the hidden thief.",
            hintEmphasis: "hidden thief."
        ),
        DemoArtworkContent(
            title: "Danae",
            artist: "Tiziano Vecellio",
            creationDate: "1544-1545",
            detailedDescription: "Danae reclines as Jupiter reaches her in the form of a shower of gold. Tiziano uses warm light, soft color and loose brushwork to give the mythological scene an immediate and sensuous atmosphere.",
            funFact: "Did you know? During World War II, this work was stolen by the Nazis and found in a salt mine in Austria!",
            hintText: "Follow the golden light in the scene.",
            hintEmphasis: "golden light."
        )
    ]

    private static func demoUUID(_ number: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", number))!
    }
}

private struct DemoArtworkContent {
    let title: String
    let artist: String
    let creationDate: String
    let detailedDescription: String
    let funFact: String
    let hintText: String
    let hintEmphasis: String

    init(
        title: String,
        artist: String,
        creationDate: String,
        detailedDescription: String,
        funFact: String,
        hintText: String = "Look closely around the figures in the artwork.",
        hintEmphasis: String = "around the figures"
    ) {
        self.title = title
        self.artist = artist
        self.creationDate = creationDate
        self.detailedDescription = detailedDescription
        self.funFact = funFact
        self.hintText = hintText
        self.hintEmphasis = hintEmphasis
    }
}
