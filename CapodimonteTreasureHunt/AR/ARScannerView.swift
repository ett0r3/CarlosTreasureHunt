//
//  ARScannerView.swift
//  CapodimonteTreasureHunt
//

import ARKit
import SceneKit
import SwiftUI

struct ARScannerView: View {
    @EnvironmentObject private var game: GameStore
    @AppStorage("hasSeenScannerTutorial") private var hasSeenScannerTutorial = false
    @Namespace private var swapNamespace
    @State private var showsReferenceImage = false
    @State private var tutorialStep: ScannerTutorialStep = .lens
    let artworkID: UUID

    private var isShowingTutorial: Bool {
        !hasSeenScannerTutorial
    }

    var body: some View {
        ZStack {
            if let artwork = game.artwork(with: artworkID) {
                ZStack {
                    if showsReferenceImage {
                        ReferenceScannerSurface(artwork: artwork)
                            .matchedGeometryEffect(id: "scannerSurface", in: swapNamespace)
                            .transition(.asymmetric(insertion: .scale(scale: 0.84).combined(with: .opacity), removal: .opacity))
                    } else {
                        ARSceneView()
                            .matchedGeometryEffect(id: "scannerSurface", in: swapNamespace)
                            .transition(.asymmetric(insertion: .scale(scale: 1.08).combined(with: .opacity), removal: .opacity))
                    }
                }
                .ignoresSafeArea()

                MagnifyingScannerOverlay(
                    artwork: artwork,
                    showsReferenceImage: showsReferenceImage,
                    namespace: swapNamespace
                ) {
                    swapReferenceView()
                }
                .allowsHitTesting(!isShowingTutorial || tutorialStep == .swap)
                .ignoresSafeArea()
            } else {
                ARSceneView()
                    .ignoresSafeArea()
            }

            VStack {
                if let artwork = game.artwork(with: artworkID) {
                    ScannerHeader(artwork: artwork, playerName: game.displayName)
                }

                Spacer()

                if let artwork = game.artwork(with: artworkID) {
                    PrimaryButton(title: "Simula target riconosciuto", systemImage: "checkmark.seal.fill") {
                        game.completeScan(for: artwork)
                    }
                    .padding(20)
                    .background(.black.opacity(0.001))
                    .opacity(isShowingTutorial ? 0.45 : 1)
                    .disabled(isShowingTutorial)
                }
            }

            if isShowingTutorial {
                ScannerTutorialOverlay(step: tutorialStep) {
                    advanceTutorial()
                }
                .ignoresSafeArea()
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func swapReferenceView() {
        withAnimation(.interactiveSpring(response: 0.48, dampingFraction: 0.72, blendDuration: 0.08)) {
            showsReferenceImage.toggle()
        }
    }

    private func advanceTutorial() {
        withAnimation(.interactiveSpring(response: 0.46, dampingFraction: 0.78, blendDuration: 0.08)) {
            switch tutorialStep {
            case .lens:
                tutorialStep = .swap
            case .swap:
                hasSeenScannerTutorial = true
            }
        }
    }
}

private enum ScannerTutorialStep {
    case lens
    case swap
}

private struct ScannerTutorialOverlay: View {
    let step: ScannerTutorialStep
    let advanceAction: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let lensSize = min(proxy.size.width * 0.78, proxy.size.height * 0.46)
            let lensCenterY = proxy.size.height * 0.47
            let swapSize: CGFloat = 82
            let swapCenterY = lensCenterY + (lensSize / 2) - (swapSize * 0.18)
            let focusSize = step == .lens ? lensSize + 26 : swapSize + 30
            let focusCenter = CGPoint(
                x: proxy.size.width / 2,
                y: step == .lens ? lensCenterY : swapCenterY
            )
            let bubbleY = bubbleCenterY(
                for: step,
                lensSize: lensSize,
                lensCenterY: lensCenterY,
                swapCenterY: swapCenterY,
                screenHeight: proxy.size.height
            )

            ZStack {
                Color.black.opacity(0.56)
                    .mask {
                        Rectangle()
                            .overlay {
                                Circle()
                                    .frame(width: focusSize, height: focusSize)
                                    .position(focusCenter)
                                    .blendMode(.destinationOut)
                            }
                    }
                    .compositingGroup()
                    .allowsHitTesting(false)

                TutorialFocusRing(size: focusSize, step: step)
                    .position(focusCenter)
                    .allowsHitTesting(false)

                TutorialPointer(step: step)
                    .position(
                        x: proxy.size.width / 2,
                        y: step == .lens ? lensCenterY + (lensSize / 2) + 28 : swapCenterY - 58
                    )
                    .allowsHitTesting(false)

                TutorialBubble(step: step, action: advanceAction)
                    .frame(width: min(proxy.size.width - 32, 340))
                    .position(x: proxy.size.width / 2, y: bubbleY)
            }
            .animation(.interactiveSpring(response: 0.46, dampingFraction: 0.78), value: step)
        }
    }

    private func bubbleCenterY(
        for step: ScannerTutorialStep,
        lensSize: CGFloat,
        lensCenterY: CGFloat,
        swapCenterY: CGFloat,
        screenHeight: CGFloat
    ) -> CGFloat {
        switch step {
        case .lens:
            return max(150, lensCenterY - (lensSize / 2) - 74)
        case .swap:
            return min(screenHeight - 178, swapCenterY + 122)
        }
    }
}

private struct TutorialFocusRing: View {
    let size: CGFloat
    let step: ScannerTutorialStep
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.white.opacity(0.96), lineWidth: step == .lens ? 4 : 3)
                .frame(width: size, height: size)

            Circle()
                .strokeBorder(Color(red: 0.98, green: 0.75, blue: 0.21), lineWidth: 4)
                .frame(width: size + 12, height: size + 12)
                .scaleEffect(isPulsing ? 1.08 : 0.96)
                .opacity(isPulsing ? 0.28 : 0.82)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.82).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

private struct TutorialPointer: View {
    let step: ScannerTutorialStep
    @State private var isFloating = false

    var body: some View {
        Image(systemName: step == .lens ? "arrow.up" : "arrow.down")
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(.white)
            .padding(12)
            .background(Color(red: 0.98, green: 0.45, blue: 0.18))
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.28), radius: 10, y: 6)
            .offset(y: isFloating ? -6 : 6)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.62).repeatForever(autoreverses: true)) {
                    isFloating = true
                }
            }
    }
}

private struct TutorialBubble: View {
    let step: ScannerTutorialStep
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: iconName)
                .font(.headline)
                .foregroundStyle(Color(red: 0.49, green: 0.19, blue: 0.62))

            Text(message)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color(red: 0.18, green: 0.12, blue: 0.23))
                .fixedSize(horizontal: false, vertical: true)

            Button(action: action) {
                Text(buttonTitle)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.49, green: 0.19, blue: 0.62))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(.white.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.26), radius: 18, y: 8)
        .transition(.scale(scale: 0.92).combined(with: .opacity))
    }

    private var title: String {
        switch step {
        case .lens:
            return "La lente"
        case .swap:
            return "Immagine guida"
        }
    }

    private var iconName: String {
        switch step {
        case .lens:
            return "viewfinder.circle"
        case .swap:
            return "arrow.triangle.2.circlepath"
        }
    }

    private var message: String {
        switch step {
        case .lens:
            return "Metti il dettaglio del quadro dentro la lente."
        case .swap:
            return "Premi questo cerchio quando vuoi vedere l'immagine guida."
        }
    }

    private var buttonTitle: String {
        switch step {
        case .lens:
            return "Ho capito"
        case .swap:
            return "Ok, ci sono"
        }
    }
}

private struct MagnifyingScannerOverlay: View {
    let artwork: ArtworkTarget
    let showsReferenceImage: Bool
    let namespace: Namespace.ID
    let swapAction: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let lensSize = min(proxy.size.width * 0.78, proxy.size.height * 0.46)
            let lensCenterY = proxy.size.height * 0.47
            let swapSize: CGFloat = 82

            ZStack {
                Color.black.opacity(0.52)
                    .mask {
                        Rectangle()
                            .overlay {
                                Circle()
                                    .frame(width: lensSize, height: lensSize)
                                    .position(x: proxy.size.width / 2, y: lensCenterY)
                                    .blendMode(.destinationOut)
                            }
                    }
                    .compositingGroup()
                    .allowsHitTesting(false)

                Circle()
                    .strokeBorder(.white.opacity(0.94), lineWidth: 5)
                    .frame(width: lensSize, height: lensSize)
                    .position(x: proxy.size.width / 2, y: lensCenterY)
                    .shadow(color: .black.opacity(0.35), radius: 16, y: 8)
                    .allowsHitTesting(false)

                Circle()
                    .strokeBorder(Color(red: 0.98, green: 0.75, blue: 0.21), lineWidth: 3)
                    .frame(width: lensSize + 12, height: lensSize + 12)
                    .position(x: proxy.size.width / 2, y: lensCenterY)
                    .scaleEffect(showsReferenceImage ? 1.03 : 0.98)
                    .opacity(showsReferenceImage ? 0.95 : 0.72)
                    .allowsHitTesting(false)

                SwapPreviewButton(
                    artwork: artwork,
                    showsReferenceImage: showsReferenceImage,
                    namespace: namespace,
                    action: swapAction
                )
                .frame(width: swapSize, height: swapSize)
                .position(
                    x: proxy.size.width / 2,
                    y: lensCenterY + (lensSize / 2) - (swapSize * 0.18)
                )
            }
        }
        .animation(.easeInOut(duration: 0.22), value: showsReferenceImage)
    }
}

private struct SwapPreviewButton: View {
    let artwork: ArtworkTarget
    let showsReferenceImage: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.28), radius: 12, y: 6)

                Circle()
                    .fill(Color(red: 0.49, green: 0.19, blue: 0.62).opacity(0.12))
                    .padding(5)

                if showsReferenceImage {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 31, weight: .bold))
                        .foregroundStyle(Color(red: 0.49, green: 0.19, blue: 0.62))
                        .matchedGeometryEffect(id: "swapIcon", in: namespace)
                } else {
                    ReferenceThumbnail(artwork: artwork)
                        .matchedGeometryEffect(id: "swapIcon", in: namespace)
                        .clipShape(Circle())
                        .padding(8)
                }

                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(7)
                    .background(Color(red: 0.98, green: 0.45, blue: 0.18))
                    .clipShape(Circle())
                    .offset(x: 27, y: 27)
            }
            .rotationEffect(.degrees(showsReferenceImage ? 360 : 0))
            .scaleEffect(showsReferenceImage ? 1.04 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(showsReferenceImage ? "Torna alla camera" : "Mostra immagine di riferimento")
    }
}

private struct ReferenceScannerSurface: View {
    let artwork: ArtworkTarget

    var body: some View {
        GeometryReader { proxy in
            let lensSize = min(proxy.size.width * 0.78, proxy.size.height * 0.46)
            let lensCenterY = proxy.size.height * 0.47
            let referenceSize = lensSize * 0.86

            ZStack {
                Color(red: 0.12, green: 0.09, blue: 0.16)

                ReferenceArtworkImage(artwork: artwork)
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .blur(radius: 18)
                    .opacity(0.32)

                ReferenceArtworkImage(artwork: artwork)
                    .scaledToFit()
                    .frame(width: referenceSize, height: referenceSize)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(.white.opacity(0.88), lineWidth: 2)
                    }
                    .shadow(color: .black.opacity(0.35), radius: 18, y: 10)
                    .position(x: proxy.size.width / 2, y: lensCenterY)

                Text(artwork.targetTitle)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.42))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .position(x: proxy.size.width / 2, y: max(72, lensCenterY - (lensSize / 2) - 34))
            }
        }
    }
}

private struct ReferenceThumbnail: View {
    let artwork: ArtworkTarget

    var body: some View {
        ReferenceArtworkImage(artwork: artwork)
            .scaledToFill()
    }
}

private struct ReferenceArtworkImage: View {
    let artwork: ArtworkTarget

    var body: some View {
        if let targetAssetName = artwork.targetAssetName {
            Image(targetAssetName)
                .resizable()
        } else {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.75, blue: 0.21),
                        Color(red: 0.49, green: 0.19, blue: 0.62),
                        Color(red: 0.10, green: 0.45, blue: 0.38)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(spacing: 10) {
                    Image(systemName: "photo.artframe")
                        .font(.system(size: 52, weight: .semibold))

                    Text("Immagine guida")
                        .font(.headline)

                    Text(artwork.targetTitle)
                        .font(.caption.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 18)
                }
                .foregroundStyle(.white)
            }
        }
    }
}

private struct ScannerHeader: View {
    let artwork: ArtworkTarget
    let playerName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Scanner AR + Core ML", systemImage: "camera.viewfinder")
                .font(.headline)

            Text(artwork.targetTitle)
                .font(.title2.bold())

            Text("\(playerName), punta la camera sul dettaglio del quadro.")
                .font(.subheadline)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.black.opacity(0.55))
    }
}

private struct ARSceneView: UIViewRepresentable {
    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView(frame: .zero)
        view.delegate = context.coordinator
        view.autoenablesDefaultLighting = true
        view.scene = SCNScene()

        if ARWorldTrackingConfiguration.isSupported {
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = [.horizontal]
            view.session.run(configuration)
        }

        context.coordinator.placeDemoTreasure(in: view)
        return view
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {}

    static func dismantleUIView(_ uiView: ARSCNView, coordinator: Coordinator) {
        uiView.session.pause()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, ARSCNViewDelegate {
        func placeDemoTreasure(in view: ARSCNView) {
            let node = SCNNode(geometry: SCNSphere(radius: 0.08))
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemYellow
            node.position = SCNVector3(0, 0, -0.55)

            let pulse = CABasicAnimation(keyPath: "opacity")
            pulse.fromValue = 0.45
            pulse.toValue = 1
            pulse.duration = 0.8
            pulse.autoreverses = true
            pulse.repeatCount = .infinity
            node.addAnimation(pulse, forKey: "pulse")

            view.scene.rootNode.addChildNode(node)
        }
    }
}
