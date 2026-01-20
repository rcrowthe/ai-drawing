//
//  LensAggregator.swift
//  AIDrawing
//
//  Combines outputs from all three personality lenses
//

import Foundation

/// Aggregated analysis from all lenses
struct AggregatedAnalysis {
    let suggestedMoves: [(moveType: AIMoveType, confidence: Double)]
    let lensAnalyses: [LensAnalysis]

    /// Get parameters from specific lens
    func parameters(for lensType: LensType) -> [String: Double] {
        return lensAnalyses.first { $0.lensType == lensType }?.parameters ?? [:]
    }
}

class LensAggregator {
    private let musicianLens: MusicianLens
    private let painterLens: PainterLens
    private let physicistLens: PhysicistLens

    init() {
        self.musicianLens = MusicianLens()
        self.painterLens = PainterLens()
        self.physicistLens = PhysicistLens()
    }

    /// Update lens weights from configuration
    func updateWeights(configuration: AIConfiguration) {
        musicianLens.weight = configuration.musicianWeight
        painterLens.weight = configuration.painterWeight
        physicistLens.weight = configuration.physicistWeight
    }

    /// Aggregate analyses from all lenses
    func aggregate(
        userStroke: Stroke,
        recentStrokes: [Stroke],
        canvasState: CanvasState,
        configuration: AIConfiguration
    ) -> AggregatedAnalysis {
        // Update weights
        updateWeights(configuration: configuration)

        // Run all lenses in parallel (conceptually)
        let musicianAnalysis = musicianLens.analyze(
            userStroke: userStroke,
            recentStrokes: recentStrokes,
            canvasState: canvasState
        )

        let painterAnalysis = painterLens.analyze(
            userStroke: userStroke,
            recentStrokes: recentStrokes,
            canvasState: canvasState
        )

        let physicistAnalysis = physicistLens.analyze(
            userStroke: userStroke,
            recentStrokes: recentStrokes,
            canvasState: canvasState
        )

        // Collect all analyses
        let analyses = [musicianAnalysis, painterAnalysis, physicistAnalysis]

        // Combine suggestions with weighted scores
        let weightedSuggestions = combine(analyses: analyses)

        return AggregatedAnalysis(
            suggestedMoves: weightedSuggestions,
            lensAnalyses: analyses
        )
    }

    // MARK: - Combination Logic

    private func combine(analyses: [LensAnalysis]) -> [(AIMoveType, Double)] {
        var moveScores: [AIMoveType: Double] = [:]

        // FORCE VARIETY: Start with baseline scores for ALL move types
        moveScores[.echo] = 0.3
        moveScores[.texture] = 0.3
        moveScores[.structural] = 0.3
        moveScores[.contrast] = 0.3
        moveScores[.predictive] = 0.3
        moveScores[.surprise] = 0.3

        for analysis in analyses {
            for (moveType, confidence) in analysis.suggestedMoveTypes {
                // Weighted confidence = confidence * urgency * lens weight
                let weightedConfidence = confidence * analysis.urgency

                // Accumulate scores (adds to baseline)
                moveScores[moveType, default: 0.3] += weightedConfidence
            }
        }

        // Sort by score (highest first)
        let sortedMoves = moveScores.sorted { $0.value > $1.value }

        // Normalize scores to [0, 1] range
        guard let maxScore = sortedMoves.first?.value, maxScore > 0 else {
            return []
        }

        let normalized = sortedMoves.map { (moveType, score) in
            (moveType, min(score / maxScore, 1.0))
        }

        print("🔍 LensAggregator final suggestions:")
        for (moveType, confidence) in normalized {
            print("🔍   - \(moveType): \(String(format: "%.2f", confidence))")
        }

        return normalized
    }
}
