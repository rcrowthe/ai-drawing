//
//  StrokePoint.swift
//  AIDrawing
//
//  High-fidelity stroke point capture for real-time ink pipeline
//

import Foundation
import CoreGraphics

#if canImport(UIKit)
import UIKit
#endif

/// A single point captured from Apple Pencil or finger input
struct StrokePoint: Codable, Equatable {
    let location: CGPoint
    let timestamp: TimeInterval
    let force: CGFloat
    let altitudeAngle: CGFloat  // Tilt angle (0 = flat, π/2 = perpendicular)
    let azimuthAngle: CGFloat   // Direction of tilt

    // Estimated properties bitmask (for tracking prediction confidence)
    let estimatedPropertiesMask: Int

    init(
        location: CGPoint,
        timestamp: TimeInterval,
        force: CGFloat,
        altitudeAngle: CGFloat,
        azimuthAngle: CGFloat,
        estimatedProperties: UITouch.Properties = []
    ) {
        self.location = location
        self.timestamp = timestamp
        self.force = force
        self.altitudeAngle = altitudeAngle
        self.azimuthAngle = azimuthAngle
        self.estimatedPropertiesMask = estimatedProperties.rawValue
    }

    /// Create from UITouch
    init(from touch: UITouch, in view: UIView, timestamp: TimeInterval) {
        self.location = touch.location(in: view)
        self.timestamp = timestamp
        self.force = touch.force
        self.altitudeAngle = touch.altitudeAngle
        self.azimuthAngle = touch.azimuthAngle(in: view)
        self.estimatedPropertiesMask = touch.estimatedProperties.rawValue
    }

    var estimatedProperties: UITouch.Properties {
        return UITouch.Properties(rawValue: estimatedPropertiesMask)
    }
}

/// A stroke being drawn in real-time (not yet committed)
struct InProgressStroke {
    var points: [StrokePoint]
    let startTime: Date
    let touchType: UITouch.TouchType
    var isPredicted: Bool = false  // For ghost rendering

    init(touchType: UITouch.TouchType = .pencil) {
        self.points = []
        self.startTime = Date()
        self.touchType = touchType
    }

    mutating func append(_ point: StrokePoint) {
        points.append(point)
    }

    mutating func append(contentsOf newPoints: [StrokePoint]) {
        points.append(contentsOf: newPoints)
    }

    var length: CGFloat {
        guard points.count > 1 else { return 0 }
        var total: CGFloat = 0
        for i in 1..<points.count {
            let prev = points[i - 1].location
            let curr = points[i].location
            total += hypot(curr.x - prev.x, curr.y - prev.y)
        }
        return total
    }

    var averageForce: CGFloat {
        guard !points.isEmpty else { return 0 }
        return points.reduce(0) { $0 + $1.force } / CGFloat(points.count)
    }

    var boundingBox: CGRect {
        guard !points.isEmpty else { return .zero }
        let locations = points.map { $0.location }
        let minX = locations.map { $0.x }.min() ?? 0
        let maxX = locations.map { $0.x }.max() ?? 0
        let minY = locations.map { $0.y }.min() ?? 0
        let maxY = locations.map { $0.y }.max() ?? 0
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}
