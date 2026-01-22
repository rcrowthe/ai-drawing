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
    @Published var userPKDrawing: PKDrawing  // NEW: Only user strokes
    @Published var aiPKDrawing: PKDrawing    // NEW: Only AI strokes
    @Published var canvasZoomScale: CGFloat = 0.5  // Start at minimum zoom to see full canvas
    @Published var canvasContentOffset: CGPoint = .zero  // Synchronized pan between layers
    @Published var canvasBounds: CGSize = CGSize(width: 800, height: 1200)  // Canvas viewport size (updated from view)
    @Published var selectedTool: PKTool = PKInkingTool(.pen, color: GeneratorColors.userPenColor, width: 5)
    @Published var canUndo: Bool = false
    @Published var canRedo: Bool = false
    @Published var aiState: AIState = AIState()
    @Published var aiConfiguration: AIConfiguration
    @Published var showAIStrokes: Bool = true  // Phase 8: AI visibility toggle

    // DEPRECATED: Keep for compatibility during transition
    var pkDrawing: PKDrawing {
        get {
            // Combine both drawings for compatibility
            var combined = PKDrawing()
            combined.strokes = aiPKDrawing.strokes + userPKDrawing.strokes
            return combined
        }
        set {
            // Split strokes when set (during load)
            userPKDrawing = newValue
            aiPKDrawing = PKDrawing()
        }
    }

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

    // AI stroke cache: Keeps PKStroke references alive across session save/load
    // Maps stroke ID → PKStroke for AI strokes only
    private var aiStrokeCache: [UUID: PKStroke] = [:]

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

        // Initialize AI decision engine with configuration
        self.aiDecisionEngine = AIDecisionEngine(configuration: loadedConfig)
        print("🔧 AI Decision Engine initialized")

        // Try to load existing session or create new one
        if let sessionID = PersistenceService.shared.loadCurrentSessionID(),
           let session = try? PersistenceService.shared.loadSession(id: sessionID) {
            self.currentSession = session

            // Split strokes into user and AI canvases
            var userDrawing = PKDrawing()
            var aiDrawing = PKDrawing()
            for stroke in session.strokes {
                if let pkStroke = stroke.toPKStroke() {
                    if stroke.source == .user {
                        userDrawing.strokes.append(pkStroke)
                    } else {
                        aiDrawing.strokes.append(pkStroke)
                    }
                }
            }
            self.userPKDrawing = userDrawing
            self.aiPKDrawing = aiDrawing
            print("🔧 Loaded existing session with \(session.strokes.count) strokes (user: \(userDrawing.strokes.count), ai: \(aiDrawing.strokes.count))")
        } else {
            self.currentSession = DrawingSession()
            self.userPKDrawing = PKDrawing()
            self.aiPKDrawing = PKDrawing()
            print("🔧 Created new drawing session")
        }

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

        // Add to user canvas immediately (already there from user input)
        // No need to modify userPKDrawing - it's already updated by the canvas

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

            // Calculate visible viewport rect
            let visibleRect = self.calculateVisibleRect()

            // Generate AI move based on CURRENT canvas state (includes all strokes)
            guard let aiMove = self.aiDecisionEngine.generateResponse(
                userStroke: mostRecentStroke,  // Use most recent stroke (AI learns from its own marks too!)
                session: self.currentSession,   // Session has ALL strokes
                visibleRect: visibleRect        // Current viewport
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

            // Calculate visible viewport rect
            let visibleRect = self.calculateVisibleRect()

            // Generate AI move
            guard let aiMove = self.aiDecisionEngine.generateResponse(
                userStroke: userStroke,
                session: self.currentSession,
                visibleRect: visibleRect
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

        // Create stroke model BEFORE animation
        let stroke = Stroke(pkStroke: pkStroke, source: .ai, moveType: move.moveType)

        // Cache the PKStroke reference so it survives session save/load
        aiStrokeCache[stroke.id] = pkStroke
        print("💾 Cached AI stroke \(stroke.id) in memory")

        // Add to session ONLY for AI logic (so next AI move can react to this stroke)
        // But DON'T render it from session yet - let animation handle rendering
        currentSession.addStroke(stroke)

        // Record in history
        historyManager.record(.aiStroke(stroke))

        // Track last AI move type for reinforcement (Phase 6)
        lastAIMoveType = move.moveType

        // Record implicit positive reinforcement (move was generated and kept)
        behaviorTracker.recordPositiveReinforcement(for: move.moveType)

        // Save session
        saveSession()

        // Animate the stroke (rendering is handled by animation system)
        DispatchQueue.main.async {
            self.animateStroke(pkStroke, speed: move.animationSpeed, strokeModel: stroke) {
                // Animation complete - stroke is already in session, just update display
                print("🎬 Animation complete for stroke \(stroke.id)")
            }
        }
    }

    // Track strokes currently being animated - allows multiple concurrent animations
    private var animatingStrokes: [UUID: AnimatingStroke] = [:]
    private var currentlyAnimatingStrokeIDs: Set<UUID> = []
    private var displayLink: CADisplayLink?  // For 60fps vsync animation
    private var lastAnimationUpdateTime: Date = Date()  // Throttle animation updates
    private let minUpdateInterval: TimeInterval = 1.0 / 15.0  // Max 15fps for animation updates (reduce overhead)

    private struct AnimatingStroke {
        let strokeID: UUID  // ID of the Stroke model
        let fullStroke: PKStroke
        let speed: Double
        let startTime: Date
        let duration: TimeInterval  // Total animation duration

        var isComplete: Bool {
            Date().timeIntervalSince(startTime) >= duration
        }

        var progress: CGFloat {
            let elapsed = Date().timeIntervalSince(startTime)
            let ratio = CGFloat(elapsed / duration)
            return min(1.0, max(0.0, ratio))  // Clamp to [0, 1]
        }
    }

    private func animateStroke(_ pkStroke: PKStroke, speed: Double, strokeModel: Stroke, completion: @escaping () -> Void) {
        let animationID = UUID()  // Unique ID for this animation

        // Track that this stroke is animating (to avoid rendering from session)
        currentlyAnimatingStrokeIDs.insert(strokeModel.id)

        // Calculate animation duration based on speed
        let finalSpeed = speed * aiConfiguration.animationSpeedMultiplier
        let baseDuration: TimeInterval = 1.0  // Base duration for 1x speed
        let animationDuration = baseDuration / finalSpeed

        print("🎬 Starting animation - duration: \(String(format: "%.2f", animationDuration))s, speed: \(String(format: "%.2f", finalSpeed))x")

        // Add to animating strokes (time-based, not step-based)
        animatingStrokes[animationID] = AnimatingStroke(
            strokeID: strokeModel.id,
            fullStroke: pkStroke,
            speed: speed,
            startTime: Date(),
            duration: animationDuration
        )

        // Start display link if not already running (vsync @ 60fps or higher)
        if displayLink == nil {
            startDisplayLink()
        }

        // Update display immediately to show animation start
        updateAIDrawingWithAnimations()

        // Handle completion when animation finishes
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) { [weak self] in
            guard let self = self else { return }

            // Remove from animating state
            self.animatingStrokes.removeValue(forKey: animationID)
            self.currentlyAnimatingStrokeIDs.remove(strokeModel.id)

            // Update display one final time to show complete stroke from session
            self.updateAIDrawingWithAnimations()

            completion()
        }
    }

    private func startDisplayLink() {
        // Stop any existing display link
        displayLink?.invalidate()

        // Create display link that fires on every screen refresh (60fps+ depending on device)
        let link = CADisplayLink(target: self, selector: #selector(displayLinkFired))
        link.add(to: .main, forMode: .common)
        displayLink = link

        print("🎬 Display link started for vsync animation")
    }

    @objc private func displayLinkFired(_ displayLink: CADisplayLink) {
        let fireTime = Date()

        // This fires every frame (60fps or 120fps on ProMotion displays)
        // Check if there are any active animations
        let hasActiveAnimations = !animatingStrokes.values.allSatisfy { $0.isComplete }

        if hasActiveAnimations {
            // THROTTLE: Only update at most 30fps to avoid overwhelming SwiftUI
            let timeSinceLastUpdate = fireTime.timeIntervalSince(lastAnimationUpdateTime)
            if timeSinceLastUpdate >= minUpdateInterval {
                let updateStartTime = Date()

                // Rebuild AI drawing with all partial strokes
                updateAIDrawingWithAnimations()

                let updateDuration = Date().timeIntervalSince(updateStartTime)
                if updateDuration > 0.016 {  // Warn if update takes longer than one frame (16ms)
                    print("⚠️ Slow animation update: \(String(format: "%.1f", updateDuration * 1000))ms")
                }

                lastAnimationUpdateTime = fireTime
            }
        } else {
            // Stop display link if no active animations
            displayLink.invalidate()
            self.displayLink = nil
            print("🎬 Display link stopped - no active animations")
        }
    }

    private func updateAIDrawingWithAnimations() {
        let updateStart = Date()
        var drawing = PKDrawing()

        // Debug: Count what we're about to add
        let totalAIStrokesInSession = currentSession.strokes.filter { $0.source == .ai }.count
        var skippedCount = 0
        var addedFromSessionCount = 0

        // Add all completed AI strokes from session (skip ones currently animating to avoid duplicates)
        for stroke in currentSession.strokes where stroke.source == .ai {
            // Skip if this stroke is currently being animated
            if currentlyAnimatingStrokeIDs.contains(stroke.id) {
                skippedCount += 1
                continue
            }

            // Try to get PKStroke - first from the stroke, then from cache if needed
            var pkStroke: PKStroke? = stroke.toPKStroke()

            // If toPKStroke() failed (nil), try to restore from cache
            if pkStroke == nil, let cachedStroke = aiStrokeCache[stroke.id] {
                pkStroke = cachedStroke
                // Restore it to the stroke model too
                var mutableStroke = stroke
                mutableStroke.pkStroke = cachedStroke
            }

            if let pkStroke = pkStroke {
                drawing.strokes.append(pkStroke)
                addedFromSessionCount += 1
            }
        }

        // Add all currently animating strokes (partial or complete)
        var addedAnimatingCount = 0
        var skippedLowProgress = 0
        for (_, animating) in animatingStrokes {
            if animating.isComplete {
                // Fully animated - add complete stroke
                drawing.strokes.append(animating.fullStroke)
                addedAnimatingCount += 1
            } else {
                // Still animating - check if we have enough progress to show
                // DON'T show strokes until they have at least 10% rendered to avoid the "dot" effect
                let progress = animating.progress
                if progress >= 0.1 {
                    // Add partial stroke
                    if let partialStroke = createPartialStroke(
                        from: animating.fullStroke,
                        progress: progress
                    ) {
                        drawing.strokes.append(partialStroke)
                        addedAnimatingCount += 1
                    }
                } else {
                    skippedLowProgress += 1
                }
            }
        }

        let updateDuration = Date().timeIntervalSince(updateStart)

        // Only log if update is slow or we skipped strokes
        if updateDuration > 0.016 || skippedLowProgress > 0 {
            print("📊 updateAIDrawing: \(drawing.strokes.count) strokes (\(addedFromSessionCount) session + \(addedAnimatingCount) animating, skipped \(skippedLowProgress) low-progress) - \(String(format: "%.1f", updateDuration * 1000))ms")
        }

        self.aiPKDrawing = drawing
    }

    private func createPartialStroke(from fullStroke: PKStroke, progress: CGFloat) -> PKStroke? {
        let pointCount = fullStroke.path.count
        guard pointCount > 1 else { return nil }

        let targetPointCount = max(1, Int(CGFloat(pointCount) * progress))
        var partialPoints: [PKStrokePoint] = []

        for i in 0..<min(targetPointCount, pointCount) {
            partialPoints.append(fullStroke.path[i])
        }

        guard partialPoints.count > 0 else { return nil }

        let partialPath = PKStrokePath(controlPoints: partialPoints, creationDate: Date())
        return PKStroke(ink: fullStroke.ink, path: partialPath)
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

    /// Calculate the visible viewport rectangle in canvas coordinates
    private func calculateVisibleRect() -> CGRect? {
        // Only return a rect if zoomed in (zoom > 0.9) - at zoom 1.0 or below, assume full canvas visible
        guard canvasZoomScale > 0.9 else {
            print("📐 Viewport: Full canvas (zoom \(String(format: "%.2f", canvasZoomScale)) ≤ 0.9)")
            return nil  // Full canvas visible
        }

        // Calculate visible area in canvas coordinates
        let visibleWidth = canvasBounds.width / canvasZoomScale
        let visibleHeight = canvasBounds.height / canvasZoomScale

        let rect = CGRect(
            x: canvasContentOffset.x,
            y: canvasContentOffset.y,
            width: visibleWidth,
            height: visibleHeight
        )

        print("📐 Viewport: origin:(\(Int(rect.origin.x)),\(Int(rect.origin.y))) size:\(Int(rect.width))x\(Int(rect.height)) zoom:\(String(format: "%.2f", canvasZoomScale))")
        print("📐   canvasBounds: \(Int(canvasBounds.width))x\(Int(canvasBounds.height)), contentOffset: (\(Int(canvasContentOffset.x)),\(Int(canvasContentOffset.y)))")

        return rect
    }

    // MARK: - Cleanup

    deinit {
        stopContinuousDrawing()
        displayLink?.invalidate()
        saveSession()
    }
}
