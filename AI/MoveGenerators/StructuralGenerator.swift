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
        state: AIState
    ) -> AIMove? {
        // Analyze what kind of structure to reinforce
        let structureType = analyzeStructure(stroke: userStroke, recentStrokes: recentStrokes)

        switch structureType {
        case .edge:
            return reinforceEdge(stroke: userStroke, state: state)
        case .curve:
            return reinforceCurve(stroke: userStroke, state: state)
        case .angle:
            return reinforceAngle(stroke: userStroke, recentStrokes: recentStrokes, state: state)
        case .closure:
            return suggestClosure(stroke: userStroke, recentStrokes: recentStrokes, state: state)
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

    private func reinforceEdge(stroke: Stroke, state: AIState) -> AIMove? {
        // Create a parallel line to reinforce the edge
        let offset: CGFloat = state.attentionMode == .wander ? 40.0 : 20.0

        // Calculate perpendicular direction
        let dx = stroke.endPoint.x - stroke.startPoint.x
        let dy = stroke.endPoint.y - stroke.startPoint.y
        let length = hypot(dx, dy)

        guard length > 0 else { return nil }

        let perpX = -dy / length * offset
        let perpY = dx / length * offset

        // Create parallel stroke
        let start = CGPoint(x: stroke.startPoint.x + perpX, y: stroke.startPoint.y + perpY)
        let end = CGPoint(x: stroke.endPoint.x + perpX, y: stroke.endPoint.y + perpY)

        var controlPoints: [PKStrokePoint] = []
        let segments = 5

        for i in 0...segments {
            let t = CGFloat(i) / CGFloat(segments)
            let x = start.x + (end.x - start.x) * t
            let y = start.y + (end.y - start.y) * t

            let point = PKStrokePoint(
                location: CGPoint(x: x, y: y),
                timeOffset: TimeInterval(i) * 0.01,
                size: CGSize(width: 5.0, height: 5.0),
                opacity: 1.0,
                force: 0.8,
                azimuth: 0,
                altitude: .pi / 4
            )
            controlPoints.append(point)
        }

        let path = PKStrokePath(controlPoints: controlPoints, creationDate: Date())

        return AIMove(
            moveType: .structural,
            path: path,
            tool: PKInkingTool(.marker, color: .cyan, width: 8.0),
            metadata: ["structureType": "edge"]
        )
    }

    // MARK: - Curve Reinforcement

    private func reinforceCurve(stroke: Stroke, state: AIState) -> AIMove? {
        print("🏗️ StructuralGenerator: reinforceCurve - using simple parallel approach")

        // Use simple parallel line approach instead of complex path reconstruction
        let offset: CGFloat = 15.0

        // Calculate perpendicular direction
        let dx = stroke.endPoint.x - stroke.startPoint.x
        let dy = stroke.endPoint.y - stroke.startPoint.y
        let length = hypot(dx, dy)

        guard length > 0 else {
            print("🏗️ StructuralGenerator: reinforceCurve - ERROR: length is 0")
            return nil
        }

        let perpX = -dy / length * offset
        let perpY = dx / length * offset

        // Create parallel stroke
        let start = CGPoint(x: stroke.startPoint.x + perpX, y: stroke.startPoint.y + perpY)
        let end = CGPoint(x: stroke.endPoint.x + perpX, y: stroke.endPoint.y + perpY)

        var controlPoints: [PKStrokePoint] = []
        let segments = 8

        for i in 0...segments {
            let t = CGFloat(i) / CGFloat(segments)
            let x = start.x + (end.x - start.x) * t
            let y = start.y + (end.y - start.y) * t

            let newPoint = PKStrokePoint(
                location: CGPoint(x: x, y: y),
                timeOffset: TimeInterval(i) * 0.01,
                size: CGSize(width: 4.0, height: 4.0),
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

        print("🏗️ StructuralGenerator: reinforceCurve - SUCCESS")
        return AIMove(
            moveType: .structural,
            path: path,
            tool: PKInkingTool(.marker, color: .cyan, width: 6.0),
            metadata: ["structureType": "curve"]
        )
    }

    // MARK: - Angle Reinforcement

    private func reinforceAngle(stroke: Stroke, recentStrokes: [Stroke], state: AIState) -> AIMove? {
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
            size: CGSize(width: 8.0, height: 8.0),
            opacity: 1.0,
            force: 0.8,
            azimuth: 0,
            altitude: .pi / 4
        )

        controlPoints.append(cornerPoint)

        let path = PKStrokePath(controlPoints: [cornerPoint], creationDate: Date())

        return AIMove(
            moveType: .structural,
            path: path,
            tool: PKInkingTool(.marker, color: .cyan, width: 10.0),
            metadata: ["structureType": "angle"]
        )
    }

    // MARK: - Closure Suggestion

    private func suggestClosure(stroke: Stroke, recentStrokes: [Stroke], state: AIState) -> AIMove? {
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
                size: CGSize(width: 5.0, height: 5.0),
                opacity: 1.0,
                force: 0.7,
                azimuth: 0,
                altitude: .pi / 4
            )
            controlPoints.append(point)
        }

        guard !controlPoints.isEmpty else { return nil }

        let path = PKStrokePath(controlPoints: controlPoints, creationDate: Date())

        return AIMove(
            moveType: .structural,
            path: path,
            tool: PKInkingTool(.marker, color: .cyan, width: 7.0),
            metadata: ["structureType": "closure"]
        )
    }
}
