//
//  ARScannerView.swift
//  CarlosTreasureHunt
//

import ARKit
import Combine
import CoreImage
import SceneKit
import SwiftUI
import Vision

struct ARScannerView: View {
    @EnvironmentObject private var game: GameStore
    @Namespace private var swapNamespace
    @State private var showsReferenceImage: Bool
    @State private var isSwapBubbleDipped = false
    @State private var tutorialStage: ARTutorialStage
    @State private var didCompleteRecognition = false
    @State private var recognitionStartedAt: Date?
    @State private var lastMatchingRecognitionAt: Date?
    @State private var recognitionProgress = 0.0
    @State private var hintElapsed: TimeInterval
    @State private var lastHintTimerTick: Date?
    @State private var isHintAvailable: Bool
    @State private var showsHintOverlay: Bool
    let artworkID: UUID
    private let usesLiveCamera: Bool
    private let recognitionTimer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    private static let requiredRecognitionDuration: TimeInterval = 4
    private static let recognitionFreshnessInterval: TimeInterval = 0.75
    private static let hintDelay: TimeInterval = 15

    init(
        artworkID: UUID,
        usesLiveCamera: Bool = true,
        showsTutorial: Bool = true,
        previewTutorialStep: Int? = nil,
        previewHintStep: Int? = nil
    ) {
        self.artworkID = artworkID
        self.usesLiveCamera = usesLiveCamera

        let initialStage: ARTutorialStage
        if previewHintStep != nil {
            initialStage = .completed
        } else {
            switch previewTutorialStep {
            case 1:
                initialStage = .cameraHint
            case 2:
                initialStage = .referenceHint
            case 3:
                initialStage = .ready
            case 4:
                initialStage = .completed
            default:
                initialStage = showsTutorial ? .find : .completed
            }
        }

        _tutorialStage = State(initialValue: initialStage)
        _showsReferenceImage = State(
            initialValue: previewHintStep == nil && initialStage != .referenceHint
        )
        let previewShowsHint = previewHintStep == 1 || previewHintStep == 2
        _hintElapsed = State(initialValue: previewShowsHint ? Self.hintDelay : 0)
        _lastHintTimerTick = State(initialValue: nil)
        _isHintAvailable = State(initialValue: previewShowsHint)
        _showsHintOverlay = State(initialValue: previewHintStep == 2)
    }

    private var isShowingTutorial: Bool {
        tutorialStage != .completed
    }

    private var isSwapEnabled: Bool {
        tutorialStage == .cameraHint ||
        tutorialStage == .referenceHint ||
        tutorialStage == .completed
    }

    var body: some View {
        ZStack {
            if let artwork = game.artwork(with: artworkID) {
                ZStack {
                    if showsReferenceImage {
                        ReferenceScannerSurface(artwork: artwork)
                            .matchedGeometryEffect(id: "scannerSurface", in: swapNamespace)
                            .transition(.opacity.combined(with: .scale(scale: 0.985)))
                    } else if usesLiveCamera {
                        ARSceneView(artwork: artwork) { result in
                            handleRecognitionResult(result, for: artwork)
                        }
                            .matchedGeometryEffect(id: "scannerSurface", in: swapNamespace)
                            .transition(.opacity.combined(with: .scale(scale: 1.015)))
                    } else {
                        Color.black
                            .overlay {
                                Image(systemName: "camera.viewfinder")
                                    .font(.system(size: 72, weight: .thin))
                                    .foregroundStyle(.white.opacity(0.35))
                            }
                    }
                }
                .ignoresSafeArea()

                MagnifyingScannerOverlay(
                    artwork: artwork,
                    showsReferenceImage: showsReferenceImage,
                    isSwapBubbleDipped: isSwapBubbleDipped,
                    isSwapEnabled: isSwapEnabled,
                    isSwapHighlighted: tutorialStage == .cameraHint || tutorialStage == .referenceHint,
                    recognitionProgress: recognitionProgress,
                    showsRecognitionProgress: tutorialStage == .completed && !showsReferenceImage && !didCompleteRecognition,
                    showsHintButton: isHintAvailable &&
                        tutorialStage == .completed &&
                        !showsReferenceImage &&
                        !didCompleteRecognition &&
                        !showsHintOverlay,
                    namespace: swapNamespace
                ) {
                    handleSwapButtonTap()
                } hintAction: {
                    showHint()
                }
                .ignoresSafeArea()
            } else {
                ARSceneView(artwork: nil) { _ in }
                    .ignoresSafeArea()
            }

            if isShowingTutorial {
                switch tutorialStage {
                case .find:
                    FindTargetTutorialOverlay {
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                            tutorialStage = .cameraHint
                        }
                    }
                    .ignoresSafeArea()
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))

                case .cameraHint:
                    NumberedARTutorialOverlay(
                        number: 1,
                        message: "Tap this button to open the camera and scan the hidden detail."
                    )
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))

                case .referenceHint:
                    NumberedARTutorialOverlay(
                        number: 2,
                        message: "Press this button whenever you need to view the reference image again."
                    )
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))

                case .ready:
                    ScannerReadyOverlay {
                        beginGame()
                    }
                    .ignoresSafeArea()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))

                case .completed:
                    EmptyView()
                }
            }

            if DeveloperToolsConfiguration.isSkipScanButtonEnabled && !didCompleteRecognition {
                VStack {
                    HStack {
                        Spacer()

                        Button {
                            skipScanForTesting()
                        } label: {
                            Label("Skip scan", systemImage: "forward.end.fill")
                                .font(.system(size: 13, weight: .black, design: .rounded))
                                .foregroundStyle(GameTheme.ink)
                                .padding(.horizontal, 14)
                                .frame(height: 40)
                                .background(
                                    Capsule()
                                        .fill(GameTheme.gold)
                                        .shadow(color: .black.opacity(0.20), radius: 8, y: 4)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Skip artwork scan")
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
            }

            if
                showsHintOverlay,
                let artwork = game.artwork(with: artworkID)
            {
                ScannerHintOverlay(artwork: artwork) {
                    hideHint()
                }
                .ignoresSafeArea()
                .transition(.opacity)
                .zIndex(20)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(recognitionTimer) { now in
            updateRecognitionProgress(at: now)
            updateHintAvailability(at: now)
        }
    }

    private func handleSwapButtonTap() {
        switch tutorialStage {
        case .cameraHint:
            performSwap(toReference: false) {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                    tutorialStage = .referenceHint
                }
            }
        case .referenceHint:
            performSwap(toReference: true) {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                    tutorialStage = .ready
                }
            }
        case .completed:
            performSwap(toReference: !showsReferenceImage)
        case .find, .ready:
            break
        }
    }

    private func beginGame() {
        game.completeScannerTutorial()
        tutorialStage = .completed
        performSwap(toReference: false)
    }

    private func performSwap(
        toReference: Bool,
        completion: @escaping () -> Void = {}
    ) {
        if toReference {
            resetRecognitionProgress()
        }

        guard showsReferenceImage != toReference else {
            completion()
            return
        }

        withAnimation(.easeInOut(duration: 0.16)) {
            isSwapBubbleDipped = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.linear(duration: 0.24)) {
                showsReferenceImage = toReference
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
            withAnimation(.easeOut(duration: 0.18)) {
                isSwapBubbleDipped = false
            }
            completion()
        }
    }

    private func handleRecognitionResult(_ result: ArtworkRecognitionResult?, for artwork: ArtworkTarget) {
        guard
            tutorialStage == .completed,
            !showsReferenceImage,
            !showsHintOverlay,
            !didCompleteRecognition
        else {
            return
        }

        guard
            let result,
            ArtworkRecognitionService().matches(result, target: artwork)
        else {
            resetRecognitionProgress()
            return
        }

        let now = Date()

        if recognitionStartedAt == nil {
            recognitionStartedAt = now
        }

        lastMatchingRecognitionAt = now
    }

    private func updateRecognitionProgress(at now: Date) {
        guard
            tutorialStage == .completed,
            !showsReferenceImage,
            !showsHintOverlay,
            !didCompleteRecognition,
            let recognitionStartedAt,
            let lastMatchingRecognitionAt
        else {
            return
        }

        guard now.timeIntervalSince(lastMatchingRecognitionAt) <= Self.recognitionFreshnessInterval else {
            resetRecognitionProgress()
            return
        }

        let elapsed = now.timeIntervalSince(recognitionStartedAt)
        recognitionProgress = min(elapsed / Self.requiredRecognitionDuration, 1)

        if recognitionProgress >= 1, let artwork = game.artwork(with: artworkID) {
            didCompleteRecognition = true
            game.completeScan(for: artwork)
        }
    }

    private func resetRecognitionProgress() {
        recognitionStartedAt = nil
        lastMatchingRecognitionAt = nil

        withAnimation(.easeOut(duration: 0.16)) {
            recognitionProgress = 0
        }
    }

    private func updateHintAvailability(at now: Date) {
        guard
            tutorialStage == .completed,
            !showsReferenceImage,
            !showsHintOverlay,
            !didCompleteRecognition,
            !isHintAvailable
        else {
            lastHintTimerTick = nil
            return
        }

        guard let lastHintTimerTick else {
            self.lastHintTimerTick = now
            return
        }

        hintElapsed += now.timeIntervalSince(lastHintTimerTick)
        self.lastHintTimerTick = now

        if hintElapsed >= Self.hintDelay {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
                isHintAvailable = true
            }
            self.lastHintTimerTick = nil
        }
    }

    private func showHint() {
        guard isHintAvailable, !didCompleteRecognition else {
            return
        }

        resetRecognitionProgress()
        lastHintTimerTick = nil

        withAnimation(.easeInOut(duration: 0.24)) {
            showsHintOverlay = true
        }
    }

    private func hideHint() {
        withAnimation(.easeInOut(duration: 0.22)) {
            showsHintOverlay = false
        }
    }

    private func skipScanForTesting() {
        guard
            !didCompleteRecognition,
            let artwork = game.artwork(with: artworkID)
        else {
            return
        }

        resetRecognitionProgress()
        didCompleteRecognition = true
        game.completeScan(for: artwork)
    }
}

private enum ARTutorialStage {
    case find
    case cameraHint
    case referenceHint
    case ready
    case completed
}

private struct FindTargetTutorialOverlay: View {
    let action: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let lensCenterY = proxy.size.height / 2

            ZStack {
                Color(red: 0.12, green: 0.10, blue: 0.40)
                    .opacity(0.20)
                    .allowsHitTesting(false)

                Button(action: action) {
                    ZStack {
                        Image("star")
                            .resizable()
                            .scaledToFit()

                        Text("Find and frame\nthis element!")
                            .font(.system(size: 25, weight: .black, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color(red: 0.13, green: 0.16, blue: 0.60))
                            .minimumScaleFactor(0.72)
                    }
                }
                .buttonStyle(.plain)
                .frame(width: min(proxy.size.width * 0.96, 410))
                .position(x: proxy.size.width / 2, y: lensCenterY)
                .accessibilityLabel("Find and frame this element")
            }
        }
    }
}

private struct NumberedARTutorialOverlay: View {
    let number: Int
    let message: String

    var body: some View {
        GeometryReader { proxy in
            let lensSize = ScannerLensGeometry.lensSize(in: proxy.size)
            let swapCenter = ScannerLensGeometry.swapCenter(
                in: proxy.size,
                lensSize: lensSize
            )
            let focusDiameter = ScannerLensGeometry.swapButtonSize + 44
            let bubbleCenterY = max(150, swapCenter.y - 170)

            ZStack {
                Color(red: 0.12, green: 0.10, blue: 0.40)
                    .opacity(0.38)
                    .mask {
                        Rectangle()
                            .overlay {
                                Circle()
                                    .frame(width: focusDiameter, height: focusDiameter)
                                    .position(swapCenter)
                                    .blendMode(.destinationOut)
                            }
                    }
                    .compositingGroup()

                VStack(spacing: -18) {
                    Text("\(number)")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(Color(red: 0.17, green: 0.18, blue: 0.60))
                        .frame(width: 70, height: 70)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 1.0, green: 0.98, blue: 0.87),
                                            Color(red: 1.0, green: 0.78, blue: 0.24)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                        .zIndex(1)

                    Text(message)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color(red: 0.05, green: 0.04, blue: 0.04))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 24)
                        .padding(.top, 38)
                        .padding(.bottom, 26)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 1.0, green: 0.95, blue: 0.88))
                                .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
                        )
                }
                .frame(width: min(proxy.size.width - 48, 310))
                .position(x: proxy.size.width / 2, y: bubbleCenterY)
            }
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
    let isSwapEnabled: Bool
    let isSwapHighlighted: Bool
    let recognitionProgress: Double
    let showsRecognitionProgress: Bool
    let showsHintButton: Bool
    let namespace: Namespace.ID
    let swapAction: () -> Void
    let hintAction: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let lensSize = ScannerLensGeometry.lensSize(in: proxy.size)
            let lensOpeningSize = ScannerLensGeometry.openingSize(in: proxy.size)
            let lensCenterY = proxy.size.height / 2
            let swapCenter = ScannerLensGeometry.swapCenter(
                in: proxy.size,
                lensSize: lensSize
            )
            let hintCenter = ScannerLensGeometry.hintCenter(
                in: proxy.size,
                lensSize: lensSize
            )

            ZStack {
                Color(red: 0.48, green: 0.12, blue: 0.72)
                    .opacity(showsReferenceImage ? 0.32 : 0.26)
                    .mask {
                        Rectangle()
                            .overlay {
                                Circle()
                                    .frame(width: lensOpeningSize, height: lensOpeningSize)
                                    .position(x: proxy.size.width / 2, y: lensCenterY)
                                    .blendMode(.destinationOut)
                            }
                    }
                    .compositingGroup()
                    .allowsHitTesting(false)

                ScannerLensAsset(lensSize: lensSize, lensCenterY: lensCenterY)
                    .allowsHitTesting(false)

                if showsRecognitionProgress {
                    MagicalRecognitionRing(progress: recognitionProgress)
                        .frame(
                            width: lensOpeningSize - 22,
                            height: lensOpeningSize - 22
                        )
                        .position(x: proxy.size.width / 2, y: lensCenterY)
                        .transition(.opacity)
                        .allowsHitTesting(false)
                }

                SwapPreviewButton(
                    artwork: artwork,
                    showsReferenceImage: showsReferenceImage,
                    isDipped: isSwapBubbleDipped,
                    isEnabled: isSwapEnabled,
                    isHighlighted: isSwapHighlighted,
                    namespace: namespace,
                    action: swapAction
                )
                .frame(
                    width: ScannerLensGeometry.swapButtonSize,
                    height: ScannerLensGeometry.swapButtonSize
                )
                .position(swapCenter)

                if showsHintButton {
                    ScannerHintButton(action: hintAction)
                        .frame(
                            width: ScannerLensGeometry.hintButtonSize,
                            height: ScannerLensGeometry.hintButtonSize
                        )
                        .position(hintCenter)
                        .transition(
                            .scale(scale: 0.55)
                                .combined(with: .opacity)
                        )
                        .zIndex(3)
                }
            }
        }
        .animation(.easeInOut(duration: 0.22), value: showsReferenceImage)
        .animation(.easeInOut(duration: 0.18), value: isSwapBubbleDipped)
        .animation(.spring(response: 0.42, dampingFraction: 0.78), value: showsHintButton)
    }
}

private enum ScannerLensGeometry {
    static let assetWidth: CGFloat = 593
    static let assetHeight: CGFloat = 809
    static let circleCenterY: CGFloat = 295
    static let outerRadius: CGFloat = 294.5
    static let openingDiameter: CGFloat = 515
    static let swapButtonSize: CGFloat = 86
    static let hintButtonSize: CGFloat = 82

    static let assetAspectRatio = assetHeight / assetWidth
    static let circleCenterOffsetRatio = (assetHeight / 2 - circleCenterY) / assetWidth
    static let outerRadiusRatio = outerRadius / assetWidth
    static let openingRatio = openingDiameter / assetWidth

    static func lensSize(in size: CGSize) -> CGFloat {
        min(size.width * 1.28, size.height * 0.70)
    }

    static func openingSize(in size: CGSize) -> CGFloat {
        lensSize(in: size) * openingRatio
    }

    static func swapCenter(in size: CGSize, lensSize: CGFloat) -> CGPoint {
        CGPoint(
            x: size.width / 2,
            y: (size.height / 2) +
                (lensSize * outerRadiusRatio) -
                (swapButtonSize * 0.2)
        )
    }

    static func hintCenter(in size: CGSize, lensSize: CGFloat) -> CGPoint {
        CGPoint(
            x: size.width / 2,
            y: (size.height / 2) -
                (lensSize * outerRadiusRatio) +
                (hintButtonSize * 0.18)
        )
    }
}

private struct ScannerHintButton: View {
    let accessibilityLabel: String
    let action: () -> Void

    init(
        accessibilityLabel: String = "Show a hint",
        action: @escaping () -> Void
    ) {
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.90, blue: 0.48),
                                Color(red: 1.0, green: 0.67, blue: 0.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: GameTheme.gold.opacity(0.46), radius: 15, y: 5)

                Image(systemName: "lightbulb")
                    .font(.system(size: 38, weight: .medium))
                    .foregroundStyle(Color(red: 0.55, green: 0.35, blue: 0.0))
                    .symbolEffect(.pulse, options: .repeating.speed(0.55))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

private struct ScannerHintOverlay: View {
    let artwork: ArtworkTarget
    let dismissAction: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color(red: 1.0, green: 0.68, blue: 0.02)
                    .opacity(0.78)
                    .contentShape(Rectangle())
                    .onTapGesture {}

                VStack(spacing: -42) {
                    ScannerHintButton(
                        accessibilityLabel: "Close hint",
                        action: dismissAction
                    )
                        .frame(
                            width: ScannerLensGeometry.hintButtonSize,
                            height: ScannerLensGeometry.hintButtonSize
                        )
                        .zIndex(1)

                    Text(attributedHint)
                        .font(.system(size: 28, weight: .regular, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color(red: 0.72, green: 0.47, blue: 0.0))
                        .lineSpacing(4)
                        .minimumScaleFactor(0.74)
                        .padding(.horizontal, 30)
                        .padding(.top, 76)
                        .padding(.bottom, 44)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 38)
                                .fill(Color(red: 1.0, green: 0.97, blue: 0.90))
                                .shadow(color: .black.opacity(0.12), radius: 22, y: 12)
                        )
                }
                .frame(width: min(proxy.size.width - 48, 340))
                .position(x: proxy.size.width / 2, y: proxy.size.height * 0.51)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var attributedHint: AttributedString {
        var result = AttributedString(artwork.hintText)

        if let emphasisRange = result.range(of: artwork.hintEmphasis) {
            result[emphasisRange].font = .system(size: 28, weight: .black, design: .rounded)
        }

        return result
    }
}

private struct MagicalRecognitionRing: View {
    let progress: Double

    var body: some View {
        TimelineView(.animation) { timeline in
            let pulse = (sin(timeline.date.timeIntervalSinceReferenceDate * 6) + 1) / 2
            let clampedProgress = min(max(progress, 0), 1)

            GeometryReader { proxy in
                let lineWidth: CGFloat = 8
                let diameter = min(proxy.size.width, proxy.size.height)
                let radius = (diameter - lineWidth) / 2
                let angle = Angle.degrees(-90 + (360 * clampedProgress))
                let endpoint = CGPoint(
                    x: proxy.size.width / 2 + cos(angle.radians) * radius,
                    y: proxy.size.height / 2 + sin(angle.radians) * radius
                )

                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.18), lineWidth: lineWidth)

                    Circle()
                        .trim(from: 0, to: max(clampedProgress, 0.002))
                        .stroke(
                            AngularGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.63, blue: 0.0),
                                    Color(red: 1.0, green: 0.96, blue: 0.55),
                                    Color.white,
                                    Color(red: 1.0, green: 0.70, blue: 0.0)
                                ],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .shadow(
                            color: Color(red: 1.0, green: 0.78, blue: 0.10).opacity(0.9),
                            radius: 8
                        )
                        .animation(.linear(duration: 0.08), value: clampedProgress)

                    if clampedProgress > 0 {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.92))
                                .frame(width: 11 + pulse * 4, height: 11 + pulse * 4)
                                .shadow(color: GameTheme.gold, radius: 12 + pulse * 5)

                            ForEach(0..<4, id: \.self) { index in
                                let sparkleAngle = Double(index) * (.pi / 2) + pulse
                                Circle()
                                    .fill(index.isMultiple(of: 2) ? Color.white : GameTheme.gold)
                                    .frame(width: 3 + pulse * 2, height: 3 + pulse * 2)
                                    .offset(
                                        x: cos(sparkleAngle) * (12 + pulse * 5),
                                        y: sin(sparkleAngle) * (12 + pulse * 5)
                                    )
                            }
                        }
                        .position(endpoint)
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }
}

private struct ScannerLensAsset: View {
    let lensSize: CGFloat
    let lensCenterY: CGFloat

    var body: some View {
        GeometryReader { proxy in
            Image("lente")
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(
                    width: lensSize,
                    height: lensSize * ScannerLensGeometry.assetAspectRatio
                )
                .position(
                    x: proxy.size.width / 2,
                    y: lensCenterY + lensSize * ScannerLensGeometry.circleCenterOffsetRatio
                )
        }
    }
}

private struct SwapPreviewButton: View {
    let artwork: ArtworkTarget
    let showsReferenceImage: Bool
    let isDipped: Bool
    let isEnabled: Bool
    let isHighlighted: Bool
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
                    .shadow(
                        color: Color.white.opacity(isHighlighted ? 0.82 : 0),
                        radius: isHighlighted ? 18 : 0
                    )
                    .shadow(
                        color: Color(red: 0.60, green: 0.18, blue: 1.0).opacity(isDipped ? 0.12 : 0.36),
                        radius: isDipped ? 5 : 14,
                        y: isDipped ? 2 : 8
                    )

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
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.44)
        .accessibilityLabel(showsReferenceImage ? "Open camera" : "Show reference image")
    }
}

private struct ReferenceScannerSurface: View {
    let artwork: ArtworkTarget

    var body: some View {
        GeometryReader { proxy in
            let lensSize = ScannerLensGeometry.lensSize(in: proxy.size)
            let lensCenterY = proxy.size.height / 2
            let referenceSize = ScannerLensGeometry.openingSize(in: proxy.size)

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

private final class ScannerARSCNView: ARSCNView {
    var onViewportSizeChange: ((CGSize) -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        onViewportSizeChange?(bounds.size)
    }
}

private struct ARSceneView: UIViewRepresentable {
    let artwork: ArtworkTarget?
    let onRecognitionUpdate: (ArtworkRecognitionResult?) -> Void

    func makeUIView(context: Context) -> ARSCNView {
        let view = ScannerARSCNView(frame: .zero)
        view.onViewportSizeChange = { [weak coordinator = context.coordinator] size in
            coordinator?.updateViewportSize(size)
        }
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

    func updateUIView(_ uiView: ARSCNView, context: Context) {
        context.coordinator.updateViewportSize(uiView.bounds.size)
    }

    static func dismantleUIView(_ uiView: ARSCNView, coordinator: Coordinator) {
        (uiView as? ScannerARSCNView)?.onViewportSizeChange = nil
        uiView.session.pause()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(artwork: artwork, onRecognitionUpdate: onRecognitionUpdate)
    }

    final class Coordinator: NSObject, ARSessionDelegate {
        private let service = ArtworkRecognitionService()
        private let visionQueue = DispatchQueue(label: "capodimonte.coreml.vision")
        private let imageContext = CIContext(options: [.cacheIntermediates: false])
        private let viewportLock = NSLock()
        private var request: VNCoreMLRequest?
        private var isProcessingFrame = false
        private var lastAnalysisTime: TimeInterval = 0
        private var viewportSize: CGSize = .zero
        private var artwork: ArtworkTarget?
        private var onRecognitionUpdate: (ArtworkRecognitionResult?) -> Void

        init(artwork: ArtworkTarget?, onRecognitionUpdate: @escaping (ArtworkRecognitionResult?) -> Void) {
            self.artwork = artwork
            self.onRecognitionUpdate = onRecognitionUpdate
            super.init()
            configureModel()
        }

        func updateViewportSize(_ size: CGSize) {
            guard size.width > 0, size.height > 0 else {
                return
            }

            viewportLock.lock()
            viewportSize = size
            viewportLock.unlock()
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
            let viewportSize = currentViewportSize()

            visionQueue.async { [weak self] in
                guard let self, let request = self.request else {
                    return
                }

                defer {
                    self.isProcessingFrame = false
                }

                guard let lensImage = self.makeCircularLensImage(
                    from: pixelBuffer,
                    viewportSize: viewportSize
                ) else {
                    DispatchQueue.main.async { [onRecognitionUpdate = self.onRecognitionUpdate] in
                        onRecognitionUpdate(nil)
                    }
                    return
                }

                let handler = VNImageRequestHandler(cgImage: lensImage, orientation: .up)
                try? handler.perform([request])
            }
        }

        private func currentViewportSize() -> CGSize {
            viewportLock.lock()
            defer { viewportLock.unlock() }
            return viewportSize
        }

        private func makeCircularLensImage(
            from pixelBuffer: CVPixelBuffer,
            viewportSize: CGSize
        ) -> CGImage? {
            guard viewportSize.width > 0, viewportSize.height > 0 else {
                return nil
            }

            let orientedImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(.right)
            let sourceImage = orientedImage.transformed(
                by: CGAffineTransform(
                    translationX: -orientedImage.extent.minX,
                    y: -orientedImage.extent.minY
                )
            )
            let sourceExtent = sourceImage.extent
            let displayScale = max(
                viewportSize.width / sourceExtent.width,
                viewportSize.height / sourceExtent.height
            )
            let visibleCropSide = min(
                ScannerLensGeometry.openingSize(in: viewportSize),
                viewportSize.width,
                viewportSize.height
            )
            let sourceCropSide = min(
                visibleCropSide / displayScale,
                sourceExtent.width,
                sourceExtent.height
            )
            let cropRect = CGRect(
                x: sourceExtent.midX - sourceCropSide / 2,
                y: sourceExtent.midY - sourceCropSide / 2,
                width: sourceCropSide,
                height: sourceCropSide
            ).integral
            let croppedImage = sourceImage
                .cropped(to: cropRect)
                .transformed(
                    by: CGAffineTransform(
                        translationX: -cropRect.minX,
                        y: -cropRect.minY
                    )
                )
            let outputExtent = CGRect(origin: .zero, size: cropRect.size)
            let visibleLensRadius = ScannerLensGeometry.openingSize(in: viewportSize) / 2
            let sourceLensRadius = min(
                visibleLensRadius / displayScale,
                hypot(outputExtent.width, outputExtent.height) / 2
            )

            guard
                let radialMask = CIFilter(
                    name: "CIRadialGradient",
                    parameters: [
                        kCIInputCenterKey: CIVector(x: outputExtent.midX, y: outputExtent.midY),
                        "inputRadius0": max(sourceLensRadius - 1, 0),
                        "inputRadius1": sourceLensRadius,
                        "inputColor0": CIColor.white,
                        "inputColor1": CIColor.black
                    ]
                )?.outputImage?.cropped(to: outputExtent),
                let blendFilter = CIFilter(name: "CIBlendWithMask")
            else {
                return nil
            }

            blendFilter.setValue(croppedImage, forKey: kCIInputImageKey)
            blendFilter.setValue(
                CIImage(color: CIColor.black).cropped(to: outputExtent),
                forKey: kCIInputBackgroundImageKey
            )
            blendFilter.setValue(radialMask, forKey: kCIInputMaskImageKey)

            guard let maskedImage = blendFilter.outputImage else {
                return nil
            }

            return imageContext.createCGImage(maskedImage, from: outputExtent)
        }

        private func configureModel() {
            do {
                let model = try ArtworkRecognitionService.loadBundledModel()
                request = try service.makeVisionRequest(model: model) { [weak self] result in
                    DispatchQueue.main.async {
                        self?.onRecognitionUpdate(result)
                    }
                }
                request?.imageCropAndScaleOption = .scaleFill
            } catch {
                DispatchQueue.main.async { [onRecognitionUpdate] in
                    onRecognitionUpdate(nil)
                }
            }
        }
    }
}

struct ARScannerView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            preview(step: 0)
                .previewDisplayName("A-9 Find target")

            preview(step: 1)
                .previewDisplayName("A-10 Camera button")

            preview(step: 2)
                .previewDisplayName("A-11 Reference button")

            hintPreview(step: 0)
                .previewDisplayName("A-14 Scanner")

            hintPreview(step: 1)
                .previewDisplayName("A-15 Hint available")

            hintPreview(step: 2)
                .previewDisplayName("A-16 Hint overlay")
        }
    }

    private static func preview(step: Int) -> some View {
        NavigationStack {
            ARScannerView(
                artworkID: PreviewSupport.firstArtwork.id,
                usesLiveCamera: false,
                previewTutorialStep: step
            )
        }
        .environmentObject(PreviewSupport.game)
    }

    private static func hintPreview(step: Int) -> some View {
        NavigationStack {
            ARScannerView(
                artworkID: PreviewSupport.firstArtwork.id,
                usesLiveCamera: false,
                showsTutorial: false,
                previewHintStep: step
            )
        }
        .environmentObject(PreviewSupport.game)
    }
}
