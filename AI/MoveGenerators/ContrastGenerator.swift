//
//  ContrastGenerator.swift
//  AIDrawing
//
//  Generates contrast moves that introduce tension and deviation
//

import Foundation
import PencilKit
import CoreGraphics

class ContrastGenerator {
    /// Generate contrast move that deviates from user's pattern
    func generate(
        userStroke: Stroke,
        recentStrokes: [Stroke],
        canvasState: CanvasState,
        state: AIState,
        configuration: AIConfiguration
    ) -> AIMove? {
        // RESPOND TO STROKE QUALITIES
        // User draws curved → respond with straight lines
        // User draws fast → respond with slow, deliberate marks
        // User high pressure → respond with light touch
        // Extract angle from stroke, rotate by 45-90° for contrast

        // Analyze user's stroke characteristics
        // AMPLIFIED: Lowered thresholds for more sensitivity
        let isCurved = userStroke.curvature > 0.3 // Was 0.5, now 0.3
        let isFast = userStroke.avgVelocity > 250.0 // Was 400.0, now 250.0
        let isHighPressure = userStroke.avgPressure > 0.4 // Was 0.6, now 0.4

        // CURVATURE CONTRAST: Curved strokes get straight contrast, straight get curved
        let shouldBeStraight = isCurved
        let waveAmplitude: CGFloat = shouldBeStraight ? 0.0 : 15.0

        // Calculate opposite direction with controlled deviation
        let oppositeAngle = calculateOppositeDirection(stroke: userStroke)

        // LENGTH CONTRAST: Match or contrast based on alignment mode
        let lengthFactor: CGFloat = state.alignmentMode == .anti ? 0.4 : 0.6
        let length = CGFloat(userStroke.length) * lengthFactor

        // Start from random point along the stroke using actual path
        let t = CGFloat.random(in: 0.3...0.7)
        let start = userStroke.pointAt(fraction: t)

        var controlPoints: [PKStrokePoint] = []
        let segments = 10

        for i in 0...segments {
            let t = CGFloat(i) / CGFloat(segments)

            // Base position
            let baseX = start.x + length * t * cos(oppositeAngle)
            let baseY = start.y + length * t * sin(oppositeAngle)

            // CURVATURE RESPONSE: Add wave only if contrasting with straight strokes
            let wave = sin(t * .pi * 2) * waveAmplitude
            let x = baseX + wave * cos(oppositeAngle + .pi / 2)
            let y = baseY + wave * sin(oppositeAngle + .pi / 2)

            // PRESSURE CONTRAST: High pressure user → light AI, low pressure user → heavy AI
            let contrastPressure = isHighPressure ? 0.5 : 1.0
            let contrastSize: CGFloat = isHighPressure ? 2.0 : 4.0

            // VELOCITY CONTRAST: Fast user → slow deliberate AI (smooth, even points)
            // Slow user → energetic AI (variable)
            let force = isFast ? contrastPressure * 0.8 : contrastPressure * 1.2

            let point = PKStrokePoint(
                location: CGPoint(x: x, y: y),
                timeOffset: TimeInterval(i) * 0.01,
                size: CGSize(width: contrastSize, height: contrastSize),
                opacity: 1.0,
                force: force,
                azimuth: 0,
                altitude: .pi / 3
            )
            controlPoints.append(point)
        }

        let path = PKStrokePath(controlPoints: controlPoints, creationDate: Date())

        // PRESSURE RESPONSE: Stroke width contrasts with user
        let strokeWidth: CGFloat = isHighPressure ? 2.0 : 4.0

        // ANIMATION SPEED: Invert user's velocity for contrast
        // Fast user (>250) → slow AI animation (0.5x = deliberate, measured)
        // Slow user (<250) → fast AI animation (2.0x = quick, energetic)
        let animationSpeed = isFast ? 0.5 : 2.0

        print("🔀 ContrastGenerator: curved=\(isCurved), fast=\(isFast), highPressure=\(isHighPressure)")
        print("🔀   → straight=\(shouldBeStraight), wave=\(String(format: "%.1f", waveAmplitude)), width=\(String(format: "%.1f", strokeWidth)), animSpeed=\(animationSpeed)x")

        // Apply color variation from configuration
        let baseColor = GeneratorColors.contrastColor
        let variedColor = configuration.applyColorVariation(to: baseColor)

        return AIMove(
            moveType: .contrast,
            path: path,
            tool: PKInkingTool(.pen, color: variedColor, width: strokeWidth),
            animationSpeed: animationSpeed,
            metadata: [
                "oppositeAngle": oppositeAngle,
                "curvatureContrast": shouldBeStraight,
                "pressureContrast": isHighPressure,
                "velocityContrast": isFast
            ]
        )
    }

    private func calculateOppositeDirection(stroke: Stroke) -> CGFloat {
        let userAngle = atan2(
            stroke.endPoint.y - stroke.startPoint.y,
            stroke.endPoint.x - stroke.startPoint.x
        )

        // Add 90-180 degrees for contrast
        let contrastOffset = CGFloat.random(in: (.pi / 2)...(.pi))
        return userAngle + contrastOffset
    }
}
