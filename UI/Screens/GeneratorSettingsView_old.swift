//
//  GeneratorSettingsView.swift
//  AIDrawing
//
//  Complete settings panel for all AI generator parameters
//

import SwiftUI

struct GeneratorSettingsView: View {
    @Binding var configuration: AIConfiguration
    @Environment(\.dismiss) var dismiss

    // Closure to call when user pen color changes
    var onUserColorChanged: (() -> Void)?

    // Force UI refresh when sliders change
    @State private var refreshID = UUID()

    // Tab selection
    @State private var selectedTab = 0

    // Helper to create binding that refreshes UI
    private func binding<T>(
        get: @escaping () -> T,
        set: @escaping (T) -> Void
    ) -> Binding<T> {
        Binding(
            get: get,
            set: { newValue in
                set(newValue)
                refreshID = UUID()
            }
        )
    }

    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // Tab 1: AI Behavior & Colors
                behaviorAndColorsTab()
                    .tabItem {
                        Label("Behavior", systemImage: "brain.head.profile")
                    }
                    .tag(0)

                // Tab 2: Echo & Structural
                echoStructuralTab()
                    .tabItem {
                        Label("Echo & Structural", systemImage: "waveform")
                    }
                    .tag(1)

                // Tab 3: Contrast & Texture
                contrastTextureTab()
                    .tabItem {
                        Label("Contrast & Texture", systemImage: "scribble")
                    }
                    .tag(2)

                // Tab 4: Predictive & Surprise
                predictiveSurpriseTab()
                    .tabItem {
                        Label("Predictive & Surprise", systemImage: "sparkles")
                    }
                    .tag(3)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Tab 1: Behavior & Colors

    private func behaviorAndColorsTab() -> some View {
        Form {
                // MARK: - AI Configuration
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Assertiveness: \(String(format: "%.2f", configuration.assertiveness))")
                            .font(.headline)
                        Text("How often the AI responds to your strokes (0 = never, 1 = always)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: $configuration.assertiveness, in: 0...1, step: 0.05)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Surprise Probability: \(String(format: "%.2f", configuration.surpriseProbability))")
                            .font(.headline)
                        Text("Frequency of unexpected flourishes like spirals and loops")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: $configuration.surpriseProbability, in: 0...1, step: 0.05)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Alignment Bias: \(String(format: "%.2f", configuration.alignmentBias))")
                            .font(.headline)
                        Text("How much AI reinforces vs contrasts (0 = always contrast, 1 = always reinforce)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: $configuration.alignmentBias, in: 0...1, step: 0.05)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Idle Timeout: \(String(format: "%.1f", configuration.idleTimeout))s")
                            .font(.headline)
                        Text("Seconds of inactivity before AI stops responding")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: $configuration.idleTimeout, in: 0.5...10, step: 0.5)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Musician Weight: \(String(format: "%.1f", configuration.musicianWeight))")
                            .font(.headline)
                        Text("Emphasis on rhythm, tempo, and timing patterns")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: $configuration.musicianWeight, in: 0...3, step: 0.1)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Painter Weight: \(String(format: "%.1f", configuration.painterWeight))")
                            .font(.headline)
                        Text("Emphasis on composition, balance, and spatial density")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: $configuration.painterWeight, in: 0...3, step: 0.1)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Physicist Weight: \(String(format: "%.1f", configuration.physicistWeight))")
                            .font(.headline)
                        Text("Emphasis on forces, energy, and motion dynamics")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: $configuration.physicistWeight, in: 0...3, step: 0.1)
                    }
                } header: {
                    Text("AI Behavior")
                }

                // MARK: - Generator Toggles
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Echo (Cyan)", isOn: $configuration.echoEnabled)
                        Text("Parallel wavy strokes that follow your drawing")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Texture (Orange)", isOn: $configuration.textureEnabled)
                        Text("Hatching, stippling, and dots for detail and shading")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Structural (Cyan)", isOn: $configuration.structuralEnabled)
                        Text("Reinforces shapes, edges, curves, and perspective")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Contrast (Green)", isOn: $configuration.contrastEnabled)
                        Text("Draws in opposing directions to create tension")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Predictive (Magenta)", isOn: $configuration.predictiveEnabled)
                        Text("Anticipates and extends where you'll draw next")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Surprise (Purple)", isOn: $configuration.surpriseEnabled)
                        Text("Unexpected flourishes like spirals, loops, and zigzags")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Enable/Disable Generators")
                }

                // MARK: - Colors
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("User Pen Color")
                            .font(.headline)
                        Text("Color of your drawing strokes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ColorPicker("", selection: Binding(
                            get: { Color(GeneratorColors.userPenColor) },
                            set: {
                                GeneratorColors.userPenColor = UIColor($0)
                                onUserColorChanged?()
                            }
                        ))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Echo Color")
                            .font(.headline)
                        Text("Color of parallel wavy echo strokes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ColorPicker("", selection: Binding(
                            get: { Color(GeneratorColors.echoColor) },
                            set: { GeneratorColors.echoColor = UIColor($0) }
                        ))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Texture Color")
                            .font(.headline)
                        Text("Color of hatching and stippling texture")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ColorPicker("", selection: Binding(
                            get: { Color(GeneratorColors.textureColor) },
                            set: { GeneratorColors.textureColor = UIColor($0) }
                        ))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Structural Color")
                            .font(.headline)
                        Text("Color of shape reinforcement strokes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ColorPicker("", selection: Binding(
                            get: { Color(GeneratorColors.structuralColor) },
                            set: { GeneratorColors.structuralColor = UIColor($0) }
                        ))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Contrast Color")
                            .font(.headline)
                        Text("Color of contrasting tension strokes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ColorPicker("", selection: Binding(
                            get: { Color(GeneratorColors.contrastColor) },
                            set: { GeneratorColors.contrastColor = UIColor($0) }
                        ))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Predictive Color")
                            .font(.headline)
                        Text("Color of anticipatory strokes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ColorPicker("", selection: Binding(
                            get: { Color(GeneratorColors.predictiveColor) },
                            set: { GeneratorColors.predictiveColor = UIColor($0) }
                        ))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Surprise Color")
                            .font(.headline)
                        Text("Color of unexpected flourishes and spirals")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ColorPicker("", selection: Binding(
                            get: { Color(GeneratorColors.surpriseColor) },
                            set: { GeneratorColors.surpriseColor = UIColor($0) }
                        ))
                    }
                } header: {
                    Text("Colors")
                }

                // MARK: - Echo Generator
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Base Offset Wander: \(String(format: "%.0f", GeneratorParameters.Echo.baseOffsetWander))")
                            .font(.headline)
                        Text("Distance from stroke in exploratory mode (pixels)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Echo.baseOffsetWander) },
                            set: { GeneratorParameters.Echo.baseOffsetWander = CGFloat($0) }
                        ), in: 0...100, step: 5)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Base Offset Focus: \(String(format: "%.0f", GeneratorParameters.Echo.baseOffsetFocus))")
                            .font(.headline)
                        Text("Distance from stroke in concentrated mode (pixels)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Echo.baseOffsetFocus) },
                            set: { GeneratorParameters.Echo.baseOffsetFocus = CGFloat($0) }
                        ), in: 0...100, step: 5)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Wave Amplitude: \(String(format: "%.0f", GeneratorParameters.Echo.waveAmplitude))")
                            .font(.headline)
                        Text("How much the echo wiggles (0 = straight parallel)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Echo.waveAmplitude) },
                            set: { GeneratorParameters.Echo.waveAmplitude = CGFloat($0) }
                        ), in: 0...50, step: 1)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Segments: \(GeneratorParameters.Echo.segments)")
                            .font(.headline)
                        Text("Curve smoothness (higher = smoother but slower)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Echo.segments) },
                            set: { GeneratorParameters.Echo.segments = Int($0) }
                        ), in: 2...30, step: 1)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Point Size: \(String(format: "%.1f", GeneratorParameters.Echo.pointSize))")
                            .font(.headline)
                        Text("Thickness of individual stroke points")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Echo.pointSize) },
                            set: { GeneratorParameters.Echo.pointSize = CGFloat($0) }
                        ), in: 1...20, step: 0.5)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Stroke Width: \(String(format: "%.1f", GeneratorParameters.Echo.strokeWidth))")
                            .font(.headline)
                        Text("Overall line thickness")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Echo.strokeWidth) },
                            set: { GeneratorParameters.Echo.strokeWidth = CGFloat($0) }
                        ), in: 1...20, step: 0.5)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Opacity: \(String(format: "%.2f", GeneratorParameters.Echo.opacity))")
                            .font(.headline)
                        Text("Transparency (0 = invisible, 1 = fully opaque)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Echo.opacity) },
                            set: { GeneratorParameters.Echo.opacity = CGFloat($0) }
                        ), in: 0...1, step: 0.05)
                    }
                } header: {
                    Text("Echo Generator (Cyan)")
                }

                // MARK: - Structural Generator
                Section {
                    Text("Edge Reinforcement")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Offset Wander: \(String(format: "%.0f", GeneratorParameters.Structural.Edge.offsetWander))")
                            .font(.headline)
                        Text("Distance for parallel edges in wander mode")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Structural.Edge.offsetWander) },
                            set: { GeneratorParameters.Structural.Edge.offsetWander = CGFloat($0) }
                        ), in: 0...100, step: 5)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Offset Focus: \(String(format: "%.0f", GeneratorParameters.Structural.Edge.offsetFocus))")
                            .font(.headline)
                        Text("Distance for parallel edges in focus mode")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Structural.Edge.offsetFocus) },
                            set: { GeneratorParameters.Structural.Edge.offsetFocus = CGFloat($0) }
                        ), in: 0...100, step: 5)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Wobble Amplitude: \(String(format: "%.0f", GeneratorParameters.Structural.Edge.wobbleAmplitude))")
                            .font(.headline)
                        Text("Organic variation in edge lines (0 = perfectly straight)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Structural.Edge.wobbleAmplitude) },
                            set: { GeneratorParameters.Structural.Edge.wobbleAmplitude = CGFloat($0) }
                        ), in: 0...20, step: 1)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Edge Segments: \(GeneratorParameters.Structural.Edge.segments)")
                            .font(.headline)
                        Text("Number of points in edge reinforcement")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Structural.Edge.segments) },
                            set: { GeneratorParameters.Structural.Edge.segments = Int($0) }
                        ), in: 2...30, step: 1)
                    }

                    Text("Curve Reinforcement")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Base Offset: \(String(format: "%.0f", GeneratorParameters.Structural.Curve.baseOffset))")
                            .font(.headline)
                        Text("Base distance from curved strokes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Structural.Curve.baseOffset) },
                            set: { GeneratorParameters.Structural.Curve.baseOffset = CGFloat($0) }
                        ), in: 0...50, step: 1)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Arc Amplitude: \(String(format: "%.0f", GeneratorParameters.Structural.Curve.arcAmplitude))")
                            .font(.headline)
                        Text("How much reinforcement curves bulge (0 = parallel)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Structural.Curve.arcAmplitude) },
                            set: { GeneratorParameters.Structural.Curve.arcAmplitude = CGFloat($0) }
                        ), in: 0...30, step: 1)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Curve Segments: \(GeneratorParameters.Structural.Curve.segments)")
                            .font(.headline)
                        Text("Smoothness of curved reinforcement")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Structural.Curve.segments) },
                            set: { GeneratorParameters.Structural.Curve.segments = Int($0) }
                        ), in: 2...30, step: 1)
                    }
                } header: {
                    Text("Structural Generator (Cyan)")
                }

                // MARK: - Contrast Generator
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Length Multiplier: \(String(format: "%.2f", GeneratorParameters.Contrast.lengthMultiplier))")
                            .font(.headline)
                        Text("Contrast stroke length as fraction of your stroke")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Contrast.lengthMultiplier) },
                            set: { GeneratorParameters.Contrast.lengthMultiplier = CGFloat($0) }
                        ), in: 0.1...2, step: 0.1)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Wave Amplitude: \(String(format: "%.0f", GeneratorParameters.Contrast.waveAmplitude))")
                            .font(.headline)
                        Text("Curvature of contrast strokes (0 = straight line)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Contrast.waveAmplitude) },
                            set: { GeneratorParameters.Contrast.waveAmplitude = CGFloat($0) }
                        ), in: 0...50, step: 1)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Segments: \(GeneratorParameters.Contrast.segments)")
                            .font(.headline)
                        Text("Smoothness of contrast curves")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Contrast.segments) },
                            set: { GeneratorParameters.Contrast.segments = Int($0) }
                        ), in: 2...30, step: 1)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Point Size: \(String(format: "%.1f", GeneratorParameters.Contrast.pointSize))")
                            .font(.headline)
                        Text("Thickness of stroke points")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Contrast.pointSize) },
                            set: { GeneratorParameters.Contrast.pointSize = CGFloat($0) }
                        ), in: 1...20, step: 0.5)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Stroke Width: \(String(format: "%.1f", GeneratorParameters.Contrast.strokeWidth))")
                            .font(.headline)
                        Text("Overall line thickness")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Contrast.strokeWidth) },
                            set: { GeneratorParameters.Contrast.strokeWidth = CGFloat($0) }
                        ), in: 1...20, step: 0.5)
                    }
                } header: {
                    Text("Contrast Generator (Green)")
                }

                // MARK: - Texture Generator
                Section {
                    Text("Hatching (Cross-hatch lines)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Line Count Wander: \(GeneratorParameters.Texture.Hatching.lineCountWander)")
                            .font(.headline)
                        Text("Number of parallel lines in wander mode")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Texture.Hatching.lineCountWander) },
                            set: { GeneratorParameters.Texture.Hatching.lineCountWander = Int($0) }
                        ), in: 0...10, step: 1)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Line Count Focus: \(GeneratorParameters.Texture.Hatching.lineCountFocus)")
                            .font(.headline)
                        Text("Number of parallel lines in focus mode")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Texture.Hatching.lineCountFocus) },
                            set: { GeneratorParameters.Texture.Hatching.lineCountFocus = Int($0) }
                        ), in: 0...10, step: 1)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Spacing Wander: \(String(format: "%.0f", GeneratorParameters.Texture.Hatching.spacingWander))")
                            .font(.headline)
                        Text("Pixels between hatch lines in wander mode")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Texture.Hatching.spacingWander) },
                            set: { GeneratorParameters.Texture.Hatching.spacingWander = CGFloat($0) }
                        ), in: 1...50, step: 1)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Spacing Focus: \(String(format: "%.0f", GeneratorParameters.Texture.Hatching.spacingFocus))")
                            .font(.headline)
                        Text("Pixels between hatch lines in focus mode")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Texture.Hatching.spacingFocus) },
                            set: { GeneratorParameters.Texture.Hatching.spacingFocus = CGFloat($0) }
                        ), in: 1...50, step: 1)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Length Multiplier: \(String(format: "%.2f", GeneratorParameters.Texture.Hatching.lengthMultiplier))")
                            .font(.headline)
                        Text("Hatch line length as fraction of bounding box")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Texture.Hatching.lengthMultiplier) },
                            set: { GeneratorParameters.Texture.Hatching.lengthMultiplier = CGFloat($0) }
                        ), in: 0.05...1, step: 0.05)
                    }

                    Text("Stippling (Random dots)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dot Count Wander: \(GeneratorParameters.Texture.Stippling.dotCountWander)")
                            .font(.headline)
                        Text("Number of random dots in wander mode")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Texture.Stippling.dotCountWander) },
                            set: { GeneratorParameters.Texture.Stippling.dotCountWander = Int($0) }
                        ), in: 0...30, step: 1)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dot Count Focus: \(GeneratorParameters.Texture.Stippling.dotCountFocus)")
                            .font(.headline)
                        Text("Number of random dots in focus mode")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Texture.Stippling.dotCountFocus) },
                            set: { GeneratorParameters.Texture.Stippling.dotCountFocus = Int($0) }
                        ), in: 0...30, step: 1)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Radius Multiplier: \(String(format: "%.2f", GeneratorParameters.Texture.Stippling.radiusMultiplier))")
                            .font(.headline)
                        Text("Scatter radius as fraction of bounding box")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Texture.Stippling.radiusMultiplier) },
                            set: { GeneratorParameters.Texture.Stippling.radiusMultiplier = CGFloat($0) }
                        ), in: 0.1...2, step: 0.1)
                    }

                    Text("Dots (Along path)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dot Count: \(GeneratorParameters.Texture.Dots.dotCount)")
                            .font(.headline)
                        Text("Number of dots placed along stroke path")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Texture.Dots.dotCount) },
                            set: { GeneratorParameters.Texture.Dots.dotCount = Int($0) }
                        ), in: 1...20, step: 1)
                    }
                } header: {
                    Text("Texture Generator (Orange)")
                }

                // MARK: - Predictive Generator
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Projection Distance: \(String(format: "%.0f", GeneratorParameters.Predictive.projectionDistance))")
                            .font(.headline)
                        Text("How far ahead to project your next stroke (pixels)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Predictive.projectionDistance) },
                            set: { GeneratorParameters.Predictive.projectionDistance = CGFloat($0) }
                        ), in: 10...200, step: 5)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Segments: \(GeneratorParameters.Predictive.segments)")
                            .font(.headline)
                        Text("Smoothness of predictive stroke")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Predictive.segments) },
                            set: { GeneratorParameters.Predictive.segments = Int($0) }
                        ), in: 2...30, step: 1)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Point Size: \(String(format: "%.1f", GeneratorParameters.Predictive.pointSize))")
                            .font(.headline)
                        Text("Thickness of stroke points")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Predictive.pointSize) },
                            set: { GeneratorParameters.Predictive.pointSize = CGFloat($0) }
                        ), in: 1...20, step: 0.5)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Stroke Width: \(String(format: "%.1f", GeneratorParameters.Predictive.strokeWidth))")
                            .font(.headline)
                        Text("Overall line thickness")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Predictive.strokeWidth) },
                            set: { GeneratorParameters.Predictive.strokeWidth = CGFloat($0) }
                        ), in: 1...20, step: 0.5)
                    }
                } header: {
                    Text("Predictive Generator (Magenta)")
                }

                // MARK: - Surprise Generator
                Section {
                    Text("Spiral")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Turns: \(String(format: "%.2f", GeneratorParameters.Surprise.Spiral.turns))")
                            .font(.headline)
                        Text("Number of rotations in spiral")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Surprise.Spiral.turns) },
                            set: { GeneratorParameters.Surprise.Spiral.turns = CGFloat($0) }
                        ), in: 0.25...5, step: 0.25)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Max Radius: \(String(format: "%.0f", GeneratorParameters.Surprise.Spiral.maxRadius))")
                            .font(.headline)
                        Text("Maximum size of spiral (pixels)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Surprise.Spiral.maxRadius) },
                            set: { GeneratorParameters.Surprise.Spiral.maxRadius = CGFloat($0) }
                        ), in: 10...100, step: 5)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Segments: \(GeneratorParameters.Surprise.Spiral.segments)")
                            .font(.headline)
                        Text("Smoothness of spiral curve")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Surprise.Spiral.segments) },
                            set: { GeneratorParameters.Surprise.Spiral.segments = Int($0) }
                        ), in: 4...50, step: 1)
                    }

                    Text("Zigzag")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Zig Count: \(GeneratorParameters.Surprise.Zigzag.zigCount)")
                            .font(.headline)
                        Text("Number of back-and-forth zigs")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Surprise.Zigzag.zigCount) },
                            set: { GeneratorParameters.Surprise.Zigzag.zigCount = Int($0) }
                        ), in: 1...10, step: 1)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Zig Width: \(String(format: "%.0f", GeneratorParameters.Surprise.Zigzag.zigWidth))")
                            .font(.headline)
                        Text("Height of each zig (pixels)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Surprise.Zigzag.zigWidth) },
                            set: { GeneratorParameters.Surprise.Zigzag.zigWidth = CGFloat($0) }
                        ), in: 5...50, step: 5)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Zig Length: \(String(format: "%.0f", GeneratorParameters.Surprise.Zigzag.zigLength))")
                            .font(.headline)
                        Text("Horizontal spacing between zigs (pixels)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Surprise.Zigzag.zigLength) },
                            set: { GeneratorParameters.Surprise.Zigzag.zigLength = CGFloat($0) }
                        ), in: 5...50, step: 5)
                    }

                    Text("Loop")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Radius: \(String(format: "%.0f", GeneratorParameters.Surprise.Loop.radius))")
                            .font(.headline)
                        Text("Size of circular loop (pixels)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Surprise.Loop.radius) },
                            set: { GeneratorParameters.Surprise.Loop.radius = CGFloat($0) }
                        ), in: 5...80, step: 5)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Segments: \(GeneratorParameters.Surprise.Loop.segments)")
                            .font(.headline)
                        Text("Smoothness of loop (higher = rounder)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Surprise.Loop.segments) },
                            set: { GeneratorParameters.Surprise.Loop.segments = Int($0) }
                        ), in: 4...30, step: 1)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Point Size: \(String(format: "%.1f", GeneratorParameters.Surprise.pointSize))")
                            .font(.headline)
                        Text("Thickness of stroke points")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Surprise.pointSize) },
                            set: { GeneratorParameters.Surprise.pointSize = CGFloat($0) }
                        ), in: 1...20, step: 0.5)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Stroke Width: \(String(format: "%.1f", GeneratorParameters.Surprise.strokeWidth))")
                            .font(.headline)
                        Text("Overall line thickness")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: binding(
                            get: { Double(GeneratorParameters.Surprise.strokeWidth) },
                            set: { GeneratorParameters.Surprise.strokeWidth = CGFloat($0) }
                        ), in: 1...20, step: 0.5)
                    }
                } header: {
                    Text("Surprise Generator (Purple)")
                }

                // MARK: - Reset Button
                Section {
                    Button("Reset All to Defaults", role: .destructive) {
                        resetToDefaults()
                    }
                }
            }
            .navigationTitle("Generator Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func resetToDefaults() {
        // Reset all parameters to original values
        GeneratorParameters.Echo.baseOffsetWander = 30.0
        GeneratorParameters.Echo.baseOffsetFocus = 15.0
        GeneratorParameters.Echo.waveAmplitude = 8.0
        GeneratorParameters.Echo.segments = 12
        GeneratorParameters.Echo.pointSize = 3.0
        GeneratorParameters.Echo.strokeWidth = 3.0
        GeneratorParameters.Echo.opacity = 1.0

        // Add all other defaults...
        configuration = AIConfiguration()
    }
}
