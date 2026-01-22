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

        // DIRECTIONAL TREND: Average direction with random variation
        let baseDirection = calculateAverageDirection(allStrokes)
        // Add directional variation: ±30 degrees to explore possibilities
        let directionVariation = CGFloat.random(in: -0.52...0.52)  // ±30 degrees in radians
        let direction = baseDirection + directionVariation

        // CURVATURE RESPONSE: Use configuration curvature multiplier with randomness
        let curvatureMultiplier = configuration.applyRandomness(
            to: configuration.predictiveCurvature,
            randomness: configuration.predictiveCurvatureRandomness
        )
        let avgCurvature = allStrokes.map { $0.curvature }.reduce(0, +) / Double(allStrokes.count)

        // VARIETY IN CURVE BEHAVIOR: Mix different prediction styles
        enum PredictionStyle {
            case straight           // Continue in direction
            case gentleCurve       // Slight arc
            case strongCurve       // Pronounced arc
            case spiral            // Spiraling motion
            case overshoot         // Go past expected direction
        }

        // Choose style based on curvature and randomness
        let style: PredictionStyle
        let roll = Double.random(in: 0...1)

        if avgCurvature < 0.15 {
            // Mostly straight strokes → predict straight or gentle
            style = roll < 0.6 ? .straight : (roll < 0.85 ? .gentleCurve : .overshoot)
        } else if avgCurvature < 0.4 {
            // Moderately curved → variety of curves
            style = roll < 0.3 ? .gentleCurve : (roll < 0.7 ? .strongCurve : .spiral)
        } else {
            // Very curved → predict complex motion
            style = roll < 0.5 ? .strongCurve : .spiral
        }

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

        // Random curve side for variety (sometimes left, sometimes right)
        let curveSide = Double.random(in: 0...1) < 0.5 ? 1.0 : -1.0

        for i in 0...segments {
            let t = CGFloat(i) / CGFloat(segments)

            var x = projectionStart.x + (end.x - projectionStart.x) * t
            var y = projectionStart.y + (end.y - projectionStart.y) * t

            // APPLY PREDICTION STYLE
            switch style {
            case .straight:
                // No modification - continues in predicted direction
                break

            case .gentleCurve:
                // Subtle arc using sine wave
                let arcAmplitude: CGFloat = 15.0 * CGFloat(curvatureMultiplier) * CGFloat(curveSide)
                let arc = sin(t * .pi) * arcAmplitude
                x += arc * cos(direction + .pi / 2)
                y += arc * sin(direction + .pi / 2)

            case .strongCurve:
                // Pronounced arc with exponential growth
                let arcAmplitude: CGFloat = 30.0 * CGFloat(curvatureMultiplier) * CGFloat(curveSide)
                let arc = sin(t * .pi) * arcAmplitude * (1.0 + t * 0.5)  // Grows stronger
                x += arc * cos(direction + .pi / 2)
                y += arc * sin(direction + .pi / 2)

            case .spiral:
                // Spiraling motion with increasing radius
                let spiralRadius: CGFloat = 25.0 * CGFloat(curvatureMultiplier)
                let spiralAngle = t * .pi * 3.0  // 1.5 rotations
                let spiralOffset = spiralRadius * t  // Radius grows
                x += cos(spiralAngle + direction) * spiralOffset
                y += sin(spiralAngle + direction) * spiralOffset

            case .overshoot:
                // Overshoots then corrects back (anticipatory motion)
                let overshootAmount: CGFloat = 20.0 * CGFloat(curvatureMultiplier)
                let overshoot = sin(t * .pi * 2.0 - .pi / 2) * overshootAmount * CGFloat(curveSide)
                x += overshoot * cos(direction + .pi / 2)
                y += overshoot * sin(direction + .pi / 2)
            }

            // PRESSURE RESPONSE: Match user's typical pressure
            let avgPressure = allStrokes.map { $0.avgPressure }.reduce(0, +) / Double(allStrokes.count)
            let dynamicSize = GeneratorParameters.Predictive.pointSize * (0.8 + avgPressure * 0.4)
            let pointSize = dynamicSize

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

        // Stroke width from settings (respects user configuration!)
        let strokeWidth = GeneratorParameters.Predictive.strokeWidth

        // Apply color variation from configuration
        let baseColor = GeneratorColors.predictiveColor
        let variedColor = configuration.applyColorVariation(to: baseColor)

        let styleString = "\(style)"
        print("🔮 PredictiveGenerator: style=\(styleString), velocity=\(String(format: "%.1f", avgVelocity)), curvature=\(String(format: "%.2f", avgCurvature)), distance=\(projectionDistance.isFinite ? Int(projectionDistance) : -1)")
        print("🔮   → direction=\(String(format: "%.1f", direction * 180 / .pi))°, lineLength=\(String(format: "%.1f", baseLineLength)), curveMult=\(String(format: "%.2f", curvatureMultiplier))")

        return AIMove(
            moveType: .predictive,
            path: path,
            tool: PKInkingTool(.pen, color: variedColor, width: strokeWidth),
            metadata: [
                "projectedDirection": direction,
                "velocityFactor": velocityFactor,
                "style": styleString,
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
