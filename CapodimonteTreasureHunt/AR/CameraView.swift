//
//  CameraView.swift
//  CapodimonteTreasureHunt
//
//  Created by AFP FED 02 on 04/06/26.
//

import SwiftUI
import AVFoundation
import Vision
import CoreML
import Combine

struct CameraView: View {

    @StateObject private var camera = CameraViewModel()

    var body: some View {

        ZStack {

            CameraPreview(session: camera.session)
                .ignoresSafeArea()

            VStack {

                Spacer()

                Text(camera.detectedArtwork)
                    .font(.title)
                    .bold()
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            camera.checkPermissions()
            camera.setupCamera()
        }
    }
}

class CameraViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    @Published var detectedArtwork = "Inquadra un dipinto"

    let session = AVCaptureSession()

    private let videoOutput = AVCaptureVideoDataOutput()

    private var requests = [VNRequest]()

    func checkPermissions() {

        AVCaptureDevice.requestAccess(for: .video) { granted in

            if granted {
                print("Camera autorizzata")
            }
        }
    }

    func setupCamera() {

        session.beginConfiguration()

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                 for: .video,
                                                 position: .back),

            let input = try? AVCaptureDeviceInput(device: device)

        else { return }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        videoOutput.setSampleBufferDelegate(
            self,
            queue: DispatchQueue(label: "videoQueue")
        )

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        session.commitConfiguration()

        setupModel()

        session.startRunning()
    }

    func setupModel() {

        guard let model = try? VNCoreMLModel(
            for: CapodimonteClassifier().model
        ) else {
            return
        }

        let request = VNCoreMLRequest(model: model) { request, error in

            guard
                let results = request.results as? [VNClassificationObservation],
                let first = results.first
            else { return }

            DispatchQueue.main.async {

                self.detectedArtwork =
                    "\(first.identifier) - \(Int(first.confidence * 100))%"
            }
        }

        self.requests = [request]
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {

        guard
            let pixelBuffer =
                CMSampleBufferGetImageBuffer(sampleBuffer)
        else { return }

        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .up
        )

        try? handler.perform(requests)
    }
}

struct CameraPreview: UIViewRepresentable {

    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {

        let view = UIView(frame: UIScreen.main.bounds)

        let previewLayer = AVCaptureVideoPreviewLayer(
            session: session
        )

        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill

        view.layer.addSublayer(previewLayer)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

#Preview {
    CameraView()
}
