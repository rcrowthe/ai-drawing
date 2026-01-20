//
//  ProfileAdapter.swift
//  AIDrawing
//
//  Adapts AI configuration based on learned user profile
//

import Foundation

class ProfileAdapter {
    private let persistenceService: PersistenceService

    init(persistenceService: PersistenceService = .shared) {
        self.persistenceService = persistenceService
    }

    // MARK: - Configuration Adaptation

    /// Apply learned preferences to AI configuration
    func adaptConfiguration(_ baseConfig: AIConfiguration) -> AIConfiguration {
        guard let profile = try? persistenceService.loadUserProfile() else {
            return baseConfig
        }

        var adapted = baseConfig

        // Adapt lens weights based on learned preferences
        adapted = adaptLensWeights(adapted, profile: profile)

        // Adapt assertiveness based on interaction ratio
        adapted = adaptAssertiveness(adapted, profile: profile)

        // Adapt surprise probability based on reinforcement
        adapted = adaptSurpriseProbability(adapted, profile: profile)

        // Adapt alignment bias based on move type preferences
        adapted = adaptAlignmentBias(adapted, profile: profile)

        return adapted
    }

    // MARK: - Lens Weight Adaptation

    /// Adjust lens weights based on which lenses led to accepted moves
    private func adaptLensWeights(
        _ config: AIConfiguration,
        profile: UserProfile
    ) -> AIConfiguration {
        var adapted = config

        // Apply learned lens weight adjustments (blend with base)
        if let musicianAdjustment = profile.lensWeightAdjustments[.musician] {
            // Blend 70% base + 30% learned
            adapted.musicianWeight = config.musicianWeight * 0.7 + musicianAdjustment * 0.3
        }

        if let painterAdjustment = profile.lensWeightAdjustments[.painter] {
            adapted.painterWeight = config.painterWeight * 0.7 + painterAdjustment * 0.3
        }

        if let physicistAdjustment = profile.lensWeightAdjustments[.physicist] {
            adapted.physicistWeight = config.physicistWeight * 0.7 + physicistAdjustment * 0.3
        }

        // Clamp to reasonable ranges
        adapted.musicianWeight = clamp(adapted.musicianWeight, min: 0.3, max: 2.0)
        adapted.painterWeight = clamp(adapted.painterWeight, min: 0.3, max: 2.0)
        adapted.physicistWeight = clamp(adapted.physicistWeight, min: 0.3, max: 2.0)

        return adapted
    }

    // MARK: - Assertiveness Adaptation

    /// Adjust assertiveness based on AI interaction ratio
    private func adaptAssertiveness(
        _ config: AIConfiguration,
        profile: UserProfile
    ) -> AIConfiguration {
        var adapted = config

        // If user has high AI interaction ratio, they like the AI being active
        // Gradually increase assertiveness
        if profile.averageAIInteractionRatio > 0.8 {
            adapted.assertiveness = min(1.0, config.assertiveness + 0.05)
        }

        // If user has low AI interaction ratio, reduce assertiveness
        else if profile.averageAIInteractionRatio < 0.3 && profile.totalSessions > 5 {
            adapted.assertiveness = max(0.2, config.assertiveness - 0.05)
        }

        // Consider reinforcement ratio
        let totalReinforcements = profile.positiveReinforcementCount + profile.negativeReinforcementCount
        if totalReinforcements > 20 {
            let positiveRatio = Double(profile.positiveReinforcementCount) / Double(totalReinforcements)

            // If user mostly accepts AI moves, increase assertiveness
            if positiveRatio > 0.7 {
                adapted.assertiveness = min(1.0, config.assertiveness + 0.03)
            }
            // If user mostly rejects AI moves, decrease assertiveness
            else if positiveRatio < 0.4 {
                adapted.assertiveness = max(0.2, config.assertiveness - 0.03)
            }
        }

        return adapted
    }

    // MARK: - Surprise Probability Adaptation

    /// Adjust surprise probability based on surprise move acceptance
    private func adaptSurpriseProbability(
        _ config: AIConfiguration,
        profile: UserProfile
    ) -> AIConfiguration {
        var adapted = config

        let surpriseAccepted = profile.moveTypeHistory[.surprise] ?? 0
        let surpriseRejected = profile.moveTypeRejections[.surprise] ?? 0
        let totalSurprises = surpriseAccepted + surpriseRejected

        guard totalSurprises > 5 else { return adapted }

        let acceptanceRate = Double(surpriseAccepted) / Double(totalSurprises)

        // If user likes surprises, increase probability
        if acceptanceRate > 0.7 {
            adapted.surpriseProbability = min(0.3, config.surpriseProbability + 0.02)
        }
        // If user dislikes surprises, decrease probability
        else if acceptanceRate < 0.3 {
            adapted.surpriseProbability = max(0.0, config.surpriseProbability - 0.02)
        }

        return adapted
    }

    // MARK: - Alignment Bias Adaptation

    /// Adjust alignment bias based on move type preferences
    private func adaptAlignmentBias(
        _ config: AIConfiguration,
        profile: UserProfile
    ) -> AIConfiguration {
        var adapted = config

        // Calculate preference for reinforcing vs contrasting moves
        let reinforcingAccepted = (profile.moveTypeHistory[.echo] ?? 0) +
                                   (profile.moveTypeHistory[.structural] ?? 0) +
                                   (profile.moveTypeHistory[.texture] ?? 0)

        let contrastingAccepted = (profile.moveTypeHistory[.contrast] ?? 0) +
                                   (profile.moveTypeHistory[.surprise] ?? 0)

        let totalAccepted = reinforcingAccepted + contrastingAccepted

        guard totalAccepted > 10 else { return adapted }

        let reinforcingRatio = Double(reinforcingAccepted) / Double(totalAccepted)

        // Adjust alignment bias toward user's preference
        if reinforcingRatio > 0.7 {
            // User prefers reinforcing moves (pro mode)
            adapted.alignmentBias = min(1.0, config.alignmentBias + 0.05)
        } else if reinforcingRatio < 0.4 {
            // User prefers contrasting moves (anti mode)
            adapted.alignmentBias = max(0.0, config.alignmentBias - 0.05)
        }

        return adapted
    }

    // MARK: - Utility

    private func clamp(_ value: Double, min minValue: Double, max maxValue: Double) -> Double {
        return min(max(value, minValue), maxValue)
    }

    // MARK: - Profile Analysis

    /// Get insights about user's drawing style
    func getProfileInsights() -> ProfileInsights? {
        guard let profile = try? persistenceService.loadUserProfile() else { return nil }

        let avgVelocity = profile.averageVelocity
        let avgPressure = profile.averagePressure

        // Classify drawing style
        let drawingStyle: DrawingStyle
        if avgVelocity > 200 && avgPressure > 0.7 {
            drawingStyle = .bold
        } else if avgVelocity < 100 && avgPressure < 0.4 {
            drawingStyle = .gentle
        } else if avgPressure > 0.7 {
            drawingStyle = .deliberate
        } else if avgVelocity > 150 {
            drawingStyle = .gestural
        } else {
            drawingStyle = .balanced
        }

        // Calculate AI acceptance rate
        let totalReinforcements = profile.positiveReinforcementCount + profile.negativeReinforcementCount
        let acceptanceRate = totalReinforcements > 0 ?
            Double(profile.positiveReinforcementCount) / Double(totalReinforcements) : 0.5

        // Get most common motifs
        let topMotifs = Array(profile.motifs.prefix(3))

        return ProfileInsights(
            drawingStyle: drawingStyle,
            aiAcceptanceRate: acceptanceRate,
            mostCommonMotifs: topMotifs,
            totalSessions: profile.totalSessions,
            totalDrawingTime: profile.totalDrawingTime
        )
    }
}

// MARK: - Supporting Types

enum DrawingStyle: String {
    case bold = "Bold & Energetic"
    case gentle = "Gentle & Delicate"
    case deliberate = "Deliberate & Controlled"
    case gestural = "Fast & Gestural"
    case balanced = "Balanced"
}

struct ProfileInsights {
    let drawingStyle: DrawingStyle
    let aiAcceptanceRate: Double
    let mostCommonMotifs: [Motif]
    let totalSessions: Int
    let totalDrawingTime: TimeInterval

    var acceptancePercentage: String {
        String(format: "%.0f%%", aiAcceptanceRate * 100)
    }

    var totalDrawingTimeFormatted: String {
        let hours = Int(totalDrawingTime) / 3600
        let minutes = (Int(totalDrawingTime) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}
