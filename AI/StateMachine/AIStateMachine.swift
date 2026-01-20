//
//  AIStateMachine.swift
//  AIDrawing
//
//  Central state coordinator for AI
//

import Foundation
import Combine
import CoreGraphics

class AIStateMachine: ObservableObject {
    @Published private(set) var attentionMode: AttentionMode = .wander
    @Published private(set) var alignmentMode: AlignmentMode = .pro
    @Published private(set) var activityState: ActivityState = .idle

    private var recentStrokes: [Stroke] = []
    private var lastUserStrokeTime: Date?
    private var recentAIMoves: [AIMoveType] = []

    private let configuration: AIConfiguration
    private var timer: Timer?

    // Thresholds for mode detection
    private let wanderSpreadThreshold: Double = 200.0  // Points
    private let focusOverlapThreshold: Double = 0.7    // Ratio
    private let stagnationThreshold: Double = 0.3      // Variety score

    init(configuration: AIConfiguration = AIConfiguration()) {
        self.configuration = configuration
        startStateTick()
    }

    // MARK: - State Updates

    func processUserStroke(_ stroke: Stroke) {
        // Add to recent strokes
        recentStrokes.append(stroke)
        lastUserStrokeTime = Date()

        // Keep only last 20 strokes for analysis
        if recentStrokes.count > 20 {
            recentStrokes.removeFirst()
        }

        // Update modes based on stroke analysis
        updateAttentionMode()
        updateAlignmentMode()

        // Transition to active state
        activityState = .activeWithUser
    }

    func recordAIMove(_ moveType: AIMoveType) {
        recentAIMoves.append(moveType)

        // Keep only last 10 moves
        if recentAIMoves.count > 10 {
            recentAIMoves.removeFirst()
        }
    }

    // MARK: - State Tick (60fps)

    private func startStateTick() {
        // Run at 60fps to check for state transitions
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        guard let lastStrokeTime = lastUserStrokeTime else {
            activityState = .idle
            return
        }

        let timeSinceLastStroke = Date().timeIntervalSince(lastStrokeTime)

        switch activityState {
        case .activeWithUser:
            // Transition to responding after brief pause
            if timeSinceLastStroke > 0.1 {  // 100ms threshold
                activityState = .responding
            }

        case .responding:
            // Transition to idle after timeout
            if timeSinceLastStroke > configuration.idleTimeout {
                activityState = .idle
            }

        case .idle:
            // Check if autonomous mode should activate
            if configuration.autonomousModeEnabled {
                // In autonomous mode, AI can draw even when idle
                // For now, stay idle until autonomous features are implemented
            }
        }
    }

    // MARK: - Attention Mode Detection

    private func updateAttentionMode() {
        guard recentStrokes.count >= 3 else {
            attentionMode = .wander
            return
        }

        // Calculate spatial spread
        let centroids = recentStrokes.map { $0.boundingBox.center }
        let spread = calculateSpread(centroids)

        // Calculate velocity variance
        let velocities = recentStrokes.map { $0.avgVelocity }
        let velocityVariance = calculateVariance(velocities)

        // Calculate overlap density (focus indicator)
        let overlapDensity = calculateOverlapDensity(recentStrokes)

        // Decision logic
        if spread > wanderSpreadThreshold || velocityVariance > 0.5 {
            attentionMode = .wander
        } else if overlapDensity > focusOverlapThreshold {
            attentionMode = .focus
        } else {
            // Default to wander
            attentionMode = .wander
        }
    }

    // MARK: - Alignment Mode Selection

    private func updateAlignmentMode() {
        // Check for stagnation in AI moves
        let moveVariety = calculateMoveVariety(recentAIMoves)

        if moveVariety < stagnationThreshold {
            // Too consistent - switch to anti to add variety
            alignmentMode = .anti
            return
        }

        // Use configuration bias
        let biasRoll = Double.random(in: 0...1)
        if biasRoll < configuration.alignmentBias {
            alignmentMode = .pro
        } else {
            alignmentMode = .anti
        }
    }

    // MARK: - Analysis Helpers

    private func calculateSpread(_ points: [CGPoint]) -> Double {
        guard points.count > 1 else { return 0.0 }

        // Calculate standard deviation of points
        let avgX = points.map { $0.x }.reduce(0, +) / CGFloat(points.count)
        let avgY = points.map { $0.y }.reduce(0, +) / CGFloat(points.count)

        let variances = points.map { point in
            let dx = point.x - avgX
            let dy = point.y - avgY
            return dx * dx + dy * dy
        }

        let avgVariance = variances.reduce(0, +) / CGFloat(points.count)
        return sqrt(Double(avgVariance))
    }

    private func calculateVariance(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0.0 }

        let avg = values.reduce(0, +) / Double(values.count)
        let squaredDiffs = values.map { pow($0 - avg, 2) }
        return squaredDiffs.reduce(0, +) / Double(values.count)
    }

    private func calculateOverlapDensity(_ strokes: [Stroke]) -> Double {
        guard strokes.count >= 2 else { return 0.0 }

        var overlapCount = 0
        let totalPairs = strokes.count * (strokes.count - 1) / 2

        for i in 0..<strokes.count {
            for j in (i+1)..<strokes.count {
                if strokes[i].boundingBox.intersects(strokes[j].boundingBox) {
                    overlapCount += 1
                }
            }
        }

        return Double(overlapCount) / Double(totalPairs)
    }

    private func calculateMoveVariety(_ moves: [AIMoveType]) -> Double {
        guard !moves.isEmpty else { return 1.0 }

        // Count unique move types
        let uniqueMoves = Set(moves)
        return Double(uniqueMoves.count) / Double(moves.count)
    }

    // MARK: - State Access

    func getCurrentState() -> AIState {
        return AIState(
            attentionMode: attentionMode,
            alignmentMode: alignmentMode,
            activityState: activityState,
            lastUserStrokeTime: lastUserStrokeTime,
            autonomousModeEnabled: configuration.autonomousModeEnabled
        )
    }

    // MARK: - Cleanup

    deinit {
        timer?.invalidate()
    }
}
