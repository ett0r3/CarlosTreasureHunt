//
//  ARScannerView.swift
//  CapodimonteTreasureHunt
//

import ARKit
import SceneKit
import SwiftUI
import Vision

struct ARScannerView: View {
    @EnvironmentObject private var game: GameStore
    @AppStorage("hasSeenScannerTutorial") private var hasSeenScannerTutorial = false
    @Namespace private var swapNamespace
    @State private var showsReferenceImage = false
    @State private var isSwapBubbleDipped = false
    @State private var tutorialStep: ScannerTutorialStep = .lens
    @State private var hasCompletedTutorialInCurrentSession = false
    @State private var recognitionStatus = "Cerco il dettaglio..."
    @State private var recognizedResult: ArtworkRecognitionResult?
    @State private var didCompleteRecognition = false
    let artworkID: UUID

    private var isShowingTutorial: Bool {
        !hasCompletedTutorialInCurrentSession
    }

    var body: some View {
        ZStack {
            if let artwork = game.artwork(with: artworkID) {
                ZStack {
                    if showsReferenceImage {
                        ReferenceScannerSurface(artwork: artwork)
                            .matchedGeometryEffect(id: "scannerSurface", in: swapNamespace)
                            .transition(.opacity.combined(with: .scale(scale: 0.985)))
                    } else {
                        ARSceneView(artwork: artwork) { result in
                            handleRecognitionResult(result, for: artwork)
                        }
                            .matchedGeometryEffect(id: "scannerSurface", in: swapNamespace)
                            .transition(.opacity.combined(with: .scale(scale: 1.015)))
                    }
                }
                .ignoresSafeArea()

                MagnifyingScannerOverlay(
                    artwork: artwork,
                    showsReferenceImage: showsReferenceImage,
                    isSwapBubbleDipped: isSwapBubbleDipped,
                    namespace: swapNamespace
                ) {
                    swapReferenceView()
                }
                .allowsHitTesting(!isShowingTutorial || tutorialStep == .swap)
                .ignoresSafeArea()
            } else {
                ARSceneView(artwork: nil) { _ in }
                    .ignoresSafeArea()
            }

            VStack {
                if let artwork = game.artwork(with: artworkID) {
                    ScannerHeader(
                        artwork: artwork,
                        playerName: game.displayName,
                        recognitionStatus: recognitionStatus,
                        confidenceText: confidenceText
                    )
                }

                Spacer()

                if let artwork = game.artwork(with: artworkID) {
                    ScannerActionButton(title: "Conferma test", systemImage: "checkmark") {
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
        withAnimation(.easeInOut(duration: 0.16)) {
            isSwapBubbleDipped = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeInOut(duration: 0.28)) {
                showsReferenceImage.toggle()
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.76)) {
                isSwapBubbleDipped = false
            }
        }
    }

    private func openReferenceFromTutorial() {
        if !showsReferenceImage {
            swapReferenceView()
        } else {
            withAnimation(.easeInOut(duration: 0.16)) {
                isSwapBubbleDipped = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.76)) {
                    isSwapBubbleDipped = false
                }
            }
        }
    }

    private func advanceTutorial() {
        withAnimation(.interactiveSpring(response: 0.46, dampingFraction: 0.78, blendDuration: 0.08)) {
            switch tutorialStep {
            case .lens:
                tutorialStep = .swap
            case .swap:
                hasCompletedTutorialInCurrentSession = true
            }
        }
    }

    private var confidenceText: String? {
        guard let recognizedResult else {
            return nil
        }

        return "\(recognizedResult.label) · \(Int(recognizedResult.confidence * 100))%"
    }

    private func handleRecognitionResult(_ result: ArtworkRecognitionResult?, for artwork: ArtworkTarget) {
        guard let result else {
            if !didCompleteRecognition {
                recognitionStatus = "Cerco il dettaglio..."
            }
            return
        }

        recognizedResult = result

        if ArtworkRecognitionService().matches(result, target: artwork) {
            recognitionStatus = "Dettaglio riconosciuto"

            if !isShowingTutorial && !showsReferenceImage && !didCompleteRecognition {
                didCompleteRecognition = true
                game.completeScan(for: artwork)
            }
        } else {
            recognitionStatus = "Continua a inquadrare"
        }
    }
}

private struct ScannerActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(.white.opacity(0.28), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
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
            let lensSize = min(proxy.size.width * 0.92, proxy.size.height * 0.54)
            let lensCenterY = proxy.size.height * 0.48
            let swapSize: CGFloat = 86
            let swapCenterY = lensCenterY + (lensSize / 2) - (swapSize * 0.2)
            let focusSize = step == .lens ? lensSize + 18 : swapSize + 20
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
                Color.black.opacity(0.42)
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
            return max(138, lensCenterY - (lensSize / 2) - 68)
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
                .strokeBorder(Color.white.opacity(0.9), lineWidth: 2)
                .frame(width: size, height: size)

            Circle()
                .strokeBorder(Color.white.opacity(0.44), lineWidth: 1)
                .frame(width: size + 10, height: size + 10)
                .scaleEffect(isPulsing ? 1.05 : 0.98)
                .opacity(isPulsing ? 0.18 : 0.58)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.82).repeatForever(autoreverses: true)) {
                isPulsing = true
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
                .foregroundStyle(Color(red: 0.18, green: 0.12, blue: 0.23))

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
                    .background(Color(red: 0.18, green: 0.12, blue: 0.23))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.16), radius: 14, y: 6)
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
    let isSwapBubbleDipped: Bool
    let namespace: Namespace.ID
    let swapAction: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let lensSize = min(proxy.size.width * 0.92, proxy.size.height * 0.54)
            let lensCenterY = proxy.size.height * 0.48
            let swapSize: CGFloat = 86

            ZStack {
                Color(red: 0.48, green: 0.12, blue: 0.72)
                    .opacity(showsReferenceImage ? 0.32 : 0.26)
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

                PurpleLensChrome(lensSize: lensSize, lensCenterY: lensCenterY)
                    .allowsHitTesting(false)

                SwapPreviewButton(
                    artwork: artwork,
                    showsReferenceImage: showsReferenceImage,
                    isDipped: isSwapBubbleDipped,
                    namespace: namespace,
                    action: swapAction
                )
                .frame(width: swapSize, height: swapSize)
                .position(
                    x: proxy.size.width / 2,
                    y: lensCenterY + (lensSize / 2) - (swapSize * 0.2)
                )
            }
        }
        .animation(.easeInOut(duration: 0.22), value: showsReferenceImage)
        .animation(.easeInOut(duration: 0.18), value: isSwapBubbleDipped)
    }
}

private struct PurpleLensChrome: View {
    let lensSize: CGFloat
    let lensCenterY: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let centerX = proxy.size.width / 2
            let handleWidth = lensSize * 0.17
            let handleHeight = lensSize * 0.56

            ZStack {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.86, green: 0.42, blue: 1.0),
                                Color(red: 0.54, green: 0.12, blue: 0.88)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: handleWidth, height: handleHeight)
                    .rotationEffect(.degrees(32))
                    .shadow(color: Color(red: 0.65, green: 0.18, blue: 1.0).opacity(0.42), radius: 18)
                    .position(x: centerX - lensSize * 0.43, y: lensCenterY + lensSize * 0.55)

                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color(red: 0.90, green: 0.52, blue: 1.0),
                                Color(red: 0.54, green: 0.12, blue: 0.88)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 22
                    )
                    .frame(width: lensSize, height: lensSize)
                    .shadow(color: Color(red: 0.64, green: 0.18, blue: 1.0).opacity(0.48), radius: 18)
                    .position(x: centerX, y: lensCenterY)
            }
        }
    }
}

private struct SwapPreviewButton: View {
    let artwork: ArtworkTarget
    let showsReferenceImage: Bool
    let isDipped: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.78, green: 0.36, blue: 1.0),
                                Color(red: 0.56, green: 0.16, blue: 0.92)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(red: 0.60, green: 0.18, blue: 1.0).opacity(isDipped ? 0.12 : 0.36), radius: isDipped ? 5 : 14, y: isDipped ? 2 : 8)

                if showsReferenceImage {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(.white)
                        .matchedGeometryEffect(id: "swapIcon", in: namespace)
                } else {
                    ReferenceThumbnail(artwork: artwork)
                        .matchedGeometryEffect(id: "swapIcon", in: namespace)
                        .clipShape(Circle())
                        .padding(7)
                }
            }
            .offset(y: isDipped ? 18 : 0)
            .scaleEffect(isDipped ? 0.74 : 1)
            .opacity(isDipped ? 0.46 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(showsReferenceImage ? "Torna alla camera" : "Mostra immagine di riferimento")
    }
}

private struct ReferenceScannerSurface: View {
    let artwork: ArtworkTarget

    var body: some View {
        GeometryReader { proxy in
            let lensSize = min(proxy.size.width * 0.92, proxy.size.height * 0.54)
            let lensCenterY = proxy.size.height * 0.48
            let referenceSize = lensSize * 0.88

            ZStack {
                ReferenceArtworkImage(artwork: artwork)
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .blur(radius: 18)
                    .opacity(0.42)

                LinearGradient(
                    colors: [
                        Color(red: 0.34, green: 0.08, blue: 0.50).opacity(0.82),
                        Color(red: 0.56, green: 0.20, blue: 0.82).opacity(0.74)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                ReferenceArtworkImage(artwork: artwork)
                    .scaledToFill()
                    .frame(width: referenceSize, height: referenceSize)
                    .clipShape(Circle())
                    .position(x: proxy.size.width / 2, y: lensCenterY)

                Text(artwork.targetTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 22)
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
    let recognitionStatus: String
    let confidenceText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Scanner AR", systemImage: "camera.viewfinder")
                .font(.subheadline.weight(.semibold))

            Text(artwork.targetTitle)
                .font(.title2.bold())

            Text("\(playerName), punta la camera sul dettaglio del quadro.")
                .font(.subheadline)

            VStack(alignment: .leading, spacing: 2) {
                Text(recognitionStatus)
                    .font(.caption.weight(.semibold))

                if let confidenceText {
                    Text(confidenceText)
                        .font(.caption2)
                        .opacity(0.78)
                }
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            LinearGradient(
                colors: [.black.opacity(0.52), .black.opacity(0)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

private struct ARSceneView: UIViewRepresentable {
    let artwork: ArtworkTarget?
    let onRecognitionUpdate: (ArtworkRecognitionResult?) -> Void

    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView(frame: .zero)
        view.session.delegate = context.coordinator
        view.autoenablesDefaultLighting = true
        view.scene = SCNScene()

        if ARWorldTrackingConfiguration.isSupported {
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = [.horizontal]
            view.session.run(configuration)
        }

        return view
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {}

    static func dismantleUIView(_ uiView: ARSCNView, coordinator: Coordinator) {
        uiView.session.pause()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(artwork: artwork, onRecognitionUpdate: onRecognitionUpdate)
    }

    final class Coordinator: NSObject, ARSessionDelegate {
        private let service = ArtworkRecognitionService()
        private let visionQueue = DispatchQueue(label: "capodimonte.coreml.vision")
        private var request: VNCoreMLRequest?
        private var isProcessingFrame = false
        private var lastAnalysisTime: TimeInterval = 0
        private var artwork: ArtworkTarget?
        private var onRecognitionUpdate: (ArtworkRecognitionResult?) -> Void

        init(artwork: ArtworkTarget?, onRecognitionUpdate: @escaping (ArtworkRecognitionResult?) -> Void) {
            self.artwork = artwork
            self.onRecognitionUpdate = onRecognitionUpdate
            super.init()
            configureModel()
        }

        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            guard request != nil else {
                return
            }

            let currentTime = frame.timestamp

            guard !isProcessingFrame, currentTime - lastAnalysisTime > 0.45 else {
                return
            }

            isProcessingFrame = true
            lastAnalysisTime = currentTime
            let pixelBuffer = frame.capturedImage

            visionQueue.async { [weak self] in
                guard let self, let request = self.request else {
                    return
                }

                let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right)
                try? handler.perform([request])
                self.isProcessingFrame = false
            }
        }

        private func configureModel() {
            do {
                let model = try ArtworkRecognitionService.loadBundledModel()
                request = try service.makeVisionRequest(model: model) { [weak self] result in
                    DispatchQueue.main.async {
                        self?.onRecognitionUpdate(result)
                    }
                }
                request?.imageCropAndScaleOption = .centerCrop
            } catch {
                DispatchQueue.main.async { [onRecognitionUpdate] in
                    onRecognitionUpdate(nil)
                }
            }
        }
    }
}
