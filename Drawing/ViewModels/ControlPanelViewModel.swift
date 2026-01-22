//
//  ControlPanelViewModel.swift
//  AIDrawing
//
//  View model for AI control panel with real-time parameter updates
//

import Foundation
import Combine

class ControlPanelViewModel: ObservableObject {
    @Published var configuration: AIConfiguration

    private let configurationChanged: (AIConfiguration) -> Void
    private let persistenceService: PersistenceService
    private var cancellables = Set<AnyCancellable>()

    init(
        initialConfiguration: AIConfiguration,
        persistenceService: PersistenceService,
        onConfigurationChanged: @escaping (AIConfiguration) -> Void
    ) {
        self.configuration = initialConfiguration
        self.persistenceService = persistenceService
        self.configurationChanged = onConfigurationChanged

        // Observe configuration changes and propagate them
        setupConfigurationObserver()
    }

    // MARK: - Configuration Updates

    func updateAssertiveness(_ value: Double) {
        configuration.assertiveness = value
        notifyConfigurationChanged()
    }

    func updateSurpriseProbability(_ value: Double) {
        configuration.surpriseProbability = value
        notifyConfigurationChanged()
    }

    func updateMusicianWeight(_ value: Double) {
        configuration.musicianWeight = value
        notifyConfigurationChanged()
    }

    func updatePainterWeight(_ value: Double) {
        configuration.painterWeight = value
        notifyConfigurationChanged()
    }

    func updatePhysicistWeight(_ value: Double) {
        configuration.physicistWeight = value
        notifyConfigurationChanged()
    }

    func updateAlignmentBias(_ value: Double) {
        configuration.alignmentBias = value
        notifyConfigurationChanged()
    }

    func updateIdleTimeout(_ value: TimeInterval) {
        configuration.idleTimeout = value
        notifyConfigurationChanged()
    }

    // MARK: - Continuous Drawing Updates

    func updateContinuousDrawDuration(_ value: Double) {
        configuration.continuousDrawDuration = value
        notifyConfigurationChanged()
    }

    func updateContinuousDrawInterval(_ value: Double) {
        configuration.continuousDrawInterval = value
        notifyConfigurationChanged()
    }

    func updateContinuousDrawMaxStrokes(_ value: Int) {
        configuration.continuousDrawMaxStrokes = value
        notifyConfigurationChanged()
    }

    // MARK: - Color Variation Updates

    func updateColorHueVariation(_ value: Double) {
        configuration.colorHueVariation = value
        notifyConfigurationChanged()
    }

    func updateColorSaturationVariation(_ value: Double) {
        configuration.colorSaturationVariation = value
        notifyConfigurationChanged()
    }

    func updateColorBrightnessVariation(_ value: Double) {
        configuration.colorBrightnessVariation = value
        notifyConfigurationChanged()
    }

    func updateColorOpacityVariation(_ value: Double) {
        configuration.colorOpacityVariation = value
        notifyConfigurationChanged()
    }

    // MARK: - Animation Speed Update

    func updateAnimationSpeedMultiplier(_ value: Double) {
        configuration.animationSpeedMultiplier = value
        notifyConfigurationChanged()
    }

    // MARK: - Presets

    func applyPreset(_ preset: AIConfiguration.Preset) {
        switch preset {
        case .subtleCompanion:
            configuration = AIConfiguration.subtleCompanion
        case .boldCollaborator:
            configuration = AIConfiguration.boldCollaborator
        case .contrarian:
            configuration = AIConfiguration.contrarian
        }
        notifyConfigurationChanged()
    }

    func resetToDefault() {
        configuration = AIConfiguration()
        notifyConfigurationChanged()
    }

    // MARK: - Private Helpers

    private func setupConfigurationObserver() {
        // Debounce configuration changes to avoid excessive saves
        $configuration
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] config in
                self?.persistenceService.saveConfiguration(config)
            }
            .store(in: &cancellables)
    }

    private func notifyConfigurationChanged() {
        configurationChanged(configuration)
    }

    // MARK: - Computed Properties

    var assertivenessPercentage: String {
        String(format: "%.0f%%", configuration.assertiveness * 100)
    }

    var surpriseProbabilityPercentage: String {
        String(format: "%.0f%%", configuration.surpriseProbability * 100)
    }

    var alignmentBiasDescription: String {
        if configuration.alignmentBias < 0.3 {
            return "Anti (Contrasting)"
        } else if configuration.alignmentBias > 0.7 {
            return "Pro (Reinforcing)"
        } else {
            return "Balanced"
        }
    }

    var idleTimeoutDescription: String {
        String(format: "%.1fs", configuration.idleTimeout)
    }

    var continuousDrawDurationDescription: String {
        String(format: "%.1fs", configuration.continuousDrawDuration)
    }

    var continuousDrawIntervalDescription: String {
        String(format: "%.2fs", configuration.continuousDrawInterval)
    }

    var continuousDrawMaxStrokesDescription: String {
        String(format: "%d strokes", configuration.continuousDrawMaxStrokes)
    }

    var colorHueVariationDescription: String {
        String(format: "%.0f°", configuration.colorHueVariation)
    }

    var colorSaturationVariationDescription: String {
        String(format: "%.0f%%", configuration.colorSaturationVariation * 100)
    }

    var colorBrightnessVariationDescription: String {
        String(format: "%.0f%%", configuration.colorBrightnessVariation * 100)
    }

    var colorOpacityVariationDescription: String {
        String(format: "%.0f%%", configuration.colorOpacityVariation * 100)
    }

    var animationSpeedDescription: String {
        String(format: "%.1fx", configuration.animationSpeedMultiplier)
    }
}
