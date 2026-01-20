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
        state: AIState
    ) -> AIMove? {
        // Create a stroke that contrasts with user's direction
        let oppositeAngle = calculateOppositeDirection(stroke: userStroke)
        let length = CGFloat(userStroke.length) * 0.6

        // Start from random point along the stroke (not just the end)
        let t = CGFloat.random(in: 0.3...0.7)  // Random position along stroke
        let start = CGPoint(
            x: userStroke.startPoint.x + (userStroke.endPoint.x - userStroke.startPoint.x) * t,
            y: userStroke.startPoint.y + (userStroke.endPoint.y - userStroke.startPoint.y) * t
        )

        var controlPoints: [PKStrokePoint] = []
        let segments = 10

        for i in 0...segments {
            let t = CGFloat(i) / CGFloat(segments)

            // Add curve to make it more interesting than straight line
            let baseX = start.x + length * t * cos(oppositeAngle)
            let baseY = start.y + length * t * sin(oppositeAngle)

            // Add perpendicular wave for curved contrast
            let wave = sin(t * .pi * 2) * 10.0
            let x = baseX + wave * cos(oppositeAngle + .pi / 2)
            let y = baseY + wave * sin(oppositeAngle + .pi / 2)

            let point = PKStrokePoint(
                location: CGPoint(x: x, y: y),
                timeOffset: TimeInterval(i) * 0.01,
                size: CGSize(width: 3.0, height: 3.0),
                opacity: 1.0,
                force: 0.8,
                azimuth: 0,
                altitude: .pi / 3
            )
            controlPoints.append(point)
        }

        let path = PKStrokePath(controlPoints: controlPoints, creationDate: Date())

        return AIMove(
            moveType: .contrast,
            path: path,
            tool: PKInkingTool(.pen, color: GeneratorColors.contrastColor, width: 3.0),
            metadata: ["oppositeAngle": oppositeAngle]
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
