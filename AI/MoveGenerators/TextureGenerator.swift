//
//  TextureGenerator.swift
//  AIDrawing
//
//  Generates texture moves: hatching, stippling, dots
//

import Foundation
import PencilKit
import CoreGraphics

class TextureGenerator {
    /// Generate texture move near the user's stroke
    func generate(
        userStroke: Stroke,
        recentStrokes: [Stroke],
        canvasState: CanvasState,
        state: AIState,
        configuration: AIConfiguration
    ) -> AIMove? {
        // RESPOND TO STROKE QUALITIES
        // High pressure → dense stippling
        // Low pressure → sparse hatching
        // Fast stroke → angled hatching following momentum
        // Slow stroke → perpendicular cross-hatching

        let density = canvasState.session.calculateDensity()
        let textureType = selectTextureType(
            attentionMode: state.attentionMode,
            density: density,
            pressure: userStroke.avgPressure,
            velocity: userStroke.avgVelocity
        )

        switch textureType {
        case .hatching:
            return generateHatching(near: userStroke, state: state, configuration: configuration)
        case .stippling:
            return generateStippling(near: userStroke, state: state, pressure: userStroke.avgPressure, configuration: configuration)
        case .dots:
            return generateDots(near: userStroke, state: state, configuration: configuration)
        }
    }

    // MARK: - Texture Type Selection

    private enum TextureType {
        case hatching, stippling, dots
    }

    private func selectTextureType(
        attentionMode: AttentionMode,
        density: Double,
        pressure: Double,
        velocity: Double
    ) -> TextureType {
        // PRESSURE RESPONSE: High pressure favors dense stippling
        // AMPLIFIED: Lowered threshold from 0.7 to 0.5 for more sensitivity
        if pressure > 0.5 {
            return .stippling
        }

        // VELOCITY RESPONSE: Fast strokes favor hatching
        // AMPLIFIED: Lowered threshold from 400 to 300 for more sensitivity
        if velocity > 300.0 {
            return .hatching
        }

        if attentionMode == .wander {
            // In wander mode, prefer stippling or dots
            return Double.random(in: 0...1) < 0.5 ? .stippling : .dots
        } else {
            // In focus mode, prefer hatching for structural reinforcement
            return .hatching
        }
    }

    // MARK: - Hatching Generation

    private func generateHatching(near stroke: Stroke, state: AIState, configuration: AIConfiguration) -> AIMove? {
        // Create SHORT hatching strokes that FOLLOW the user's stroke
        // These should feel like shading/texture applied TO the stroke

        let bounds = stroke.boundingBox

        // Determine hatching angle - parallel to stroke for reinforcement
        let strokeAngle = atan2(
            stroke.endPoint.y - stroke.startPoint.y,
            stroke.endPoint.x - stroke.startPoint.x
        )

        // Create short hatching lines perpendicular to the stroke
        let hatchAngle = strokeAngle + .pi / 2

        // Very short hatching lines (not full strokes)
        let lineLength: CGFloat = 15.0  // Much shorter
        let lineCount = 3  // Fewer lines
        let spacing: CGFloat = 8.0

        var controlPoints: [PKStrokePoint] = []

        // Generate SHORT parallel lines near the stroke
        for i in 0..<lineCount {
            // Position along the user's stroke
            let t = CGFloat(i) / CGFloat(lineCount - 1)
            let baseX = stroke.startPoint.x + (stroke.endPoint.x - stroke.startPoint.x) * t
            let baseY = stroke.startPoint.y + (stroke.endPoint.y - stroke.startPoint.y) * t

            // Offset slightly perpendicular
            let offset: CGFloat = 10.0
            let startX = baseX + offset * cos(hatchAngle)
            let startY = baseY + offset * sin(hatchAngle)

            // Short line parallel to stroke
            let endX = startX + lineLength * cos(strokeAngle)
            let endY = startY + lineLength * sin(strokeAngle)

            // Create stroke points for this hatch line
            let segments = 2  // Just 2 points for a short line
            for j in 0...segments {
                let segT = CGFloat(j) / CGFloat(segments)
                let x = startX + (endX - startX) * segT
                let y = startY + (endY - startY) * segT

                let point = PKStrokePoint(
                    location: CGPoint(x: x, y: y),
                    timeOffset: TimeInterval(i * segments + j) * 0.01,
                    size: CGSize(width: 1.5, height: 1.5),
                    opacity: 0.8,
                    force: 0.5,
                    azimuth: 0,
                    altitude: .pi / 4
                )
                controlPoints.append(point)
            }
        }

        guard !controlPoints.isEmpty else { return nil }

        let path = PKStrokePath(controlPoints: controlPoints, creationDate: Date())

        // Apply color variation from configuration
        let baseColor = GeneratorColors.textureColor
        let variedColor = configuration.applyColorVariation(to: baseColor)

        print("🎨 TextureGenerator (hatching): velocity=\(String(format: "%.1f", stroke.avgVelocity)), angle=\(String(format: "%.2f", hatchAngle))")

        return AIMove(
            moveType: .texture,
            path: path,
            tool: PKInkingTool(.pen, color: variedColor, width: 1.5),
            metadata: ["textureType": "hatching", "angle": hatchAngle]
        )
    }

    // MARK: - Stippling Generation

    private func generateStippling(near stroke: Stroke, state: AIState, pressure: Double, configuration: AIConfiguration) -> AIMove? {
        // Create SMALL dots clustered AROUND the stroke
        // Should feel like adding texture/shading to the stroke area

        // Density scales with pressure
        let baseDotCount = 6
        let pressureFactor = max(0.5, min(pressure * 2.0, 2.5))
        let dotCountDouble = Double(baseDotCount) * pressureFactor

        // Safety: Check for valid value before Int conversion
        guard dotCountDouble.isFinite else {
            print("⚠️ TextureGenerator: Invalid dot count calculation")
            return nil
        }

        let dotCount = Int(dotCountDouble)

        var controlPoints: [PKStrokePoint] = []

        for i in 0..<dotCount {
            // Position along the stroke with small perpendicular offset
            let t = CGFloat.random(in: 0...1)
            let baseX = stroke.startPoint.x + (stroke.endPoint.x - stroke.startPoint.x) * t
            let baseY = stroke.startPoint.y + (stroke.endPoint.y - stroke.startPoint.y) * t

            // Small random offset perpendicular to stroke
            let strokeAngle = atan2(
                stroke.endPoint.y - stroke.startPoint.y,
                stroke.endPoint.x - stroke.startPoint.x
            )
            let perpAngle = strokeAngle + .pi / 2
            let offset = CGFloat.random(in: -15...15)

            let x = baseX + offset * cos(perpAngle)
            let y = baseY + offset * sin(perpAngle)

            // Tiny dot size
            let dotSize = 1.5 + (pressure * 1.0)

            // Create a minimal dot (single point)
            let point = PKStrokePoint(
                location: CGPoint(x: x, y: y),
                timeOffset: TimeInterval(i) * 0.01,
                size: CGSize(width: dotSize, height: dotSize),
                opacity: 0.9,
                force: 0.6,
                azimuth: 0,
                altitude: .pi / 2
            )

            controlPoints.append(point)
        }

        guard !controlPoints.isEmpty else { return nil }

        let path = PKStrokePath(controlPoints: controlPoints, creationDate: Date())

        // Apply color variation from configuration
        let baseColor = GeneratorColors.textureColor
        let variedColor = configuration.applyColorVariation(to: baseColor)

        print("🎨 TextureGenerator (stippling): pressure=\(String(format: "%.2f", pressure)), dots=\(dotCount)")

        return AIMove(
            moveType: .texture,
            path: path,
            tool: PKInkingTool(.pen, color: variedColor, width: 2.0),
            metadata: ["textureType": "stippling", "dotCount": dotCount]
        )
    }

    // MARK: - Dots Generation

    private func generateDots(near stroke: Stroke, state: AIState, configuration: AIConfiguration) -> AIMove? {
        // Create a few small dots trailing the stroke
        let dotCount = 4

        var controlPoints: [PKStrokePoint] = []

        // Calculate stroke direction for trailing
        let strokeAngle = atan2(
            stroke.endPoint.y - stroke.startPoint.y,
            stroke.endPoint.x - stroke.startPoint.x
        )

        // Place dots trailing behind the stroke endpoint
        for i in 0..<dotCount {
            // Trail backward from endpoint
            let trailDistance = CGFloat(i + 1) * 8.0
            let x = stroke.endPoint.x - trailDistance * cos(strokeAngle)
            let y = stroke.endPoint.y - trailDistance * sin(strokeAngle)

            // Small perpendicular offset for variation
            let perpOffset = CGFloat.random(in: -3...3)
            let finalX = x + perpOffset * cos(strokeAngle + .pi/2)
            let finalY = y + perpOffset * sin(strokeAngle + .pi/2)

            // Create dot
            let point = PKStrokePoint(
                location: CGPoint(x: finalX, y: finalY),
                timeOffset: TimeInterval(i) * 0.01,
                size: CGSize(width: 2.0, height: 2.0),
                opacity: 0.8,
                force: 0.6,
                azimuth: 0,
                altitude: .pi / 2
            )

            controlPoints.append(point)
        }

        guard !controlPoints.isEmpty else { return nil }

        let path = PKStrokePath(controlPoints: controlPoints, creationDate: Date())

        // Apply color variation from configuration
        let baseColor = GeneratorColors.textureColor
        let variedColor = configuration.applyColorVariation(to: baseColor)

        return AIMove(
            moveType: .texture,
            path: path,
            tool: PKInkingTool(.pen, color: variedColor, width: 1.8),
            metadata: ["textureType": "dots"]
        )
    }
}
