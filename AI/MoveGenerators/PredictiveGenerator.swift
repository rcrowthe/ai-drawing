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
        let baseDirection = calculateAverageDirection(recentStrokes + [userStroke])

        // Add variation to prevent infinite straight lines
        let angleVariation = CGFloat.random(in: -0.3...0.3)  // +/- ~17 degrees
        let direction = baseDirection + angleVariation

        // Project forward from a random point along stroke (not always the end)
        let t = CGFloat.random(in: 0.5...1.0)  // Favor end but not always
        let projectionStart = CGPoint(
            x: userStroke.startPoint.x + (userStroke.endPoint.x - userStroke.startPoint.x) * t,
            y: userStroke.startPoint.y + (userStroke.endPoint.y - userStroke.startPoint.y) * t
        )

        // Vary the projection distance too
        let projectionDistance = CGFloat.random(in: 30.0...70.0)
        let end = CGPoint(
            x: projectionStart.x + projectionDistance * cos(direction),
            y: projectionStart.y + projectionDistance * sin(direction)
        )

        // Check for nearby strokes and adjust if collision detected
        let adjustedEnd = avoidCollisions(start: projectionStart, end: end, allStrokes: canvasState.session.strokes)

        var controlPoints: [PKStrokePoint] = []
        let segments = 6

        for i in 0...segments {
            let t = CGFloat(i) / CGFloat(segments)
            let x = projectionStart.x + (adjustedEnd.x - projectionStart.x) * t
            let y = projectionStart.y + (adjustedEnd.y - projectionStart.y) * t

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
            moveType: .predictive,
            path: path,
            tool: PKInkingTool(.pen, color: GeneratorColors.predictiveColor, width: 3.0),
            metadata: ["projectedDirection": direction]
        )
    }

    /// Adjust end point if it would collide with recent strokes
    private func avoidCollisions(start: CGPoint, end: CGPoint, allStrokes: [Stroke]) -> CGPoint {
        // Find strokes drawn in the last 2 seconds
        let recentStrokes = allStrokes.filter { stroke in
            Date().timeIntervalSince(stroke.timestamp) < 2.0
        }

        // Check if our projected line is too close to any recent stroke
        for stroke in recentStrokes {
            let distance = distanceToStroke(from: end, stroke: stroke)
            if distance < 30.0 {  // Too close!
                // Adjust end point away from the collision
                let avoidanceAngle = atan2(end.y - stroke.boundingBox.center.y,
                                          end.x - stroke.boundingBox.center.x)
                let adjustedEnd = CGPoint(
                    x: start.x + (end.x - start.x) * 0.7 + 20 * cos(avoidanceAngle),
                    y: start.y + (end.y - start.y) * 0.7 + 20 * sin(avoidanceAngle)
                )
                return adjustedEnd
            }
        }

        return end
    }

    /// Calculate distance from a point to a stroke's bounding box center
    private func distanceToStroke(from point: CGPoint, stroke: Stroke) -> CGFloat {
        let center = stroke.boundingBox.center
        return hypot(point.x - center.x, point.y - center.y)
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
