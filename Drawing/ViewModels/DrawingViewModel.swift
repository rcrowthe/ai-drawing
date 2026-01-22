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

    // Status indicator tracking
    @Published var userSpeedText: String = "---"
    @Published var aiSpeedText: String = "---"
    @Published var lastMoveType: String? = nil

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

    // CONTINUOUS AI DRAWING TIMER
    private var continuousDrawingTimer: Timer?
    private var lastUserStrokeForContinuation: Stroke?
    private var continuousDrawCount: Int = 0
    private let maxContinuousDraws: Int = 5  // Limit AI to 5 moves after user stops
    private var continuousDrawingStartTime: Date?

    init() {
        print("🔧 DrawingViewModel: init started")
        // Load or create AI configuration
        let loadedConfig = PersistenceService.shared.loadConfiguration() ?? AIConfiguration()
        self.aiConfiguration = loadedConfig
        print("🔧 AI Configuration loaded:")
        print("🔧   echoEnabled: \(loadedConfig.echoEnabled)")
        print("🔧   textureEnabled: \(loadedConfig.textureEnabled)")
        print("🔧   structuralEnabled: \(loadedConfig.structuralEnabled)")
        print("🔧   contrastEnabled: \(loadedConfig.contrastEnabled)")
        print("🔧   predictiveEnabled: \(loadedConfig.predictiveEnabled)")
        print("🔧   surpriseEnabled: \(loadedConfig.surpriseEnabled)")
        print("🔧   ivyEnabled: \(loadedConfig.ivyEnabled)")

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

    func handleUserStartedDrawing() {
        print("📝 User started drawing - stopping continuous AI timer")
        stopContinuousDrawing()
    }

    func handleStrokeAdded(_ pkStroke: PKStroke) {
        print("📝 handleStrokeAdded called")

        // Create stroke model
        let stroke = Stroke(pkStroke: pkStroke, source: .user)
        print("📝 Stroke created: \(stroke.id)")

        // Update user speed indicator
        updateUserSpeed(stroke.avgVelocity)

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

        // START CONTINUOUS AI DRAWING
        // Store the latest stroke for the AI to continue building on
        lastUserStrokeForContinuation = stroke
        startContinuousDrawing()
    }

    private func startContinuousDrawing() {
        // Stop any existing timer
        stopContinuousDrawing()

        // Don't start if duration is 0 (disabled)
        let duration = aiConfiguration.continuousDrawDuration
        if duration <= 0 {
            print("🔁 Continuous drawing disabled (duration = 0)")
            return
        }

        // Reset counter and record start time
        continuousDrawCount = 0
        continuousDrawingStartTime = Date()

        let interval = aiConfiguration.continuousDrawInterval

        print("🔁 Starting continuous AI drawing timer (fires every \(interval)s, max \(duration) seconds)")

        // IMPORTANT: Schedule on main run loop so it fires reliably
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.continuousDrawingTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
                guard let self = self else {
                    timer.invalidate()
                    return
                }

                // Check if max duration has elapsed since last USER stroke
                if let startTime = self.continuousDrawingStartTime {
                    let elapsed = Date().timeIntervalSince(startTime)
                    print(String(format: "🔁 Timer fired - %.1fs elapsed", elapsed))

                    if elapsed >= duration {
                        print("🔁 \(duration) seconds elapsed since last user stroke - stopping")
                        self.stopContinuousDrawing()
                        return
                    }
                }

                // Check if max strokes reached
                if self.continuousDrawCount >= self.aiConfiguration.continuousDrawMaxStrokes {
                    print("🔁 Max strokes (\(self.aiConfiguration.continuousDrawMaxStrokes)) reached - stopping")
                    self.stopContinuousDrawing()
                    return
                }

                // Generate another AI move based on the latest context
                let elapsed = Date().timeIntervalSince(self.continuousDrawingStartTime ?? Date())
                print(String(format: "🔁 Continuous AI draw tick #%d (%.1fs elapsed)", self.continuousDrawCount + 1, elapsed))
                self.generateContinuousAIMove()
                self.continuousDrawCount += 1
            }

            // Make sure timer is added to the run loop
            if let timer = self.continuousDrawingTimer {
                RunLoop.main.add(timer, forMode: .common)
            }
        }
    }

    private func stopContinuousDrawing() {
        continuousDrawingTimer?.invalidate()
        continuousDrawingTimer = nil
        print("🔁 Stopped continuous AI drawing timer")
    }

    private func generateContinuousAIMove() {
        print("🔁 generateContinuousAIMove() called")

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                print("🔁 ERROR: self is nil")
                return
            }

            // Get the MOST RECENT stroke (could be user OR AI) to react to the evolving canvas
            guard let mostRecentStroke = self.currentSession.strokes.last else {
                print("🔁 ERROR: No strokes in session")
                return
            }

            print("🔁 Analyzing most recent stroke: \(mostRecentStroke.id) (source: \(mostRecentStroke.source))")
            print("🔁 Total strokes on canvas: \(self.currentSession.strokes.count)")

            // SKIP shouldRespond check during continuous drawing - we're in a 3-second window
            // The timer already handles the time limit

            // Generate AI move based on CURRENT canvas state (includes all strokes)
            guard let aiMove = self.aiDecisionEngine.generateResponse(
                userStroke: mostRecentStroke,  // Use most recent stroke (AI learns from its own marks too!)
                session: self.currentSession    // Session has ALL strokes
            ) else {
                print("🔁 ERROR: generateResponse returned nil")
                return
            }

            print("🔁 Continuous AI move generated: \(aiMove.moveType)")

            // Execute AI move on main thread
            DispatchQueue.main.async {
                print("🔁 Executing continuous AI move on main thread")
                self.executeAIMove(aiMove)
                self.aiState = self.aiDecisionEngine.getCurrentState()
            }
        }
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

        // Update AI speed and move type indicators
        updateAISpeed(move.animationSpeed)
        updateLastMoveType(move.moveType)

        // Convert to PKStroke
        let pkStroke = move.toPKStroke()

        // Add to PencilKit drawing WITH ANIMATION
        DispatchQueue.main.async {
            // Animate the stroke being drawn at the specified speed
            self.animateStroke(pkStroke, speed: move.animationSpeed) {
                // Animation complete
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

    // Track strokes currently being animated
    private var animatingStrokeCount = 0

    private func animateStroke(_ pkStroke: PKStroke, speed: Double, completion: @escaping () -> Void) {
        // Get total number of points in the stroke
        let pointCount = pkStroke.path.count
        guard pointCount > 1 else {
            // Not enough points, just add it BELOW user strokes
            var drawing = self.pkDrawing
            let insertionIndex = getAIStrokeInsertionIndex(in: drawing.strokes)
            drawing.strokes.insert(pkStroke, at: insertionIndex)
            self.pkDrawing = drawing
            completion()
            return
        }

        // Track the starting stroke count to identify our partial strokes
        let startingStrokeCount = self.pkDrawing.strokes.count

        // Animate by progressively revealing points over time
        // Apply configuration speed multiplier (default 2.0 = twice as fast)
        // speed parameter comes from generator (can vary by stroke properties)
        let finalSpeed = speed * aiConfiguration.animationSpeedMultiplier
        let baseDuration: TimeInterval = 0.1
        let animationDuration = baseDuration / finalSpeed
        let steps = 10 // Number of animation frames
        var currentStep = 0

        // Create a timer to progressively add points
        let timer = Timer.scheduledTimer(withTimeInterval: animationDuration / Double(steps), repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                completion()
                return
            }

            currentStep += 1

            if currentStep >= steps {
                // Animation complete - add the full stroke BELOW user strokes
                timer.invalidate()
                var drawing = self.pkDrawing

                // Remove the last partial stroke we added
                if drawing.strokes.count > startingStrokeCount {
                    _ = drawing.strokes.popLast()
                }

                // Insert AI stroke BELOW recent user strokes
                let insertionIndex = self.getAIStrokeInsertionIndex(in: drawing.strokes)
                drawing.strokes.insert(pkStroke, at: insertionIndex)
                self.pkDrawing = drawing
                print("🤖 AI stroke fully animated onto canvas (speed: \(speed)x, config: \(aiConfiguration.animationSpeedMultiplier)x, final: \(String(format: "%.1f", speed * aiConfiguration.animationSpeedMultiplier))x) at index \(insertionIndex). Total strokes: \(drawing.strokes.count)")
                completion()
            } else {
                // Create partial stroke - take first N points
                let progress = CGFloat(currentStep) / CGFloat(steps)
                let targetPointCount = Int(CGFloat(pointCount) * progress)

                if targetPointCount > 0 {
                    // Get subset of control points
                    var partialPoints: [PKStrokePoint] = []
                    for i in 0..<min(targetPointCount, pointCount) {
                        partialPoints.append(pkStroke.path[i])
                    }

                    if partialPoints.count > 0 {
                        let partialPath = PKStrokePath(controlPoints: partialPoints, creationDate: Date())
                        let partialStroke = PKStroke(ink: pkStroke.ink, path: partialPath)

                        // Replace the last stroke (partial) with updated partial
                        var drawing = self.pkDrawing
                        if drawing.strokes.count > startingStrokeCount {
                            // Remove previous partial and add updated one
                            _ = drawing.strokes.popLast()
                        }
                        // For animation, we can append (it will be repositioned when complete)
                        drawing.strokes.append(partialStroke)
                        self.pkDrawing = drawing
                    }
                }
            }
        }

        RunLoop.main.add(timer, forMode: .common)
    }

    /// Get the index where AI strokes should be inserted (before recent user strokes)
    /// This ensures user strokes are always rendered on top
    private func getAIStrokeInsertionIndex(in strokes: [PKStroke]) -> Int {
        // Simple approach: Insert AI strokes at the beginning
        // This ensures ALL user strokes are rendered on top of ALL AI strokes
        return 0
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

    // MARK: - Status Indicator Updates

    private func updateUserSpeed(_ velocity: Double) {
        userSpeedText = formatSpeed(velocity)
    }

    private func updateAISpeed(_ animationSpeed: Double) {
        // Animation speed: 0.5 = slow, 1.0 = normal, 2.0 = fast
        if animationSpeed < 0.7 {
            aiSpeedText = "SLOW"
        } else if animationSpeed < 1.3 {
            aiSpeedText = "MED"
        } else {
            aiSpeedText = "FAST"
        }
    }

    private func updateLastMoveType(_ moveType: AIMoveType) {
        lastMoveType = moveType.rawValue
    }

    private func formatSpeed(_ velocity: Double) -> String {
        // Velocity ranges: <150 = slow, 150-350 = med, >350 = fast
        if velocity < 150 {
            return "SLOW"
        } else if velocity < 350 {
            return "MED"
        } else {
            return "FAST"
        }
    }

    // MARK: - Cleanup

    deinit {
        stopContinuousDrawing()
        saveSession()
    }
}
