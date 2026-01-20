//
//  LensProtocol.swift
//  AIDrawing
//
//  Protocol defining the interface for personality lenses
//

import Foundation
import CoreGraphics

/// Type of lens
enum LensType: String, Codable, CaseIterable {
    case musician
    case painter
    case physicist
}

/// Analysis result from a lens
struct LensAnalysis {
    let lensType: LensType
    let suggestedMoveTypes: [(moveType: AIMoveType, confidence: Double)]
    let parameters: [String: Double]  // Lens-specific analysis data
    let urgency: Double  // 0-1, how strongly lens wants to respond

    init(
        lensType: LensType,
        suggestedMoveTypes: [(AIMoveType, Double)],
        parameters: [String: Double],
        urgency: Double
    ) {
        self.lensType = lensType
        self.suggestedMoveTypes = suggestedMoveTypes
        self.parameters = parameters
        self.urgency = urgency
    }
}

/// Protocol for personality lenses
protocol Lens {
    var weight: Double { get set }  // User-configurable importance (0-2)

    func analyze(
        userStroke: Stroke,
        recentStrokes: [Stroke],
        canvasState: CanvasState
    ) -> LensAnalysis
}

// MARK: - Helper Extensions

extension LensAnalysis {
    /// Calculate urgency from confidence scores
    static func calculateUrgency(from suggestions: [(AIMoveType, Double)]) -> Double {
        guard !suggestions.isEmpty else { return 0.0 }

        // Urgency is the highest confidence score
        let maxConfidence = suggestions.map { $0.1 }.max() ?? 0.0
        return min(maxConfidence, 1.0)
    }
}
