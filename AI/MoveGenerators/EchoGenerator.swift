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
        state: AIState,
        configuration: AIConfiguration
    ) -> AIMove? {
        print("🔊 EchoGenerator: stroke start=(\(userStroke.startPoint.x), \(userStroke.startPoint.y)) end=(\(userStroke.endPoint.x), \(userStroke.endPoint.y))")

        // RESPOND TO STROKE QUALITIES
        // Fast stroke (high velocity) → echo with matching velocity (longer wave amplitude)
        // Slow stroke → subtle, tight echo
        // High pressure → thicker echo stroke
        // Long stroke → echo at greater offset
        // Short stroke → tight, close echo

        // Base offset varies by attention mode
        let baseOffset: CGFloat = state.attentionMode == .wander
            ? GeneratorParameters.Echo.baseOffsetWander
            : GeneratorParameters.Echo.baseOffsetFocus

        // VELOCITY RESPONSE: Fast strokes get more dramatic echoes
        // AMPLIFIED: Changed from /500 to /200 for stronger effect
        let velocityFactor = min(userStroke.avgVelocity / 200.0, 3.0) // Cap at 3x instead of 2x
        let velocityOffset = baseOffset * CGFloat(velocityFactor)

        // LENGTH RESPONSE: Longer strokes get further offsets
        // AMPLIFIED: Changed from /200 to /150 for stronger effect
        let lengthFactor = min(userStroke.length / 150.0, 2.0) // Cap at 2x instead of 1.5x
        let lengthOffset = velocityOffset * CGFloat(lengthFactor)

        // Add random variation
        let finalOffset = lengthOffset + CGFloat.random(in: -10.0...10.0)

        // WAVE AMPLITUDE RESPONSE: Fast, energetic strokes get more wave
        // AMPLIFIED: Changed from /50000 to /30000 for stronger effect
        let baseWaveAmplitude = GeneratorParameters.Echo.waveAmplitude
        let energyFactor = min((userStroke.avgVelocity * userStroke.length) / 30000.0, 3.0) // Cap at 3x
        let waveAmplitude = baseWaveAmplitude * CGFloat(energyFactor)

        // PRESSURE RESPONSE: Calculate pressure factor once (used in loop and metadata)
        // AMPLIFIED: Changed from *1.5 to *2.0 for stronger effect
        let pressureFactor = max(0.3, min(userStroke.avgPressure * 2.0, 3.0)) // Wider range: 0.3-3.0

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

            // Add wave variation (responsive to stroke energy)
            let wave = sin(t * .pi * 2) * waveAmplitude
            let currentOffset = finalOffset + wave

            let x = baseX + perpX * currentOffset
            let y = baseY + perpY * currentOffset

            // PRESSURE RESPONSE: High pressure strokes get thicker echoes
            // But NEVER below minimum visible thickness (3.5)
            let dynamicSize = GeneratorParameters.Echo.pointSize * CGFloat(pressureFactor)
            let pointSize = max(3.5, dynamicSize)  // Floor at 3.5 for visibility

            let point = PKStrokePoint(
                location: CGPoint(x: x, y: y),
                timeOffset: TimeInterval(i) * 0.01,
                size: CGSize(width: pointSize, height: pointSize),
                opacity: GeneratorParameters.Echo.opacity,
                force: GeneratorParameters.Echo.force * pressureFactor,
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

        // PRESSURE RESPONSE: Stroke width scales with user pressure
        // AMPLIFIED: Changed from *1.5 to *2.5 for stronger effect
        let strokeWidth = GeneratorParameters.Echo.strokeWidth * CGFloat(max(0.3, min(userStroke.avgPressure * 2.5, 3.0)))

        // Apply color variation from configuration
        let baseColor = GeneratorColors.echoColor
        let variedColor = configuration.applyColorVariation(to: baseColor)

        print("🔊 EchoGenerator: SUCCESS - velocity=\(String(format: "%.1f", userStroke.avgVelocity)), pressure=\(String(format: "%.2f", userStroke.avgPressure)), length=\(userStroke.length.isFinite ? Int(userStroke.length) : -1)")
        print("🔊   → offset=\(finalOffset.isFinite ? Int(finalOffset) : -1), wave=\(String(format: "%.1f", waveAmplitude)), width=\(String(format: "%.1f", strokeWidth))")

        return AIMove(
            moveType: .echo,
            path: path,
            tool: PKInkingTool(.pen, color: variedColor, width: strokeWidth),
            metadata: [
                "originalStrokeId": userStroke.id.uuidString,
                "offset": finalOffset,
                "velocityFactor": velocityFactor,
                "pressureFactor": pressureFactor
            ]
        )
    }
}
