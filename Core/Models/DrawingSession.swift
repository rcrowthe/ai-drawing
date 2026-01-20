//
//  DrawingSession.swift
//  AIDrawing
//
//  Represents a complete drawing session with all strokes
//

import Foundation
import PencilKit

/// Container for a drawing session
struct DrawingSession: Identifiable, Codable {
    let id: UUID
    let createdAt: Date
    var lastModified: Date
    var strokes: [Stroke]

    init() {
        self.id = UUID()
        self.createdAt = Date()
        self.lastModified = Date()
        self.strokes = []
    }

    init(id: UUID, createdAt: Date, lastModified: Date, strokes: [Stroke]) {
        self.id = id
        self.createdAt = createdAt
        self.lastModified = lastModified
        self.strokes = strokes
    }

    /// Add a stroke to the session
    mutating func addStroke(_ stroke: Stroke) {
        strokes.append(stroke)
        lastModified = Date()
    }

    /// Remove a stroke by ID
    mutating func removeStroke(id: UUID) {
        strokes.removeAll { $0.id == id }
        lastModified = Date()
    }

    /// Get recent strokes within a time window (seconds)
    func recentStrokes(window: TimeInterval) -> [Stroke] {
        let cutoff = Date().addingTimeInterval(-window)
        return strokes.filter { $0.timestamp > cutoff }
    }

    /// Get user strokes only
    var userStrokes: [Stroke] {
        return strokes.filter { $0.source == .user }
    }

    /// Get AI strokes only
    var aiStrokes: [Stroke] {
        return strokes.filter { $0.source == .ai }
    }

    /// Get visible strokes only
    var visibleStrokes: [Stroke] {
        return strokes.filter { $0.isVisible }
    }

    /// Convert to PKDrawing for rendering
    func toPKDrawing() -> PKDrawing {
        var drawing = PKDrawing()
        for stroke in visibleStrokes {
            if let pkStroke = stroke.toPKStroke() {
                drawing.strokes.append(pkStroke)
            }
        }
        return drawing
    }

    /// Calculate overall density (strokes per square point)
    func calculateDensity() -> Double {
        guard !strokes.isEmpty else { return 0.0 }

        // Find overall bounding box
        let allBounds = strokes.map { $0.boundingBox }
        guard let first = allBounds.first else { return 0.0 }

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

        let area = (maxX - minX) * (maxY - minY)
        guard area > 0 else { return 0.0 }

        return Double(strokes.count) / Double(area)
    }
}
