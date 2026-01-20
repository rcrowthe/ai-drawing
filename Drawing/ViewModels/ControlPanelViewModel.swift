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
}
