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

    var body: some View {
        print("🖼️ DrawingScreen body rendering")
        return ZStack {
            // Main canvas
            DrawingCanvasView(
                drawing: $viewModel.pkDrawing,
                onStrokeAdded: viewModel.handleStrokeAdded,
                onStrokeRemoved: viewModel.handleStrokeRemoved,
                onUserStartedDrawing: viewModel.handleUserStartedDrawing,
                tool: viewModel.selectedTool
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

#Preview {
    DrawingScreen()
}
