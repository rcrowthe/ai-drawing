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
        state: AIState
    ) -> AIMove? {
        // Predict next position based on recent stroke velocity and direction
        let velocity = calculateAverageVelocity(recentStrokes + [userStroke])
        let direction = calculateAverageDirection(recentStrokes + [userStroke])

        // Project forward
        let projectionDistance: CGFloat = 50.0
        let start = userStroke.endPoint
        let end = CGPoint(
            x: start.x + projectionDistance * cos(direction),
            y: start.y + projectionDistance * sin(direction)
        )

        var controlPoints: [PKStrokePoint] = []
        let segments = 6

        for i in 0...segments {
            let t = CGFloat(i) / CGFloat(segments)
            let x = start.x + (end.x - start.x) * t
            let y = start.y + (end.y - start.y) * t

            let point = PKStrokePoint(
                location: CGPoint(x: x, y: y),
                timeOffset: TimeInterval(i) * 0.01,
                size: CGSize(width: 4.0, height: 4.0),
                opacity: 1.0,
                force: 0.7,
                azimuth: 0,
                altitude: .pi / 4
            )
            controlPoints.append(point)
        }

        let path = PKStrokePath(controlPoints: controlPoints, creationDate: Date())

        return AIMove(
            moveType: .predictive,
            path: path,
            tool: PKInkingTool(.marker, color: .systemPink, width: 7.0),
            metadata: ["projectedDirection": direction]
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
