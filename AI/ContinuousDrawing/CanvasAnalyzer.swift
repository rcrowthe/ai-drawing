//
//  CanvasAnalyzer.swift
//  AIDrawing
//
//  Perceives and analyzes entire canvas state
//

import Foundation
import CoreGraphics

/// Snapshot of canvas state at a moment in time
struct CanvasSnapshot {
    let allStrokes: [Stroke]
    let userStrokes: [Stroke]
    let aiStrokes: [Stroke]
    let timestamp: Date

    init(session: DrawingSession) {
        self.allStrokes = session.visibleStrokes
        self.userStrokes = session.userStrokes
        self.aiStrokes = session.aiStrokes
        self.timestamp = Date()
    }
}

/// Analyzed perception of canvas state
struct CanvasPerception {
    let allStrokes: [Stroke]
    let recentUserActivity: Bool  // User drew in last 2 seconds
    let recentAIActivity: Bool    // AI drew in last 1 second
    let localDensity: Double      // 0-1, density in active area
    let globalDensity: Double     // 0-1, overall canvas density
    let interestingStrokes: [Stroke]  // Strokes worth responding to

    /// Find the most interesting stroke to respond to
    func findInterestingStroke() -> Stroke? {
        // Helper to check if stroke has meaningful content
        func isValidStroke(_ stroke: Stroke) -> Bool {
            // Must have non-zero length (at least 5 points of distance)
            return stroke.length > 5.0
        }

        // Priority 1: Recent user strokes (last 2 seconds)
        let recentUser = allStrokes
            .filter { $0.source == .user && Date().timeIntervalSince($0.timestamp) < 2.0 }
            .filter(isValidStroke)
            .sorted { $0.timestamp > $1.timestamp }

        if let newest = recentUser.first {
            print("🔍 CanvasPerception: Found recent user stroke")
            return newest
        }

        // Priority 2: Isolated strokes (low local density, potential for echo)
        let isolated = allStrokes
            .filter(isValidStroke)
            .filter { stroke in
                let nearby = allStrokes.filter { other in
                    stroke.id != other.id &&
                    stroke.boundingBox.center.distance(to: other.boundingBox.center) < 100
                }
                return nearby.count < 3
            }

        if let target = isolated.randomElement() {
            print("🔍 CanvasPerception: Found isolated stroke (\(target.source))")
            return target
        }

        // Priority 3: Recent AI strokes (respond to own work)
        let recentAI = allStrokes
            .filter { $0.source == .ai && Date().timeIntervalSince($0.timestamp) < 3.0 }
            .filter(isValidStroke)

        if let target = recentAI.randomElement() {
            print("🔍 CanvasPerception: Found recent AI stroke (self-response)")
            return target
        }

        // Priority 4: Random existing stroke
        let validStrokes = allStrokes.filter(isValidStroke)
        if let target = validStrokes.randomElement() {
            print("🔍 CanvasPerception: Found random stroke (\(target.source))")
            return target
        }

        return nil
    }

    /// Find the most recent user stroke to respond to (for continuous mode)
    func findRecentUserStroke() -> Stroke? {
        // In continuous mode, find the most recent user stroke regardless of age
        // because when user is actively drawing (finger down), we want to respond to
        // whatever they're working on, even if they paused before continuing
        let userStrokes = allStrokes
            .filter { $0.source == .user }
            .filter { stroke in
                // Must have meaningful content (at least 5 pixels of length)
                return stroke.length > 5.0
            }
            .sorted { $0.timestamp > $1.timestamp }

        if let newest = userStrokes.first {
            print("🔍 findRecentUserStroke: Found user stroke id=\(newest.id.uuidString.prefix(8)), age=\(String(format: "%.2f", Date().timeIntervalSince(newest.timestamp)))s")
            return newest
        }

        print("🔍 findRecentUserStroke: NO user strokes found (or all too short)")
        return nil
    }
}

/// Analyzes canvas snapshots to produce perceptions
class CanvasAnalyzer {
    private let spatialMap = SpatialDensityMap()

    func analyze(_ snapshot: CanvasSnapshot) -> CanvasPerception {
        let now = Date()

        // Detect recent activity
        let recentUser = snapshot.allStrokes.contains {
            $0.source == .user && now.timeIntervalSince($0.timestamp) < 2.0
        }

        let recentAI = snapshot.allStrokes.contains {
            $0.source == .ai && now.timeIntervalSince($0.timestamp) < 1.0
        }

        // Calculate spatial density
        let (localDensity, globalDensity) = spatialMap.calculate(strokes: snapshot.allStrokes)

        // Find interesting strokes
        let interesting = identifyInterestingStrokes(snapshot.allStrokes)

        print("🔍 CanvasAnalyzer: user_activity=\(recentUser), ai_activity=\(recentAI), local_density=\(String(format: "%.2f", localDensity)), global_density=\(String(format: "%.2f", globalDensity)), interesting=\(interesting.count)")

        return CanvasPerception(
            allStrokes: snapshot.allStrokes,
            recentUserActivity: recentUser,
            recentAIActivity: recentAI,
            localDensity: localDensity,
            globalDensity: globalDensity,
            interestingStrokes: interesting
        )
    }

    private func identifyInterestingStrokes(_ strokes: [Stroke]) -> [Stroke] {
        // Strokes that are good candidates for AI response
        return strokes.filter { stroke in
            // Recent strokes (last 3 seconds)
            if Date().timeIntervalSince(stroke.timestamp) < 3.0 {
                return true
            }

            // Isolated strokes (few nearby neighbors)
            let nearby = strokes.filter { other in
                other.id != stroke.id &&
                stroke.boundingBox.center.distance(to: other.boundingBox.center) < 150
            }

            return nearby.count < 5
        }
    }
}
