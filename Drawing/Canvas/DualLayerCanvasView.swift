//
//  DualLayerCanvasView.swift
//  AIDrawing
//
//  Two-layer canvas system: AI strokes below, user strokes above
//  Ensures user input is ALWAYS captured regardless of AI animation
//

import SwiftUI
import PencilKit

struct DualLayerCanvasView: View {
    @Binding var userDrawing: PKDrawing
    @Binding var aiDrawing: PKDrawing
    let onUserStrokeAdded: (PKStroke) -> Void
    let onUserStrokeRemoved: (PKStroke) -> Void
    let onUserStartedDrawing: (() -> Void)?
    let tool: PKTool

    var body: some View {
        ZStack {
            // LAYER 1 (BOTTOM): AI Canvas - non-interactive, shows only AI strokes
            AICanvasView(drawing: $aiDrawing)

            // LAYER 2 (TOP): User Canvas - interactive, transparent background, shows only user strokes
            DrawingCanvasView(
                drawing: $userDrawing,
                onStrokeAdded: onUserStrokeAdded,
                onStrokeRemoved: onUserStrokeRemoved,
                onUserStartedDrawing: onUserStartedDrawing,
                tool: tool,
                isTransparent: true  // Transparent so AI strokes show through
            )
        }
    }
}

/// Non-interactive canvas for displaying AI strokes only
struct AICanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawing = drawing
        canvas.backgroundColor = .white
        canvas.isOpaque = true
        canvas.isUserInteractionEnabled = false  // Disable all interaction
        canvas.drawingPolicy = .default

        // Disable zoom to prevent interference
        canvas.minimumZoomScale = 1.0
        canvas.maximumZoomScale = 1.0

        print("🎨 AI Canvas setup complete - non-interactive layer")
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        // Update drawing if it changed externally (AI strokes being added)
        if canvas.drawing != drawing {
            canvas.drawing = drawing
        }
    }
}
