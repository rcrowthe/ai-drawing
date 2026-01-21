//
//  AIDecisionEngine.swift
//  AIDrawing
//
//  Main AI decision orchestrator
//

import Foundation
import Combine

class AIDecisionEngine: ObservableObject {
    private let safetyValidator: SafetyValidator
    private let stateMachine: AIStateMachine
    private let lensAggregator: LensAggregator
    private let moveSelector: MoveSelector

    // All 6 move generators
    private let echoGenerator: EchoGenerator
    private let textureGenerator: TextureGenerator
    private let structuralGenerator: StructuralGenerator
    private let contrastGenerator: ContrastGenerator
    private let predictiveGenerator: PredictiveGenerator
    private let surpriseGenerator: SurpriseGenerator

    private var configuration: AIConfiguration

    init(configuration: AIConfiguration = AIConfiguration()) {
        self.configuration = configuration
        self.safetyValidator = SafetyValidator()
        self.stateMachine = AIStateMachine(configuration: configuration)
        self.lensAggregator = LensAggregator()
        self.moveSelector = MoveSelector()

        // Initialize all generators
        self.echoGenerator = EchoGenerator()
        self.textureGenerator = TextureGenerator()
        self.structuralGenerator = StructuralGenerator()
        self.contrastGenerator = ContrastGenerator()
        self.predictiveGenerator = PredictiveGenerator()
        self.surpriseGenerator = SurpriseGenerator()
    }

    /// Decide if AI should respond to a user stroke
    func shouldRespond(
        to userStroke: Stroke,
        session: DrawingSession
    ) -> Bool {
        print("🤖 shouldRespond: checking...")
        let state = stateMachine.getCurrentState()
        print("🤖 Activity state: \(state.activityState)")

        // FOR NOW: Always respond if assertiveness passes (ignore idle state for testing)
        // TODO: Fix state machine to properly transition from idle to active

        // Check assertiveness
        let roll = Double.random(in: 0...1)
        print("🤖 Assertiveness roll: \(roll) vs \(configuration.assertiveness)")
        let shouldRespond = roll < configuration.assertiveness
        print("🤖 Final decision: \(shouldRespond)")
        return shouldRespond
    }

    /// Generate an AI response to a user stroke
    func generateResponse(
        userStroke: Stroke,
        session: DrawingSession
    ) -> AIMove? {
        print("🤖 generateResponse: starting")

        // SKIP state machine updates for speed - just get basic state
        let aiState = stateMachine.getCurrentState()

        // Create minimal canvas state
        let canvasState = CanvasState(
            session: session,
            aiState: aiState
        )

        // FAST MODE: Randomly pick move type (skip expensive lens aggregation)
        // Filter to only enabled generators
        var enabledMoveTypes: [AIMoveType] = []
        if configuration.echoEnabled { enabledMoveTypes.append(.echo) }
        if configuration.textureEnabled { enabledMoveTypes.append(.texture) }
        if configuration.structuralEnabled { enabledMoveTypes.append(.structural) }
        if configuration.contrastEnabled { enabledMoveTypes.append(.contrast) }
        if configuration.predictiveEnabled { enabledMoveTypes.append(.predictive) }
        if configuration.surpriseEnabled { enabledMoveTypes.append(.surprise) }

        guard !enabledMoveTypes.isEmpty else {
            print("🤖 ERROR: All generators disabled!")
            return nil
        }

        let selectedMoveType = enabledMoveTypes.randomElement()!
        print("🤖 FAST MODE - Random move type: \(selectedMoveType)")

        // Generate move using appropriate generator
        let proposedMove = generateMove(
            type: selectedMoveType,
            userStroke: userStroke,
            session: session,
            aiState: aiState,
            canvasState: canvasState
        )

        guard let move = proposedMove else {
            print("🤖 ERROR: generateMove returned nil for type \(selectedMoveType)")
            return nil
        }
        print("🤖 Move generated successfully")

        return move
    }

    // MARK: - Move Generation

    private func generateMove(
        type: AIMoveType,
        userStroke: Stroke,
        session: DrawingSession,
        aiState: AIState,
        canvasState: CanvasState
    ) -> AIMove? {
        let recentStrokes = session.recentStrokes(window: 10.0)

        switch type {
        case .echo:
            return echoGenerator.generate(
                userStroke: userStroke,
                recentStrokes: recentStrokes,
                canvasState: canvasState,
                state: aiState
            )

        case .texture:
            return textureGenerator.generate(
                userStroke: userStroke,
                recentStrokes: recentStrokes,
                canvasState: canvasState,
                state: aiState
            )

        case .structural:
            return structuralGenerator.generate(
                userStroke: userStroke,
                recentStrokes: recentStrokes,
                canvasState: canvasState,
                state: aiState
            )

        case .contrast:
            return contrastGenerator.generate(
                userStroke: userStroke,
                recentStrokes: recentStrokes,
                canvasState: canvasState,
                state: aiState
            )

        case .predictive:
            return predictiveGenerator.generate(
                userStroke: userStroke,
                recentStrokes: recentStrokes,
                canvasState: canvasState,
                state: aiState
            )

        case .surprise:
            return surpriseGenerator.generate(
                userStroke: userStroke,
                recentStrokes: recentStrokes,
                canvasState: canvasState,
                state: aiState
            )
        }
    }

    /// Get current AI state (for UI display)
    func getCurrentState() -> AIState {
        return stateMachine.getCurrentState()
    }

    /// Update configuration when settings change
    func updateConfiguration(_ newConfiguration: AIConfiguration) {
        self.configuration = newConfiguration
        print("🤖 Configuration updated: assertiveness=\(newConfiguration.assertiveness)")
    }

    // MARK: - Canvas-Aware Generation (Continuous Mode)

    /// Generate response to any stroke (user OR AI) with full canvas context
    /// Used by continuous drawing engine to respond to all canvas content
    func generateResponseToAnyStroke(
        targetStroke: Stroke,
        allStrokes: [Stroke],
        aiState: AIState
    ) -> AIMove? {
        print("🤖 generateResponseToAnyStroke: target=\(targetStroke.source) id=\(targetStroke.id)")

        // Create session from all strokes for context
        let session = DrawingSession(
            id: UUID(),
            createdAt: Date(),
            lastModified: Date(),
            strokes: allStrokes
        )

        let canvasState = CanvasState(session: session, aiState: aiState)

        // Pick enabled generator type
        var enabledTypes: [AIMoveType] = []
        if configuration.echoEnabled { enabledTypes.append(.echo) }
        if configuration.textureEnabled { enabledTypes.append(.texture) }
        if configuration.structuralEnabled { enabledTypes.append(.structural) }
        if configuration.contrastEnabled { enabledTypes.append(.contrast) }
        if configuration.predictiveEnabled { enabledTypes.append(.predictive) }
        if configuration.surpriseEnabled { enabledTypes.append(.surprise) }

        guard !enabledTypes.isEmpty else {
            print("🤖 ERROR: All generators disabled")
            return nil
        }

        let moveType = enabledTypes.randomElement()!
        print("🤖 Selected move type: \(moveType)")

        // Generate move responding to target stroke (can be user OR AI)
        let proposedMove = generateMove(
            type: moveType,
            userStroke: targetStroke,  // Note: can be AI stroke too
            session: session,
            aiState: aiState,
            canvasState: canvasState
        )

        guard let move = proposedMove else {
            print("🤖 ERROR: generateMove returned nil")
            return nil
        }

        // Safety validation
        guard safetyValidator.isValid(move, canvasState: canvasState) else {
            print("🚫 Move REJECTED by safety validator")
            return nil
        }

        print("🤖 Move generated and validated successfully")
        return move
    }
}
