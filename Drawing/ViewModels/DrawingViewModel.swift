//
//  DrawingViewModel.swift
//  AIDrawing
//
//  Main view model for the drawing screen
//

import Foundation
import PencilKit
import Combine
import UIKit

// Note: ContinuousDrawingEngine is in the same module, no import needed
// Note: StrokePoint and InProgressStroke are in the same module, no import needed

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
    internal var aiDecisionEngine: AIDecisionEngine  // Internal for ContinuousDrawingEngine access
    private var continuousEngine: ContinuousDrawingEngine?

    // Learning system (Phase 6)
    private let behaviorTracker = BehaviorTracker()
    private let motifDetector = MotifDetector()
    private let profileAdapter = ProfileAdapter()

    private var cancellables = Set<AnyCancellable>()
    private var lastAIMoveType: AIMoveType?  // Track last AI move for reinforcement
    private var isAddingAIStroke = false  // Prevent feedback loop
    @Published var isUserDrawing = false  // Track if user is actively drawing RIGHT NOW

    // Overlay stroke management for real-time rendering
    @Published var pendingOverlayStrokes: [(move: AIMove, timestamp: Date)] = []
    @Published var shouldClearOverlay: Bool = false

    // Metal-based streaming support
    @Published var currentInProgressStroke: InProgressStroke?
    @Published var metalDrawingColor: UIColor = GeneratorColors.userPenColor
    @Published var metalStrokeWidth: CGFloat = 5.0
    @Published var metalToolType: MetalToolType = .pen
    weak var metalCanvasView: TouchCaptureView?  // Reference to Metal canvas for AI stroke rendering
    private var inProgressStrokeStartTime: Date?

    enum MetalToolType {
        case pen
        case marker
        case eraser
    }

    init() {
        print("🔧 DrawingViewModel: init started")
        // Load or create AI configuration
        var loadedConfig = PersistenceService.shared.loadConfiguration() ?? AIConfiguration()

        // FORCE continuous mode to be enabled (override any saved config)
        loadedConfig.continuousModeEnabled = true

        self.aiConfiguration = loadedConfig
        print("🔧 AI Configuration loaded, continuousModeEnabled FORCED to true")
        print("🔧 Configuration: drawRate=\(loadedConfig.continuousDrawRate), startDelay=\(loadedConfig.startDelay), stopDelay=\(loadedConfig.stopDelay)")

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

        // Initialize continuous drawing engine
        self.continuousEngine = ContinuousDrawingEngine(configuration: loadedConfig)
        print("🔧 Continuous Drawing Engine initialized")

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
                self?.continuousEngine?.updateConfiguration(newConfig)
                self?.persistenceService.saveConfiguration(newConfig)
                print("🔧 Configuration auto-updated from settings")
            }
            .store(in: &cancellables)
    }

    // MARK: - Stroke Handling

    func handleStrokeAdded(_ pkStroke: PKStroke) {
        print("📝 handleStrokeAdded called")

        // Safety check: ensure stroke has a valid path
        guard pkStroke.path.count > 0 else {
            print("⚠️ handleStrokeAdded: Received stroke with empty path, ignoring")
            return
        }

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
        // Skip regular AI response if continuous mode is active
        if aiConfiguration.continuousModeEnabled {
            print("📝 Skipping regular AI response (continuous mode active)")
            return
        }

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

    // MARK: - Real-Time Drawing State

    func userDidBeginDrawing() {
        isUserDrawing = true
        print("✏️ User STARTED drawing - isUserDrawing set to TRUE")
        // Clear any previous overlay strokes when starting a new stroke
        pendingOverlayStrokes.removeAll()
    }

    func userDidEndDrawing() {
        isUserDrawing = false
        print("✏️ User STOPPED drawing - isUserDrawing set to FALSE")

        // Commit all pending overlay strokes to PKDrawing
        commitOverlayStrokes()
    }

    // MARK: - Metal Streaming Integration (New)

    /// Called when user starts a new stroke with Metal pipeline
    func handleMetalStrokeBegan() {
        isUserDrawing = true
        inProgressStrokeStartTime = Date()
        print("✏️ Metal: User STARTED drawing stroke")

        // Start continuous AI drawing if enabled
        if aiConfiguration.continuousModeEnabled {
            continuousEngine?.startContinuousDrawing(viewModel: self)
        }
    }

    /// Called on each touchesMoved with delta points (streaming)
    func handleMetalStrokeProgress(deltaPoints: [StrokePoint]) {
        print("✏️ Metal: Received \(deltaPoints.count) delta points")

        // Update current in-progress stroke
        if currentInProgressStroke == nil {
            currentInProgressStroke = InProgressStroke()
        }
        currentInProgressStroke?.append(contentsOf: deltaPoints)

        // Stream to continuous engine for real-time AI response
        if aiConfiguration.continuousModeEnabled {
            continuousEngine?.processInProgressStroke(deltaPoints: deltaPoints, viewModel: self)
        }
    }

    /// Called when user completes a stroke
    func handleMetalStrokeCommitted(finalStroke: InProgressStroke) {
        isUserDrawing = false
        print("✏️ Metal: Stroke COMMITTED with \(finalStroke.points.count) points, tool: \(metalToolType)")

        // Handle eraser differently
        if metalToolType == .eraser {
            // Eraser: Remove intersecting strokes from Metal renderer
            if let metalCanvas = metalCanvasView {
                metalCanvas.renderer.eraseStrokesIntersecting(finalStroke.points)
                print("🧹 Eraser applied - removed intersecting strokes")
            }
            return  // Don't add eraser strokes to session
        }

        // Convert InProgressStroke to PKStroke for session storage
        let pkStroke = convertInProgressStrokeToPKStroke(finalStroke)

        // Create stroke model
        let stroke = Stroke(pkStroke: pkStroke, source: .user)
        print("📝 Metal stroke created: \(stroke.id)")

        // Add to session
        currentSession.addStroke(stroke)
        print("📝 Stroke added to session. Total strokes: \(currentSession.strokes.count)")

        // Record in history
        historyManager.record(.userStroke(stroke))

        // Track behavior for learning
        behaviorTracker.recordUserStroke(stroke, session: currentSession)

        // Save session
        saveSession()

        // Clear in-progress stroke
        currentInProgressStroke = nil
        inProgressStrokeStartTime = nil

        // Stop continuous AI drawing
        if aiConfiguration.continuousModeEnabled {
            continuousEngine?.stop()
        }

        // Commit all pending overlay strokes to PKDrawing
        commitOverlayStrokes()
    }

    /// Called when stroke is cancelled
    func handleMetalStrokeCancelled() {
        isUserDrawing = false
        currentInProgressStroke = nil
        inProgressStrokeStartTime = nil
        print("✏️ Metal: Stroke CANCELLED")

        // Stop continuous AI drawing
        if aiConfiguration.continuousModeEnabled {
            continuousEngine?.stop()
        }
    }

    /// Convert InProgressStroke to PKStroke for storage/compatibility
    private func convertInProgressStrokeToPKStroke(_ inProgressStroke: InProgressStroke) -> PKStroke {
        // Convert StrokePoint array to PKStrokePoint array
        let pkPoints = inProgressStroke.points.map { point in
            PKStrokePoint(
                location: point.location,
                timeOffset: point.timestamp - inProgressStroke.points[0].timestamp,
                size: CGSize(width: 3.0, height: 3.0),  // Base size
                opacity: 1.0,
                force: point.force,
                azimuth: point.azimuthAngle,
                altitude: point.altitudeAngle
            )
        }

        let path = PKStrokePath(controlPoints: pkPoints, creationDate: inProgressStroke.startTime)
        let ink = PKInk(.pen, color: metalDrawingColor)
        return PKStroke(ink: ink, path: path)
    }

    // MARK: - Real-Time Drawing State (PencilKit - Legacy)

    func userDidBeginDrawing_legacy() {
        isUserDrawing = true
        print("✏️ User STARTED drawing - isUserDrawing set to TRUE")
        // Clear any previous overlay strokes when starting a new stroke
        pendingOverlayStrokes.removeAll()
    }

    func userDidEndDrawing_legacy() {
        isUserDrawing = false
        print("✏️ User STOPPED drawing - isUserDrawing set to FALSE")

        // Commit all pending overlay strokes to PKDrawing
        commitOverlayStrokes()
    }

    /// Commit pending overlay strokes to PKDrawing and clear overlay
    private func commitOverlayStrokes() {
        guard !pendingOverlayStrokes.isEmpty else { return }

        print("🎭 Committing \(pendingOverlayStrokes.count) overlay strokes to PKDrawing")

        // Set flag to prevent feedback loop
        isAddingAIStroke = true

        var drawing = self.pkDrawing

        for (move, _) in pendingOverlayStrokes {
            let pkStroke = move.toPKStroke()
            drawing.strokes.append(pkStroke)

            // Add to session
            let stroke = Stroke(pkStroke: pkStroke, source: .ai, moveType: move.moveType)
            currentSession.addStroke(stroke)
            historyManager.record(.aiStroke(stroke))
            behaviorTracker.recordPositiveReinforcement(for: move.moveType)
        }

        // Update PKDrawing
        self.pkDrawing = drawing
        saveSession()

        // Clear pending strokes and trigger overlay clear
        pendingOverlayStrokes.removeAll()
        shouldClearOverlay = true

        print("🎭 Committed \(drawing.strokes.count) total strokes to PKDrawing")

        // Reset flag after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.isAddingAIStroke = false
        }
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

        case .removeStroke(let _):
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

        // Clear Metal canvas if using Metal renderer
        metalCanvasView?.clearCanvas()

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

        // Metal mode settings
        metalToolType = .pen
        metalStrokeWidth = 5.0
        metalDrawingColor = GeneratorColors.userPenColor
    }

    func selectMarkerTool() {
        currentToolType = .marker
        selectedTool = PKInkingTool(.marker, color: GeneratorColors.userPenColor, width: 20)

        // Metal mode settings (wider, semi-transparent)
        metalToolType = .marker
        metalStrokeWidth = 20.0
        metalDrawingColor = GeneratorColors.userPenColor.withAlphaComponent(0.6)
    }

    func selectEraserTool() {
        currentToolType = .eraser
        selectedTool = PKEraserTool(.vector)

        // Metal mode settings
        metalToolType = .eraser
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

        // Update continuous drawing engine with new configuration
        self.continuousEngine?.updateConfiguration(newConfiguration)

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

    // MARK: - Continuous Drawing Mode

    func startContinuousDrawing() {
        guard let engine = continuousEngine else {
            print("⚠️ Continuous engine not initialized")
            return
        }
        engine.startContinuousDrawing(viewModel: self)
        aiConfiguration.continuousModeEnabled = true
        print("🎨 Continuous co-drawing STARTED")
    }

    func stopContinuousDrawing() {
        continuousEngine?.stop()
        aiConfiguration.continuousModeEnabled = false
        print("🎨 Continuous co-drawing STOPPED")
    }

    func setContinuousDrawRate(_ rate: Double) {
        continuousEngine?.aiDrawRate = rate
        aiConfiguration.continuousDrawRate = rate
    }

    /// Execute AI move with animation for continuous mode
    /// Called by ContinuousDrawingEngine
    func executeAIMoveContinuous(_ move: AIMove, completion: @escaping () -> Void) {
        print("🤖 executeAIMoveContinuous: \(move.moveType) - TO OVERLAY")

        // If user is actively drawing, add to overlay for immediate rendering
        if isUserDrawing {
            // Add to pending overlay strokes
            // The AIStrokeOverlayView observes this array and will render it automatically
            pendingOverlayStrokes.append((move: move, timestamp: Date()))
            print("🎭 AI stroke queued for overlay: \(move.moveType), total pending: \(pendingOverlayStrokes.count)")

            // ALSO render via Metal if using Metal renderer
            if let metalCanvas = metalCanvasView {
                let aiColor = move.tool.color
                let aiWidth = move.tool.width
                let scale = metalCanvas.contentScaleFactor

                // Convert AIMove path to StrokePoint array
                var strokePoints: [StrokePoint] = []
                for index in 0..<move.path.count {
                    let pathPoint = move.path[index]
                    let strokePoint = StrokePoint(
                        location: pathPoint.location,
                        timestamp: Date().timeIntervalSince1970 + Double(index) * 0.01,
                        force: pathPoint.force,
                        altitudeAngle: .pi / 4,  // Default tilt for AI strokes
                        azimuthAngle: 0,
                        estimatedProperties: []
                    )
                    strokePoints.append(strokePoint)
                }

                metalCanvas.renderer.addAIStroke(strokePoints, color: aiColor, baseWidth: aiWidth, scale: scale)
                print("🎨 AI stroke rendered via Metal: \(strokePoints.count) points")
            }
        } else {
            // User not drawing - add directly to PKDrawing
            let pkStroke = move.toPKStroke()

            isAddingAIStroke = true

            var drawing = self.pkDrawing
            drawing.strokes.append(pkStroke)
            self.pkDrawing = drawing

            let finalStroke = Stroke(pkStroke: pkStroke, source: .ai, moveType: move.moveType)
            self.currentSession.addStroke(finalStroke)
            self.historyManager.record(.aiStroke(finalStroke))
            self.behaviorTracker.recordPositiveReinforcement(for: move.moveType)
            self.saveSession()

            print("🤖 AI stroke added directly to PKDrawing: \(move.moveType)")

            // ALSO render via Metal if using Metal renderer
            if let metalCanvas = metalCanvasView {
                let aiColor = move.tool.color
                let aiWidth = move.tool.width
                let scale = metalCanvas.contentScaleFactor

                var strokePoints: [StrokePoint] = []
                for index in 0..<move.path.count {
                    let pathPoint = move.path[index]
                    let strokePoint = StrokePoint(
                        location: pathPoint.location,
                        timestamp: Date().timeIntervalSince1970 + Double(index) * 0.01,
                        force: pathPoint.force,
                        altitudeAngle: .pi / 4,  // Default tilt for AI strokes
                        azimuthAngle: 0,
                        estimatedProperties: []
                    )
                    strokePoints.append(strokePoint)
                }

                metalCanvas.renderer.addAIStroke(strokePoints, color: aiColor, baseWidth: aiWidth, scale: scale)
                print("🎨 AI stroke rendered via Metal: \(strokePoints.count) points")
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.isAddingAIStroke = false
            }
        }

        completion()
    }

    private func animateStroke(_ move: AIMove, duration: TimeInterval, completion: @escaping () -> Void) {
        print("🤖 animateStroke: \(move.moveType) over \(String(format: "%.2f", duration))s")

        let path = move.path
        let totalPoints = path.count

        // Safety check: ensure path has points
        guard totalPoints > 0 else {
            print("⚠️ animateStroke: path is empty, aborting")
            completion()
            return
        }

        let framesPerSecond = 60.0
        let totalFrames = Int(duration * framesPerSecond)
        let pointsPerFrame = max(1, totalPoints / totalFrames)

        var currentFrame = 0
        var strokeIndex: Int?  // Track the index of our animating stroke

        let timer = Timer.scheduledTimer(withTimeInterval: 1.0 / framesPerSecond, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                completion()
                return
            }

            currentFrame += 1
            let pointsToReveal = min(totalPoints, currentFrame * pointsPerFrame)

            // Safety check
            guard pointsToReveal > 0 && pointsToReveal <= totalPoints else {
                timer.invalidate()
                completion()
                return
            }

            // Build partial path
            var accumulatedPoints: [PKStrokePoint] = []
            for i in 0..<pointsToReveal {
                guard i < path.count else { break }
                accumulatedPoints.append(path[i])
            }

            guard !accumulatedPoints.isEmpty else {
                timer.invalidate()
                completion()
                return
            }

            let partialPath = PKStrokePath(controlPoints: accumulatedPoints, creationDate: Date())
            let partialStroke = PKStroke(ink: PKInk(move.tool.inkType, color: move.tool.color), path: partialPath)

            // Update canvas on main thread
            DispatchQueue.main.async {
                self.isAddingAIStroke = true

                var drawing = self.pkDrawing

                // Replace previous partial stroke or append new
                if let index = strokeIndex {
                    // Update existing stroke at tracked index
                    if index < drawing.strokes.count {
                        drawing.strokes[index] = partialStroke
                    }
                } else {
                    // First frame: append new stroke and remember its index
                    drawing.strokes.append(partialStroke)
                    strokeIndex = drawing.strokes.count - 1
                }

                self.pkDrawing = drawing
                self.isAddingAIStroke = false
            }

            // Complete animation
            if pointsToReveal >= totalPoints {
                timer.invalidate()

                DispatchQueue.main.async {
                    // Finalize stroke in session
                    let finalStroke = Stroke(pkStroke: partialStroke, source: .ai, moveType: move.moveType)
                    self.currentSession.addStroke(finalStroke)
                    self.historyManager.record(.aiStroke(finalStroke))
                    self.behaviorTracker.recordPositiveReinforcement(for: move.moveType)
                    self.saveSession()

                    print("🤖 AI stroke animated and saved: \(move.moveType)")
                    completion()
                }
            }
        }
    }

    private func calculateAnimationDuration(_ path: PKStrokePath) -> TimeInterval {
        let length = calculatePathLength(path)
        // 100-200ms based on length - faster for responsive co-drawing
        return min(0.2, max(0.1, Double(length) / 2000.0))
    }

    private func calculatePathLength(_ path: PKStrokePath) -> CGFloat {
        var length: CGFloat = 0
        for i in 1..<path.count {
            let prev = path[i - 1].location
            let curr = path[i].location
            length += hypot(curr.x - prev.x, curr.y - prev.y)
        }
        return length
    }

    // MARK: - Cleanup

    deinit {
        stopContinuousDrawing()
        saveSession()
    }
}
