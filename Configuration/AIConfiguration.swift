//
//  AIConfiguration.swift
//  AIDrawing
//
//  User-adjustable AI parameters
//

import Foundation

struct AIConfiguration: Codable {
    // Assertiveness: how often AI proposes gestures (0.0 - 1.0)
    var assertiveness: Double = 0.85

    // Surprise probability: frequency of deviation (0.0 - 0.3 recommended)
    var surpriseProbability: Double = 0.15

    // Lens weights: balance between perspectives (0.0 - 2.0)
    var musicianWeight: Double = 1.2
    var painterWeight: Double = 1.2
    var physicistWeight: Double = 1.2

    // Alignment bias: pro vs anti (0.0 = always anti, 1.0 = always pro)
    var alignmentBias: Double = 0.4

    // Idle timeout: seconds before AI goes silent (1.0 - 10.0)
    var idleTimeout: TimeInterval = 3.0

    // Autonomous mode: AI draws even when user is idle
    var autonomousModeEnabled: Bool = false

    /// Create configuration with default values
    init() {}

    /// Create configuration with custom values
    init(
        assertiveness: Double,
        surpriseProbability: Double,
        musicianWeight: Double,
        painterWeight: Double,
        physicistWeight: Double,
        alignmentBias: Double,
        idleTimeout: TimeInterval,
        autonomousModeEnabled: Bool = false
    ) {
        self.assertiveness = assertiveness
        self.surpriseProbability = surpriseProbability
        self.musicianWeight = musicianWeight
        self.painterWeight = painterWeight
        self.physicistWeight = physicistWeight
        self.alignmentBias = alignmentBias
        self.idleTimeout = idleTimeout
        self.autonomousModeEnabled = autonomousModeEnabled
    }
}

// MARK: - Presets

extension AIConfiguration {
    enum Preset {
        case subtleCompanion
        case boldCollaborator
        case contrarian
    }

    /// Subtle AI that rarely intervenes
    static var subtleCompanion: AIConfiguration {
        return AIConfiguration(
            assertiveness: 0.3,
            surpriseProbability: 0.05,
            musicianWeight: 1.5,
            painterWeight: 1.0,
            physicistWeight: 0.5,
            alignmentBias: 0.9,
            idleTimeout: 2.0
        )
    }

    /// Bold AI that frequently contributes
    static var boldCollaborator: AIConfiguration {
        return AIConfiguration(
            assertiveness: 0.8,
            surpriseProbability: 0.2,
            musicianWeight: 1.0,
            painterWeight: 1.2,
            physicistWeight: 1.2,
            alignmentBias: 0.5,
            idleTimeout: 5.0
        )
    }

    /// Contrarian AI that challenges user
    static var contrarian: AIConfiguration {
        return AIConfiguration(
            assertiveness: 0.6,
            surpriseProbability: 0.25,
            musicianWeight: 0.5,
            painterWeight: 1.0,
            physicistWeight: 1.5,
            alignmentBias: 0.2,
            idleTimeout: 4.0
        )
    }
}
