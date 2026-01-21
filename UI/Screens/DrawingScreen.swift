//
//  DrawingScreen.swift
//  AIDrawing
//
//  Main drawing interface
//

import SwiftUI
import PencilKit

struct DrawingScreen: View {
    @StateObject private var viewModel = DrawingViewModel()
    @State private var showingSettings = false
    @State private var controlPanelViewModel: ControlPanelViewModel?

    // Feature flag: switch between PencilKit and Metal rendering
    @State private var useMetalRenderer = true  // Set to true to enable Metal pipeline

    var body: some View {
        print("🖼️ DrawingScreen body rendering - useMetalRenderer: \(useMetalRenderer)")
        return ZStack {
            // Canvas layer (conditional based on feature flag)
            if useMetalRenderer {
                // NEW: Metal-based streaming canvas
                MetalCanvasView(
                    onStrokeBegan: viewModel.handleMetalStrokeBegan,
                    onStrokeProgress: viewModel.handleMetalStrokeProgress,
                    onStrokeCommitted: viewModel.handleMetalStrokeCommitted,
                    onStrokeCancelled: viewModel.handleMetalStrokeCancelled,
                    drawingColor: $viewModel.metalDrawingColor,
                    strokeWidth: $viewModel.metalStrokeWidth,
                    onViewReady: { touchCaptureView in
                        viewModel.metalCanvasView = touchCaptureView
                        print("🎨 Metal canvas view reference stored in ViewModel")
                    }
                )
                .edgesIgnoringSafeArea(.all)
            } else {
                // LEGACY: PencilKit canvas
                DrawingCanvasView(
                    drawing: $viewModel.pkDrawing,
                    onStrokeAdded: viewModel.handleStrokeAdded,
                    onStrokeRemoved: viewModel.handleStrokeRemoved,
                    tool: viewModel.selectedTool,
                    onDrawingBegan: viewModel.userDidBeginDrawing,
                    onDrawingEnded: viewModel.userDidEndDrawing
                )
                .edgesIgnoringSafeArea(.all)

                // AI Stroke Overlay - only for PencilKit mode
                AIStrokeOverlayView(viewModel: viewModel)
                    .edgesIgnoringSafeArea(.all)
            }

            // AI Activity Indicator (Phase 8)
            VStack {
                HStack {
                    Spacer()
                    AIActivityIndicator(aiState: viewModel.aiState)
                        .padding()
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

                    // Drawing tools (work with both PencilKit and Metal)
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
                    },
                    drawingViewModel: viewModel
                )
            }

            // Auto-start continuous mode if enabled in configuration
            if viewModel.aiConfiguration.continuousModeEnabled {
                print("🎛️ DrawingScreen: Auto-starting continuous drawing (enabled by default)")
                viewModel.startContinuousDrawing()
            }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationView {
                GeneratorSettingsView(
                    configuration: $viewModel.aiConfiguration,
                    onUserColorChanged: {
                        viewModel.updateToolColor()
                    },
                    onContinuousModeChanged: { enabled in
                        print("🎛️ DrawingScreen: onContinuousModeChanged called with: \(enabled)")
                        if enabled {
                            print("🎛️ DrawingScreen: Starting continuous drawing")
                            viewModel.startContinuousDrawing()
                        } else {
                            print("🎛️ DrawingScreen: Stopping continuous drawing")
                            viewModel.stopContinuousDrawing()
                        }
                    },
                    onDrawRateChanged: { rate in
                        viewModel.setContinuousDrawRate(rate)
                    }
                )
            }
        }
    }
}

#Preview {
    DrawingScreen()
}
