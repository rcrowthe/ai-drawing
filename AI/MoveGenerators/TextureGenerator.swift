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
        state: AIState
    ) -> AIMove? {
        // Choose texture type based on attention mode and density
        let density = canvasState.session.calculateDensity()
        let textureType = selectTextureType(attentionMode: state.attentionMode, density: density)

        switch textureType {
        case .hatching:
            return generateHatching(near: userStroke, state: state)
        case .stippling:
            return generateStippling(near: userStroke, state: state)
        case .dots:
            return generateDots(near: userStroke, state: state)
        }
    }

    // MARK: - Texture Type Selection

    private enum TextureType {
        case hatching, stippling, dots
    }

    private func selectTextureType(attentionMode: AttentionMode, density: Double) -> TextureType {
        if attentionMode == .wander {
            // In wander mode, prefer stippling or dots
            return Double.random(in: 0...1) < 0.5 ? .stippling : .dots
        } else {
            // In focus mode, prefer hatching for structural reinforcement
            return .hatching
        }
    }

    // MARK: - Hatching Generation

    private func generateHatching(near stroke: Stroke, state: AIState) -> AIMove? {
        // Create parallel lines near the stroke - REDUCED for less chaos
        let bounds = stroke.boundingBox
        let lineCount = state.attentionMode == .wander ? 2 : 3  // Was 3:5, now 2:3
        let spacing: CGFloat = state.attentionMode == .wander ? 12.0 : 8.0  // Was 8:4, now 12:8

        var controlPoints: [PKStrokePoint] = []

        // Determine hatching angle based on stroke direction
        let strokeAngle = atan2(
            stroke.endPoint.y - stroke.startPoint.y,
            stroke.endPoint.x - stroke.startPoint.x
        )
        let hatchAngle = strokeAngle + (.pi / 4)  // 45° offset

        // Generate parallel lines
        for i in 0..<lineCount {
            let offset = CGFloat(i) * spacing - CGFloat(lineCount - 1) * spacing / 2.0

            // Start point
            let startX = bounds.midX + offset * cos(hatchAngle + .pi / 2)
            let startY = bounds.midY + offset * sin(hatchAngle + .pi / 2)

            // End point - REDUCED LENGTH
            let lineLength: CGFloat = bounds.width * 0.2  // Was 0.3, now 0.2
            let endX = startX + lineLength * cos(hatchAngle)
            let endY = startY + lineLength * sin(hatchAngle)

            // Create stroke points
            let segments = 4  // Was 5, now 4
            for j in 0...segments {
                let t = CGFloat(j) / CGFloat(segments)
                let x = startX + (endX - startX) * t
                let y = startY + (endY - startY) * t

                let point = PKStrokePoint(
                    location: CGPoint(x: x, y: y),
                    timeOffset: TimeInterval(j) * 0.01,
                    size: CGSize(width: 2.0, height: 2.0),
                    opacity: 1.0,
                    force: 0.6,
                    azimuth: 0,
                    altitude: .pi / 4
                )
                controlPoints.append(point)
            }
        }

        guard !controlPoints.isEmpty else { return nil }

        let path = PKStrokePath(controlPoints: controlPoints, creationDate: Date())

        return AIMove(
            moveType: .texture,
            path: path,
            tool: PKInkingTool(.pen, color: GeneratorColors.textureColor, width: 2.0),
            metadata: ["textureType": "hatching"]
        )
    }

    // MARK: - Stippling Generation

    private func generateStippling(near stroke: Stroke, state: AIState) -> AIMove? {
        // Create random dots around the stroke - REDUCED for less chaos
        let bounds = stroke.boundingBox
        let dotCount = state.attentionMode == .wander ? 8 : 5  // Was 15:8, now 8:5
        let radius = bounds.width * 0.3  // Was 0.4, now 0.3

        var controlPoints: [PKStrokePoint] = []

        for i in 0..<dotCount {
            // Random position within radius
            let angle = Double.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 0...radius)

            let x = bounds.midX + distance * cos(angle)
            let y = bounds.midY + distance * sin(angle)

            // Create a tiny dot (2 points for minimal stroke)
            let point1 = PKStrokePoint(
                location: CGPoint(x: x, y: y),
                timeOffset: TimeInterval(i) * 0.01,
                size: CGSize(width: 3.0, height: 3.0),
                opacity: 1.0,
                force: 0.7,
                azimuth: 0,
                altitude: .pi / 2
            )

            let point2 = PKStrokePoint(
                location: CGPoint(x: x + 0.1, y: y + 0.1),  // Minimal offset
                timeOffset: TimeInterval(i) * 0.01 + 0.001,
                size: CGSize(width: 3.0, height: 3.0),
                opacity: 1.0,
                force: 0.7,
                azimuth: 0,
                altitude: .pi / 2
            )

            controlPoints.append(contentsOf: [point1, point2])
        }

        guard !controlPoints.isEmpty else { return nil }

        let path = PKStrokePath(controlPoints: controlPoints, creationDate: Date())

        return AIMove(
            moveType: .texture,
            path: path,
            tool: PKInkingTool(.pen, color: GeneratorColors.textureColor, width: 2.5),
            metadata: ["textureType": "stippling"]
        )
    }

    // MARK: - Dots Generation

    private func generateDots(near stroke: Stroke, state: AIState) -> AIMove? {
        // Create a small cluster of dots
        let bounds = stroke.boundingBox
        let dotCount = 5

        var controlPoints: [PKStrokePoint] = []

        for i in 0..<dotCount {
            // Position along the stroke path
            let t = CGFloat(i) / CGFloat(dotCount - 1)
            let x = stroke.startPoint.x + (stroke.endPoint.x - stroke.startPoint.x) * t
            let y = stroke.startPoint.y + (stroke.endPoint.y - stroke.startPoint.y) * t

            // Add slight random offset
            let offsetX = CGFloat.random(in: -3...3)
            let offsetY = CGFloat.random(in: -3...3)

            // Create dot
            let point = PKStrokePoint(
                location: CGPoint(x: x + offsetX, y: y + offsetY),
                timeOffset: TimeInterval(i) * 0.01,
                size: CGSize(width: 3.0, height: 3.0),
                opacity: 1.0,
                force: 0.7,
                azimuth: 0,
                altitude: .pi / 2
            )

            controlPoints.append(point)
        }

        guard !controlPoints.isEmpty else { return nil }

        let path = PKStrokePath(controlPoints: controlPoints, creationDate: Date())

        return AIMove(
            moveType: .texture,
            path: path,
            tool: PKInkingTool(.pen, color: GeneratorColors.textureColor, width: 2.5),
            metadata: ["textureType": "dots"]
        )
    }
}
