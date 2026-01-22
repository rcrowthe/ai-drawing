//
//  PredictiveGenerator.swift
//  AIDrawing
//
//  Generates predictive moves that anticipate where user will draw next
//

import Foundation
import PencilKit
import CoreGraphics

class PredictiveGenerator {
    /// Generate predictive move anticipating user's next stroke
    func generate(
        userStroke: Stroke,
        recentStrokes: [Stroke],
        canvasState: CanvasState,
        state: AIState,
        configuration: AIConfiguration
    ) -> AIMove? {
        // RESPOND TO STROKE QUALITIES
        // Analyze last 3-5 strokes for directional trend
        // High velocity → predict further ahead
        // Rhythmic repetition detected → predict continuation of pattern
        // Use curvature to predict arc continuation

        let allStrokes = recentStrokes + [userStroke]

        // VELOCITY RESPONSE: Fast strokes → predict further ahead
        let avgVelocity = calculateAverageVelocity(allStrokes)
        let velocityFactor = min(avgVelocity / 200.0, 3.0)

        // USE CONFIGURATION PARAMETERS WITH RANDOMNESS
        let baseLineLength = configuration.applyRandomness(
            to: configuration.predictiveLineLength,
            randomness: configuration.predictiveLineLengthRandomness
        )
        let projectionDistance = CGFloat(baseLineLength) * CGFloat(velocityFactor)

        // DIRECTIONAL TREND: Average direction from recent strokes
        let direction = calculateAverageDirection(allStrokes)

        // CURVATURE RESPONSE: Use configuration curvature multiplier with randomness
        let curvatureMultiplier = configuration.applyRandomness(
            to: configuration.predictiveCurvature,
            randomness: configuration.predictiveCurvatureRandomness
        )
        let avgCurvature = allStrokes.map { $0.curvature }.reduce(0, +) / Double(allStrokes.count)
        let shouldCurve = avgCurvature > 0.25

        // Project forward from a position along the stroke
        let startT = avgVelocity > 250.0 ? CGFloat.random(in: 0.7...1.0) : CGFloat.random(in: 0.5...0.8)
        let projectionStart = CGPoint(
            x: userStroke.startPoint.x + (userStroke.endPoint.x - userStroke.startPoint.x) * startT,
            y: userStroke.startPoint.y + (userStroke.endPoint.y - userStroke.startPoint.y) * startT
        )

        let end = CGPoint(
            x: projectionStart.x + projectionDistance * cos(direction),
            y: projectionStart.y + projectionDistance * sin(direction)
        )

        var controlPoints: [PKStrokePoint] = []
        let segments = 6

        for i in 0...segments {
            let t = CGFloat(i) / CGFloat(segments)

            var x = projectionStart.x + (end.x - projectionStart.x) * t
            var y = projectionStart.y + (end.y - projectionStart.y) * t

            // CURVATURE RESPONSE: Add arc if user strokes were curved, scaled by config
            if shouldCurve {
                let arcAmplitude: CGFloat = 20.0 * CGFloat(avgCurvature * curvatureMultiplier)
                let arc = sin(t * .pi) * arcAmplitude
                x += arc * cos(direction + .pi / 2)
                y += arc * sin(direction + .pi / 2)
            }

            // PRESSURE RESPONSE: Match user's typical pressure
            let avgPressure = allStrokes.map { $0.avgPressure }.reduce(0, +) / Double(allStrokes.count)
            let dynamicSize = 2.0 + (avgPressure * 2.0)
            let pointSize = max(3.5, dynamicSize)

            let point = PKStrokePoint(
                location: CGPoint(x: x, y: y),
                timeOffset: TimeInterval(i) * 0.01,
                size: CGSize(width: pointSize, height: pointSize),
                opacity: 1.0,
                force: avgPressure,
                azimuth: 0,
                altitude: .pi / 4
            )
            controlPoints.append(point)
        }

        let path = PKStrokePath(controlPoints: controlPoints, creationDate: Date())

        // Stroke width based on velocity
        let strokeWidth = 2.0 + (avgVelocity / 200.0)

        // Apply color variation from configuration
        let baseColor = GeneratorColors.predictiveColor
        let variedColor = configuration.applyColorVariation(to: baseColor)

        print("🔮 PredictiveGenerator: velocity=\(String(format: "%.1f", avgVelocity)), curvature=\(String(format: "%.2f", avgCurvature)), distance=\(projectionDistance.isFinite ? Int(projectionDistance) : -1)")
        print("🔮   → curved=\(shouldCurve), lineLength=\(String(format: "%.1f", baseLineLength)), curveMult=\(String(format: "%.2f", curvatureMultiplier))")

        return AIMove(
            moveType: .predictive,
            path: path,
            tool: PKInkingTool(.pen, color: variedColor, width: strokeWidth),
            metadata: [
                "projectedDirection": direction,
                "velocityFactor": velocityFactor,
                "curved": shouldCurve,
                "lineLength": baseLineLength
            ]
        )
    }

    private func calculateAverageVelocity(_ strokes: [Stroke]) -> Double {
        guard !strokes.isEmpty else { return 0.0 }
        return strokes.map { $0.avgVelocity }.reduce(0, +) / Double(strokes.count)
    }

    private func calculateAverageDirection(_ strokes: [Stroke]) -> CGFloat {
        guard !strokes.isEmpty else { return 0.0 }

        var sumSin: CGFloat = 0.0
        var sumCos: CGFloat = 0.0

        for stroke in strokes {
            let angle = atan2(stroke.endPoint.y - stroke.startPoint.y, stroke.endPoint.x - stroke.startPoint.x)
            sumSin += sin(angle)
            sumCos += cos(angle)
        }

        return atan2(sumSin, sumCos)
    }
}
