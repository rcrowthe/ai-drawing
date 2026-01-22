//
//  IvyGenerator.swift
//  AIDrawing
//
//  Generates organic vine-like strokes that follow and jump between strokes
//

import Foundation
import PencilKit
import CoreGraphics

class IvyGenerator {
    /// Generate ivy stroke that follows and jumps between strokes
    func generate(
        userStroke: Stroke,
        recentStrokes: [Stroke],
        canvasState: CanvasState,
        state: AIState,
        configuration: AIConfiguration
    ) -> AIMove? {
        // Start from the BEGINNING of the most recent stroke
        let startPoint = userStroke.startPoint

        // Get all strokes on canvas for proximity detection
        let allStrokes = canvasState.session.strokes

        // Generate ivy path
        var controlPoints: [PKStrokePoint] = []
        var currentStroke = userStroke
        var currentProgress: CGFloat = 0.0
        var currentSide: CGFloat = 1.0  // 1.0 = right side, -1.0 = left side
        var segmentsSinceLastJump = 0  // Cooldown to prevent excessive jumping

        let totalSegments = GeneratorParameters.Ivy.totalSegments
        var segmentCount = 0

        // Wave parameters based on user stroke energy
        let waveAmplitude = GeneratorParameters.Ivy.baseWaveAmplitude * (userStroke.avgPressure > 0.5 ? 1.5 : 1.0)
        let waveFrequency = CGFloat.pi * 2.0 / CGFloat(min(currentStroke.length / 20.0, 10.0))

        while segmentCount < totalSegments {
            // Sample point along current stroke
            let t = currentProgress
            let strokePoint = interpolatePoint(on: currentStroke, at: t)

            // Calculate tangent and perpendicular directions
            let tangent = calculateTangent(on: currentStroke, at: t)
            let perpendicular = CGPoint(x: -tangent.y, y: tangent.x)

            // Wave offset (sine wave along the stroke)
            let waveOffset = sin(CGFloat(segmentCount) * waveFrequency) * waveAmplitude * currentSide

            // Occasionally crisscross (flip to other side)
            if Double.random(in: 0...1) < GeneratorParameters.Ivy.crisscrossProbability {
                currentSide *= -1.0
            }

            // Calculate ivy point position
            let ivyX = strokePoint.x + perpendicular.x * waveOffset
            let ivyY = strokePoint.y + perpendicular.y * waveOffset
            let ivyPoint = CGPoint(x: ivyX, y: ivyY)

            // Calculate point size (needed for both regular points and transitions)
            let basePressure = GeneratorParameters.Ivy.pointSize + (userStroke.avgPressure * 1.5)
            let pointSize = max(basePressure, 3.5)  // Minimum 3.5 to ensure visibility

            // Check for nearby strokes to jump to (with cooldown and randomness)
            segmentsSinceLastJump += 1
            let canJump = segmentsSinceLastJump > 3  // Wait at least 3 segments after jump
            let shouldTryJump = Double.random(in: 0...1) < 0.3  // Only try 30% of the time

            if canJump && shouldTryJump {
                if let (nearbyStroke, landingPoint) = findNearbyStroke(
                    at: ivyPoint,
                    currentStroke: currentStroke,
                    allStrokes: allStrokes,
                    proximityThreshold: GeneratorParameters.Ivy.proximityThreshold
                ) {
                    print("🌿 Ivy jumping from stroke \(currentStroke.id) to \(nearbyStroke.id) at t=\(String(format: "%.2f", landingPoint))")

                    // Calculate the landing point on the new stroke
                    let landingStrokePoint = interpolatePoint(on: nearbyStroke, at: landingPoint)

                    // Add 2-3 transition points to smoothly connect current position to landing point
                    let transitionSteps = 3
                    for step in 1...transitionSteps {
                        let transitionT = CGFloat(step) / CGFloat(transitionSteps)
                        let transitionX = ivyPoint.x + (landingStrokePoint.x - ivyPoint.x) * transitionT
                        let transitionY = ivyPoint.y + (landingStrokePoint.y - ivyPoint.y) * transitionT

                        let transitionPoint = PKStrokePoint(
                            location: CGPoint(x: transitionX, y: transitionY),
                            timeOffset: TimeInterval(segmentCount) * 0.015,
                            size: CGSize(width: pointSize, height: pointSize),
                            opacity: GeneratorParameters.Ivy.opacity,
                            force: GeneratorParameters.Ivy.force,
                            azimuth: 0,
                            altitude: .pi / 4
                        )
                        controlPoints.append(transitionPoint)
                        segmentCount += 1
                    }

                    // Now switch to the new stroke
                    currentStroke = nearbyStroke
                    currentProgress = landingPoint
                    segmentsSinceLastJump = 0  // Reset cooldown

                    // Skip creating the normal ivy point this iteration since we just added transition
                    continue
                }
            }

            // Create stroke point with smoothness control
            let point = PKStrokePoint(
                location: ivyPoint,
                timeOffset: TimeInterval(segmentCount) * 0.015,
                size: CGSize(width: pointSize, height: pointSize),
                opacity: GeneratorParameters.Ivy.opacity,
                force: GeneratorParameters.Ivy.force,
                azimuth: 0,
                altitude: .pi / 4
            )

            controlPoints.append(point)

            // Advance along stroke
            currentProgress += 1.0 / CGFloat(totalSegments) * 2.0
            if currentProgress > 1.0 {
                break  // Reached end of stroke
            }

            segmentCount += 1
        }

        guard controlPoints.count > 1 else {
            print("🌿 Ivy: Not enough points generated")
            return nil
        }

        // Apply smoothness - interpolate between control points if needed
        if GeneratorParameters.Ivy.smoothness > 0.5 {
            controlPoints = smoothPath(controlPoints, smoothness: GeneratorParameters.Ivy.smoothness)
        }

        let path = PKStrokePath(controlPoints: controlPoints, creationDate: Date())

        // Animation speed based on user velocity
        // Slow user → languid ivy (0.7x), fast user → quick growth (1.5x)
        let animationSpeed = userStroke.avgVelocity < 200.0 ? 0.7 :
                             userStroke.avgVelocity > 400.0 ? 1.5 : 1.0

        print("🌿 IvyGenerator: points=\(controlPoints.count), smoothness=\(GeneratorParameters.Ivy.smoothness), animSpeed=\(animationSpeed)x")

        // Apply color variation from configuration
        let baseColor = GeneratorColors.ivyColor
        let variedColor = configuration.applyColorVariation(to: baseColor)

        return AIMove(
            moveType: .ivy,
            path: path,
            tool: PKInkingTool(.pen, color: variedColor, width: GeneratorParameters.Ivy.strokeWidth),
            animationSpeed: animationSpeed,
            metadata: [
                "smoothness": GeneratorParameters.Ivy.smoothness,
                "jumps": 0,  // Could track stroke jumps
                "waveAmplitude": Double(waveAmplitude)
            ]
        )
    }

    // MARK: - Helper Methods

    /// Interpolate point along stroke at parameter t (0.0 to 1.0)
    private func interpolatePoint(on stroke: Stroke, at t: CGFloat) -> CGPoint {
        let clampedT = max(0.0, min(1.0, t))
        let x = stroke.startPoint.x + (stroke.endPoint.x - stroke.startPoint.x) * clampedT
        let y = stroke.startPoint.y + (stroke.endPoint.y - stroke.startPoint.y) * clampedT
        return CGPoint(x: x, y: y)
    }

    /// Calculate tangent direction at point on stroke
    private func calculateTangent(on stroke: Stroke, at t: CGFloat) -> CGPoint {
        // Simple tangent = direction vector normalized
        let dx = stroke.endPoint.x - stroke.startPoint.x
        let dy = stroke.endPoint.y - stroke.startPoint.y
        let lengthSquared = dx * dx + dy * dy

        // Safety: Check for valid value before sqrt
        guard lengthSquared.isFinite && lengthSquared >= 0 else {
            print("⚠️ IvyGenerator: Invalid length calculation in tangent")
            return CGPoint(x: 1.0, y: 0.0)
        }

        let length = sqrt(lengthSquared)

        guard length > 0 else {
            return CGPoint(x: 1.0, y: 0.0)
        }

        return CGPoint(x: dx / length, y: dy / length)
    }

    /// Find nearby stroke within proximity threshold and return the closest point on it
    /// Returns tuple of (stroke, t parameter where 0=start, 1=end)
    private func findNearbyStroke(
        at point: CGPoint,
        currentStroke: Stroke,
        allStrokes: [Stroke],
        proximityThreshold: CGFloat
    ) -> (Stroke, CGFloat)? {
        var closestStroke: Stroke?
        var closestT: CGFloat = 0.0
        var closestDistance: CGFloat = proximityThreshold

        for stroke in allStrokes {
            // Skip current stroke and AI strokes
            if stroke.id == currentStroke.id || stroke.source == .ai {
                continue
            }

            // Find closest point on this stroke
            let (closestPointOnStroke, t) = closestPointOnLineSegment(
                point: point,
                lineStart: stroke.startPoint,
                lineEnd: stroke.endPoint
            )

            let distance = point.distance(to: closestPointOnStroke)

            if distance < closestDistance {
                closestDistance = distance
                closestStroke = stroke
                // Add small bias toward endpoint (prefer t > 0.5)
                // This makes ivy tend to follow strokes toward their ends
                closestT = t < 0.5 ? t + 0.1 : t
                closestT = min(1.0, closestT) // Clamp to valid range
            }
        }

        if let stroke = closestStroke {
            return (stroke, closestT)
        }
        return nil
    }

    /// Project a point onto a line segment and return closest point + parameter t
    private func closestPointOnLineSegment(
        point: CGPoint,
        lineStart: CGPoint,
        lineEnd: CGPoint
    ) -> (CGPoint, CGFloat) {
        let dx = lineEnd.x - lineStart.x
        let dy = lineEnd.y - lineStart.y
        let lengthSquared = dx * dx + dy * dy

        // Handle degenerate case (line is a point)
        guard lengthSquared > 0.0001 else {
            return (lineStart, 0.0)
        }

        // Calculate projection parameter t
        let t = ((point.x - lineStart.x) * dx + (point.y - lineStart.y) * dy) / lengthSquared

        // Clamp t to [0, 1] to stay on the line segment
        let clampedT = max(0.0, min(1.0, t))

        // Calculate the closest point
        let closestX = lineStart.x + clampedT * dx
        let closestY = lineStart.y + clampedT * dy

        return (CGPoint(x: closestX, y: closestY), clampedT)
    }

    /// Smooth path by interpolating between control points
    private func smoothPath(_ points: [PKStrokePoint], smoothness: Double) -> [PKStrokePoint] {
        guard points.count > 2, smoothness > 0.5 else {
            return points
        }

        var smoothed: [PKStrokePoint] = []

        // Keep first point
        smoothed.append(points[0])

        // Interpolate between points using smoothness factor
        for i in 1..<(points.count - 1) {
            let prev = points[i - 1]
            let curr = points[i]
            let next = points[i + 1]

            // Catmull-Rom-like smoothing
            let smoothFactor = CGFloat(smoothness)
            let x = curr.location.x
            let y = curr.location.y

            // Blend toward average of neighbors
            let avgX = (prev.location.x + next.location.x) / 2.0
            let avgY = (prev.location.y + next.location.y) / 2.0

            let smoothedX = x * (1.0 - smoothFactor) + avgX * smoothFactor
            let smoothedY = y * (1.0 - smoothFactor) + avgY * smoothFactor

            let smoothedPoint = PKStrokePoint(
                location: CGPoint(x: smoothedX, y: smoothedY),
                timeOffset: curr.timeOffset,
                size: curr.size,
                opacity: curr.opacity,
                force: curr.force,
                azimuth: curr.azimuth,
                altitude: curr.altitude
            )

            smoothed.append(smoothedPoint)
        }

        // Keep last point
        smoothed.append(points[points.count - 1])

        return smoothed
    }
}
