//
//  SafetyValidator.swift
//  AIDrawing
//
//  Validates AI moves against safety constraints
//

import Foundation
import CoreGraphics

class SafetyValidator {
    // Safety thresholds
    private let maxDensityThreshold: Double = 0.01  // Max strokes per square point
    private let maxMoveSizeThreshold: CGFloat = 50000  // Max area for AI move
    private let maxOverlapThreshold: Double = 0.3    // Max overlap with recent user strokes
    private let responseWindowThreshold: TimeInterval = 3.0  // Seconds

    /// Validate AI move against all safety constraints
    func isValid(_ move: AIMove, canvasState: CanvasState) -> Bool {
        let canvasSafe = validateCanvasSafety(move, canvasState)
        let temporalSafe = validateTemporalSafety(move, canvasState)
        let controlSafe = validateControlSafety(move, canvasState)

        print("🛡️ SafetyValidator: canvas=\(canvasSafe), temporal=\(temporalSafe), control=\(controlSafe), autonomous=\(canvasState.aiState.autonomousModeEnabled)")

        return canvasSafe && temporalSafe && controlSafe
    }

    // MARK: - Canvas Safety

    private func validateCanvasSafety(_ move: AIMove, _ state: CanvasState) -> Bool {
        // 1. Check canvas density - prevent overwhelming marks
        let currentDensity = state.session.calculateDensity()
        if currentDensity > maxDensityThreshold {
            print("🛡️ CanvasSafety: ❌ REJECTED (density \(String(format: "%.4f", currentDensity)) > max \(String(format: "%.4f", maxDensityThreshold)))")
            return false  // Canvas too dense
        }

        // 2. Check move size - prevent obstructing user work
        let moveBounds = move.estimatedBoundingBox
        let moveArea = moveBounds.area

        // In autonomous/continuous mode, allow larger strokes (structural moves need more space)
        let effectiveMaxSize = state.aiState.autonomousModeEnabled ? (maxMoveSizeThreshold * 2.5) : maxMoveSizeThreshold

        if moveArea > effectiveMaxSize {
            print("🛡️ CanvasSafety: ❌ REJECTED (move area \(String(format: "%.0f", moveArea)) > max \(String(format: "%.0f", effectiveMaxSize)))")
            return false  // Move too large
        }

        // 3. Check overlap with recent user strokes
        let recentUserStrokes = state.session.recentStrokes(window: 2.0)
            .filter { $0.source == .user }

        if !recentUserStrokes.isEmpty {
            let overlapRatio = calculateOverlap(moveBounds, recentUserStrokes)
            if overlapRatio > maxOverlapThreshold {
                print("🛡️ CanvasSafety: ❌ REJECTED (overlap \(String(format: "%.2f", overlapRatio)) > max \(String(format: "%.2f", maxOverlapThreshold)))")
                return false  // Too much overlap
            }
            print("🛡️ CanvasSafety: ✅ ALLOWED (overlap \(String(format: "%.2f", overlapRatio)) OK)")
        }

        print("🛡️ CanvasSafety: ✅ ALLOWED (all checks passed)")
        return true
    }

    // MARK: - Temporal Safety

    private func validateTemporalSafety(_ move: AIMove, _ state: CanvasState) -> Bool {
        print("🛡️ TemporalSafety: autonomousModeEnabled=\(state.aiState.autonomousModeEnabled)")

        // In autonomous/continuous mode, always allow drawing
        if state.aiState.autonomousModeEnabled {
            print("🛡️ TemporalSafety: ✅ ALLOWED (autonomous mode)")
            return true
        }

        // AI acts only during/after user action (unless autonomous mode)
        guard let lastUserStroke = state.aiState.lastUserStrokeTime else {
            print("🛡️ TemporalSafety: ❌ REJECTED (no last user stroke time)")
            return false
        }

        let timeSinceUser = Date().timeIntervalSince(lastUserStroke)

        switch state.aiState.activityState {
        case .activeWithUser:
            print("🛡️ TemporalSafety: ✅ ALLOWED (active with user)")
            return true  // OK to draw simultaneously

        case .responding:
            let allowed = timeSinceUser < responseWindowThreshold
            print("🛡️ TemporalSafety: \(allowed ? "✅ ALLOWED" : "❌ REJECTED") (responding, time=\(timeSinceUser)s)")
            return allowed  // Within response window

        case .idle:
            print("🛡️ TemporalSafety: ❌ REJECTED (idle, non-autonomous)")
            return false  // In non-autonomous mode, idle means no drawing
        }
    }

    // MARK: - Control Safety

    private func validateControlSafety(_ move: AIMove, _ state: CanvasState) -> Bool {
        // User retains absolute authority - always true
        // This constraint is enforced by undo/visibility toggles, not by blocking AI
        return true
    }

    // MARK: - Helpers

    private func calculateOverlap(
        _ moveBounds: CGRect,
        _ userStrokes: [Stroke]
    ) -> Double {
        guard !userStrokes.isEmpty else { return 0.0 }

        var overlapArea: CGFloat = 0.0

        for stroke in userStrokes {
            let intersection = moveBounds.intersection(stroke.boundingBox)
            if !intersection.isNull {
                overlapArea += intersection.area
            }
        }

        let totalUserArea = userStrokes.reduce(0.0) { $0 + $1.boundingBox.area }
        guard totalUserArea > 0 else { return 0.0 }

        return Double(overlapArea / totalUserArea)
    }
}

/// Canvas state snapshot for validation
struct CanvasState {
    let session: DrawingSession
    let aiState: AIState
}
