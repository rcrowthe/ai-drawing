//
//  SurpriseGenerator.swift
//  AIDrawing
//
//  Generates surprise moves with controlled deviation
//

import Foundation
import PencilKit
import CoreGraphics

class SurpriseGenerator {
    /// Generate surprise move with unexpected but controlled deviation
    func generate(
        userStroke: Stroke,
        recentStrokes: [Stroke],
        canvasState: CanvasState,
        state: AIState
    ) -> AIMove? {
        // Create an unexpected flourish or gesture
        let surpriseType = Int.random(in: 0...2)

        switch surpriseType {
        case 0:
            return generateSpiral(near: userStroke)
        case 1:
            return generateZigzag(near: userStroke)
        default:
            return generateLoop(near: userStroke)
        }
    }

    private func generateSpiral(near stroke: Stroke) -> AIMove? {
        // Center at random point in bounding box, not always the center
        let bounds = stroke.boundingBox
        let center = CGPoint(
            x: bounds.midX + CGFloat.random(in: -bounds.width * 0.3...bounds.width * 0.3),
            y: bounds.midY + CGFloat.random(in: -bounds.height * 0.3...bounds.height * 0.3)
        )
        var controlPoints: [PKStrokePoint] = []

        let turns: CGFloat = 1.5
        let maxRadius: CGFloat = 30.0
        let segments = 20

        for i in 0...segments {
            let t = CGFloat(i) / CGFloat(segments)
            let angle = t * turns * 2 * .pi
            let radius = t * maxRadius

            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)

            let point = PKStrokePoint(
                location: CGPoint(x: x, y: y),
                timeOffset: TimeInterval(i) * 0.01,
                size: CGSize(width: 3.0, height: 3.0),
                opacity: 1.0,
                force: 0.7,
                azimuth: 0,
                altitude: .pi / 4
            )
            controlPoints.append(point)
        }

        let path = PKStrokePath(controlPoints: controlPoints, creationDate: Date())

        return AIMove(
            moveType: .surprise,
            path: path,
            tool: PKInkingTool(.pen, color: GeneratorColors.surpriseColor, width: 3.0),
            metadata: ["surpriseType": "spiral"]
        )
    }

    private func generateZigzag(near stroke: Stroke) -> AIMove? {
        // Start from random point along stroke (not always the end)
        let t = CGFloat.random(in: 0.3...0.8)
        let start = CGPoint(
            x: stroke.startPoint.x + (stroke.endPoint.x - stroke.startPoint.x) * t,
            y: stroke.startPoint.y + (stroke.endPoint.y - stroke.startPoint.y) * t
        )
        var controlPoints: [PKStrokePoint] = []

        let zigCount = 4
        let zigWidth: CGFloat = 15.0
        let zigLength: CGFloat = 10.0

        for i in 0...zigCount {
            let x = start.x + CGFloat(i) * zigLength
            let y = start.y + (i % 2 == 0 ? zigWidth : -zigWidth)

            let point = PKStrokePoint(
                location: CGPoint(x: x, y: y),
                timeOffset: TimeInterval(i) * 0.01,
                size: CGSize(width: 3.0, height: 3.0),
                opacity: 1.0,
                force: 0.7,
                azimuth: 0,
                altitude: .pi / 3
            )
            controlPoints.append(point)
        }

        let path = PKStrokePath(controlPoints: controlPoints, creationDate: Date())

        return AIMove(
            moveType: .surprise,
            path: path,
            tool: PKInkingTool(.pen, color: GeneratorColors.surpriseColor, width: 3.0),
            metadata: ["surpriseType": "zigzag"]
        )
    }

    private func generateLoop(near stroke: Stroke) -> AIMove? {
        // Center at random point along stroke (not always the end)
        let t = CGFloat.random(in: 0.2...0.8)
        let center = CGPoint(
            x: stroke.startPoint.x + (stroke.endPoint.x - stroke.startPoint.x) * t,
            y: stroke.startPoint.y + (stroke.endPoint.y - stroke.startPoint.y) * t
        )
        var controlPoints: [PKStrokePoint] = []

        let radius: CGFloat = 20.0
        let segments = 12

        for i in 0...segments {
            let t = CGFloat(i) / CGFloat(segments)
            let angle = t * 2 * .pi

            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)

            let point = PKStrokePoint(
                location: CGPoint(x: x, y: y),
                timeOffset: TimeInterval(i) * 0.01,
                size: CGSize(width: 3.0, height: 3.0),
                opacity: 1.0,
                force: 0.7,
                azimuth: 0,
                altitude: .pi / 4
            )
            controlPoints.append(point)
        }

        let path = PKStrokePath(controlPoints: controlPoints, creationDate: Date())

        return AIMove(
            moveType: .surprise,
            path: path,
            tool: PKInkingTool(.pen, color: GeneratorColors.surpriseColor, width: 3.0),
            metadata: ["surpriseType": "loop"]
        )
    }
}
