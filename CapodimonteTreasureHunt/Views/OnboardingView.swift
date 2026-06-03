//
//  OnboardingView.swift
//  CapodimonteTreasureHunt
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var game: GameStore
    @State private var pageIndex = 0

    var body: some View {
        ZStack {
            GameBackground()

            VStack(alignment: .leading, spacing: 24) {
                Spacer(minLength: 12)

                NarratorBubble(text: currentNarration)

                if pageIndex == 1 {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Come ti chiami?")
                            .font(.headline)
                            .foregroundStyle(Color(red: 0.18, green: 0.12, blue: 0.23))

                        TextField("Inserisci il tuo nome", text: $game.playerName)
                            .textInputAutocapitalization(.words)
                            .font(.title3.weight(.semibold))
                            .padding(14)
                            .background(.white.opacity(0.86))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }

                PhraseProgressView(slots: game.phraseSlots)

                Spacer()

                PrimaryButton(title: buttonTitle, systemImage: "arrow.right") {
                    advance()
                }
            }
            .padding(24)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var currentNarration: String {
        switch pageIndex {
        case 0:
            return "C'e un libro vuoto nella galleria. Per riempirlo dovrai trovare 5 dettagli nascosti nei quadri."
        case 1:
            return "Prima pero devo sapere chi guidera la missione. Scrivi il tuo nome: lo usero quando ti parlero durante l'avventura."
        default:
            return "\(game.displayName), ogni dettaglio sblocca un quadro e una parola. Alla fine le 5 parole formeranno la frase segreta."
        }
    }

    private var buttonTitle: String {
        pageIndex < 2 ? "Continua" : "Vai al primo target"
    }

    private func advance() {
        if pageIndex < 2 {
            pageIndex += 1
        } else {
            game.finishIntro()
        }
    }
}

private struct NarratorBubble: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Narratore", systemImage: "quote.bubble.fill")
                .font(.headline)
                .foregroundStyle(Color(red: 0.49, green: 0.19, blue: 0.62))

            Text(text)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color(red: 0.18, green: 0.12, blue: 0.23))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
