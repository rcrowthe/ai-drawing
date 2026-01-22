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

    // All 7 move generators
    private let echoGenerator: EchoGenerator
    private let textureGenerator: TextureGenerator
    private let structuralGenerator: StructuralGenerator
    private let contrastGenerator: ContrastGenerator
    private let predictiveGenerator: PredictiveGenerator
    private let surpriseGenerator: SurpriseGenerator
    private let ivyGenerator: IvyGenerator

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
        self.ivyGenerator = IvyGenerator()
    }

    /// Decide if AI should respond to a user stroke
    func shouldRespond(
        to userStroke: Stroke,
        session: DrawingSession
    ) -> Bool {
        print("🤖 shouldRespond: checking...")

        // Update state machine with user stroke
        stateMachine.processUserStroke(userStroke)

        let state = stateMachine.getCurrentState()
        print("🤖 Activity state: \(state.activityState)")
        print("🤖 Attention mode: \(state.attentionMode)")
        print("🤖 Alignment mode: \(state.alignmentMode)")

        // Only respond during active or responding states (NOT idle)
        guard state.activityState == .activeWithUser || state.activityState == .responding else {
            print("🤖 Final decision: false (idle state - user inactive for >3s)")
            return false
        }

        // AI ALWAYS responds to ANY mark unless user is idle for 3+ seconds
        // The assertiveness parameter is now just a global on/off switch
        let shouldRespond = configuration.assertiveness > 0.5 // Essentially always true (set to 1.0)
        print("🤖 Final decision: \(shouldRespond) (assertiveness=\(configuration.assertiveness))")
        return shouldRespond
    }

    /// Generate an AI response to a user stroke
    func generateResponse(
        userStroke: Stroke,
        session: DrawingSession
    ) -> AIMove? {
        print("🤖 generateResponse: starting")

        let aiState = stateMachine.getCurrentState()

        // HEAVILY WEIGHT THE LATEST STROKE
        // Get recent strokes but the current userStroke is the PRIMARY focus
        let recentStrokes = session.recentStrokes(window: 5.0) // Shortened window from 10s to 5s

        // Create canvas state
        let canvasState = CanvasState(
            session: session,
            aiState: aiState
        )

        // LENS-DRIVEN MODE: Aggregate lens analyses
        // The lenses will analyze the userStroke (most recent) most heavily
        print("🤖 Running lens aggregation (focused on latest stroke)...")
        let aggregated = lensAggregator.aggregate(
            userStroke: userStroke,
            recentStrokes: recentStrokes,
            canvasState: canvasState,
            configuration: configuration
        )

        // Filter to only enabled generators
        print("🤖 Filtering generators - configuration states:")
        print("🤖   echoEnabled: \(configuration.echoEnabled)")
        print("🤖   textureEnabled: \(configuration.textureEnabled)")
        print("🤖   structuralEnabled: \(configuration.structuralEnabled)")
        print("🤖   contrastEnabled: \(configuration.contrastEnabled)")
        print("🤖   predictiveEnabled: \(configuration.predictiveEnabled)")
        print("🤖   surpriseEnabled: \(configuration.surpriseEnabled)")
        print("🤖   ivyEnabled: \(configuration.ivyEnabled)")

        let enabledSuggestions = aggregated.suggestedMoves.filter { moveType, _ in
            switch moveType {
            case .echo: return configuration.echoEnabled
            case .texture: return configuration.textureEnabled
            case .structural: return configuration.structuralEnabled
            case .contrast: return configuration.contrastEnabled
            case .predictive: return configuration.predictiveEnabled
            case .surprise: return configuration.surpriseEnabled
            case .ivy: return configuration.ivyEnabled
            }
        }

        print("🤖 After filtering: \(enabledSuggestions.count) generators enabled")

        guard !enabledSuggestions.isEmpty else {
            print("🤖 ERROR: All suggested generators disabled!")
            return nil
        }

        // Use MoveSelector for weighted selection with alignment bias
        let selectedMoveType = moveSelector.select(
            from: enabledSuggestions,
            state: aiState,
            configuration: configuration
        )
        print("🤖 LENS-DRIVEN selection: \(selectedMoveType)")

        // Generate move using appropriate generator
        // The generator will receive userStroke as PRIMARY input
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

        // Record the move in state machine for variety tracking
        stateMachine.recordAIMove(selectedMoveType)

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
                state: aiState,
                configuration: configuration
            )

        case .texture:
            return textureGenerator.generate(
                userStroke: userStroke,
                recentStrokes: recentStrokes,
                canvasState: canvasState,
                state: aiState,
                configuration: configuration
            )

        case .structural:
            return structuralGenerator.generate(
                userStroke: userStroke,
                recentStrokes: recentStrokes,
                canvasState: canvasState,
                state: aiState,
                configuration: configuration
            )

        case .contrast:
            return contrastGenerator.generate(
                userStroke: userStroke,
                recentStrokes: recentStrokes,
                canvasState: canvasState,
                state: aiState,
                configuration: configuration
            )

        case .predictive:
            return predictiveGenerator.generate(
                userStroke: userStroke,
                recentStrokes: recentStrokes,
                canvasState: canvasState,
                state: aiState,
                configuration: configuration
            )

        case .surprise:
            return surpriseGenerator.generate(
                userStroke: userStroke,
                recentStrokes: recentStrokes,
                canvasState: canvasState,
                state: aiState,
                configuration: configuration
            )

        case .ivy:
            return ivyGenerator.generate(
                userStroke: userStroke,
                recentStrokes: recentStrokes,
                canvasState: canvasState,
                state: aiState,
                configuration: configuration
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
}
