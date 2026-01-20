//
//  MLModelManager.swift
//  AIDrawing
//
//  Manages Core ML models for on-device gesture classification
//

import Foundation
import CoreML

class MLModelManager {
    private let featureExtractor = FeatureExtractor()

    // MARK: - Gesture Classification

    /// Classify a stroke gesture using heuristics (placeholder for ML model)
    func classifyGesture(_ stroke: Stroke) -> GestureType {
        let features = featureExtractor.extractFeatures(from: stroke)

        // Heuristic-based classification (replaces ML model for now)
        return classifyWithHeuristics(features)
    }

    /// Classify multiple strokes as a gesture sequence
    func classifySequence(_ strokes: [Stroke]) -> SequenceType {
        guard !strokes.isEmpty else { return .isolated }

        let sequenceFeatures = featureExtractor.extractSequenceFeatures(from: strokes)

        // Classify based on temporal and spatial characteristics
        if sequenceFeatures.temporalDensity > 2.0 {
            return .rapid
        } else if sequenceFeatures.temporalDensity < 0.5 {
            return .deliberate
        }

        if sequenceFeatures.spatialSpread < 50 {
            return .concentrated
        } else if sequenceFeatures.spatialSpread > 200 {
            return .exploratory
        }

        return .continuous
    }

    // MARK: - Heuristic Classification

    private func classifyWithHeuristics(_ features: StrokeFeatures) -> GestureType {
        // Very short strokes -> dot
        if features.length < 10 {
            return .dot
        }

        // High path efficiency + low curvature -> line
        if features.pathEfficiency > 0.8 && features.curvature < 0.1 {
            return .line
        }

        // Check for loop/circle (high curvature + closed path)
        if features.curvature > 0.5 && features.pathEfficiency < 0.3 {
            return .circle
        }

        // High direction changes -> zigzag
        if features.directionChanges > 4 {
            return .zigzag
        }

        // Moderate curvature -> curve
        if features.curvature > 0.1 && features.curvature < 0.5 {
            return .curve
        }

        // Arc shape (moderate curve + moderate efficiency)
        if features.curvature > 0.2 && features.pathEfficiency > 0.4 && features.pathEfficiency < 0.8 {
            return .arc
        }

        // Default
        return .gesture
    }

    // MARK: - Density Prediction

    /// Predict next density hotspot (placeholder for ML model)
    func predictNextDensity(session: DrawingSession) -> CGPoint? {
        let userStrokes = session.strokes.filter { $0.source == .user }
        guard userStrokes.count > 3 else { return nil }

        // Simple heuristic: weighted average of recent stroke positions
        let recentStrokes = Array(userStrokes.suffix(5))

        var weightedX: CGFloat = 0
        var weightedY: CGFloat = 0
        var totalWeight: CGFloat = 0

        for (index, stroke) in recentStrokes.enumerated() {
            let weight = CGFloat(index + 1) // More recent = higher weight
            weightedX += stroke.endPoint.x * weight
            weightedY += stroke.endPoint.y * weight
            totalWeight += weight
        }

        return CGPoint(
            x: weightedX / totalWeight,
            y: weightedY / totalWeight
        )
    }

    // MARK: - Future: Load Trained ML Models

    /*
    /// Load a trained Core ML model (future implementation)
    func loadGestureClassifier() throws {
        // Load .mlmodel file
        // let model = try GestureClassifier(configuration: MLModelConfiguration())
        // self.gestureClassifier = model
    }

    /// Use trained model for prediction
    func predictWithModel(_ features: StrokeFeatures) -> GestureType? {
        guard let inputArray = features.toMLMultiArray() else { return nil }

        // Run inference
        // let prediction = try? gestureClassifier.prediction(input: inputArray)
        // return GestureType(rawValue: prediction.classLabel)

        return nil
    }
    */
}

// MARK: - Classification Types

enum GestureType: String, Codable {
    case dot
    case line
    case curve
    case arc
    case circle
    case zigzag
    case gesture  // Generic/unclassified
}

enum SequenceType: String {
    case isolated       // Single strokes, disconnected
    case continuous     // Flowing, connected
    case rapid          // Fast succession
    case deliberate     // Slow, careful
    case concentrated   // Focused in small area
    case exploratory    // Spread across canvas
}
