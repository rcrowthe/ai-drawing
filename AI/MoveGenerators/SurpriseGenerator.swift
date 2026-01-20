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
        let center = stroke.boundingBox.center
        var controlPoints: [PKStrokePoint] = []

        let turns: CGFloat = 2.5  // Was 1.5, now 2.5 turns
        let maxRadius: CGFloat = 80.0  // Was 30, now 80 - MUCH bigger
        let segments = 30  // Was 20, now 30 - smoother

        for i in 0...segments {
            let t = CGFloat(i) / CGFloat(segments)
            let angle = t * turns * 2 * .pi
            let radius = t * maxRadius

            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)

            let point = PKStrokePoint(
                location: CGPoint(x: x, y: y),
                timeOffset: TimeInterval(i) * 0.01,
                size: CGSize(width: 8.0, height: 8.0),  // Was 5.0, now 8.0
                opacity: 1.0,
                force: 0.8,
                azimuth: 0,
                altitude: .pi / 4
            )
            controlPoints.append(point)
        }

        let path = PKStrokePath(controlPoints: controlPoints, creationDate: Date())

        return AIMove(
            moveType: .surprise,
            path: path,
            tool: PKInkingTool(.marker, color: .systemPurple, width: 12.0),  // Was 8.0, now 12.0
            metadata: ["surpriseType": "spiral"]
        )
    }

    private func generateZigzag(near stroke: Stroke) -> AIMove? {
        let start = stroke.endPoint
        var controlPoints: [PKStrokePoint] = []

        let zigCount = 6  // Was 4, now 6
        let zigWidth: CGFloat = 40.0  // Was 15.0, now 40.0 - MUCH bigger
        let zigLength: CGFloat = 25.0  // Was 10.0, now 25.0

        for i in 0...zigCount {
            let x = start.x + CGFloat(i) * zigLength
            let y = start.y + (i % 2 == 0 ? zigWidth : -zigWidth)

            let point = PKStrokePoint(
                location: CGPoint(x: x, y: y),
                timeOffset: TimeInterval(i) * 0.01,
                size: CGSize(width: 8.0, height: 8.0),  // Was 5.0, now 8.0
                opacity: 1.0,
                force: 0.8,
                azimuth: 0,
                altitude: .pi / 3
            )
            controlPoints.append(point)
        }

        let path = PKStrokePath(controlPoints: controlPoints, creationDate: Date())

        return AIMove(
            moveType: .surprise,
            path: path,
            tool: PKInkingTool(.marker, color: .systemPurple, width: 12.0),  // Was 8.0, now 12.0
            metadata: ["surpriseType": "zigzag"]
        )
    }

    private func generateLoop(near stroke: Stroke) -> AIMove? {
        let center = stroke.endPoint
        var controlPoints: [PKStrokePoint] = []

        let radius: CGFloat = 50.0  // Was 20.0, now 50.0 - MUCH bigger
        let segments = 16  // Was 12, now 16

        for i in 0...segments {
            let t = CGFloat(i) / CGFloat(segments)
            let angle = t * 2 * .pi

            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)

            let point = PKStrokePoint(
                location: CGPoint(x: x, y: y),
                timeOffset: TimeInterval(i) * 0.01,
                size: CGSize(width: 8.0, height: 8.0),  // Was 5.0, now 8.0
                opacity: 1.0,
                force: 0.8,
                azimuth: 0,
                altitude: .pi / 4
            )
            controlPoints.append(point)
        }

        let path = PKStrokePath(controlPoints: controlPoints, creationDate: Date())

        return AIMove(
            moveType: .surprise,
            path: path,
            tool: PKInkingTool(.marker, color: .systemPurple, width: 12.0),  // Was 8.0, now 12.0
            metadata: ["surpriseType": "loop"]
        )
    }
}
