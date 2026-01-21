//
//  ContinuousDrawingEngine.swift
//  AIDrawing
//
//  Orchestrates continuous AI drawing loop with full canvas perception
//

import Foundation
import PencilKit
import Combine
import QuartzCore

#if canImport(UIKit)
import UIKit
#endif

class ContinuousDrawingEngine: ObservableObject {
    @Published var isActive: Bool = false
    @Published var aiDrawRate: Double = 2.0  // strokes per second target

    private var displayLink: CADisplayLink?
    private weak var viewModel: DrawingViewModel?
    private var configuration: AIConfiguration

    // Timing
    private var lastAIStrokeTime: Date = Date()
    private var targetInterval: TimeInterval { 1.0 / aiDrawRate }

    // Canvas perception
    private var canvasAnalyzer: CanvasAnalyzer
    private var spatialMap: SpatialDensityMap

    // Animation tracking
    private var isCurrentlyAnimating: Bool = false

    // In-progress stroke tracking (for streaming)
    private var accumulatedInProgressPoints: [StrokePoint] = []
    private var lastInProgressUpdateTime: Date = Date()

    init(configuration: AIConfiguration) {
        self.configuration = configuration
        self.canvasAnalyzer = CanvasAnalyzer()
        self.spatialMap = SpatialDensityMap()
    }

    func startContinuousDrawing(viewModel: DrawingViewModel) {
        self.viewModel = viewModel
        isActive = true
        lastAIStrokeTime = Date()

        print("🎨 ContinuousDrawingEngine: Starting continuous mode")

        // Use CADisplayLink for smooth 60fps perception
        displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink?.add(to: .main, forMode: .common)
    }

    @objc private func tick() {
        guard isActive, let viewModel = viewModel else { return }

        // Check if user is actively drawing
        guard viewModel.isUserDrawing else { return }

        // Check rate limiting
        let timeSinceLastAI = Date().timeIntervalSince(lastAIStrokeTime)
        guard timeSinceLastAI >= targetInterval else { return }

        // Get all completed strokes from session (user + AI)
        let allStrokes = viewModel.currentSession.strokes

        // Find most recent user stroke to respond to
        let recentUserStrokes = allStrokes
            .filter { $0.source == .user }
            .sorted { $0.timestamp > $1.timestamp }

        guard let targetStroke = recentUserStrokes.first else {
            return // No user strokes to respond to
        }

        // Only respond to recent strokes (within last 5 seconds)
        let strokeAge = Date().timeIntervalSince(targetStroke.timestamp)
        guard strokeAge < 5.0 else {
            return // Stroke too old
        }

        print("🎨 ContinuousEngine: ✅ WILL DRAW while user drawing (responding to stroke age=\(String(format: "%.2f", strokeAge))s)")

        // Generate AI response
        if let aiMove = generateResponseToInProgressStroke(
            inProgressStroke: targetStroke,
            allSessionStrokes: allStrokes,
            viewModel: viewModel
        ) {
            lastAIStrokeTime = Date()
            isCurrentlyAnimating = true

            viewModel.executeAIMoveContinuous(aiMove) { [weak self] in
                self?.isCurrentlyAnimating = false
            }
        }
    }

    private func decideIfShouldDraw(
        perception: CanvasPerception,
        timeSinceLastAI: TimeInterval,
        isUserCurrentlyDrawing: Bool
    ) -> Bool {
        print("🔍 DecideIfShouldDraw: isUserCurrentlyDrawing=\(isUserCurrentlyDrawing), timeSinceLastAI=\(String(format: "%.2f", timeSinceLastAI))s")

        // Rate limiting: don't exceed target draw rate
        if timeSinceLastAI < targetInterval {
            print("🚫 ContinuousEngine: Rate limited (timeSinceLastAI=\(String(format: "%.2f", timeSinceLastAI))s < target=\(String(format: "%.2f", targetInterval))s)")
            return false
        }

        // CRITICAL FIX: Check if user is CURRENTLY drawing (finger on screen)
        // This is the real-time state, not based on stroke timestamps
        if !isUserCurrentlyDrawing {
            print("🚫 ContinuousEngine: User not currently drawing")
            return false
        }

        // Find the most recent user stroke (to respond to)
        let recentUserStrokes = perception.allStrokes
            .filter { $0.source == .user }
            .sorted { $0.timestamp > $1.timestamp }

        guard let latestUserStroke = recentUserStrokes.first else {
            print("🚫 ContinuousEngine: No user strokes found")
            return false // No user strokes at all
        }

        let timeSinceUserStroke = Date().timeIntervalSince(latestUserStroke.timestamp)
        print("⏱️  ContinuousEngine: timeSinceUserStroke=\(String(format: "%.2f", timeSinceUserStroke))s, startDelay=\(String(format: "%.2f", configuration.startDelay))s")

        // NEW: If the most recent stroke is OLD (>3 seconds), user is starting fresh
        // Wait for them to complete at least one NEW stroke before AI responds
        if timeSinceUserStroke > 3.0 {
            print("🚫 ContinuousEngine: Most recent stroke too old (\(String(format: "%.2f", timeSinceUserStroke))s) - waiting for user to complete a fresh stroke")
            return false
        }

        // Only start drawing after startDelay has passed since user's last completed stroke
        // This ensures we don't start TOO immediately
        if timeSinceUserStroke < configuration.startDelay {
            print("🚫 ContinuousEngine: Too soon after last stroke (timeSinceUserStroke=\(String(format: "%.2f", timeSinceUserStroke))s < startDelay=\(String(format: "%.2f", configuration.startDelay))s)")
            return false
        }

        // If canvas is empty, wait for user to make first mark
        if perception.allStrokes.isEmpty {
            print("🚫 ContinuousEngine: Canvas is empty")
            return false
        }

        // In continuous mode, if all conditions are met, just draw
        // User is actively drawing (finger down) and has a recent stroke (within 3 seconds)
        print("✅ ContinuousEngine: ALL CHECKS PASSED - WILL DRAW!")
        return true
    }

    private func generateResponseToInProgressStroke(
        inProgressStroke: Stroke,
        allSessionStrokes: [Stroke],
        viewModel: DrawingViewModel
    ) -> AIMove? {
        print("🎨 generateResponseToInProgressStroke: Responding to IN-PROGRESS stroke id=\(inProgressStroke.id.uuidString.prefix(8))")

        // Create AIState suitable for continuous mode
        var aiState = viewModel.aiDecisionEngine.getCurrentState()
        aiState.autonomousModeEnabled = true

        // Combine completed session strokes with the in-progress stroke
        // This gives AI full context of what's on canvas
        let allStrokes = allSessionStrokes + [inProgressStroke]

        // Generate move responding to the in-progress stroke
        let result = viewModel.aiDecisionEngine.generateResponseToAnyStroke(
            targetStroke: inProgressStroke,
            allStrokes: allStrokes,
            aiState: aiState
        )

        if result == nil {
            print("❌ generateResponseToInProgressStroke: aiDecisionEngine returned NIL")
        } else {
            print("✅ generateResponseToInProgressStroke: Successfully generated \(result!.moveType) move")
        }

        return result
    }

    private func generateContextualStroke(
        perception: CanvasPerception,
        viewModel: DrawingViewModel
    ) -> AIMove? {
        // Find the most recent user stroke - this is our PRIMARY target
        guard let targetStroke = perception.findRecentUserStroke() else {
            print("❌ generateContextualStroke: NO recent user stroke found by perception")
            return nil
        }

        print("🎨 ContinuousDrawingEngine: Generating response to user stroke id=\(targetStroke.id.uuidString.prefix(8))")

        // Create AIState suitable for continuous mode
        var aiState = viewModel.aiDecisionEngine.getCurrentState()
        aiState.autonomousModeEnabled = true  // Enable autonomous mode for continuous drawing

        // Generate move responding to user stroke
        // The allStrokes parameter includes ALL canvas strokes (user + AI, past + present)
        // This allows generators to be aware of and integrate with/avoid existing strokes
        let result = viewModel.aiDecisionEngine.generateResponseToAnyStroke(
            targetStroke: targetStroke,
            allStrokes: perception.allStrokes,  // Pass ALL strokes for spatial awareness
            aiState: aiState
        )

        if result == nil {
            print("❌ generateContextualStroke: aiDecisionEngine.generateResponseToAnyStroke returned NIL")
        } else {
            print("✅ generateContextualStroke: Successfully generated \(result!.moveType) move")
        }

        return result
    }

    func updateConfiguration(_ newConfig: AIConfiguration) {
        self.configuration = newConfig
    }

    // MARK: - Streaming Integration (Metal Pipeline)

    /// Process delta points from in-progress stroke (called on each touchesMoved batch)
    func processInProgressStroke(deltaPoints: [StrokePoint], viewModel: DrawingViewModel) {
        // Accumulate points
        accumulatedInProgressPoints.append(contentsOf: deltaPoints)
        lastInProgressUpdateTime = Date()

        print("🎨 ContinuousEngine: Accumulated \(accumulatedInProgressPoints.count) in-progress points")

        // Check if we should generate AI response
        let timeSinceLastAI = Date().timeIntervalSince(lastAIStrokeTime)
        guard timeSinceLastAI >= targetInterval else {
            print("🎨 ContinuousEngine: Rate limited (waiting \(String(format: "%.2f", targetInterval - timeSinceLastAI))s)")
            return
        }

        // Only generate if we have enough points (avoid responding to tiny movements)
        guard accumulatedInProgressPoints.count >= 10 else {
            print("🎨 ContinuousEngine: Not enough points yet (\(accumulatedInProgressPoints.count)/10)")
            return
        }

        // Generate AI response based on in-progress stroke trajectory
        if let aiMove = generateResponseToStreamingStroke(
            inProgressPoints: accumulatedInProgressPoints,
            viewModel: viewModel
        ) {
            lastAIStrokeTime = Date()
            isCurrentlyAnimating = true

            viewModel.executeAIMoveContinuous(aiMove) { [weak self] in
                self?.isCurrentlyAnimating = false
            }
        }
    }

    /// Generate AI response based on streaming in-progress stroke points
    private func generateResponseToStreamingStroke(
        inProgressPoints: [StrokePoint],
        viewModel: DrawingViewModel
    ) -> AIMove? {
        print("🎨 generateResponseToStreamingStroke: Responding to \(inProgressPoints.count) in-progress points")

        // Get all completed strokes from session
        let allSessionStrokes = viewModel.currentSession.strokes

        // Convert in-progress points to a temporary Stroke for analysis
        // (We create a minimal PKStroke just for geometry analysis)
        let tempPKStroke = convertPointsToPKStroke(inProgressPoints, viewModel: viewModel)
        let tempStroke = Stroke(pkStroke: tempPKStroke, source: .user)

        print("🎨 Temp stroke created: length=\(tempStroke.length), points=\(inProgressPoints.count)")

        // Create AIState for continuous mode
        var aiState = viewModel.aiDecisionEngine.getCurrentState()
        aiState.autonomousModeEnabled = true

        // Generate move responding to the in-progress stroke
        let result = viewModel.aiDecisionEngine.generateResponseToAnyStroke(
            targetStroke: tempStroke,
            allStrokes: allSessionStrokes + [tempStroke],  // Include temp stroke in context
            aiState: aiState
        )

        if result == nil {
            print("❌ generateResponseToStreamingStroke: aiDecisionEngine returned NIL")
        } else {
            print("✅ generateResponseToStreamingStroke: Generated \(result!.moveType) move")
        }

        return result
    }

    /// Convert StrokePoint array to PKStroke for compatibility with existing AI engine
    private func convertPointsToPKStroke(_ points: [StrokePoint], viewModel: DrawingViewModel) -> PKStroke {
        let pkPoints = points.enumerated().map { (index, point) in
            PKStrokePoint(
                location: point.location,
                timeOffset: index == 0 ? 0 : point.timestamp - points[0].timestamp,
                size: CGSize(width: 3.0, height: 3.0),
                opacity: 1.0,
                force: point.force,
                azimuth: point.azimuthAngle,
                altitude: point.altitudeAngle
            )
        }

        let path = PKStrokePath(controlPoints: pkPoints, creationDate: Date())
        let ink = PKInk(.pen, color: viewModel.metalDrawingColor)
        return PKStroke(ink: ink, path: path)
    }

    func stop() {
        print("🎨 ContinuousDrawingEngine: Stopping continuous mode")
        isActive = false
        displayLink?.invalidate()
        displayLink = nil

        // Clear in-progress points
        accumulatedInProgressPoints.removeAll()
    }

    deinit {
        stop()
    }
}
