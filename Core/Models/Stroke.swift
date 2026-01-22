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
    case ivy        // Organic vine that follows and jumps between strokes
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
    let pkStrokeData: Data  // Encoded PKStroke for reconstruction (user strokes only)
    let moveType: AIMoveType?  // Only for AI strokes
    var isVisible: Bool
    var reinforcement: Reinforcement?

    // TRANSIENT: Keep PKStroke in memory for AI strokes (can't be archived)
    // This field is NOT serialized - it's recreated from pkStrokeData for user strokes
    var pkStroke: PKStroke?

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

        // AI strokes: Keep PKStroke in memory (can't be serialized)
        // User strokes: Serialize to pkStrokeData for persistence
        if source == .ai {
            self.pkStroke = pkStroke
            self.pkStrokeData = Data()  // Empty - won't be used
            print("💾 Stroke \(id): AI stroke - keeping PKStroke in memory")
        } else {
            self.pkStroke = nil  // Will be recreated from pkStrokeData when needed
            if let data = try? NSKeyedArchiver.archivedData(
                withRootObject: pkStroke,
                requiringSecureCoding: false
            ) {
                self.pkStrokeData = data
                print("💾 Stroke \(id): User stroke archived successfully (\(data.count) bytes)")
            } else {
                self.pkStrokeData = Data()
                print("⚠️ Stroke \(id): User stroke archiving FAILED - pkStrokeData is empty!")
            }
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

    /// Reconstruct PKStroke from stored reference or encoded data
    func toPKStroke() -> PKStroke? {
        // AI strokes: Return stored PKStroke reference
        if let storedStroke = pkStroke {
            // Reduced logging - only log once per session would be ideal, but this works
            // print("✅ Stroke \(id): Returning stored PKStroke reference (AI stroke)")
            return storedStroke
        }

        // User strokes: Deserialize from pkStrokeData
        guard !pkStrokeData.isEmpty else {
            // Don't log for AI strokes with empty data - these are old strokes from before the fix
            if source == .user {
                print("⚠️ User stroke \(id): toPKStroke() failed - pkStrokeData is empty")
            }
            // Old AI strokes fail silently - they can't be rendered
            return nil
        }

        if let pkStroke = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(pkStrokeData) as? PKStroke {
            // print("✅ Stroke \(id): Successfully unarchived PKStroke from data")
            return pkStroke
        } else {
            print("⚠️ Stroke \(id): Unarchiving failed - data exists (\(pkStrokeData.count) bytes) but couldn't decode")
            return nil
        }
    }

    // MARK: - Codable Implementation

    enum CodingKeys: String, CodingKey {
        case id, source, timestamp, pkStrokeData, moveType, isVisible, reinforcement
        case boundingBox, length, avgVelocity, avgPressure, curvature
        case startPoint, endPoint, directionChanges
        // NOTE: pkStroke is NOT included - it's transient
    }

    // Custom decoder to handle transient pkStroke field
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        source = try container.decode(StrokeSource.self, forKey: .source)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        pkStrokeData = try container.decode(Data.self, forKey: .pkStrokeData)
        moveType = try container.decodeIfPresent(AIMoveType.self, forKey: .moveType)
        isVisible = try container.decode(Bool.self, forKey: .isVisible)
        reinforcement = try container.decodeIfPresent(Reinforcement.self, forKey: .reinforcement)

        boundingBox = try container.decode(CGRect.self, forKey: .boundingBox)
        length = try container.decode(Double.self, forKey: .length)
        avgVelocity = try container.decode(Double.self, forKey: .avgVelocity)
        avgPressure = try container.decode(Double.self, forKey: .avgPressure)
        curvature = try container.decode(Double.self, forKey: .curvature)
        startPoint = try container.decode(CGPoint.self, forKey: .startPoint)
        endPoint = try container.decode(CGPoint.self, forKey: .endPoint)
        directionChanges = try container.decode(Int.self, forKey: .directionChanges)

        // pkStroke is transient - not decoded, will be nil
        // For user strokes, it will be recreated on-demand via toPKStroke()
        // For AI strokes loaded from disk, they won't render (acceptable since sessions are temporary)
        pkStroke = nil

        if source == .ai {
            print("⚠️ AI Stroke \(id): Loaded from disk - pkStroke is nil (can't render)")
        }
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

// MARK: - Stroke Path Sampling

extension Stroke {
    /// Sample N points along the actual stroke path (not just start/end)
    /// Returns actual points from the PKStroke path, evenly distributed
    func samplePathPoints(count: Int) -> [CGPoint] {
        guard let pkStroke = toPKStroke() else {
            // Fallback: interpolate between start and end
            return (0..<count).map { i in
                let t = CGFloat(i) / CGFloat(max(1, count - 1))
                return CGPoint(
                    x: startPoint.x + (endPoint.x - startPoint.x) * t,
                    y: startPoint.y + (endPoint.y - startPoint.y) * t
                )
            }
        }

        let path = pkStroke.path
        let pointCount = path.count

        guard pointCount > 1 else {
            return [startPoint]
        }

        // Sample evenly distributed points from the actual path
        var sampledPoints: [CGPoint] = []
        for i in 0..<count {
            let t = Double(i) / Double(max(1, count - 1))
            let index = Int(t * Double(pointCount - 1))
            sampledPoints.append(path[index].location)
        }

        return sampledPoints
    }

    /// Get a random segment of the stroke path (useful for partial reactions)
    /// Returns (startIndex, endIndex, points)
    func randomPathSegment(minLength: CGFloat = 20.0) -> (start: Int, end: Int, points: [CGPoint])? {
        guard let pkStroke = toPKStroke() else { return nil }

        let path = pkStroke.path
        let pointCount = path.count

        guard pointCount > 5 else {
            // Stroke too short, return full path
            let points = (0..<pointCount).map { path[$0].location }
            return (0, pointCount - 1, points)
        }

        // Pick a random starting point (not too close to the end)
        let maxStart = pointCount - 5
        let startIndex = Int.random(in: 0..<maxStart)

        // Find end point that gives us at least minLength distance
        var endIndex = startIndex + 1
        var totalLength: CGFloat = 0

        for i in (startIndex + 1)..<pointCount {
            let prevPoint = path[i - 1].location
            let currPoint = path[i].location
            totalLength += prevPoint.distance(to: currPoint)

            if totalLength >= minLength {
                endIndex = i
                break
            }
        }

        // If we didn't find a segment long enough, use the rest of the stroke
        if totalLength < minLength {
            endIndex = pointCount - 1
        }

        let points = (startIndex...endIndex).map { path[$0].location }
        return (startIndex, endIndex, points)
    }

    /// Get the point at a specific fraction along the path (0.0 = start, 1.0 = end)
    func pointAt(fraction: CGFloat) -> CGPoint {
        guard let pkStroke = toPKStroke() else {
            // Fallback: interpolate between start and end
            let t = max(0, min(1, fraction))
            return CGPoint(
                x: startPoint.x + (endPoint.x - startPoint.x) * t,
                y: startPoint.y + (endPoint.y - startPoint.y) * t
            )
        }

        let path = pkStroke.path
        let pointCount = path.count

        guard pointCount > 1 else {
            return startPoint
        }

        let t = max(0, min(1, fraction))
        let index = Int(t * CGFloat(pointCount - 1))
        return path[index].location
    }
}
