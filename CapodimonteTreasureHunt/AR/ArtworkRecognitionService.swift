//
//  ArtworkRecognitionService.swift
//  CapodimonteTreasureHunt
//

import CoreML
import Foundation
import Vision

struct ArtworkRecognitionResult {
    let label: String
    let confidence: Double
}

final class ArtworkRecognitionService {
    private let minimumConfidence: Double

    init(minimumConfidence: Double = 0.82) {
        self.minimumConfidence = minimumConfidence
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
