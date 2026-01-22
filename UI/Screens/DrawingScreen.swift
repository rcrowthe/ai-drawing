//
//  DrawingScreen.swift
//  AIDrawing
//
//  Main drawing interface
//

import SwiftUI
import PencilKit
import UIKit

struct DrawingScreen: View {
    @StateObject private var viewModel = DrawingViewModel()
    @State private var showingSettings = false
    @State private var controlPanelViewModel: ControlPanelViewModel?

    var body: some View {
        return ZStack {
            // DUAL-LAYER CANVAS SYSTEM FOR RELIABLE USER INPUT
            // Layer 1 (Bottom): AI strokes only - non-interactive, synchronized zoom
            AICanvasLayer(
                drawing: $viewModel.aiPKDrawing,
                zoomScale: $viewModel.canvasZoomScale,
                contentOffset: $viewModel.canvasContentOffset
            )

            // Layer 2 (Top): User strokes only - always interactive, transparent
            DrawingCanvasView(
                drawing: $viewModel.userPKDrawing,
                onStrokeAdded: viewModel.handleStrokeAdded,
                onStrokeRemoved: viewModel.handleStrokeRemoved,
                onUserStartedDrawing: viewModel.handleUserStartedDrawing,
                tool: viewModel.selectedTool,
                isTransparent: true,  // Transparent to show AI strokes below
                zoomScale: $viewModel.canvasZoomScale,
                contentOffset: $viewModel.canvasContentOffset,
                canvasBounds: $viewModel.canvasBounds
            )
            .edgesIgnoringSafeArea(.all)

            // AI Activity Indicator (Phase 8)
            VStack {
                HStack {
                    Spacer()
                    AIActivityIndicator(aiState: viewModel.aiState)
                        .padding()
                }
                Spacer()
            }

            // AI Status Indicator (shows mode, speeds, etc.)
            VStack {
                HStack {
                    AIStatusIndicator(
                        aiState: viewModel.aiState,
                        userSpeed: viewModel.userSpeedText,
                        aiSpeed: viewModel.aiSpeedText,
                        lastMoveType: viewModel.lastMoveType
                    )
                    .padding()
                    Spacer()
                }
                Spacer()
            }

            // Toolbar overlay
            VStack {
                Spacer()

                HStack(spacing: 20) {
                    // Undo button
                    Button(action: viewModel.undo) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.title2)
                            .foregroundColor(viewModel.canUndo ? .primary : .gray)
                    }
                    .disabled(!viewModel.canUndo)

                    // Redo button
                    Button(action: viewModel.redo) {
                        Image(systemName: "arrow.uturn.forward")
                            .font(.title2)
                            .foregroundColor(viewModel.canRedo ? .primary : .gray)
                    }
                    .disabled(!viewModel.canRedo)

                    Spacer()

                    // Pen tool
                    Button(action: viewModel.selectPenTool) {
                        Image(systemName: "pencil")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }

                    // Marker tool
                    Button(action: viewModel.selectMarkerTool) {
                        Image(systemName: "highlighter")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }

                    // Eraser tool
                    Button(action: viewModel.selectEraserTool) {
                        Image(systemName: "eraser")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    // AI Visibility Toggle (Phase 8)
                    Button(action: viewModel.toggleAIVisibility) {
                        Image(systemName: viewModel.showAIStrokes ? "eye.fill" : "eye.slash")
                            .font(.title2)
                            .foregroundColor(viewModel.showAIStrokes ? .blue : .gray)
                    }

                    // New session
                    Button(action: viewModel.newSession) {
                        Image(systemName: "doc")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }

                    // Settings
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(uiColor: .systemBackground))
                        .shadow(radius: 8)
                )
                .padding()
            }
        }
        .onAppear {
            // Initialize control panel view model when view appears
            if controlPanelViewModel == nil {
                controlPanelViewModel = ControlPanelViewModel(
                    initialConfiguration: viewModel.aiConfiguration,
                    persistenceService: PersistenceService.shared,
                    onConfigurationChanged: { newConfig in
                        viewModel.updateConfiguration(newConfig)
                    }
                )
            }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationView {
                GeneratorSettingsView(
                    configuration: $viewModel.aiConfiguration,
                    onUserColorChanged: {
                        viewModel.updateToolColor()
                    }
                )
            }
        }
    }
}

/// Non-interactive canvas layer for displaying AI strokes below user layer
struct AICanvasLayer: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    @Binding var zoomScale: CGFloat
    @Binding var contentOffset: CGPoint

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawing = drawing
        canvas.backgroundColor = .white
        canvas.isOpaque = true
        canvas.isUserInteractionEnabled = true  // MUST be true to allow programmatic scroll/zoom
        canvas.drawingPolicy = .default

        // CRITICAL: Disable automatic content inset adjustments
        canvas.contentInsetAdjustmentBehavior = .never
        canvas.automaticallyAdjustsScrollIndicatorInsets = false

        // Set a large explicit content size matching user canvas
        let largeContentSize = CGSize(width: 4000, height: 4000)
        canvas.contentSize = largeContentSize

        // Zero out insets
        canvas.contentInset = .zero
        canvas.scrollIndicatorInsets = .zero

        // Match zoom configuration of user canvas
        canvas.minimumZoomScale = 0.5
        canvas.maximumZoomScale = 3.0
        canvas.zoomScale = zoomScale

        // CRITICAL: Keep isScrollEnabled = TRUE to allow programmatic changes
        // But disable ALL gesture recognizers to prevent user interaction
        canvas.isScrollEnabled = true  // MUST be true for programmatic zoom/pan
        canvas.panGestureRecognizer.isEnabled = false  // Disable user pan
        canvas.pinchGestureRecognizer?.isEnabled = false  // Disable user pinch

        // Disable ANY other gestures that might interfere
        for recognizer in canvas.gestureRecognizers ?? [] {
            recognizer.isEnabled = false
        }

        print("🎨 AI Canvas Layer created - gestures disabled, programmatic scroll ENABLED")
        print("🎨 AI Canvas bounds: \(canvas.bounds)")
        print("🎨 AI Canvas contentSize: \(canvas.contentSize)")
        print("🎨 AI Canvas contentOffset: \(canvas.contentOffset)")
        print("🎨 AI Canvas contentInset: \(canvas.contentInset)")
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        // ALWAYS update drawing - comparison can be unreliable with PKDrawing
        canvas.drawing = drawing

        let currentZoom = canvas.zoomScale
        let currentOffset = canvas.contentOffset
        let targetZoom = zoomScale
        let targetOffset = contentOffset

        // FORCE sync zoom and pan - use setZoomScale:animated:false to bypass scroll view's animation logic
        if abs(currentZoom - targetZoom) > 0.001 {
            canvas.setZoomScale(zoomScale, animated: false)
        }

        // FORCE contentOffset update
        if abs(currentOffset.x - targetOffset.x) > 0.5 || abs(currentOffset.y - targetOffset.y) > 0.5 {
            canvas.contentOffset = contentOffset
        }
    }
}

#Preview {
    DrawingScreen()
}
