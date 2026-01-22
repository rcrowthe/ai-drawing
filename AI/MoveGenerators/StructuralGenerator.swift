//
//  StructuralGenerator.swift
//  AIDrawing
//
//  Generates structural moves that reinforce shapes, perspective, contours
//

import Foundation
import PencilKit
import CoreGraphics

class StructuralGenerator {
    /// Generate structural move that reinforces user's drawing
    func generate(
        userStroke: Stroke,
        recentStrokes: [Stroke],
        canvasState: CanvasState,
        state: AIState,
        configuration: AIConfiguration
    ) -> AIMove? {
        // Analyze what kind of structure to reinforce
        let structureType = analyzeStructure(stroke: userStroke, recentStrokes: recentStrokes)

        switch structureType {
        case .edge:
            return reinforceEdge(stroke: userStroke, state: state, configuration: configuration)
        case .curve:
            return reinforceCurve(stroke: userStroke, state: state, configuration: configuration)
        case .angle:
            return reinforceAngle(stroke: userStroke, recentStrokes: recentStrokes, state: state, configuration: configuration)
        case .closure:
            return suggestClosure(stroke: userStroke, recentStrokes: recentStrokes, state: state, configuration: configuration)
        }
    }

    // MARK: - Structure Analysis

    private enum StructureType {
        case edge, curve, angle, closure
    }

    private func analyzeStructure(stroke: Stroke, recentStrokes: [Stroke]) -> StructureType {
        // Check if stroke is relatively straight (edge)
        let straightness = stroke.startPoint.distance(to: stroke.endPoint) / CGFloat(stroke.length)
        if straightness > 0.8 {
            return .edge
        }

        // Check if stroke has high curvature
        if stroke.curvature > 0.5 {
            return .curve
        }

        // Check if recent strokes form an angle
        if recentStrokes.count >= 2 {
            let angle = calculateAngleBetween(recentStrokes.suffix(2))
            if angle > 0.3 && angle < 2.8 {  // Not too small, not too flat
                return .angle
            }
        }

        // Check if strokes might form an unclosed shape
        if recentStrokes.count >= 3 {
            let first = recentStrokes.first!
            let last = recentStrokes.last!
            let distance = first.startPoint.distance(to: last.endPoint)
            if distance < 100 && distance > 20 {  // Close but not closed
                return .closure
            }
        }

        // Default to edge reinforcement
        return .edge
    }

    private func calculateAngleBetween(_ strokes: ArraySlice<Stroke>) -> CGFloat {
        guard strokes.count >= 2 else { return 0 }

        let stroke1 = Array(strokes)[0]
        let stroke2 = Array(strokes)[1]

        let angle1 = atan2(stroke1.endPoint.y - stroke1.startPoint.y, stroke1.endPoint.x - stroke1.startPoint.x)
        let angle2 = atan2(stroke2.endPoint.y - stroke2.startPoint.y, stroke2.endPoint.x - stroke2.startPoint.x)

        var diff = abs(angle2 - angle1)
        if diff > .pi {
            diff = 2 * .pi - diff
        }

        return diff
    }

    // MARK: - Edge Reinforcement

    private func reinforceEdge(stroke: Stroke, state: AIState, configuration: AIConfiguration) -> AIMove? {
        // RESPOND TO STROKE QUALITIES
        // Long, straight strokes (low curvature) → reinforce with parallel structural lines
        // High pressure strokes → add perpendicular bracing

        let baseOffset: CGFloat = state.attentionMode == .wander ? 40.0 : 20.0

        // PRESSURE RESPONSE: High pressure → closer reinforcement for bracing
        // AMPLIFIED: Changed from *1.5 to *2.5 for stronger effect
        let pressureFactor = max(0.3, min(stroke.avgPressure * 2.5, 4.0)) // Wider range
        let offset = baseOffset / CGFloat(pressureFactor)

        var controlPoints: [PKStrokePoint] = []
        let segments = 8

        // Sample actual points from the stroke path instead of interpolating
        let pathPoints = stroke.samplePathPoints(count: segments + 1)

        // CRITICAL: Use actual returned point count, not requested count
        let actualSegments = pathPoints.count - 1
        guard actualSegments > 0 else {
            print("🏗️ StructuralGenerator: ERROR - not enough path points")
            return nil
        }

        for i in 0...actualSegments {
            let basePoint = pathPoints[i]

            // Calculate local perpendicular direction
            // Look ahead/behind to get tangent direction at this point
            let prevPoint = i > 0 ? pathPoints[i - 1] : pathPoints[i]
            let nextPoint = i < actualSegments ? pathPoints[i + 1] : pathPoints[i]

            let dx = nextPoint.x - prevPoint.x
            let dy = nextPoint.y - prevPoint.y
            let localLength = hypot(dx, dy)

            if localLength < 0.1 { continue }  // Skip degenerate points

            // Perpendicular direction
            let perpX = -dy / localLength
            let perpY = dx / localLength

            // Add slight wobble for organic feel
            let t = CGFloat(i) / CGFloat(actualSegments)
            let wobble = sin(t * .pi * 3) * 4.0
            let currentOffset = offset + wobble

            let x = basePoint.x + perpX * currentOffset
            let y = basePoint.y + perpY * currentOffset

            // PRESSURE RESPONSE: Point size scales with user pressure
            // Structural strokes are bold, so higher minimum
            let dynamicSize = 4.0 + (stroke.avgPressure * 2.0)
            let pointSize = max(4.5, dynamicSize)  // Floor at 4.5 - structural is bold

            let point = PKStrokePoint(
                location: CGPoint(x: x, y: y),
                timeOffset: TimeInterval(i) * 0.01,
                size: CGSize(width: pointSize, height: pointSize),
                opacity: 1.0,
                force: 0.8 * stroke.avgPressure,
                azimuth: 0,
                altitude: .pi / 4
            )
            controlPoints.append(point)
        }

        guard !controlPoints.isEmpty else { return nil }

        let path = PKStrokePath(controlPoints: controlPoints, creationDate: Date())

        // PRESSURE RESPONSE: Stroke width scales with pressure
        let strokeWidth = 2.5 + (stroke.avgPressure * 2.0)

        // Apply color variation from configuration
        let baseColor = GeneratorColors.structuralColor
        let variedColor = configuration.applyColorVariation(to: baseColor)

        print("🏗️ StructuralGenerator (edge): pressure=\(String(format: "%.2f", stroke.avgPressure)), length=\(stroke.length.isFinite ? Int(stroke.length) : -1), offset=\(offset.isFinite ? Int(offset) : -1), points=\(pathPoints.count)")

        return AIMove(
            moveType: .structural,
            path: path,
            tool: PKInkingTool(.pen, color: variedColor, width: strokeWidth),
            metadata: ["structureType": "edge", "pressureFactor": pressureFactor]
        )
    }

    // MARK: - Curve Reinforcement

    private func reinforceCurve(stroke: Stroke, state: AIState, configuration: AIConfiguration) -> AIMove? {
        print("🏗️ StructuralGenerator: reinforceCurve - creating curved reinforcement")

        let offset: CGFloat = 15.0

        let dx = stroke.endPoint.x - stroke.startPoint.x
        let dy = stroke.endPoint.y - stroke.startPoint.y
        let length = hypot(dx, dy)

        guard length > 0 else {
            print("🏗️ StructuralGenerator: reinforceCurve - ERROR: length is 0")
            return nil
        }

        let perpX = -dy / length
        let perpY = dx / length

        var controlPoints: [PKStrokePoint] = []
        let segments = 10

        for i in 0...segments {
            let t = CGFloat(i) / CGFloat(segments)

            // Base position
            let baseX = stroke.startPoint.x + dx * t
            let baseY = stroke.startPoint.y + dy * t

            // Add arc to emphasize curvature
            let arc = sin(t * .pi) * 12.0  // Arc peaks in middle
            let currentOffset = offset + arc

            let x = baseX + perpX * currentOffset
            let y = baseY + perpY * currentOffset

            let newPoint = PKStrokePoint(
                location: CGPoint(x: x, y: y),
                timeOffset: TimeInterval(i) * 0.01,
                size: CGSize(width: 3.0, height: 3.0),
                opacity: 1.0,
                force: 0.7,
                azimuth: 0,
                altitude: .pi / 4
            )

            controlPoints.append(newPoint)
        }

        guard !controlPoints.isEmpty else {
            print("🏗️ StructuralGenerator: reinforceCurve - ERROR: no control points")
            return nil
        }

        let path = PKStrokePath(controlPoints: controlPoints, creationDate: Date())

        // Apply color variation from configuration
        let baseColor = GeneratorColors.structuralColor
        let variedColor = configuration.applyColorVariation(to: baseColor)

        print("🏗️ StructuralGenerator: reinforceCurve - SUCCESS")
        return AIMove(
            moveType: .structural,
            path: path,
            tool: PKInkingTool(.pen, color: variedColor, width: 3.0),
            metadata: ["structureType": "curve"]
        )
    }

    // MARK: - Angle Reinforcement

    private func reinforceAngle(stroke: Stroke, recentStrokes: [Stroke], state: AIState, configuration: AIConfiguration) -> AIMove? {
        // Draw a line connecting recent strokes to emphasize the angle
        guard let prevStroke = recentStrokes.suffix(2).first else { return nil }

        let start = prevStroke.endPoint
        let middle = stroke.startPoint
        let end = stroke.endPoint

        var controlPoints: [PKStrokePoint] = []

        // Create a line that emphasizes the corner
        let cornerPoint = PKStrokePoint(
            location: middle,
            timeOffset: 0,
            size: CGSize(width: 4.0, height: 4.0),
            opacity: 1.0,
            force: 0.8,
            azimuth: 0,
            altitude: .pi / 4
        )

        controlPoints.append(cornerPoint)

        let path = PKStrokePath(controlPoints: [cornerPoint], creationDate: Date())

        // Apply color variation from configuration
        let baseColor = GeneratorColors.structuralColor
        let variedColor = configuration.applyColorVariation(to: baseColor)

        return AIMove(
            moveType: .structural,
            path: path,
            tool: PKInkingTool(.pen, color: variedColor, width: 4.0),
            metadata: ["structureType": "angle"]
        )
    }

    // MARK: - Closure Suggestion

    private func suggestClosure(stroke: Stroke, recentStrokes: [Stroke], state: AIState, configuration: AIConfiguration) -> AIMove? {
        // Suggest closing an open shape
        guard let firstStroke = recentStrokes.first else { return nil }

        let start = stroke.endPoint
        let end = firstStroke.startPoint

        var controlPoints: [PKStrokePoint] = []
        let segments = 5

        for i in 0...segments {
            let t = CGFloat(i) / CGFloat(segments)
            let x = start.x + (end.x - start.x) * t
            let y = start.y + (end.y - start.y) * t

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

        guard !controlPoints.isEmpty else { return nil }

        let path = PKStrokePath(controlPoints: controlPoints, creationDate: Date())

        // Apply color variation from configuration
        let baseColor = GeneratorColors.structuralColor
        let variedColor = configuration.applyColorVariation(to: baseColor)

        return AIMove(
            moveType: .structural,
            path: path,
            tool: PKInkingTool(.pen, color: variedColor, width: 3.0),
            metadata: ["structureType": "closure"]
        )
    }
}
