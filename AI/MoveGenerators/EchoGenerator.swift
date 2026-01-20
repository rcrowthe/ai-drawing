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
        print("🔊 EchoGenerator: stroke start=(\(userStroke.startPoint.x), \(userStroke.startPoint.y)) end=(\(userStroke.endPoint.x), \(userStroke.endPoint.y))")

        // Create a wavy echo that mimics the stroke with organic variation
        let offset: CGFloat = state.attentionMode == .wander
            ? GeneratorParameters.Echo.baseOffsetWander
            : GeneratorParameters.Echo.baseOffsetFocus

        // Vary the offset randomly to spread out multiple echoes
        let randomizedOffset = offset + CGFloat.random(in: -10.0...10.0)

        let dx = userStroke.endPoint.x - userStroke.startPoint.x
        let dy = userStroke.endPoint.y - userStroke.startPoint.y
        let length = hypot(dx, dy)

        guard length > 0 else {
            print("🔊 EchoGenerator: ERROR - stroke length is 0")
            return nil
        }

        // Perpendicular offset direction
        let perpX = -dy / length
        let perpY = dx / length

        var controlPoints: [PKStrokePoint] = []
        let segments = GeneratorParameters.Echo.segments

        for i in 0...segments {
            let t = CGFloat(i) / CGFloat(segments)

            // Base position along stroke
            let baseX = userStroke.startPoint.x + dx * t
            let baseY = userStroke.startPoint.y + dy * t

            // Add wave variation to make it organic (mimics curvature)
            let wave = sin(t * .pi * 2) * GeneratorParameters.Echo.waveAmplitude
            let currentOffset = randomizedOffset + wave

            let x = baseX + perpX * currentOffset
            let y = baseY + perpY * currentOffset

            let point = PKStrokePoint(
                location: CGPoint(x: x, y: y),
                timeOffset: TimeInterval(i) * 0.01,
                size: CGSize(
                    width: GeneratorParameters.Echo.pointSize,
                    height: GeneratorParameters.Echo.pointSize
                ),
                opacity: GeneratorParameters.Echo.opacity,
                force: GeneratorParameters.Echo.force,
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
            tool: PKInkingTool(.pen, color: GeneratorColors.echoColor, width: GeneratorParameters.Echo.strokeWidth),
            metadata: [
                "originalStrokeId": userStroke.id.uuidString,
                "offset": randomizedOffset
            ]
        )
    }
}
