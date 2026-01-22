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

        // Enable zoom - synchronized across layers
        canvas.minimumZoomScale = 0.5
        canvas.maximumZoomScale = 3.0
        canvas.zoomScale = zoomScale

        print("🎨 Canvas setup complete - allowsFingerDrawing: \(canvas.allowsFingerDrawing)")
        print("🎨 Canvas drawingPolicy: \(canvas.drawingPolicy.rawValue)")
        print("🎨 Canvas zoom enabled - min: 0.5, max: 3.0, current: \(zoomScale)")

        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        // Update drawing if it changed externally
        if canvas.drawing != drawing {
            canvas.drawing = drawing
        }

        // Update tool - always set to ensure it's correct
        canvas.tool = tool

        // Sync zoom and pan from binding (from other canvas or programmatic changes)
        if abs(canvas.zoomScale - zoomScale) > 0.01 {
            canvas.zoomScale = zoomScale
        }
        if canvas.contentOffset != contentOffset {
            canvas.contentOffset = contentOffset
        }
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

    class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding var drawing: PKDrawing
        @Binding var zoomScale: CGFloat
        @Binding var contentOffset: CGPoint
        let onStrokeAdded: (PKStroke) -> Void
        let onStrokeRemoved: (PKStroke) -> Void
        let onUserStartedDrawing: (() -> Void)?

        private var previousStrokeCount = 0
        private var strokeCountWhenUserStartedDrawing = -1  // -1 means not in a user drawing session

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
