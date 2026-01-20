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
        let length = CGFloat(userStroke.length) * 0.9  // Was 0.6, now 0.9 - LONGER

        let start = userStroke.endPoint
        let end = CGPoint(
            x: start.x + length * cos(oppositeAngle),
            y: start.y + length * sin(oppositeAngle)
        )

        var controlPoints: [PKStrokePoint] = []
        let segments = 10  // Was 8, now 10

        for i in 0...segments {
            let t = CGFloat(i) / CGFloat(segments)
            let x = start.x + (end.x - start.x) * t
            let y = start.y + (end.y - start.y) * t

            let point = PKStrokePoint(
                location: CGPoint(x: x, y: y),
                timeOffset: TimeInterval(i) * 0.01,
                size: CGSize(width: 8.0, height: 8.0),  // Was 6.0, now 8.0
                opacity: 1.0,
                force: 0.9,
                azimuth: 0,
                altitude: .pi / 3
            )
            controlPoints.append(point)
        }

        let path = PKStrokePath(controlPoints: controlPoints, creationDate: Date())

        return AIMove(
            moveType: .contrast,
            path: path,
            tool: PKInkingTool(.marker, color: .systemGreen, width: 12.0),  // Was 10.0, now 12.0
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
