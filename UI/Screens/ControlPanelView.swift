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
