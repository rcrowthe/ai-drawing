//
//  MetalCanvasView.swift
//  AIDrawing
//
//  SwiftUI wrapper for Metal-based touch capture and rendering
//

import SwiftUI
import UIKit

struct MetalCanvasView: UIViewRepresentable {
    let onStrokeBegan: () -> Void
    let onStrokeProgress: ([StrokePoint]) -> Void
    let onStrokeCommitted: (InProgressStroke) -> Void
    let onStrokeCancelled: () -> Void
    let onViewReady: ((TouchCaptureView) -> Void)?  // Callback to expose view reference

    @Binding var drawingColor: UIColor
    @Binding var strokeWidth: CGFloat

    init(
        onStrokeBegan: @escaping () -> Void,
        onStrokeProgress: @escaping ([StrokePoint]) -> Void,
        onStrokeCommitted: @escaping (InProgressStroke) -> Void,
        onStrokeCancelled: @escaping () -> Void,
        drawingColor: Binding<UIColor>,
        strokeWidth: Binding<CGFloat>,
        onViewReady: ((TouchCaptureView) -> Void)? = nil
    ) {
        self.onStrokeBegan = onStrokeBegan
        self.onStrokeProgress = onStrokeProgress
        self.onStrokeCommitted = onStrokeCommitted
        self.onStrokeCancelled = onStrokeCancelled
        self._drawingColor = drawingColor
        self._strokeWidth = strokeWidth
        self.onViewReady = onViewReady
    }

    func makeUIView(context: Context) -> TouchCaptureView {
        print("🎨 MetalCanvasView: makeUIView called")

        let renderer = MetalRenderer()
        let view = TouchCaptureView(renderer: renderer)

        view.touchDelegate = context.coordinator
        view.allowFingerDrawing = true  // Enable for simulator testing
        view.smoothingEnabled = true
        view.decimationDistance = 1.5  // Increased for smoother appearance (was 0.2)

        // Set initial drawing properties
        view.setColor(drawingColor)
        view.setWidth(strokeWidth)

        // Notify parent that view is ready
        onViewReady?(view)

        print("🎨 MetalCanvasView: Touch capture view created and configured")
        return view
    }

    func updateUIView(_ view: TouchCaptureView, context: Context) {
        // Update drawing properties when they change
        view.setColor(drawingColor)
        view.setWidth(strokeWidth)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onStrokeBegan: onStrokeBegan,
            onStrokeProgress: onStrokeProgress,
            onStrokeCommitted: onStrokeCommitted,
            onStrokeCancelled: onStrokeCancelled
        )
    }

    class Coordinator: NSObject, TouchCaptureDelegate {
        let onStrokeBegan: () -> Void
        let onStrokeProgress: ([StrokePoint]) -> Void
        let onStrokeCommitted: (InProgressStroke) -> Void
        let onStrokeCancelled: () -> Void

        init(
            onStrokeBegan: @escaping () -> Void,
            onStrokeProgress: @escaping ([StrokePoint]) -> Void,
            onStrokeCommitted: @escaping (InProgressStroke) -> Void,
            onStrokeCancelled: @escaping () -> Void
        ) {
            self.onStrokeBegan = onStrokeBegan
            self.onStrokeProgress = onStrokeProgress
            self.onStrokeCommitted = onStrokeCommitted
            self.onStrokeCancelled = onStrokeCancelled
        }

        func touchCaptureDidBegin(_ view: TouchCaptureView) {
            print("✏️ Coordinator: Touch began")
            onStrokeBegan()
        }

        func touchCaptureDidUpdate(_ view: TouchCaptureView, deltaPoints: [StrokePoint]) {
            print("✏️ Coordinator: Touch updated with \(deltaPoints.count) delta points")
            onStrokeProgress(deltaPoints)
        }

        func touchCaptureDidEnd(_ view: TouchCaptureView, finalStroke: InProgressStroke) {
            print("✏️ Coordinator: Touch ended, stroke has \(finalStroke.points.count) total points")
            onStrokeCommitted(finalStroke)
        }

        func touchCaptureDidCancel(_ view: TouchCaptureView) {
            print("✏️ Coordinator: Touch cancelled")
            onStrokeCancelled()
        }
    }
}
