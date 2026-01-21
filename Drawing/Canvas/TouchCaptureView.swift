//
//  TouchCaptureView.swift
//  AIDrawing
//
//  Custom UIView for high-fidelity Apple Pencil touch capture with Metal rendering
//

import UIKit
import MetalKit

protocol TouchCaptureDelegate: AnyObject {
    func touchCaptureDidBegin(_ view: TouchCaptureView)
    func touchCaptureDidUpdate(_ view: TouchCaptureView, deltaPoints: [StrokePoint])
    func touchCaptureDidEnd(_ view: TouchCaptureView, finalStroke: InProgressStroke)
    func touchCaptureDidCancel(_ view: TouchCaptureView)
}

class TouchCaptureView: MTKView {
    weak var touchDelegate: TouchCaptureDelegate?

    // Expose renderer for AI stroke rendering
    private(set) var renderer: MetalRenderer
    private var currentStroke: InProgressStroke?
    private var lastTimestamp: TimeInterval = 0
    private let smoothingFilter = StrokeSmoother.OneEuroFilter(minCutoff: 0.3, beta: 0.01)

    // Throttling for AI updates (30-60Hz)
    private var lastAIUpdateTime: TimeInterval = 0
    private let aiUpdateInterval: TimeInterval = 1.0 / 60.0  // 60Hz max
    private var pendingPointsForAI: [StrokePoint] = []

    // Configuration
    var allowFingerDrawing: Bool = false
    var smoothingEnabled: Bool = true
    var decimationDistance: CGFloat = 2.0  // pixels

    // Current drawing color and width
    var drawingColor: UIColor = .black
    var baseWidth: CGFloat = 3.0

    init(renderer: MetalRenderer) {
        self.renderer = renderer
        super.init(frame: .zero, device: renderer.device)

        self.delegate = self
        self.clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1)
        self.isMultipleTouchEnabled = false  // Single touch only
        self.isOpaque = true

        // CRITICAL: Enable continuous rendering
        self.isPaused = false
        self.enableSetNeedsDisplay = false
        self.preferredFramesPerSecond = 60

        print("✏️ TouchCaptureView initialized")
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        // Filter touch type
        if touch.type == .pencil || (allowFingerDrawing && touch.type == .direct) {
            let touchLoc = touch.location(in: self)
            print("✏️ Touch began: \(touch.type == .pencil ? "Pencil" : "Finger") at (\(touchLoc.x), \(touchLoc.y))")
            print("✏️ View bounds: \(self.bounds.size), drawableSize: \(self.drawableSize), scale: \(self.contentScaleFactor)")

            // Start new stroke
            currentStroke = InProgressStroke(touchType: touch.type)
            lastTimestamp = ProcessInfo.processInfo.systemUptime
            pendingPointsForAI.removeAll()

            // Process coalesced touches
            let coalescedTouches = event?.coalescedTouches(for: touch) ?? [touch]
            processCoalescedTouches(coalescedTouches)

            // Notify delegate
            touchDelegate?.touchCaptureDidBegin(self)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              var stroke = currentStroke else { return }

        let currentTime = ProcessInfo.processInfo.systemUptime

        // Process coalesced touches (high-frequency samples)
        let coalescedTouches = event?.coalescedTouches(for: touch) ?? [touch]
        let newPoints = processCoalescedTouches(coalescedTouches)

        // Process predicted touches (ghost rendering)
        if let predictedTouches = event?.predictedTouches(for: touch), !predictedTouches.isEmpty {
            let predictedPoints = predictedTouches.map { touch in
                StrokePoint(from: touch, in: self, timestamp: currentTime)
            }
            // Render predicted points as ghost
            renderer.setPredictedStroke(predictedPoints, color: drawingColor.withAlphaComponent(0.3), baseWidth: baseWidth, scale: contentScaleFactor)
        } else {
            renderer.clearPredictedStroke()
        }

        // Throttle AI updates to prevent spam
        if currentTime - lastAIUpdateTime >= aiUpdateInterval {
            // Send accumulated points to AI
            if !pendingPointsForAI.isEmpty {
                touchDelegate?.touchCaptureDidUpdate(self, deltaPoints: pendingPointsForAI)
                pendingPointsForAI.removeAll()
            }
            lastAIUpdateTime = currentTime
        }

        lastTimestamp = currentTime
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let finalStroke = currentStroke else { return }

        print("✏️ Touch ended - total points: \(finalStroke.points.count)")

        // Process final coalesced touches
        let coalescedTouches = event?.coalescedTouches(for: touch) ?? [touch]
        processCoalescedTouches(coalescedTouches)

        // Clear predicted stroke
        renderer.clearPredictedStroke()

        // Commit stroke to renderer
        renderer.commitCurrentStroke()

        // Send final points to AI if any pending
        if !pendingPointsForAI.isEmpty {
            touchDelegate?.touchCaptureDidUpdate(self, deltaPoints: pendingPointsForAI)
            pendingPointsForAI.removeAll()
        }

        // Notify delegate
        touchDelegate?.touchCaptureDidEnd(self, finalStroke: finalStroke)

        // Clear current stroke
        currentStroke = nil
        renderer.clearCurrentStroke()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("✏️ Touch cancelled")

        // Clear everything
        renderer.clearPredictedStroke()
        renderer.clearCurrentStroke()
        currentStroke = nil
        pendingPointsForAI.removeAll()

        touchDelegate?.touchCaptureDidCancel(self)
    }

    // MARK: - Touch Processing

    @discardableResult
    private func processCoalescedTouches(_ touches: [UITouch]) -> [StrokePoint] {
        guard var stroke = currentStroke else { return [] }

        var newPoints: [StrokePoint] = []
        let currentTime = ProcessInfo.processInfo.systemUptime

        for touch in touches {
            let point = StrokePoint(from: touch, in: self, timestamp: currentTime)
            newPoints.append(point)
        }

        // Apply smoothing if enabled
        if smoothingEnabled {
            newPoints = newPoints.map { smoothingFilter.filter(point: $0) }
        }

        // Apply distance-based decimation
        newPoints = StrokeSmoother.decimate(points: newPoints, minimumDistance: decimationDistance)

        // Add to stroke
        stroke.append(contentsOf: newPoints)
        currentStroke = stroke

        // Add to pending AI buffer
        pendingPointsForAI.append(contentsOf: newPoints)

        // CRITICAL FIX: Send the ENTIRE stroke to renderer (not just delta)
        // The renderer needs at least 2 points to create line segments
        if stroke.points.count >= 2 {
            // Clear previous vertices and re-render entire stroke
            renderer.clearCurrentStroke()
            renderer.enqueuePoints(stroke.points, color: drawingColor, baseWidth: baseWidth, scale: contentScaleFactor)
        }

        return newPoints
    }

    // MARK: - Public API

    func clearCanvas() {
        renderer.clearAll()
        currentStroke = nil
        pendingPointsForAI.removeAll()
        // MTKView auto-redraws, no need to call setNeedsDisplay
    }

    func setColor(_ color: UIColor) {
        self.drawingColor = color
    }

    func setWidth(_ width: CGFloat) {
        self.baseWidth = width
    }
}

// MARK: - MTKViewDelegate

extension TouchCaptureView: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        print("✏️ Drawable size changed: \(size)")
    }

    func draw(in view: MTKView) {
        print("🎨 draw(in:) called - currentStrokeVertices count: \(renderer.currentStrokeVerticesCount)")
        renderer.draw(in: view)
    }
}
