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
        // Start from a RANDOM POINT along the most recent stroke (not always the beginning!)
        let randomStartProgress = CGFloat.random(in: 0.0...1.0)
        let startPoint = interpolatePoint(on: userStroke, at: randomStartProgress)

        // Track the origin point to prevent ivy from wandering too far
        let originPoint = startPoint
        let maxDistanceFromOrigin: CGFloat = 200.0  // Keep ivy within 200px of where it started

        // Get all strokes on canvas for proximity detection
        let allStrokes = canvasState.session.strokes

        // SHAPE AWARENESS: Detect dominant geometric angles nearby
        let dominantAngle = detectDominantAngle(
            near: originPoint,
            strokes: allStrokes,
            minRadius: CGFloat(configuration.ivyShapeDetectionMinRadius),
            maxRadius: CGFloat(configuration.ivyShapeDetectionMaxRadius)
        )

        // Determine ivy's relationship to detected shapes based on conformance setting
        // 0.0 = contrast/perpendicular, 0.5 = independent, 1.0 = conform/parallel
        let conformance = configuration.ivyShapeConformance

        // Choose generation mode based on shape detection
        if let detectedAngle = dominantAngle {
            // SHAPE-AWARE MODE: React to detected shapes
            let angleAdjustment = CGFloat((.pi / 2) * (1.0 - conformance))
            print("🌿 Ivy shape awareness: detected angle=\(Int(detectedAngle * 180 / .pi))°, conformance=\(String(format: "%.2f", conformance)), adjustment=\(Int(angleAdjustment * 180 / .pi))°")

            return generateShapeAwareIvy(
                userStroke: userStroke,
                startPoint: startPoint,
                originPoint: originPoint,
                maxDistanceFromOrigin: maxDistanceFromOrigin,
                allStrokes: allStrokes,
                detectedAngle: detectedAngle,
                angleAdjustment: angleAdjustment,
                conformance: conformance,
                configuration: configuration
            )
        } else {
            // GEOMETRIC MODE: No shapes detected, create geometric patterns
            print("🌿 Ivy geometric mode: generating geometric pattern")

            return generateGeometricIvy(
                userStroke: userStroke,
                startPoint: startPoint,
                configuration: configuration
            )
        }
    }

    // MARK: - Shape-Aware Ivy Generation

    private func generateShapeAwareIvy(
        userStroke: Stroke,
        startPoint: CGPoint,
        originPoint: CGPoint,
        maxDistanceFromOrigin: CGFloat,
        allStrokes: [Stroke],
        detectedAngle: CGFloat,
        angleAdjustment: CGFloat,
        conformance: Double,
        configuration: AIConfiguration
    ) -> AIMove? {
        // Generate ivy path
        var controlPoints: [PKStrokePoint] = []
        var currentStroke = userStroke
        var currentProgress: CGFloat = CGFloat.random(in: 0.0...1.0)  // Random start
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
            var perpendicular = CGPoint(x: -tangent.y, y: tangent.x)

            // SHAPE AWARENESS: Adjust perpendicular direction based on detected shapes
            // Calculate shape-aware direction
            let targetAngle = detectedAngle + angleAdjustment
            // Blend the natural perpendicular with the shape-aware direction
            let blendFactor = abs(conformance - 0.5) * 2.0  // 0 at 0.5, 1 at extremes
            let shapeAwareX = cos(targetAngle)
            let shapeAwareY = sin(targetAngle)
            perpendicular.x = perpendicular.x * CGFloat(1.0 - blendFactor) + shapeAwareX * CGFloat(blendFactor)
            perpendicular.y = perpendicular.y * CGFloat(1.0 - blendFactor) + shapeAwareY * CGFloat(blendFactor)

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

            // Calculate point size with subtle pressure variation (respects user settings!)
            // Range: 0.8x to 1.2x of base pointSize based on stroke pressure
            let pressureVariation = 0.8 + (userStroke.avgPressure * 0.4)
            let pointSize = GeneratorParameters.Ivy.pointSize * pressureVariation

            // Check for nearby strokes to jump to (with cooldown and randomness)
            segmentsSinceLastJump += 1
            let canJump = segmentsSinceLastJump > 3  // Wait at least 3 segments after jump
            let shouldTryJump = Double.random(in: 0...1) < 0.3  // Only try 30% of the time

            if canJump && shouldTryJump {
                if let (nearbyStroke, landingPoint) = findNearbyStroke(
                    at: ivyPoint,
                    originPoint: originPoint,
                    maxDistanceFromOrigin: maxDistanceFromOrigin,
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

    // MARK: - Geometric Ivy Generation

    private func generateGeometricIvy(
        userStroke: Stroke,
        startPoint: CGPoint,
        configuration: AIConfiguration
    ) -> AIMove? {
        // Choose geometric pattern randomly
        enum GeometricPattern {
            case square
            case circle
            case triangle  // 3 sides
            case halfCircle
        }

        let patterns: [GeometricPattern] = [.square, .circle, .triangle, .halfCircle]
        let chosenPattern = patterns.randomElement() ?? .circle

        var controlPoints: [PKStrokePoint] = []
        let totalSegments = GeneratorParameters.Ivy.totalSegments
        let radius: CGFloat = 40.0 + CGFloat.random(in: -10...20)  // 30-60px radius
        let basePointSize = GeneratorParameters.Ivy.pointSize

        print("🌿 Generating geometric pattern: \(chosenPattern)")

        switch chosenPattern {
        case .square:
            // Square pattern
            let sideLength = radius * 2.0
            let halfSide = sideLength / 2.0
            let corners = [
                CGPoint(x: startPoint.x - halfSide, y: startPoint.y - halfSide),  // Top-left
                CGPoint(x: startPoint.x + halfSide, y: startPoint.y - halfSide),  // Top-right
                CGPoint(x: startPoint.x + halfSide, y: startPoint.y + halfSide),  // Bottom-right
                CGPoint(x: startPoint.x - halfSide, y: startPoint.y + halfSide),  // Bottom-left
                CGPoint(x: startPoint.x - halfSide, y: startPoint.y - halfSide)   // Close the square
            ]

            for i in 0...totalSegments {
                let t = CGFloat(i) / CGFloat(totalSegments)
                let edgeIndex = Int(t * 4.0).clamped(to: 0...3)
                let edgeT = (t * 4.0).truncatingRemainder(dividingBy: 1.0)

                let start = corners[edgeIndex]
                let end = corners[edgeIndex + 1]
                let x = start.x + (end.x - start.x) * edgeT
                let y = start.y + (end.y - start.y) * edgeT

                let point = PKStrokePoint(
                    location: CGPoint(x: x, y: y),
                    timeOffset: TimeInterval(i) * 0.015,
                    size: CGSize(width: basePointSize, height: basePointSize),
                    opacity: GeneratorParameters.Ivy.opacity,
                    force: GeneratorParameters.Ivy.force,
                    azimuth: 0,
                    altitude: .pi / 4
                )
                controlPoints.append(point)
            }

        case .circle:
            // Perfect circle
            for i in 0...totalSegments {
                let angle = (CGFloat(i) / CGFloat(totalSegments)) * .pi * 2.0
                let x = startPoint.x + cos(angle) * radius
                let y = startPoint.y + sin(angle) * radius

                let point = PKStrokePoint(
                    location: CGPoint(x: x, y: y),
                    timeOffset: TimeInterval(i) * 0.015,
                    size: CGSize(width: basePointSize, height: basePointSize),
                    opacity: GeneratorParameters.Ivy.opacity,
                    force: GeneratorParameters.Ivy.force,
                    azimuth: 0,
                    altitude: .pi / 4
                )
                controlPoints.append(point)
            }

        case .triangle:
            // Equilateral triangle (3 sides)
            let height = radius * sqrt(3.0)
            let corners = [
                CGPoint(x: startPoint.x, y: startPoint.y - radius),                    // Top vertex
                CGPoint(x: startPoint.x - height / 2.0, y: startPoint.y + radius / 2.0), // Bottom-left
                CGPoint(x: startPoint.x + height / 2.0, y: startPoint.y + radius / 2.0), // Bottom-right
                CGPoint(x: startPoint.x, y: startPoint.y - radius)                     // Close the triangle
            ]

            for i in 0...totalSegments {
                let t = CGFloat(i) / CGFloat(totalSegments)
                let edgeIndex = Int(t * 3.0).clamped(to: 0...2)
                let edgeT = (t * 3.0).truncatingRemainder(dividingBy: 1.0)

                let start = corners[edgeIndex]
                let end = corners[edgeIndex + 1]
                let x = start.x + (end.x - start.x) * edgeT
                let y = start.y + (end.y - start.y) * edgeT

                let point = PKStrokePoint(
                    location: CGPoint(x: x, y: y),
                    timeOffset: TimeInterval(i) * 0.015,
                    size: CGSize(width: basePointSize, height: basePointSize),
                    opacity: GeneratorParameters.Ivy.opacity,
                    force: GeneratorParameters.Ivy.force,
                    azimuth: 0,
                    altitude: .pi / 4
                )
                controlPoints.append(point)
            }

        case .halfCircle:
            // Half circle (semicircle)
            let randomDirection = Bool.random()  // true = top half, false = bottom half
            let startAngle: CGFloat = randomDirection ? 0.0 : .pi

            for i in 0...totalSegments {
                let t = CGFloat(i) / CGFloat(totalSegments)
                let angle = startAngle + t * .pi  // Draw half circle (π radians)
                let x = startPoint.x + cos(angle) * radius
                let y = startPoint.y + sin(angle) * radius

                let point = PKStrokePoint(
                    location: CGPoint(x: x, y: y),
                    timeOffset: TimeInterval(i) * 0.015,
                    size: CGSize(width: basePointSize, height: basePointSize),
                    opacity: GeneratorParameters.Ivy.opacity,
                    force: GeneratorParameters.Ivy.force,
                    azimuth: 0,
                    altitude: .pi / 4
                )
                controlPoints.append(point)
            }
        }

        guard controlPoints.count > 1 else {
            return nil
        }

        // Apply smoothness for organic feel
        if GeneratorParameters.Ivy.smoothness > 0.5 {
            controlPoints = smoothPath(controlPoints, smoothness: GeneratorParameters.Ivy.smoothness * 0.7)  // Less smoothing for geometric patterns
        }

        let path = PKStrokePath(controlPoints: controlPoints, creationDate: Date())

        // Geometric patterns animate at moderate speed
        let animationSpeed = 1.0

        // Apply color variation
        let baseColor = GeneratorColors.ivyColor
        let variedColor = configuration.applyColorVariation(to: baseColor)

        return AIMove(
            moveType: .ivy,
            path: path,
            tool: PKInkingTool(.pen, color: variedColor, width: GeneratorParameters.Ivy.strokeWidth),
            animationSpeed: animationSpeed,
            metadata: [
                "pattern": "\(chosenPattern)",
                "geometric": true
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
    /// Also ensures the stroke is within maxDistanceFromOrigin to prevent wandering too far
    /// Returns tuple of (stroke, t parameter where 0=start, 1=end)
    private func findNearbyStroke(
        at point: CGPoint,
        originPoint: CGPoint,
        maxDistanceFromOrigin: CGFloat,
        currentStroke: Stroke,
        allStrokes: [Stroke],
        proximityThreshold: CGFloat
    ) -> (Stroke, CGFloat)? {
        var closestStroke: Stroke?
        var closestT: CGFloat = 0.0
        var closestDistance: CGFloat = proximityThreshold

        for stroke in allStrokes {
            // Skip only the current stroke we're already following
            // Allow jumping to ANY other stroke (including AI strokes!)
            if stroke.id == currentStroke.id {
                continue
            }

            // Find closest point on this stroke
            let (closestPointOnStroke, t) = closestPointOnLineSegment(
                point: point,
                lineStart: stroke.startPoint,
                lineEnd: stroke.endPoint
            )

            // Calculate distance from current ivy point to this stroke
            let dx1 = point.x - closestPointOnStroke.x
            let dy1 = point.y - closestPointOnStroke.y
            let distance = sqrt(dx1 * dx1 + dy1 * dy1)

            // CHECK: Would this jump take us too far from origin?
            let dx2 = originPoint.x - closestPointOnStroke.x
            let dy2 = originPoint.y - closestPointOnStroke.y
            let distanceFromOrigin = sqrt(dx2 * dx2 + dy2 * dy2)
            if distanceFromOrigin > maxDistanceFromOrigin {
                continue  // Skip this stroke - too far from where we started
            }

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

    /// Detect dominant geometric angle from nearby strokes
    /// Returns angle in radians, or nil if no clear pattern detected
    /// Uses min/max radius to avoid reacting to strokes that are too close or too far
    private func detectDominantAngle(
        near point: CGPoint,
        strokes: [Stroke],
        minRadius: CGFloat,
        maxRadius: CGFloat
    ) -> CGFloat? {
        var nearbyAngles: [CGFloat] = []

        // Collect angles from nearby strokes (within distance band)
        for stroke in strokes {
            // Check if stroke is within search radius band
            let midPoint = CGPoint(
                x: (stroke.startPoint.x + stroke.endPoint.x) / 2.0,
                y: (stroke.startPoint.y + stroke.endPoint.y) / 2.0
            )

            let dx = point.x - midPoint.x
            let dy = point.y - midPoint.y
            let distance = sqrt(dx * dx + dy * dy)

            // Only consider strokes in the distance band
            if distance >= minRadius && distance <= maxRadius {
                // Calculate stroke angle
                let angle = atan2(
                    stroke.endPoint.y - stroke.startPoint.y,
                    stroke.endPoint.x - stroke.startPoint.x
                )
                nearbyAngles.append(angle)
            }
        }

        guard nearbyAngles.count >= 2 else {
            return nil  // Not enough data for pattern detection
        }

        // Find dominant angle using circular mean
        var sumSin: CGFloat = 0.0
        var sumCos: CGFloat = 0.0

        for angle in nearbyAngles {
            sumSin += sin(angle)
            sumCos += cos(angle)
        }

        let meanAngle = atan2(sumSin, sumCos)

        // Check if there's a strong consensus (low variance)
        var variance: CGFloat = 0.0
        for angle in nearbyAngles {
            let diff = angle - meanAngle
            variance += diff * diff
        }
        variance /= CGFloat(nearbyAngles.count)

        // Only return angle if there's a clear pattern (low variance)
        // Variance < 1.0 indicates reasonably aligned strokes
        if variance < 1.0 {
            print("🌿 Shape detected: \(nearbyAngles.count) strokes, angle=\(Int(meanAngle * 180 / .pi))°, variance=\(String(format: "%.2f", variance))")
            return meanAngle
        }

        return nil  // Too much variation, no clear pattern
    }
}

// MARK: - Helper Extensions

extension Int {
    public func clamped(to range: ClosedRange<Int>) -> Int {
        return Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
