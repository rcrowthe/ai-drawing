//
//  EchoGenerator.swift
//  AIDrawing
//
//  Generates echo moves that follow user's strokes
//

import Foundation
import PencilKit
import CoreGraphics

class EchoGenerator {
    /// Generate an echo move that follows the user's stroke
    func generate(
        userStroke: Stroke,
        recentStrokes: [Stroke],
        canvasState: CanvasState,
        state: AIState
    ) -> AIMove? {
        print("🔊 EchoGenerator: Starting generation")

        // Work directly with stroke geometry instead of reconstructing PKStroke
        let offset: CGFloat = state.attentionMode == .wander ? 30.0 : 15.0

        // Create parallel stroke using start/end points
        let dx = userStroke.endPoint.x - userStroke.startPoint.x
        let dy = userStroke.endPoint.y - userStroke.startPoint.y
        let length = hypot(dx, dy)

        guard length > 0 else {
            print("🔊 EchoGenerator: ERROR - stroke length is 0")
            return nil
        }

        // Perpendicular offset
        let perpX = -dy / length * offset
        let perpY = dx / length * offset

        let offsetStart = CGPoint(
            x: userStroke.startPoint.x + perpX,
            y: userStroke.startPoint.y + perpY
        )
        let offsetEnd = CGPoint(
            x: userStroke.endPoint.x + perpX,
            y: userStroke.endPoint.y + perpY
        )

        var controlPoints: [PKStrokePoint] = []
        let segments = 8

        for i in 0...segments {
            let t = CGFloat(i) / CGFloat(segments)
            let x = offsetStart.x + (offsetEnd.x - offsetStart.x) * t
            let y = offsetStart.y + (offsetEnd.y - offsetStart.y) * t

            let point = PKStrokePoint(
                location: CGPoint(x: x, y: y),
                timeOffset: TimeInterval(i) * 0.01,
                size: CGSize(width: 5.0, height: 5.0),
                opacity: 1.0,
                force: 0.7,
                azimuth: 0,
                altitude: .pi / 4
            )
            controlPoints.append(point)
        }

        guard !controlPoints.isEmpty else {
            print("🔊 EchoGenerator: ERROR - no control points")
            return nil
        }

        let path = PKStrokePath(controlPoints: controlPoints, creationDate: Date())

        print("🔊 EchoGenerator: SUCCESS - created echo with \(controlPoints.count) points")
        return AIMove(
            moveType: .echo,
            path: path,
            tool: PKInkingTool(.marker, color: .cyan, width: 6.0),
            metadata: [
                "originalStrokeId": userStroke.id.uuidString,
                "offset": offset
            ]
        )
    }
}
