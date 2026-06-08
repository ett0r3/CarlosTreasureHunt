//
//  ArtworkRecognitionService.swift
//  CarlosTreasureHunt
//

import CoreML
import Foundation
import Vision

struct ArtworkRecognitionResult {
    let label: String
    let confidence: Double
}

final class ArtworkRecognitionService {
    static let modelResourceName = "CapodimonteClassifier"

    private let minimumConfidence: Double

    init(minimumConfidence: Double = 0.85) {
        self.minimumConfidence = minimumConfidence
    }

    static func loadBundledModel() throws -> MLModel {
        guard let modelURL = Bundle.main.url(forResource: modelResourceName, withExtension: "mlmodelc") else {
            throw ModelLoadingError.missingCompiledModel(modelResourceName)
        }

        return try MLModel(contentsOf: modelURL)
    }

    func matches(_ result: ArtworkRecognitionResult, target: ArtworkTarget) -> Bool {
        result.label == target.coreMLLabel && result.confidence >= minimumConfidence
    }

    func makeVisionRequest(model: MLModel, completion: @escaping (ArtworkRecognitionResult?) -> Void) throws -> VNCoreMLRequest {
        let visionModel = try VNCoreMLModel(for: model)

        return VNCoreMLRequest(model: visionModel) { request, _ in
            let bestObservation = request.results?
                .compactMap { $0 as? VNClassificationObservation }
                .max { $0.confidence < $1.confidence }

            guard let bestObservation else {
                completion(nil)
                return
            }

            completion(
                ArtworkRecognitionResult(
                    label: bestObservation.identifier,
                    confidence: Double(bestObservation.confidence)
                )
            )
        }
    }
}

enum ModelLoadingError: LocalizedError {
    case missingCompiledModel(String)

    var errorDescription: String? {
        switch self {
        case .missingCompiledModel(let modelName):
            return "Compiled Core ML model not found in app bundle: \(modelName).mlmodelc"
        }
    }
}
