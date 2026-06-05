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
    @Namespace private var swapNamespace
    @State private var showsReferenceImage = false
    @State private var isSwapBubbleDipped = false
    @State private var tutorialStep: ScannerTutorialStep = .lens
    @State private var hasCompletedTutorialInCurrentSession = false
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

            if isShowingTutorial {
                if tutorialStep == .ready {
                    ScannerReadyOverlay {
                        advanceTutorial()
                    }
                    .ignoresSafeArea()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                } else {
                    ScannerTutorialOverlay(step: tutorialStep) {
                        advanceTutorial()
                    }
                    .ignoresSafeArea()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
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

    private func advanceTutorial() {
        withAnimation(.interactiveSpring(response: 0.46, dampingFraction: 0.78, blendDuration: 0.08)) {
            switch tutorialStep {
            case .lens:
                tutorialStep = .swap
            case .swap:
                tutorialStep = .ready
            case .ready:
                hasCompletedTutorialInCurrentSession = true
            }
        }
    }

    private func handleRecognitionResult(_ result: ArtworkRecognitionResult?, for artwork: ArtworkTarget) {
        guard let result else {
            return
        }

        if ArtworkRecognitionService().matches(result, target: artwork) {
            if !isShowingTutorial && !showsReferenceImage && !didCompleteRecognition {
                didCompleteRecognition = true
                game.completeScan(for: artwork)
            }
        }
    }
}

private enum ScannerTutorialStep {
    case lens
    case swap
    case ready
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
        case .ready:
            return screenHeight / 2
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
            return "The lens"
        case .swap:
            return "Guide image"
        case .ready:
            return ""
        }
    }

    private var iconName: String {
        switch step {
        case .lens:
            return "viewfinder.circle"
        case .swap:
            return "arrow.triangle.2.circlepath"
        case .ready:
            return "sparkles"
        }
    }

    private var message: String {
        switch step {
        case .lens:
            return "Place the hidden detail inside the lens."
        case .swap:
            return "Tap this button whenever you need to see the guide image."
        case .ready:
            return ""
        }
    }

    private var buttonTitle: String {
        switch step {
        case .lens:
            return "Got it"
        case .swap:
            return "I'm ready"
        case .ready:
            return ""
        }
    }
}

private struct ScannerReadyOverlay: View {
    let action: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.90, blue: 0.77),
                    Color(red: 0.95, green: 0.85, blue: 0.68)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            GeometryReader { proxy in
                Image("carlo-intro6")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)

                VStack(spacing: 6) {
                    Text("Okay, Explorer!")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))

                    Text("Now you're all set.")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))

                    Text("Let's begin!")
                        .font(.system(size: 19, weight: .black, design: .rounded))
                }
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(red: 0.06, green: 0.05, blue: 0.05))
                .frame(width: proxy.size.width * 0.60, height: proxy.size.height * 0.18)
                .position(x: proxy.size.width * 0.50, y: proxy.size.height * 0.20)

                Button(action: action) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 25, weight: .black))
                        .foregroundStyle(Color(red: 0.47, green: 0.28, blue: 0.0))
                        .frame(width: 66, height: 66)
                        .background(
                            Circle()
                                .fill(Color(red: 1.0, green: 0.74, blue: 0.0))
                                .shadow(color: Color(red: 0.62, green: 0.32, blue: 0.0).opacity(0.22), radius: 9, y: 5)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Begin")
                .position(x: proxy.size.width - 62, y: proxy.size.height - 62)
            }
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

                ScannerYellowLensChrome(lensSize: lensSize, lensCenterY: lensCenterY)
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

private struct ScannerYellowLensChrome: View {
    let lensSize: CGFloat
    let lensCenterY: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let centerX = proxy.size.width / 2
            let handleWidth = lensSize * 0.17
            let handleHeight = lensSize * 0.56

            ZStack {
                Capsule()
                    .fill(lensGradient)
                    .frame(width: handleWidth, height: handleHeight)
                    .rotationEffect(.degrees(32))
                    .shadow(color: Color(red: 0.65, green: 0.44, blue: 0.08).opacity(0.34), radius: 16)
                    .position(x: centerX - lensSize * 0.43, y: lensCenterY + lensSize * 0.55)

                Circle()
                    .strokeBorder(
                        lensGradient,
                        lineWidth: 22
                    )
                    .frame(width: lensSize, height: lensSize)
                    .shadow(color: Color(red: 0.65, green: 0.44, blue: 0.08).opacity(0.40), radius: 17)
                    .position(x: centerX, y: lensCenterY)

                Circle()
                    .strokeBorder(Color.white.opacity(0.30), lineWidth: 3)
                    .frame(width: lensSize - 18, height: lensSize - 18)
                    .position(x: centerX, y: lensCenterY)
            }
        }
    }

    private var lensGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.88, blue: 0.33),
                Color(red: 0.96, green: 0.65, blue: 0.06)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
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
        .accessibilityLabel(showsReferenceImage ? "Back to camera" : "Show guide image")
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

                    Text("Guide image")
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
