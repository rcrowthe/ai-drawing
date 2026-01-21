//
//  StrokeSmoothing.swift
//  AIDrawing
//
//  Stroke smoothing and resampling algorithms
//

import Foundation
import CoreGraphics

enum StrokeSmoothingAlgorithm {
    case none
    case chaikin(iterations: Int)
    case catmullRom(alpha: CGFloat)
    case oneEuro(minCutoff: Double, beta: Double)
}

class StrokeSmoother {

    // MARK: - Chaikin Smoothing

    /// Chaikin corner cutting algorithm - simple subdivision smoothing
    static func chaikinSmooth(points: [StrokePoint], iterations: Int = 1) -> [StrokePoint] {
        guard points.count >= 2 else { return points }

        var result = points

        for _ in 0..<iterations {
            var smoothed: [StrokePoint] = []

            // Keep first point
            if let first = result.first {
                smoothed.append(first)
            }

            // Subdivide each segment
            for i in 0..<(result.count - 1) {
                let p0 = result[i]
                let p1 = result[i + 1]

                // Quarter point
                let q = interpolate(from: p0, to: p1, t: 0.25)
                smoothed.append(q)

                // Three-quarter point
                let r = interpolate(from: p0, to: p1, t: 0.75)
                smoothed.append(r)
            }

            // Keep last point
            if let last = result.last {
                smoothed.append(last)
            }

            result = smoothed
        }

        return result
    }

    // MARK: - Catmull-Rom Spline

    /// Catmull-Rom spline interpolation for smooth curves
    static func catmullRomSmooth(points: [StrokePoint], alpha: CGFloat = 0.5, segmentsPerPoint: Int = 4) -> [StrokePoint] {
        guard points.count >= 4 else { return points }

        var result: [StrokePoint] = []

        // Keep first point
        result.append(points[0])

        for i in 0..<(points.count - 3) {
            let p0 = points[i]
            let p1 = points[i + 1]
            let p2 = points[i + 2]
            let p3 = points[i + 3]

            // Generate interpolated points between p1 and p2
            for j in 0..<segmentsPerPoint {
                let t = CGFloat(j) / CGFloat(segmentsPerPoint)
                let point = catmullRomInterpolate(p0: p0, p1: p1, p2: p2, p3: p3, t: t, alpha: alpha)
                result.append(point)
            }
        }

        // Add last two points
        if points.count >= 2 {
            result.append(points[points.count - 2])
            result.append(points[points.count - 1])
        }

        return result
    }

    private static func catmullRomInterpolate(
        p0: StrokePoint,
        p1: StrokePoint,
        p2: StrokePoint,
        p3: StrokePoint,
        t: CGFloat,
        alpha: CGFloat
    ) -> StrokePoint {
        // Calculate time deltas
        let t01 = pow(distance(p0.location, p1.location), alpha)
        let t12 = pow(distance(p1.location, p2.location), alpha)
        let t23 = pow(distance(p2.location, p3.location), alpha)

        // Calculate intermediate points
        let m1 = (p2.location - p0.location) / (t01 + t12) * t12
        let m2 = (p3.location - p1.location) / (t12 + t23) * t12

        // Hermite interpolation
        let t2 = t * t
        let t3 = t2 * t

        let h00 = 2 * t3 - 3 * t2 + 1
        let h10 = t3 - 2 * t2 + t
        let h01 = -2 * t3 + 3 * t2
        let h11 = t3 - t2

        let x = h00 * p1.location.x + h10 * m1.x + h01 * p2.location.x + h11 * m2.x
        let y = h00 * p1.location.y + h10 * m1.y + h01 * p2.location.y + h11 * m2.y

        // Interpolate other properties
        let force = p1.force * (1 - t) + p2.force * t
        let altitude = p1.altitudeAngle * (1 - t) + p2.altitudeAngle * t
        let azimuth = p1.azimuthAngle * (1 - t) + p2.azimuthAngle * t
        let timestamp = p1.timestamp * Double(1 - t) + p2.timestamp * Double(t)

        return StrokePoint(
            location: CGPoint(x: x, y: y),
            timestamp: timestamp,
            force: force,
            altitudeAngle: altitude,
            azimuthAngle: azimuth
        )
    }

    // MARK: - Distance-Based Decimation

    /// Remove points that are too close together (reduces noise and AI spam)
    static func decimate(points: [StrokePoint], minimumDistance: CGFloat = 2.0) -> [StrokePoint] {
        guard points.count >= 2 else { return points }

        var result: [StrokePoint] = []

        // Always keep first point
        result.append(points[0])

        for i in 1..<points.count {
            let lastKept = result.last!
            let current = points[i]
            let dist = distance(lastKept.location, current.location)

            if dist >= minimumDistance {
                result.append(current)
            }
        }

        // Always keep last point (even if close)
        if let last = points.last, result.last != last {
            result.append(last)
        }

        return result
    }

    // MARK: - One-Euro Filter (Advanced)

    /// Low-lag filter for real-time smoothing
    /// Based on: "1€ Filter: A Simple Speed-based Low-pass Filter"
    class OneEuroFilter {
        private var minCutoff: Double
        private var beta: Double
        private var dCutoff: Double = 1.0

        private var xPrev: CGPoint?
        private var dxPrev: CGPoint = .zero
        private var tPrev: TimeInterval?

        init(minCutoff: Double = 1.0, beta: Double = 0.007) {
            self.minCutoff = minCutoff
            self.beta = beta
        }

        func filter(point: StrokePoint) -> StrokePoint {
            guard let xPrev = xPrev, let tPrev = tPrev else {
                // First sample
                self.xPrev = point.location
                self.tPrev = point.timestamp
                return point
            }

            let dt = point.timestamp - tPrev
            guard dt > 0 else { return point }

            // Calculate derivative
            let dx = CGPoint(
                x: (point.location.x - xPrev.x) / CGFloat(dt),
                y: (point.location.y - xPrev.y) / CGFloat(dt)
            )

            // Smooth derivative
            let edx = smoothWithLowPass(dx, dxPrev, alpha(dt, dCutoff))

            // Calculate cutoff frequency
            let cutoff = minCutoff + beta * abs(edx)

            // Smooth position
            let filtered = smoothWithLowPass(point.location, xPrev, alpha(dt, cutoff))

            // Update state
            self.xPrev = filtered
            self.dxPrev = edx
            self.tPrev = point.timestamp

            return StrokePoint(
                location: filtered,
                timestamp: point.timestamp,
                force: point.force,
                altitudeAngle: point.altitudeAngle,
                azimuthAngle: point.azimuthAngle
            )
        }

        private func alpha(_ dt: TimeInterval, _ cutoff: Double) -> CGFloat {
            let tau = 1.0 / (2.0 * .pi * cutoff)
            return CGFloat(1.0 / (1.0 + tau / dt))
        }

        private func smoothWithLowPass(_ current: CGPoint, _ prev: CGPoint, _ alpha: CGFloat) -> CGPoint {
            return CGPoint(
                x: alpha * current.x + (1 - alpha) * prev.x,
                y: alpha * current.y + (1 - alpha) * prev.y
            )
        }

        private func abs(_ point: CGPoint) -> Double {
            return Double(sqrt(point.x * point.x + point.y * point.y))
        }
    }

    // MARK: - Helper Functions

    private static func interpolate(from p0: StrokePoint, to p1: StrokePoint, t: CGFloat) -> StrokePoint {
        return StrokePoint(
            location: CGPoint(
                x: p0.location.x * (1 - t) + p1.location.x * t,
                y: p0.location.y * (1 - t) + p1.location.y * t
            ),
            timestamp: p0.timestamp * Double(1 - t) + p1.timestamp * Double(t),
            force: p0.force * (1 - t) + p1.force * t,
            altitudeAngle: p0.altitudeAngle * (1 - t) + p1.altitudeAngle * t,
            azimuthAngle: p0.azimuthAngle * (1 - t) + p1.azimuthAngle * t
        )
    }

    private static func distance(_ p0: CGPoint, _ p1: CGPoint) -> CGFloat {
        return hypot(p1.x - p0.x, p1.y - p0.y)
    }
}

// MARK: - CGPoint Operators

extension CGPoint {
    static func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    static func /(lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        return CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
    }

    static func *(lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        return CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
    }
}
