//
//  Stroke.swift
//  AIDrawing
//
//  Core data model representing both user and AI drawing strokes
//

import Foundation
import PencilKit
import CoreGraphics

/// Represents the source of a stroke
enum StrokeSource: String, Codable {
    case user
    case ai
}

/// Type of AI move that generated this stroke
enum AIMoveType: String, Codable {
    case echo       // Follows user's line direction, curvature, rhythm
    case texture    // Adds hatching, stipples, dots for micro-complexity
    case structural // Reinforces shape, perspective, contour
    case contrast   // Intentional deviation for tension
    case predictive // Placed where AI infers user may go next
    case surprise   // Low-frequency controlled deviation
}

/// User feedback on AI strokes
enum Reinforcement: String, Codable {
    case good
    case bad
}

/// Core stroke data model
struct Stroke: Identifiable, Codable {
    let id: UUID
    let source: StrokeSource
    let timestamp: Date
    let pkStrokeData: Data  // Encoded PKStroke for reconstruction
    let moveType: AIMoveType?  // Only for AI strokes
    var isVisible: Bool
    var reinforcement: Reinforcement?

    // Cached geometry for analysis (calculated once at creation)
    let boundingBox: CGRect
    let length: Double
    let avgVelocity: Double
    let avgPressure: Double
    let curvature: Double
    let startPoint: CGPoint
    let endPoint: CGPoint
    let directionChanges: Int

    /// Initialize from a PencilKit stroke
    init(pkStroke: PKStroke, source: StrokeSource, moveType: AIMoveType? = nil) {
        self.id = UUID()
        self.source = source
        self.timestamp = Date()
        self.moveType = moveType
        self.isVisible = true
        self.reinforcement = nil

        // Encode PKStroke for storage
        if let data = try? NSKeyedArchiver.archivedData(
            withRootObject: pkStroke,
            requiringSecureCoding: false
        ) {
            self.pkStrokeData = data
        } else {
            self.pkStrokeData = Data()
        }

        // Calculate and cache geometry
        self.boundingBox = pkStroke.renderBounds
        self.length = Self.calculateLength(pkStroke.path)
        self.avgVelocity = Self.calculateAvgVelocity(pkStroke.path)
        self.avgPressure = Self.calculateAvgPressure(pkStroke.path)
        self.curvature = Self.calculateCurvature(pkStroke.path)

        // Get start and end points
        if let firstPoint = pkStroke.path.first {
            self.startPoint = firstPoint.location
        } else {
            self.startPoint = .zero
        }

        if let lastPoint = pkStroke.path.last {
            self.endPoint = lastPoint.location
        } else {
            self.endPoint = .zero
        }

        self.directionChanges = Self.calculateDirectionChanges(pkStroke.path)
    }

    /// Reconstruct PKStroke from encoded data
    func toPKStroke() -> PKStroke? {
        guard !pkStrokeData.isEmpty else { return nil }
        return try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(pkStrokeData) as? PKStroke
    }

    // MARK: - Geometry Calculation Helpers

    private static func calculateLength(_ path: PKStrokePath) -> Double {
        var length: Double = 0.0
        for i in 1..<path.count {
            let prev = path[i - 1].location
            let curr = path[i].location
            length += hypot(curr.x - prev.x, curr.y - prev.y)
        }
        return length
    }

    private static func calculateAvgVelocity(_ path: PKStrokePath) -> Double {
        guard path.count > 1 else { return 0.0 }

        var totalVelocity: Double = 0.0
        for i in 1..<path.count {
            let prev = path[i - 1]
            let curr = path[i]
            let distance = hypot(
                curr.location.x - prev.location.x,
                curr.location.y - prev.location.y
            )
            let timeDelta = curr.timeOffset - prev.timeOffset
            if timeDelta > 0 {
                totalVelocity += distance / timeDelta
            }
        }
        return totalVelocity / Double(path.count - 1)
    }

    private static func calculateAvgPressure(_ path: PKStrokePath) -> Double {
        guard path.count > 0 else { return 0.0 }

        let totalPressure = (0..<path.count).reduce(0.0) { sum, i in
            sum + path[i].force
        }
        return totalPressure / Double(path.count)
    }

    private static func calculateCurvature(_ path: PKStrokePath) -> Double {
        guard path.count > 2 else { return 0.0 }

        var totalCurvature: Double = 0.0
        for i in 1..<(path.count - 1) {
            let p0 = path[i - 1].location
            let p1 = path[i].location
            let p2 = path[i + 1].location

            // Calculate angle between vectors
            let v1 = CGVector(dx: p1.x - p0.x, dy: p1.y - p0.y)
            let v2 = CGVector(dx: p2.x - p1.x, dy: p2.y - p1.y)

            let angle = abs(atan2(v2.dy, v2.dx) - atan2(v1.dy, v1.dx))
            totalCurvature += angle
        }

        return totalCurvature / Double(path.count - 2)
    }

    private static func calculateDirectionChanges(_ path: PKStrokePath) -> Int {
        guard path.count > 2 else { return 0 }

        var changes = 0
        let threshold: CGFloat = 0.5  // Radians (about 30 degrees)

        for i in 1..<(path.count - 1) {
            let p0 = path[i - 1].location
            let p1 = path[i].location
            let p2 = path[i + 1].location

            let v1 = CGVector(dx: p1.x - p0.x, dy: p1.y - p0.y)
            let v2 = CGVector(dx: p2.x - p1.x, dy: p2.y - p1.y)

            let angle = abs(atan2(v2.dy, v2.dx) - atan2(v1.dy, v1.dx))
            if angle > threshold {
                changes += 1
            }
        }

        return changes
    }
}

// MARK: - CGPoint Extensions

extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        return hypot(other.x - x, other.y - y)
    }
}

// MARK: - CGRect Extensions

extension CGRect {
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }

    var area: CGFloat {
        return width * height
    }
}
