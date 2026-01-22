//
//  FeatureExtractor.swift
//  AIDrawing
//
//  Extracts features from strokes for Core ML models
//

import Foundation
import CoreGraphics
import CoreML

class FeatureExtractor {

    // MARK: - Feature Extraction

    /// Extract comprehensive features from a stroke for ML classification
    func extractFeatures(from stroke: Stroke) -> StrokeFeatures {
        return StrokeFeatures(
            // Basic geometry
            length: stroke.length,
            avgVelocity: stroke.avgVelocity,
            avgPressure: stroke.avgPressure,
            curvature: stroke.curvature,
            directionChanges: Double(stroke.directionChanges),

            // Bounding box metrics
            boundingBoxArea: stroke.boundingBox.width * stroke.boundingBox.height,
            aspectRatio: stroke.boundingBox.width / max(1.0, stroke.boundingBox.height),

            // Path metrics
            startToEndDistance: calculateStartToEndDistance(stroke),
            pathEfficiency: calculatePathEfficiency(stroke),

            // Angular metrics
            averageAngle: calculateAverageAngle(stroke),
            angleVariance: calculateAngleVariance(stroke)
        )
    }

    /// Extract features from multiple strokes for sequence analysis
    func extractSequenceFeatures(from strokes: [Stroke]) -> SequenceFeatures {
        guard !strokes.isEmpty else {
            return SequenceFeatures.empty
        }

        let velocities = strokes.map { $0.avgVelocity }
        let pressures = strokes.map { $0.avgPressure }

        return SequenceFeatures(
            count: strokes.count,
            avgVelocity: velocities.reduce(0, +) / Double(velocities.count),
            velocityVariance: calculateVariance(velocities),
            avgPressure: pressures.reduce(0, +) / Double(pressures.count),
            pressureVariance: calculateVariance(pressures),
            temporalDensity: calculateTemporalDensity(strokes),
            spatialSpread: calculateSpatialSpread(strokes)
        )
    }

    // MARK: - Geometry Calculations

    private func calculateStartToEndDistance(_ stroke: Stroke) -> Double {
        let dx = stroke.endPoint.x - stroke.startPoint.x
        let dy = stroke.endPoint.y - stroke.startPoint.y
        let distanceSquared = dx * dx + dy * dy

        // Safety: Check for valid value before sqrt
        guard distanceSquared.isFinite && distanceSquared >= 0 else {
            print("⚠️ FeatureExtractor: Invalid distance calculation")
            return 0.0
        }

        return sqrt(distanceSquared)
    }

    private func calculatePathEfficiency(_ stroke: Stroke) -> Double {
        let straightLineDistance = calculateStartToEndDistance(stroke)
        return straightLineDistance / max(1.0, stroke.length)
    }

    private func calculateAverageAngle(_ stroke: Stroke) -> Double {
        let dx = stroke.endPoint.x - stroke.startPoint.x
        let dy = stroke.endPoint.y - stroke.startPoint.y
        return atan2(dy, dx)
    }

    private func calculateAngleVariance(_ stroke: Stroke) -> Double {
        // Simplified: use direction changes as proxy for angle variance
        return Double(stroke.directionChanges) / max(1.0, stroke.length)
    }

    // MARK: - Sequence Calculations

    private func calculateVariance(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0.0 }

        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDiffs = values.map { pow($0 - mean, 2) }
        return squaredDiffs.reduce(0, +) / Double(values.count)
    }

    private func calculateTemporalDensity(_ strokes: [Stroke]) -> Double {
        guard strokes.count > 1 else { return 0.0 }

        let timeSpan = strokes.last!.timestamp.timeIntervalSince(strokes.first!.timestamp)
        return Double(strokes.count) / max(1.0, timeSpan)
    }

    private func calculateSpatialSpread(_ strokes: [Stroke]) -> Double {
        guard !strokes.isEmpty else { return 0.0 }

        // Calculate centroid
        var sumX: CGFloat = 0
        var sumY: CGFloat = 0

        for stroke in strokes {
            sumX += stroke.boundingBox.midX
            sumY += stroke.boundingBox.midY
        }

        let centroidX = sumX / CGFloat(strokes.count)
        let centroidY = sumY / CGFloat(strokes.count)

        // Calculate average distance from centroid
        var totalDistance: Double = 0

        for stroke in strokes {
            let dx = stroke.boundingBox.midX - centroidX
            let dy = stroke.boundingBox.midY - centroidY
            let distanceSquared = Double(dx * dx + dy * dy)

            // Safety: Check for valid value before sqrt
            guard distanceSquared.isFinite && distanceSquared >= 0 else {
                print("⚠️ FeatureExtractor: Invalid distance in spread calculation")
                continue
            }

            totalDistance += sqrt(distanceSquared)
        }

        return totalDistance / Double(strokes.count)
    }
}

// MARK: - Feature Structures

struct StrokeFeatures {
    let length: Double
    let avgVelocity: Double
    let avgPressure: Double
    let curvature: Double
    let directionChanges: Double
    let boundingBoxArea: Double
    let aspectRatio: Double
    let startToEndDistance: Double
    let pathEfficiency: Double
    let averageAngle: Double
    let angleVariance: Double

    /// Convert to MLMultiArray for Core ML input
    func toMLMultiArray() -> MLMultiArray? {
        guard let array = try? MLMultiArray(shape: [11], dataType: .double) else {
            return nil
        }

        array[0] = NSNumber(value: length)
        array[1] = NSNumber(value: avgVelocity)
        array[2] = NSNumber(value: avgPressure)
        array[3] = NSNumber(value: curvature)
        array[4] = NSNumber(value: directionChanges)
        array[5] = NSNumber(value: boundingBoxArea)
        array[6] = NSNumber(value: aspectRatio)
        array[7] = NSNumber(value: startToEndDistance)
        array[8] = NSNumber(value: pathEfficiency)
        array[9] = NSNumber(value: averageAngle)
        array[10] = NSNumber(value: angleVariance)

        return array
    }
}

struct SequenceFeatures {
    let count: Int
    let avgVelocity: Double
    let velocityVariance: Double
    let avgPressure: Double
    let pressureVariance: Double
    let temporalDensity: Double
    let spatialSpread: Double

    static var empty: SequenceFeatures {
        SequenceFeatures(
            count: 0,
            avgVelocity: 0,
            velocityVariance: 0,
            avgPressure: 0,
            pressureVariance: 0,
            temporalDensity: 0,
            spatialSpread: 0
        )
    }
}
