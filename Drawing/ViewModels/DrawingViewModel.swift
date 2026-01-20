//
//  DrawingViewModel.swift
//  AIDrawing
//
//  Main view model for the drawing screen
//

import Foundation
import PencilKit
import Combine

class DrawingViewModel: ObservableObject {
    // Published state
    @Published var currentSession: DrawingSession
    @Published var pkDrawing: PKDrawing
    @Published var selectedTool: PKTool = PKInkingTool(.pen, color: GeneratorColors.userPenColor, width: 5)
    @Published var canUndo: Bool = false
    @Published var canRedo: Bool = false
    @Published var aiState: AIState = AIState()
    @Published var aiConfiguration: AIConfiguration
    @Published var showAIStrokes: Bool = true  // Phase 8: AI visibility toggle

    // Track current tool type for color updates
    private var currentToolType: ToolType = .pen

    private enum ToolType {
        case pen, marker, eraser
    }

    // Services
    private let historyManager = HistoryManager()
    private let persistenceService = PersistenceService.shared
    private var aiDecisionEngine: AIDecisionEngine

    // Learning system (Phase 6)
    private let behaviorTracker = BehaviorTracker()
    private let motifDetector = MotifDetector()
    private let profileAdapter = ProfileAdapter()

    private var cancellables = Set<AnyCancellable>()
    private var lastAIMoveType: AIMoveType?  // Track last AI move for reinforcement
    private var isAddingAIStroke = false  // Prevent feedback loop

    init() {
        print("🔧 DrawingViewModel: init started")
        // Load or create AI configuration
        let loadedConfig = PersistenceService.shared.loadConfiguration() ?? AIConfiguration()
        self.aiConfiguration = loadedConfig
        print("🔧 AI Configuration loaded")

        // Try to load existing session or create new one
        if let sessionID = PersistenceService.shared.loadCurrentSessionID(),
           let session = try? PersistenceService.shared.loadSession(id: sessionID) {
            self.currentSession = session
            self.pkDrawing = session.toPKDrawing()
            print("🔧 Loaded existing session with \(session.strokes.count) strokes")
        } else {
            self.currentSession = DrawingSession()
            self.pkDrawing = PKDrawing()
            print("🔧 Created new drawing session")
        }

        // Initialize AI decision engine with configuration
        self.aiDecisionEngine = AIDecisionEngine(configuration: loadedConfig)
        print("🔧 AI Decision Engine initialized")

        setupBindings()
        print("🔧 DrawingViewModel: init complete")
    }

    private func setupBindings() {
        // Bind history manager state on next run loop to avoid view update conflicts
        DispatchQueue.main.async {
            self.historyManager.$canUndo
                .assign(to: &self.$canUndo)

            self.historyManager.$canRedo
                .assign(to: &self.$canRedo)
        }

        // Observe configuration changes and propagate to AIDecisionEngine
        $aiConfiguration
            .dropFirst() // Skip initial value
            .sink { [weak self] newConfig in
                self?.aiDecisionEngine.updateConfiguration(newConfig)
                self?.persistenceService.saveConfiguration(newConfig)
                print("🔧 Configuration auto-updated from settings")
            }
            .store(in: &cancellables)
    }

    // MARK: - Stroke Handling

    func handleStrokeAdded(_ pkStroke: PKStroke) {
        print("📝 handleStrokeAdded called")

        // Skip if we're currently adding an AI stroke (prevent feedback loop)
        if isAddingAIStroke {
            print("📝 Skipping - AI stroke being added programmatically")
            return
        }

        // Create stroke model
        let stroke = Stroke(pkStroke: pkStroke, source: .user)
        print("📝 Stroke created: \(stroke.id)")

        // Add to session
        currentSession.addStroke(stroke)
        print("📝 Stroke added to session. Total strokes: \(currentSession.strokes.count)")

        // Record in history
        historyManager.record(.userStroke(stroke))

        // Track behavior for learning (Phase 6)
        behaviorTracker.recordUserStroke(stroke, session: currentSession)

        // Save session
        saveSession()

        // AI Response (Phase 2)
        print("📝 Requesting AI response")
        generateAIResponse(for: stroke)
    }

    private func generateAIResponse(for userStroke: Stroke) {
        print("🤖 generateAIResponse called")

        // Run AI decision-making on background queue for performance
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // Check if AI should respond
            guard self.aiDecisionEngine.shouldRespond(
                to: userStroke,
                session: self.currentSession
            ) else {
                print("🤖 AI decided NOT to respond")
                return
            }

            print("🤖 AI IS responding - generating move")
            // Generate AI move
            guard let aiMove = self.aiDecisionEngine.generateResponse(
                userStroke: userStroke,
                session: self.currentSession
            ) else {
                print("🤖 ERROR: generateResponse returned nil")
                return
            }

            print("🤖 AI move generated: \(aiMove.moveType)")

            // Execute AI move on main thread
            DispatchQueue.main.async {
                self.executeAIMove(aiMove)
                self.aiState = self.aiDecisionEngine.getCurrentState()
            }
        }
    }

    private func executeAIMove(_ move: AIMove) {
        print("🤖 executeAIMove: \(move.moveType)")
        // Convert to PKStroke
        let pkStroke = move.toPKStroke()

        // Set flag to prevent feedback loop
        isAddingAIStroke = true

        // Add to PencilKit drawing - force update
        DispatchQueue.main.async {
            var drawing = self.pkDrawing
            drawing.strokes.append(pkStroke)
            self.pkDrawing = drawing
            print("🤖 AI stroke added to canvas. Total canvas strokes: \(drawing.strokes.count)")
            print("🤖 pkDrawing updated with \(self.pkDrawing.strokes.count) strokes")

            // Reset flag after a short delay to ensure the update completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.isAddingAIStroke = false
            }
        }

        // Create stroke model
        let stroke = Stroke(pkStroke: pkStroke, source: .ai, moveType: move.moveType)

        // Add to session
        currentSession.addStroke(stroke)

        // Record in history
        historyManager.record(.aiStroke(stroke))

        // Track last AI move type for reinforcement (Phase 6)
        lastAIMoveType = move.moveType

        // Record implicit positive reinforcement (move was generated and kept)
        behaviorTracker.recordPositiveReinforcement(for: move.moveType)

        // Save session
        saveSession()
    }

    func handleStrokeRemoved(_ pkStroke: PKStroke) {
        // Handle stroke removal (typically from undo)
        // Implementation depends on how we track removals
    }

    // MARK: - Undo/Redo

    func undo() {
        guard let action = historyManager.undo() else { return }

        switch action {
        case .userStroke(let stroke), .aiStroke(let stroke):
            // Track negative reinforcement if undoing AI stroke (Phase 6)
            if stroke.source == .ai, let moveType = stroke.moveType {
                behaviorTracker.recordNegativeReinforcement(for: moveType)
            }

            // Remove stroke from session
            currentSession.removeStroke(id: stroke.id)

            // Update PKDrawing
            pkDrawing = currentSession.toPKDrawing()

        case .removeStroke(let id):
            // Re-add stroke (opposite of remove)
            // Would need to track removed strokes for this
            break

        case .toggleVisibility(let id, let visible):
            // Toggle back
            if let index = currentSession.strokes.firstIndex(where: { $0.id == id }) {
                currentSession.strokes[index].isVisible = !visible
                pkDrawing = currentSession.toPKDrawing()
            }
        }

        saveSession()
    }

    func redo() {
        guard let action = historyManager.redo() else { return }

        switch action {
        case .userStroke(let stroke), .aiStroke(let stroke):
            // Re-add stroke
            currentSession.addStroke(stroke)
            pkDrawing = currentSession.toPKDrawing()

        case .removeStroke(let id):
            currentSession.removeStroke(id: id)
            pkDrawing = currentSession.toPKDrawing()

        case .toggleVisibility(let id, let visible):
            if let index = currentSession.strokes.firstIndex(where: { $0.id == id }) {
                currentSession.strokes[index].isVisible = visible
                pkDrawing = currentSession.toPKDrawing()
            }
        }

        saveSession()
    }

    // MARK: - Session Management

    func newSession() {
        // Detect and record motifs from current session before closing (Phase 6)
        let detectedMotifs = motifDetector.detectMotifs(in: currentSession)
        motifDetector.updateProfileWithMotifs(detectedMotifs)

        // Record session statistics (Phase 6)
        behaviorTracker.recordSessionStats(session: currentSession)

        // Create new session
        currentSession = DrawingSession()
        pkDrawing = PKDrawing()
        historyManager.clear()

        persistenceService.saveCurrentSessionID(currentSession.id)
        saveSession()

        // Apply profile-based adaptation to AI configuration (Phase 6)
        applyProfileAdaptation()
    }

    private func saveSession() {
        try? persistenceService.saveSession(currentSession)
    }

    // MARK: - Tool Selection

    func selectPenTool() {
        currentToolType = .pen
        selectedTool = PKInkingTool(.pen, color: GeneratorColors.userPenColor, width: 5)
    }

    func selectMarkerTool() {
        currentToolType = .marker
        selectedTool = PKInkingTool(.marker, color: GeneratorColors.userPenColor, width: 20)
    }

    func selectEraserTool() {
        currentToolType = .eraser
        selectedTool = PKEraserTool(.vector)
    }

    /// Update tool color when color changes in settings
    func updateToolColor() {
        switch currentToolType {
        case .pen:
            selectedTool = PKInkingTool(.pen, color: GeneratorColors.userPenColor, width: 5)
        case .marker:
            selectedTool = PKInkingTool(.marker, color: GeneratorColors.userPenColor, width: 20)
        case .eraser:
            break // Eraser doesn't use color
        }
    }

    // MARK: - AI Visibility Toggle (Phase 8)

    func toggleAIVisibility() {
        showAIStrokes.toggle()
        updatePKDrawingVisibility()
    }

    private func updatePKDrawingVisibility() {
        if showAIStrokes {
            // Show all strokes
            pkDrawing = currentSession.toPKDrawing()
        } else {
            // Show only user strokes
            let userOnlySession = DrawingSession(
                id: currentSession.id,
                createdAt: currentSession.createdAt,
                lastModified: currentSession.lastModified,
                strokes: currentSession.strokes.filter { $0.source == .user }
            )
            pkDrawing = userOnlySession.toPKDrawing()
        }
    }

    // MARK: - Configuration Management

    func updateConfiguration(_ newConfiguration: AIConfiguration) {
        self.aiConfiguration = newConfiguration

        // Update AI decision engine with new configuration
        self.aiDecisionEngine.updateConfiguration(newConfiguration)

        // Save the configuration
        persistenceService.saveConfiguration(newConfiguration)

        print("🔧 Configuration updated in DrawingViewModel")
    }

    /// Apply profile-based adaptations to AI configuration (Phase 6)
    private func applyProfileAdaptation() {
        // Get adapted configuration based on learned profile
        let adaptedConfig = profileAdapter.adaptConfiguration(aiConfiguration)

        // Only update if adaptation made significant changes
        let hasSignificantChanges =
            abs(adaptedConfig.assertiveness - aiConfiguration.assertiveness) > 0.05 ||
            abs(adaptedConfig.surpriseProbability - aiConfiguration.surpriseProbability) > 0.02 ||
            abs(adaptedConfig.alignmentBias - aiConfiguration.alignmentBias) > 0.05

        if hasSignificantChanges {
            updateConfiguration(adaptedConfig)
        }
    }

    // MARK: - Cleanup

    deinit {
        saveSession()
    }
}
