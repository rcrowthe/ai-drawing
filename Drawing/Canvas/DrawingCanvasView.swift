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

    func makeUIView(context: Context) -> PKCanvasView {
        print("🎨 DrawingCanvasView: makeUIView called")
        let canvas = PKCanvasView()
        canvas.delegate = context.coordinator
        canvas.drawingPolicy = .anyInput  // Allow mouse/trackpad for simulator
        canvas.tool = tool
        canvas.drawing = drawing
        canvas.backgroundColor = .white
        canvas.isOpaque = true

        // Enable finger/mouse drawing for simulator testing
        canvas.allowsFingerDrawing = true  // Enable for simulator
        canvas.becomeFirstResponder()

        // Configure zoom behavior
        canvas.minimumZoomScale = 0.5   // Allow zooming out to 50%
        canvas.maximumZoomScale = 3.0   // Allow zooming in to 300%
        canvas.zoomScale = 1.0          // Start at 100% (normal size)

        print("🎨 Canvas setup complete - allowsFingerDrawing: \(canvas.allowsFingerDrawing)")
        print("🎨 Canvas drawingPolicy: \(canvas.drawingPolicy.rawValue)")
        print("🎨 Canvas zoom configured - min: 0.5, max: 3.0, current: 1.0")

        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        // Update drawing if it changed externally
        if canvas.drawing != drawing {
            canvas.drawing = drawing
        }

        // Update tool - always set to ensure it's correct
        canvas.tool = tool
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            drawing: $drawing,
            onStrokeAdded: onStrokeAdded,
            onStrokeRemoved: onStrokeRemoved,
            onUserStartedDrawing: onUserStartedDrawing
        )
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding var drawing: PKDrawing
        let onStrokeAdded: (PKStroke) -> Void
        let onStrokeRemoved: (PKStroke) -> Void
        let onUserStartedDrawing: (() -> Void)?

        private var previousStrokeCount = 0
        private var strokeCountWhenUserStartedDrawing = -1  // -1 means not in a user drawing session

        init(
            drawing: Binding<PKDrawing>,
            onStrokeAdded: @escaping (PKStroke) -> Void,
            onStrokeRemoved: @escaping (PKStroke) -> Void,
            onUserStartedDrawing: (() -> Void)?
        ) {
            self._drawing = drawing
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
