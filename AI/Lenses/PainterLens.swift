//
//  PainterLens.swift
//  AIDrawing
//
//  Analyzes composition, balance, density, and form
//

import Foundation
import CoreGraphics

class PainterLens: Lens {
    var weight: Double = 1.0

    // Thresholds
    private let balanceThreshold = 0.3
    private let negativeSpaceThreshold = 0.4
    private let gridSize = 16  // For density map

    func analyze(
        userStroke: Stroke,
        recentStrokes: [Stroke],
        canvasState: CanvasState
    ) -> LensAnalysis {
        let allStrokes = canvasState.session.strokes

        // Extract compositional features
        let densityMap = buildDensityMap(allStrokes)
        let balanceScore = calculateBalance(densityMap)
        let edgeDefinition = analyzeEdges(userStroke, recentStrokes)
        let negativeSpace = calculateNegativeSpace(allStrokes)

        var suggestions: [(AIMoveType, Double)] = []

        // Composition is unbalanced - add structural support
        if balanceScore < balanceThreshold {
            suggestions.append((.structural, 0.7))
        }

        // Edges need reinforcement
        if edgeDefinition.isWeak {
            suggestions.append((.structural, 0.6))
        }

        // Too much negative space - suggest filling
        if negativeSpace > negativeSpaceThreshold {
            suggestions.append((.predictive, 0.5))
        }

        // Dense area - add contrast or texture
        if densityMap.hasHighDensityZones {
            suggestions.append((.contrast, 0.5))
            suggestions.append((.texture, 0.4))
        }

        let parameters: [String: Double] = [
            "balance": balanceScore,
            "negativeSpace": negativeSpace,
            "edgeStrength": edgeDefinition.strength,
            "maxDensity": densityMap.maxDensity
        ]

        let urgency = LensAnalysis.calculateUrgency(from: suggestions)

        return LensAnalysis(
            lensType: .painter,
            suggestedMoveTypes: suggestions,
            parameters: parameters,
            urgency: balanceScore < 0.3 ? 0.8 : urgency * weight
        )
    }

    // MARK: - Analysis Methods

    private func buildDensityMap(_ strokes: [Stroke]) -> DensityMap {
        // Create grid-based density map
        var grid = Array(repeating: Array(repeating: 0, count: gridSize), count: gridSize)

        guard !strokes.isEmpty else {
            return DensityMap(grid: grid, gridSize: gridSize)
        }

        // Find canvas bounds
        let bounds = calculateCanvasBounds(strokes)

        // Map strokes to grid cells
        for stroke in strokes {
            let centerX = stroke.boundingBox.midX
            let centerY = stroke.boundingBox.midY

            let cellX = Int((centerX - bounds.minX) / bounds.width * CGFloat(gridSize - 1))
            let cellY = Int((centerY - bounds.minY) / bounds.height * CGFloat(gridSize - 1))

            let clampedX = max(0, min(gridSize - 1, cellX))
            let clampedY = max(0, min(gridSize - 1, cellY))

            grid[clampedY][clampedX] += 1
        }

        return DensityMap(grid: grid, gridSize: gridSize)
    }

    private func calculateBalance(_ densityMap: DensityMap) -> Double {
        let grid = densityMap.grid

        // Calculate center of mass
        var totalMass: Double = 0.0
        var centerX: Double = 0.0
        var centerY: Double = 0.0

        for y in 0..<densityMap.gridSize {
            for x in 0..<densityMap.gridSize {
                let mass = Double(grid[y][x])
                totalMass += mass
                centerX += mass * Double(x)
                centerY += mass * Double(y)
            }
        }

        guard totalMass > 0 else { return 1.0 }

        centerX /= totalMass
        centerY /= totalMass

        // Calculate distance from canvas center
        let canvasCenter = Double(densityMap.gridSize) / 2.0
        let distanceX = abs(centerX - canvasCenter)
        let distanceY = abs(centerY - canvasCenter)
        let distance = sqrt(distanceX * distanceX + distanceY * distanceY)

        // Normalize distance (max distance is from center to corner)
        let maxDistance = sqrt(2.0) * canvasCenter
        let normalizedDistance = distance / maxDistance

        // Balance score: 1.0 = perfectly balanced, 0.0 = very unbalanced
        return 1.0 - normalizedDistance
    }

    private func analyzeEdges(_ stroke: Stroke, _ recentStrokes: [Stroke]) -> (isWeak: Bool, strength: Double) {
        // Analyze if strokes have clear edge definition
        let allStrokes = recentStrokes + [stroke]

        var edgeStrengthSum: Double = 0.0

        for stroke in allStrokes {
            // Edge strength correlates with straightness and length
            let straightness = stroke.startPoint.distance(to: stroke.endPoint) / CGFloat(stroke.length)
            let lengthFactor = min(stroke.length / 200.0, 1.0)  // Normalize

            edgeStrengthSum += Double(straightness) * lengthFactor
        }

        let avgEdgeStrength = edgeStrengthSum / Double(allStrokes.count)
        let isWeak = avgEdgeStrength < 0.3

        return (isWeak, avgEdgeStrength)
    }

    private func calculateNegativeSpace(_ strokes: [Stroke]) -> Double {
        guard !strokes.isEmpty else { return 1.0 }

        let bounds = calculateCanvasBounds(strokes)
        let canvasArea = bounds.width * bounds.height

        guard canvasArea > 0 else { return 1.0 }

        // Sum of stroke bounding boxes
        let strokeArea = strokes.reduce(0.0) { sum, stroke in
            sum + Double(stroke.boundingBox.area)
        }

        // Negative space = 1 - (stroke area / canvas area)
        let negativeSpace = 1.0 - (strokeArea / Double(canvasArea))
        return max(0.0, min(1.0, negativeSpace))
    }

    private func calculateCanvasBounds(_ strokes: [Stroke]) -> (minX: CGFloat, minY: CGFloat, width: CGFloat, height: CGFloat) {
        guard let first = strokes.first else {
            return (0, 0, 1000, 1000)  // Default canvas size
        }

        var minX = first.boundingBox.minX
        var minY = first.boundingBox.minY
        var maxX = first.boundingBox.maxX
        var maxY = first.boundingBox.maxY

        for stroke in strokes {
            minX = min(minX, stroke.boundingBox.minX)
            minY = min(minY, stroke.boundingBox.minY)
            maxX = max(maxX, stroke.boundingBox.maxX)
            maxY = max(maxY, stroke.boundingBox.maxY)
        }

        return (minX, minY, maxX - minX, maxY - minY)
    }
}

// MARK: - Helper Structures

struct DensityMap {
    let grid: [[Int]]
    let gridSize: Int

    var maxDensity: Double {
        let maxCell = grid.flatMap { $0 }.max() ?? 0
        return Double(maxCell)
    }

    var hasHighDensityZones: Bool {
        return maxDensity > 3.0  // Threshold for "high density"
    }
}
