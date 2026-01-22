//
//  ControlPanelView.swift
//  AIDrawing
//
//  UI for adjusting AI parameters in real-time
//

import SwiftUI

struct ControlPanelView: View {
    @ObservedObject var viewModel: ControlPanelViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                // Presets Section
                Section {
                    PresetButton(
                        title: "Subtle Companion",
                        description: "Gentle, supportive AI responses",
                        action: { viewModel.applyPreset(.subtleCompanion) }
                    )
                    PresetButton(
                        title: "Bold Collaborator",
                        description: "Active, assertive AI participation",
                        action: { viewModel.applyPreset(.boldCollaborator) }
                    )
                    PresetButton(
                        title: "Contrarian",
                        description: "Challenging, tension-creating AI",
                        action: { viewModel.applyPreset(.contrarian) }
                    )
                } header: {
                    Text("Presets")
                } footer: {
                    Text("Quick configurations for different AI personalities")
                }

                // Assertiveness Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Assertiveness")
                                .font(.headline)
                            Spacer()
                            Text(viewModel.assertivenessPercentage)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Slider(
                            value: Binding(
                                get: { viewModel.configuration.assertiveness },
                                set: { viewModel.updateAssertiveness($0) }
                            ),
                            in: 0...1
                        )

                        Text("How often AI responds to your strokes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Response Frequency")
                }

                // Surprise Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Surprise Probability")
                                .font(.headline)
                            Spacer()
                            Text(viewModel.surpriseProbabilityPercentage)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Slider(
                            value: Binding(
                                get: { viewModel.configuration.surpriseProbability },
                                set: { viewModel.updateSurpriseProbability($0) }
                            ),
                            in: 0...0.3
                        )

                        Text("Chance of unexpected flourishes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Unpredictability")
                }

                // Lens Weights Section
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        // Musician Weight
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Musician")
                                    .font(.subheadline)
                                Spacer()
                                Text(String(format: "%.1f", viewModel.configuration.musicianWeight))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Slider(
                                value: Binding(
                                    get: { viewModel.configuration.musicianWeight },
                                    set: { viewModel.updateMusicianWeight($0) }
                                ),
                                in: 0...2
                            )
                            Text("Rhythm, tempo, timing analysis")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Divider()

                        // Painter Weight
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Painter")
                                    .font(.subheadline)
                                Spacer()
                                Text(String(format: "%.1f", viewModel.configuration.painterWeight))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Slider(
                                value: Binding(
                                    get: { viewModel.configuration.painterWeight },
                                    set: { viewModel.updatePainterWeight($0) }
                                ),
                                in: 0...2
                            )
                            Text("Composition, balance, density analysis")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Divider()

                        // Physicist Weight
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Physicist")
                                    .font(.subheadline)
                                Spacer()
                                Text(String(format: "%.1f", viewModel.configuration.physicistWeight))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Slider(
                                value: Binding(
                                    get: { viewModel.configuration.physicistWeight },
                                    set: { viewModel.updatePhysicistWeight($0) }
                                ),
                                in: 0...2
                            )
                            Text("Forces, energy, dynamics analysis")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Personality Lenses")
                } footer: {
                    Text("Adjust the influence of each personality lens (0 = off, 1 = normal, 2 = doubled)")
                }

                // Alignment Bias Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Alignment Mode")
                                .font(.headline)
                            Spacer()
                            Text(viewModel.alignmentBiasDescription)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Anti")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Slider(
                                value: Binding(
                                    get: { viewModel.configuration.alignmentBias },
                                    set: { viewModel.updateAlignmentBias($0) }
                                ),
                                in: 0...1
                            )

                            Text("Pro")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Text("Pro: Reinforces your patterns | Anti: Creates contrast")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Collaboration Style")
                }

                // Timing Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Idle Timeout")
                                .font(.headline)
                            Spacer()
                            Text(viewModel.idleTimeoutDescription)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Slider(
                            value: Binding(
                                get: { viewModel.configuration.idleTimeout },
                                set: { viewModel.updateIdleTimeout($0) }
                            ),
                            in: 1...10,
                            step: 0.5
                        )

                        Text("Seconds before AI goes idle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Timing")
                }

                // Animation Speed Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Animation Speed")
                                .font(.headline)
                            Spacer()
                            Text(viewModel.animationSpeedDescription)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Slider(
                            value: Binding(
                                get: { viewModel.configuration.animationSpeedMultiplier },
                                set: { viewModel.updateAnimationSpeedMultiplier($0) }
                            ),
                            in: 0.5...3.0,
                            step: 0.1
                        )

                        Text("Speed multiplier for AI drawing animation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Animation")
                }

                // Continuous Drawing Section
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        // Duration
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Duration")
                                    .font(.subheadline)
                                Spacer()
                                Text(viewModel.continuousDrawDurationDescription)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Slider(
                                value: Binding(
                                    get: { viewModel.configuration.continuousDrawDuration },
                                    set: { viewModel.updateContinuousDrawDuration($0) }
                                ),
                                in: 0...30,
                                step: 1.0
                            )
                            Text("How long AI continues drawing (0 = disabled)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Divider()

                        // Interval
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Interval")
                                    .font(.subheadline)
                                Spacer()
                                Text(viewModel.continuousDrawIntervalDescription)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Slider(
                                value: Binding(
                                    get: { viewModel.configuration.continuousDrawInterval },
                                    set: { viewModel.updateContinuousDrawInterval($0) }
                                ),
                                in: 0.1...2.0,
                                step: 0.1
                            )
                            Text("Time between AI strokes")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Divider()

                        // Max Strokes
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Max Strokes")
                                    .font(.subheadline)
                                Spacer()
                                Text(viewModel.continuousDrawMaxStrokesDescription)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Slider(
                                value: Binding(
                                    get: { Double(viewModel.configuration.continuousDrawMaxStrokes) },
                                    set: { viewModel.updateContinuousDrawMaxStrokes(Int($0)) }
                                ),
                                in: 1...100,
                                step: 5
                            )
                            Text("Maximum continuous strokes (safety limit)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Continuous Drawing")
                } footer: {
                    Text("Controls for AI continuous drawing behavior")
                }

                // Color Variation Section
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        // Hue Variation
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Hue Variation")
                                    .font(.subheadline)
                                Spacer()
                                Text(viewModel.colorHueVariationDescription)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Slider(
                                value: Binding(
                                    get: { viewModel.configuration.colorHueVariation },
                                    set: { viewModel.updateColorHueVariation($0) }
                                ),
                                in: 0...360,
                                step: 10
                            )
                            Text("Random hue shift (0-360 degrees)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Divider()

                        // Saturation Variation
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Saturation Variation")
                                    .font(.subheadline)
                                Spacer()
                                Text(viewModel.colorSaturationVariationDescription)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Slider(
                                value: Binding(
                                    get: { viewModel.configuration.colorSaturationVariation },
                                    set: { viewModel.updateColorSaturationVariation($0) }
                                ),
                                in: 0...1,
                                step: 0.05
                            )
                            Text("Random saturation adjustment")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Divider()

                        // Brightness Variation
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Brightness Variation")
                                    .font(.subheadline)
                                Spacer()
                                Text(viewModel.colorBrightnessVariationDescription)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Slider(
                                value: Binding(
                                    get: { viewModel.configuration.colorBrightnessVariation },
                                    set: { viewModel.updateColorBrightnessVariation($0) }
                                ),
                                in: 0...1,
                                step: 0.05
                            )
                            Text("Random brightness adjustment")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Divider()

                        // Opacity Variation
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Opacity Variation")
                                    .font(.subheadline)
                                Spacer()
                                Text(viewModel.colorOpacityVariationDescription)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Slider(
                                value: Binding(
                                    get: { viewModel.configuration.colorOpacityVariation },
                                    set: { viewModel.updateColorOpacityVariation($0) }
                                ),
                                in: 0...1,
                                step: 0.05
                            )
                            Text("Random opacity adjustment")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Color Variation")
                } footer: {
                    Text("Add random variation to AI stroke colors")
                }

                // Reset Section
                Section {
                    Button(role: .destructive) {
                        viewModel.resetToDefault()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Reset to Default")
                            Spacer()
                        }
                    }
                } footer: {
                    Text("Restores all settings to default values")
                }
            }
            .navigationTitle("AI Settings")
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
}

// MARK: - Preset Button Component

struct PresetButton: View {
    let title: String
    let description: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ControlPanelView(
        viewModel: ControlPanelViewModel(
            initialConfiguration: AIConfiguration(),
            persistenceService: PersistenceService(),
            onConfigurationChanged: { _ in }
        )
    )
}
