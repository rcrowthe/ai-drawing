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
        return validateCanvasSafety(move, canvasState) &&
               validateTemporalSafety(move, canvasState) &&
               validateControlSafety(move, canvasState)
    }

    // MARK: - Canvas Safety

    private func validateCanvasSafety(_ move: AIMove, _ state: CanvasState) -> Bool {
        // 1. Check canvas density - prevent overwhelming marks
        let currentDensity = state.session.calculateDensity()
        if currentDensity > maxDensityThreshold {
            return false  // Canvas too dense
        }

        // 2. Check move size - prevent obstructing user work
        let moveBounds = move.estimatedBoundingBox
        if moveBounds.area > maxMoveSizeThreshold {
            return false  // Move too large
        }

        // 3. Check overlap with recent user strokes
        let recentUserStrokes = state.session.recentStrokes(window: 2.0)
            .filter { $0.source == .user }

        if !recentUserStrokes.isEmpty {
            let overlapRatio = calculateOverlap(moveBounds, recentUserStrokes)
            if overlapRatio > maxOverlapThreshold {
                return false  // Too much overlap
            }
        }

        return true
    }

    // MARK: - Temporal Safety

    private func validateTemporalSafety(_ move: AIMove, _ state: CanvasState) -> Bool {
        // AI acts only during/after user action (unless autonomous mode)
        guard let lastUserStroke = state.aiState.lastUserStrokeTime else {
            return false
        }

        let timeSinceUser = Date().timeIntervalSince(lastUserStroke)

        switch state.aiState.activityState {
        case .activeWithUser:
            return true  // OK to draw simultaneously

        case .responding:
            return timeSinceUser < responseWindowThreshold  // Within response window

        case .idle:
            return state.aiState.autonomousModeEnabled  // Only if autonomous
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
