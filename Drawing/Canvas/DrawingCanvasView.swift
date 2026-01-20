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

        print("🎨 Canvas setup complete - allowsFingerDrawing: \(canvas.allowsFingerDrawing)")
        print("🎨 Canvas drawingPolicy: \(canvas.drawingPolicy.rawValue)")

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
            onStrokeRemoved: onStrokeRemoved
        )
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding var drawing: PKDrawing
        let onStrokeAdded: (PKStroke) -> Void
        let onStrokeRemoved: (PKStroke) -> Void

        private var previousStrokeCount = 0

        init(
            drawing: Binding<PKDrawing>,
            onStrokeAdded: @escaping (PKStroke) -> Void,
            onStrokeRemoved: @escaping (PKStroke) -> Void
        ) {
            self._drawing = drawing
            self.onStrokeAdded = onStrokeAdded
            self.onStrokeRemoved = onStrokeRemoved
            self.previousStrokeCount = drawing.wrappedValue.strokes.count
        }

        // MARK: - PKCanvasViewDelegate

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            print("✏️ canvasViewDrawingDidChange called")
            let currentStrokes = canvasView.drawing.strokes
            let currentCount = currentStrokes.count
            print("✏️ Current stroke count: \(currentCount), previous: \(previousStrokeCount)")

            // Detect new strokes
            if currentCount > previousStrokeCount {
                // Strokes were added
                print("✏️ NEW STROKES DETECTED: \(currentCount - previousStrokeCount)")
                let newStrokes = Array(currentStrokes.suffix(currentCount - previousStrokeCount))
                for stroke in newStrokes {
                    print("✏️ Calling onStrokeAdded callback")
                    onStrokeAdded(stroke)
                }
            } else if currentCount < previousStrokeCount {
                // Strokes were removed (undo)
                print("✏️ STROKES REMOVED")
                // For now, we'll handle this through the HistoryManager
                // This is just for detection
            }

            previousStrokeCount = currentCount
            drawing = canvasView.drawing
        }

        func canvasViewDidBeginUsingTool(_ canvasView: PKCanvasView) {
            // User started drawing - could notify AI here
        }

        func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) {
            // User finished drawing - AI response window starts
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
