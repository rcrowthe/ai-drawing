//
//  DrawingCanvasView.swift
//  AIDrawing
//
//  SwiftUI wrapper for PKCanvasView
//

import SwiftUI
import PencilKit
import UIKit

struct DrawingCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    let onStrokeAdded: (PKStroke) -> Void
    let onStrokeRemoved: (PKStroke) -> Void
    let onUserStartedDrawing: (() -> Void)?  // Callback when user begins drawing
    let tool: PKTool
    var isTransparent: Bool = false  // New: supports transparent background for layering
    @Binding var zoomScale: CGFloat  // Synchronized zoom
    @Binding var contentOffset: CGPoint  // Synchronized pan
    @Binding var canvasBounds: CGSize  // Canvas viewport size (reported to view model)

    func makeUIView(context: Context) -> PKCanvasView {
        print("🎨 DrawingCanvasView: makeUIView called")
        let canvas = PKCanvasView()
        canvas.delegate = context.coordinator
        canvas.drawingPolicy = .anyInput  // Allow mouse/trackpad for simulator
        canvas.tool = tool
        canvas.drawing = drawing

        // Configure background based on transparency mode
        if isTransparent {
            canvas.backgroundColor = .clear
            canvas.isOpaque = false
            print("🎨 Canvas setup as TRANSPARENT layer (user input layer)")
        } else {
            canvas.backgroundColor = .white
            canvas.isOpaque = true
            print("🎨 Canvas setup as OPAQUE layer")
        }

        // Enable finger/mouse drawing for simulator testing
        canvas.allowsFingerDrawing = true  // Enable for simulator
        canvas.becomeFirstResponder()

        // CRITICAL: Disable automatic content inset adjustments
        canvas.contentInsetAdjustmentBehavior = .never
        canvas.automaticallyAdjustsScrollIndicatorInsets = false

        // Set a large explicit content size so canvas doesn't end early
        let largeContentSize = CGSize(width: 4000, height: 4000)
        canvas.contentSize = largeContentSize

        // Center the content initially
        // This will be overridden by zoomScale binding, but sets a good initial state
        canvas.contentInset = .zero
        canvas.scrollIndicatorInsets = .zero

        // Enable zoom - synchronized across layers
        canvas.minimumZoomScale = 0.5
        canvas.maximumZoomScale = 3.0
        canvas.zoomScale = zoomScale

        // Set scroll view delegate for zoom/pan synchronization
        // PKCanvasView is a UIScrollView subclass
        context.coordinator.scrollViewDelegate = canvas
        if let scrollView = canvas as? UIScrollView {
            scrollView.delegate = context.coordinator
        }

        print("🎨 Canvas setup complete - allowsFingerDrawing: \(canvas.allowsFingerDrawing)")
        print("🎨 Canvas drawingPolicy: \(canvas.drawingPolicy.rawValue)")
        print("🎨 Canvas zoom enabled - min: 0.5, max: 3.0, current: \(zoomScale)")
        print("🎨 Canvas bounds: \(canvas.bounds)")
        print("🎨 Canvas contentSize: \(canvas.contentSize)")
        print("🎨 Canvas contentOffset: \(canvas.contentOffset)")
        print("🎨 Canvas contentInset: \(canvas.contentInset)")

        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        // Update drawing if it changed externally
        if canvas.drawing != drawing {
            canvas.drawing = drawing
        }

        // Update tool - always set to ensure it's correct
        canvas.tool = tool

        // Report canvas bounds if changed
        let newBounds = canvas.bounds.size
        if newBounds != canvasBounds {
            DispatchQueue.main.async {
                self.canvasBounds = newBounds
                print("📏 Canvas bounds updated: \(Int(newBounds.width))x\(Int(newBounds.height))")
            }
        }

        // DON'T update zoom/pan from binding - the user canvas DRIVES these values
        // via scrollViewDidZoom/scrollViewDidScroll, so setting them here creates a feedback loop
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            drawing: $drawing,
            zoomScale: $zoomScale,
            contentOffset: $contentOffset,
            onStrokeAdded: onStrokeAdded,
            onStrokeRemoved: onStrokeRemoved,
            onUserStartedDrawing: onUserStartedDrawing
        )
    }

    class Coordinator: NSObject, PKCanvasViewDelegate, UIScrollViewDelegate {
        @Binding var drawing: PKDrawing
        @Binding var zoomScale: CGFloat
        @Binding var contentOffset: CGPoint
        let onStrokeAdded: (PKStroke) -> Void
        let onStrokeRemoved: (PKStroke) -> Void
        let onUserStartedDrawing: (() -> Void)?

        private var previousStrokeCount = 0
        private var strokeCountWhenUserStartedDrawing = -1  // -1 means not in a user drawing session
        weak var scrollViewDelegate: UIScrollView?  // Reference to canvas as scroll view

        init(
            drawing: Binding<PKDrawing>,
            zoomScale: Binding<CGFloat>,
            contentOffset: Binding<CGPoint>,
            onStrokeAdded: @escaping (PKStroke) -> Void,
            onStrokeRemoved: @escaping (PKStroke) -> Void,
            onUserStartedDrawing: (() -> Void)?
        ) {
            self._drawing = drawing
            self._zoomScale = zoomScale
            self._contentOffset = contentOffset
            self.onStrokeAdded = onStrokeAdded
            self.onStrokeRemoved = onStrokeRemoved
            self.onUserStartedDrawing = onUserStartedDrawing
            self.previousStrokeCount = drawing.wrappedValue.strokes.count
        }

        // MARK: - PKCanvasViewDelegate

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            let currentStrokes = canvasView.drawing.strokes
            let currentCount = currentStrokes.count

            // ONLY log and process if stroke count actually changed
            guard currentCount != previousStrokeCount else {
                // Stroke count unchanged - just update binding without logging
                DispatchQueue.main.async {
                    self.drawing = canvasView.drawing
                }
                return
            }

            print("✏️ canvasViewDrawingDidChange called")
            print("✏️ Current stroke count: \(currentCount), previous: \(previousStrokeCount)")

            // Detect new strokes
            if currentCount > previousStrokeCount {
                let newStrokeCount = currentCount - previousStrokeCount

                // Check if these strokes were added during a user drawing session
                // If currentCount > strokeCountWhenUserStartedDrawing AND we've seen a beginUsingTool,
                // then these are user strokes
                if strokeCountWhenUserStartedDrawing >= 0 && currentCount > strokeCountWhenUserStartedDrawing {
                    print("✏️ NEW USER STROKES DETECTED: \(newStrokeCount)")
                    let newStrokes = Array(currentStrokes.suffix(newStrokeCount))

                    // Call callback asynchronously to avoid "Publishing changes from within view updates"
                    DispatchQueue.main.async {
                        for stroke in newStrokes {
                            print("✏️ Calling onStrokeAdded callback for user stroke")
                            self.onStrokeAdded(stroke)
                        }
                    }

                    // Reset after processing user strokes
                    strokeCountWhenUserStartedDrawing = -1
                } else {
                    // Strokes added programmatically (AI) - don't trigger callback
                    print("✏️ AI STROKES DETECTED (skipping callback): \(newStrokeCount)")
                }
            } else if currentCount < previousStrokeCount {
                // Strokes were removed (undo)
                print("✏️ STROKES REMOVED")
            }

            previousStrokeCount = currentCount

            // Update binding asynchronously to avoid "Publishing changes from within view updates"
            DispatchQueue.main.async {
                self.drawing = canvasView.drawing
            }
        }

        func canvasViewDidBeginUsingTool(_ canvasView: PKCanvasView) {
            // User started drawing - record current stroke count
            strokeCountWhenUserStartedDrawing = canvasView.drawing.strokes.count
            print("✏️ User STARTED drawing - stroke count: \(strokeCountWhenUserStartedDrawing)")
            // Notify view model to stop continuous drawing
            onUserStartedDrawing?()
        }

        func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) {
            // User finished drawing - DON'T reset strokeCountWhenUserStartedDrawing yet
            // It will be reset after processing the strokes in canvasViewDrawingDidChange
            print("✏️ User FINISHED drawing")

            // Report zoom/pan changes to binding
            DispatchQueue.main.async {
                self.zoomScale = canvasView.zoomScale
                self.contentOffset = canvasView.contentOffset
            }
        }

        // MARK: - UIScrollViewDelegate (for real-time zoom/pan sync)

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            // Update binding immediately and synchronously when user zooms (pinch gesture)
            zoomScale = scrollView.zoomScale
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            // Update binding immediately and synchronously when user pans
            contentOffset = scrollView.contentOffset
        }
    }
}

// MARK: - Default Tool Helper

extension PKTool {
    static var defaultPen: PKTool {
        return PKInkingTool(.pen, color: .black, width: 2.0)
    }

    static var defaultMarker: PKTool {
        return PKInkingTool(.marker, color: .black, width: 10.0)
    }

    static var aiPen: PKTool {
        // AI uses a distinct color (blue) to differentiate
        return PKInkingTool(.pen, color: .systemBlue, width: 1.5)
    }
}
