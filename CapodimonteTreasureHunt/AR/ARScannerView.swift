//
//  ARScannerView.swift
//  CapodimonteTreasureHunt
//

import ARKit
import SceneKit
import SwiftUI

struct ARScannerView: View {
    @EnvironmentObject private var game: GameStore
    let artworkID: UUID

    var body: some View {
        ZStack {
            ARSceneView()
                .ignoresSafeArea()

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
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
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
