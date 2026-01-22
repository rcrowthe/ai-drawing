//
//  PhysicistLens.swift
//  AIDrawing
//
//  Analyzes dynamic systems, forces, attractors, and energy
//

import Foundation
import CoreGraphics

class PhysicistLens: Lens {
    var weight: Double = 1.0

    // Thresholds
    private let attractorMinPoints = 5
    private let energyThreshold = 200.0  // High energy threshold
    private let stabilityThreshold = 0.3
    private let epsilon = 50.0  // For clustering (DBSCAN-like)

    func analyze(
        userStroke: Stroke,
        recentStrokes: [Stroke],
        canvasState: CanvasState
    ) -> LensAnalysis {
        // ANALYZE ALL STROKES for overall system dynamics
        let allStrokes = canvasState.session.strokes

        // Extract dynamic features from ALL strokes
        let attractors = findAttractors(allStrokes)

        // Also analyze RECENT strokes including latest for oscillation and stability
        let recentPlusLatest = recentStrokes + [userStroke]
        let oscillation = detectOscillation(recentPlusLatest)
        let stabilityScore = calculateStability(recentPlusLatest)

        // Analyze JUST the latest stroke for immediate energy level
        let latestEnergy = calculateEnergyLevel(userStroke)
        let latestVelocity = userStroke.avgVelocity

        var suggestions: [(AIMoveType, Double)] = []

        // Strong attractor points - reinforce or orbit them
        if attractors.count > 0 {
            suggestions.append((.structural, 0.7))
        }

        // User is oscillating - echo the pattern
        if oscillation.isDetected {
            suggestions.append((.echo, 0.8))
        }

        // Latest stroke has HIGH ENERGY - immediate contrast/surprise response (weighted heavily)
        if latestEnergy > energyThreshold {
            suggestions.append((.contrast, 0.85))  // High confidence for latest stroke
            suggestions.append((.surprise, 0.6))
        }

        // High energy overall, unstable - introduce contrast/surprise
        if latestEnergy > energyThreshold && stabilityScore < stabilityThreshold {
            suggestions.append((.contrast, 0.6))
            suggestions.append((.surprise, 0.4))
        }

        // Low energy, stable - add gentle texture
        if latestEnergy < energyThreshold / 2 && stabilityScore > 0.7 {
            suggestions.append((.texture, 0.5))
        }

        // Latest stroke is VERY FAST (high kinetic energy) - structural bracing
        if latestVelocity > 400.0 {
            suggestions.append((.structural, 0.8))
        }

        let parameters: [String: Double] = [
            "energy": latestEnergy,
            "stability": stabilityScore,
            "attractorCount": Double(attractors.count),
            "oscillationFreq": oscillation.frequency,
            "latestEnergy": latestEnergy,  // Track latest stroke separately
            "latestVelocity": latestVelocity
        ]

        let urgency = LensAnalysis.calculateUrgency(from: suggestions)

        return LensAnalysis(
            lensType: .physicist,
            suggestedMoveTypes: suggestions,
            parameters: parameters,
            urgency: latestEnergy > energyThreshold ? 0.9 : urgency * weight
        )
    }

    // MARK: - Analysis Methods

    private func findAttractors(_ strokes: [Stroke]) -> [CGPoint] {
        guard strokes.count >= attractorMinPoints else { return [] }

        // Extract centroids
        let centroids = strokes.map { $0.boundingBox.center }

        // Use density-based clustering (DBSCAN-like)
        var clusters: [[CGPoint]] = []
        var visited = Set<Int>()

        for i in 0..<centroids.count {
            if visited.contains(i) { continue }

            var cluster: [CGPoint] = []
            var queue = [i]

            while !queue.isEmpty {
                let idx = queue.removeFirst()
                if visited.contains(idx) { continue }

                visited.insert(idx)
                cluster.append(centroids[idx])

                // Find neighbors within epsilon
                for j in 0..<centroids.count {
                    if !visited.contains(j) {
                        let distance = centroids[idx].distance(to: centroids[j])
                        if distance < epsilon {
                            queue.append(j)
                        }
                    }
                }
            }

            if cluster.count >= attractorMinPoints {
                clusters.append(cluster)
            }
        }

        // Calculate cluster centers (attractors)
        return clusters.map { cluster in
            let avgX = cluster.map { $0.x }.reduce(0, +) / CGFloat(cluster.count)
            let avgY = cluster.map { $0.y }.reduce(0, +) / CGFloat(cluster.count)
            return CGPoint(x: avgX, y: avgY)
        }
    }

    private func calculateEnergyLevel(_ stroke: Stroke) -> Double {
        // Energy = velocity * length (kinetic energy analog)
        return stroke.avgVelocity * stroke.length
    }

    private func detectOscillation(_ strokes: [Stroke]) -> (isDetected: Bool, frequency: Double) {
        guard strokes.count >= 4 else {
            return (false, 0.0)
        }

        // Analyze direction changes
        var directionChanges: [CGFloat] = []

        for i in 1..<strokes.count {
            let prev = strokes[i - 1]
            let curr = strokes[i]

            let prevAngle = atan2(prev.endPoint.y - prev.startPoint.y, prev.endPoint.x - prev.startPoint.x)
            let currAngle = atan2(curr.endPoint.y - curr.startPoint.y, curr.endPoint.x - curr.startPoint.x)

            var angleDiff = currAngle - prevAngle
            // Normalize to [-π, π]
            while angleDiff > .pi { angleDiff -= 2 * .pi }
            while angleDiff < -.pi { angleDiff += 2 * .pi }

            directionChanges.append(angleDiff)
        }

        // Check for oscillating pattern (alternating signs)
        var oscillationCount = 0
        for i in 1..<directionChanges.count {
            if (directionChanges[i] * directionChanges[i - 1]) < 0 {
                oscillationCount += 1
            }
        }

        let oscillationRatio = Double(oscillationCount) / Double(max(directionChanges.count - 1, 1))
        let isDetected = oscillationRatio > 0.6

        // Frequency (oscillations per stroke)
        let frequency = Double(oscillationCount) / Double(strokes.count)

        return (isDetected, frequency)
    }

    private func calculateStability(_ strokes: [Stroke]) -> Double {
        guard strokes.count >= 2 else { return 1.0 }

        // Stability = inverse of velocity variance
        let velocities = strokes.map { $0.avgVelocity }
        let avgVelocity = velocities.reduce(0, +) / Double(velocities.count)

        let variance = velocities.map { pow($0 - avgVelocity, 2) }.reduce(0, +) / Double(velocities.count)

        // Safety: Check variance is valid before sqrt
        guard variance.isFinite && variance >= 0 else {
            print("⚠️ PhysicistLens: Invalid variance in stability calculation")
            return 1.0
        }

        let stdDev = sqrt(variance)

        guard avgVelocity > 0 else { return 1.0 }

        // Coefficient of variation (inverse = stability)
        let coefficientOfVariation = stdDev / avgVelocity
        return max(0.0, 1.0 - coefficientOfVariation)
    }
}
