//
//  DrawingCanvasView.swift
//  AIDrawing
//
//  SwiftUI wrapper for PKCanvasView
//

import SwiftUI
import PencilKit
import UIKit

// MARK: - DrawingCanvasView

struct DrawingCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    let onStrokeAdded: (PKStroke) -> Void
    let onStrokeRemoved: (PKStroke) -> Void
    let tool: PKTool
    let onDrawingBegan: () -> Void
    let onDrawingEnded: () -> Void

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
            onStrokeRemoved: onStrokeRemoved,
            onDrawingBegan: onDrawingBegan,
            onDrawingEnded: onDrawingEnded
        )
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding var drawing: PKDrawing
        let onStrokeAdded: (PKStroke) -> Void
        let onStrokeRemoved: (PKStroke) -> Void
        let onDrawingBegan: () -> Void
        let onDrawingEnded: () -> Void

        private var previousStrokeCount = 0

        init(
            drawing: Binding<PKDrawing>,
            onStrokeAdded: @escaping (PKStroke) -> Void,
            onStrokeRemoved: @escaping (PKStroke) -> Void,
            onDrawingBegan: @escaping () -> Void,
            onDrawingEnded: @escaping () -> Void
        ) {
            self._drawing = drawing
            self.onStrokeAdded = onStrokeAdded
            self.onStrokeRemoved = onStrokeRemoved
            self.onDrawingBegan = onDrawingBegan
            self.onDrawingEnded = onDrawingEnded
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
            // User started drawing
            print("✏️ User began using tool")
            onDrawingBegan()
        }

        func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) {
            // User finished drawing
            print("✏️ User ended using tool")
            onDrawingEnded()
        }
    }
}

// MARK: - AIStrokeOverlayView

/// UIKit view that renders AI strokes in real-time using Core Graphics
class AIStrokeOverlayUIView: UIView {
    private var activeStrokes: [(path: UIBezierPath, color: UIColor, width: CGFloat)] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.isUserInteractionEnabled = false  // Pass touches through to canvas below
        print("🎭 AIStrokeOverlayUIView.init with frame: \(frame)")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        print("🎭 Overlay layoutSubviews - frame: \(frame), bounds: \(bounds)")
    }

    /// Add an AI stroke to be rendered
    func addStroke(path: PKStrokePath, color: UIColor, width: CGFloat) {
        let bezierPath = UIBezierPath()

        // Convert PKStrokePath to UIBezierPath
        guard path.count > 0 else { return }

        let firstPoint = path[0].location
        bezierPath.move(to: firstPoint)

        for i in 1..<path.count {
            let point = path[i].location
            bezierPath.addLine(to: point)
        }

        activeStrokes.append((path: bezierPath, color: color, width: width))

        // Trigger redraw
        DispatchQueue.main.async {
            self.setNeedsDisplay()
        }

        print("🎭 Overlay: Added stroke, total active: \(activeStrokes.count)")
    }

    /// Clear all active strokes (call this after committing to PKDrawing)
    func clearStrokes() {
        activeStrokes.removeAll()
        DispatchQueue.main.async {
            self.setNeedsDisplay()
        }
        print("🎭 Overlay: Cleared all strokes")
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            print("🎭 Overlay.draw: NO GRAPHICS CONTEXT!")
            return
        }

        print("🎭 Overlay.draw called - drawing \(activeStrokes.count) strokes in rect: \(rect)")

        // Draw each active stroke
        for (index, (path, color, width)) in activeStrokes.enumerated() {
            context.setStrokeColor(color.cgColor)
            context.setLineWidth(width)
            context.setLineCap(.round)
            context.setLineJoin(.round)

            context.addPath(path.cgPath)
            context.strokePath()

            print("🎭 Drew stroke \(index + 1)/\(activeStrokes.count): color=\(color), width=\(width), bounds=\(path.bounds)")
        }
    }
}

/// SwiftUI wrapper for the overlay view
struct AIStrokeOverlayView: UIViewRepresentable {
    @ObservedObject var viewModel: DrawingViewModel

    func makeUIView(context: Context) -> AIStrokeOverlayUIView {
        print("🎭 AIStrokeOverlayView: makeUIView called")
        let view = AIStrokeOverlayUIView()
        return view
    }

    func updateUIView(_ view: AIStrokeOverlayUIView, context: Context) {
        print("🎭 AIStrokeOverlayView.updateUIView called - pending: \(viewModel.pendingOverlayStrokes.count), rendered: \(context.coordinator.renderedCount)")

        // Clear overlay if requested
        if viewModel.shouldClearOverlay {
            print("🎭 Clearing overlay and resetting count")
            view.clearStrokes()
            context.coordinator.renderedCount = 0
            // Reset flag
            DispatchQueue.main.async {
                viewModel.shouldClearOverlay = false
            }
            return
        }

        // Add only NEW strokes that haven't been rendered yet
        let newStrokeCount = viewModel.pendingOverlayStrokes.count - context.coordinator.renderedCount
        if newStrokeCount > 0 {
            print("🎭 Adding \(newStrokeCount) new strokes to overlay")
            let newStrokes = viewModel.pendingOverlayStrokes.suffix(newStrokeCount)
            for (move, _) in newStrokes {
                view.addStroke(path: move.path, color: move.tool.color, width: move.tool.width)
                context.coordinator.renderedCount += 1
            }
            print("🎭 Rendered count now: \(context.coordinator.renderedCount)")
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var renderedCount: Int = 0
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
