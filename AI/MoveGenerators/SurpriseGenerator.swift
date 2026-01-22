//
//  SurpriseGenerator.swift
//  AIDrawing
//
//  Generates surprise moves with unexpected but contextual deviations
//

import Foundation
import PencilKit
import CoreGraphics

class SurpriseGenerator {
    /// Generate surprise move - unexpected but still contextually relevant
    /// Surprise = breaking expected patterns while staying connected to the composition
    func generate(
        userStroke: Stroke,
        recentStrokes: [Stroke],
        canvasState: CanvasState,
        state: AIState,
        configuration: AIConfiguration
    ) -> AIMove? {
        // Surprise should break expectations but still be compositionally relevant
        // Option 1: Sudden directional shift (perpendicular continuation)
        // Option 2: Scale jump (much larger or smaller than expected)
        // Option 3: Energy inversion (slow becomes explosive, fast becomes gentle)

        let surpriseType = Int.random(in: 0...2)

        switch surpriseType {
        case 0:
            return generatePerpendicularFlourish(from: userStroke, configuration: configuration)
        case 1:
            return generateScaleJump(from: userStroke, canvasState: canvasState, configuration: configuration)
        default:
            return generateEnergyInversion(from: userStroke, configuration: configuration)
        }
    }

    private func generatePerpendicularFlourish(from stroke: Stroke, configuration: AIConfiguration) -> AIMove? {
        // Start from the end of the user's stroke
        let start = stroke.endPoint

        // Calculate perpendicular direction to user stroke
        let strokeAngle = atan2(
            stroke.endPoint.y - stroke.startPoint.y,
            stroke.endPoint.x - stroke.startPoint.x
        )
        let perpAngle = strokeAngle + .pi / 2

        // Create a quick flourish perpendicular to the stroke direction
        let length: CGFloat = stroke.length * 0.4
        var controlPoints: [PKStrokePoint] = []

        let segments = 8
        for i in 0...segments {
            let t = CGFloat(i) / CGFloat(segments)

            // Add slight curve to the flourish
            let curveFactor = sin(t * .pi) * 0.3
            let x = start.x + length * t * CGFloat(cos(perpAngle)) + length * curveFactor * CGFloat(cos(perpAngle + .pi/2))
            let y = start.y + length * t * CGFloat(sin(perpAngle)) + length * curveFactor * CGFloat(sin(perpAngle + .pi/2))

            let point = PKStrokePoint(
                location: CGPoint(x: x, y: y),
                timeOffset: TimeInterval(i) * 0.01,
                size: CGSize(width: 3.0, height: 3.0),
                opacity: 1.0,
                force: 0.6,
                azimuth: 0,
                altitude: .pi / 4
            )
            controlPoints.append(point)
        }

        let path = PKStrokePath(controlPoints: controlPoints, creationDate: Date())

        // Apply color variation from configuration
        let baseColor = GeneratorColors.surpriseColor
        let variedColor = configuration.applyColorVariation(to: baseColor)

        return AIMove(
            moveType: .surprise,
            path: path,
            tool: PKInkingTool(.pen, color: variedColor, width: 2.5),
            metadata: ["surpriseType": "perpendicular"]
        )
    }

    private func generateScaleJump(from stroke: Stroke, canvasState: CanvasState, configuration: AIConfiguration) -> AIMove? {
        // Create a stroke that is dramatically larger or smaller than the user's
        let scaleMultiplier: CGFloat = stroke.length > 100 ? 0.3 : 3.0  // Invert scale

        // Start from the end of the user's stroke (not offset)
        let start = stroke.endPoint

        // Mimic the user's stroke direction but at different scale
        let strokeAngle = atan2(
            stroke.endPoint.y - stroke.startPoint.y,
            stroke.endPoint.x - stroke.startPoint.x
        )

        let scaledLength = stroke.length * scaleMultiplier
        var controlPoints: [PKStrokePoint] = []

        let segments = 6
        for i in 0...segments {
            let t = CGFloat(i) / CGFloat(segments)
            let x = start.x + scaledLength * t * CGFloat(cos(strokeAngle))
            let y = start.y + scaledLength * t * CGFloat(sin(strokeAngle))

            let point = PKStrokePoint(
                location: CGPoint(x: x, y: y),
                timeOffset: TimeInterval(i) * 0.01,
                size: CGSize(width: 2.5, height: 2.5),
                opacity: 1.0,
                force: 0.7,
                azimuth: 0,
                altitude: .pi / 4
            )
            controlPoints.append(point)
        }

        let path = PKStrokePath(controlPoints: controlPoints, creationDate: Date())

        // Apply color variation from configuration
        let baseColor = GeneratorColors.surpriseColor
        let variedColor = configuration.applyColorVariation(to: baseColor)

        return AIMove(
            moveType: .surprise,
            path: path,
            tool: PKInkingTool(.pen, color: variedColor, width: scaleMultiplier > 1 ? 4.0 : 1.5),
            metadata: ["surpriseType": "scaleJump", "scale": Double(scaleMultiplier)]
        )
    }

    private func generateEnergyInversion(from stroke: Stroke, configuration: AIConfiguration) -> AIMove? {
        // If user drew fast → respond with slow deliberate mark
        // If user drew slow → respond with quick energetic burst

        let isFast = stroke.avgVelocity > 300.0

        if isFast {
            // Slow, deliberate arc
            return generateSlowArc(from: stroke, configuration: configuration)
        } else {
            // Quick, energetic burst
            return generateQuickBurst(from: stroke, configuration: configuration)
        }
    }

    private func generateSlowArc(from stroke: Stroke, configuration: AIConfiguration) -> AIMove? {
        let start = stroke.endPoint
        let strokeAngle = atan2(
            stroke.endPoint.y - stroke.startPoint.y,
            stroke.endPoint.x - stroke.startPoint.x
        )

        var controlPoints: [PKStrokePoint] = []
        let radius: CGFloat = 60.0
        let arcAngle: CGFloat = .pi / 2

        let segments = 12
        for i in 0...segments {
            let t = CGFloat(i) / CGFloat(segments)
            let angle = strokeAngle + arcAngle * t

            let x = start.x + radius * (1 - CGFloat(cos(arcAngle * t))) * CGFloat(cos(strokeAngle + .pi/2))
            let y = start.y + radius * (1 - CGFloat(cos(arcAngle * t))) * CGFloat(sin(strokeAngle + .pi/2))

            let point = PKStrokePoint(
                location: CGPoint(x: x, y: y),
                timeOffset: TimeInterval(i) * 0.02,  // Slower timing
                size: CGSize(width: 3.5, height: 3.5),
                opacity: 1.0,
                force: 0.8,
                azimuth: 0,
                altitude: .pi / 3
            )
            controlPoints.append(point)
        }

        let path = PKStrokePath(controlPoints: controlPoints, creationDate: Date())

        // Apply color variation from configuration
        let baseColor = GeneratorColors.surpriseColor
        let variedColor = configuration.applyColorVariation(to: baseColor)

        return AIMove(
            moveType: .surprise,
            path: path,
            tool: PKInkingTool(.pen, color: variedColor, width: 3.0),
            metadata: ["surpriseType": "slowArc"]
        )
    }

    private func generateQuickBurst(from stroke: Stroke, configuration: AIConfiguration) -> AIMove? {
        let start = stroke.endPoint
        let strokeAngle = atan2(
            stroke.endPoint.y - stroke.startPoint.y,
            stroke.endPoint.x - stroke.startPoint.x
        )

        // Quick shooting line
        var controlPoints: [PKStrokePoint] = []
        let length: CGFloat = 80.0

        let segments = 4  // Very few points = quick
        for i in 0...segments {
            let t = CGFloat(i) / CGFloat(segments)
            let x = start.x + length * t * CGFloat(cos(strokeAngle))
            let y = start.y + length * t * CGFloat(sin(strokeAngle))

            let point = PKStrokePoint(
                location: CGPoint(x: x, y: y),
                timeOffset: TimeInterval(i) * 0.005,  // Fast timing
                size: CGSize(width: 2.0, height: 2.0),
                opacity: 1.0,
                force: 0.5,
                azimuth: 0,
                altitude: .pi / 4
            )
            controlPoints.append(point)
        }

        let path = PKStrokePath(controlPoints: controlPoints, creationDate: Date())

        // Apply color variation from configuration
        let baseColor = GeneratorColors.surpriseColor
        let variedColor = configuration.applyColorVariation(to: baseColor)

        return AIMove(
            moveType: .surprise,
            path: path,
            tool: PKInkingTool(.pen, color: variedColor, width: 1.5),
            metadata: ["surpriseType": "quickBurst"]
        )
    }
}
