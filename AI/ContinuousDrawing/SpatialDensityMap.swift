//
//  SpatialDensityMap.swift
//  AIDrawing
//
//  Calculates stroke density to avoid overcrowding
//

import Foundation
import CoreGraphics

class SpatialDensityMap {
    private let gridSize: CGFloat = 100.0  // 100x100 point cells

    /// Calculate local (max cell) and global (overall) density
    /// Returns (local: 0-1, global: 0-1)
    func calculate(strokes: [Stroke]) -> (local: Double, global: Double) {
        guard !strokes.isEmpty else {
            return (0.0, 0.0)
        }

        // Calculate global density (total strokes / canvas area)
        let bounds = calculateBounds(strokes)
        let area = bounds.width * bounds.height

        guard area > 0 else {
            return (0.0, 0.0)
        }

        let globalDensity = Double(strokes.count) / Double(area) * 10000.0

        // Calculate local density (densest grid cell)
        let grid = buildDensityGrid(strokes, bounds: bounds)
        let maxCellDensity = grid.values.max() ?? 0
        let localDensity = min(1.0, Double(maxCellDensity) / 10.0)  // Normalize

        return (localDensity, min(1.0, globalDensity))
    }

    private func buildDensityGrid(_ strokes: [Stroke], bounds: CGRect) -> [String: Int] {
        var grid: [String: Int] = [:]

        for stroke in strokes {
            let center = stroke.boundingBox.center
            let cellX = Int(center.x / gridSize)
            let cellY = Int(center.y / gridSize)
            let key = "\(cellX),\(cellY)"

            grid[key, default: 0] += 1
        }

        return grid
    }

    private func calculateBounds(_ strokes: [Stroke]) -> CGRect {
        let allBounds = strokes.map { $0.boundingBox }
        guard let first = allBounds.first else {
            return .zero
        }

        var minX = first.minX
        var minY = first.minY
        var maxX = first.maxX
        var maxY = first.maxY

        for bounds in allBounds {
            minX = min(minX, bounds.minX)
            minY = min(minY, bounds.minY)
            maxX = max(maxX, bounds.maxX)
            maxY = max(maxY, bounds.maxY)
        }

        let width = maxX - minX
        let height = maxY - minY

        // Ensure minimum canvas size for density calculation
        let minSize: CGFloat = 100.0
        let finalWidth = max(width, minSize)
        let finalHeight = max(height, minSize)

        return CGRect(x: minX, y: minY, width: finalWidth, height: finalHeight)
    }
}
