//
//  BehaviorTracker.swift
//  AIDrawing
//
//  Tracks user behavior patterns for AI learning and adaptation
//

import Foundation
import CoreGraphics

class BehaviorTracker {
    private let persistenceService: PersistenceService

    init(persistenceService: PersistenceService = .shared) {
        self.persistenceService = persistenceService
    }

    // MARK: - Stroke Analysis

    /// Record a user stroke for behavioral analysis
    func recordUserStroke(_ stroke: Stroke, session: DrawingSession) {
        guard let profile = try? persistenceService.loadUserProfile() else { return }

        var updatedProfile = profile

        // Update running averages
        updatedProfile.totalStrokes += 1
        updatedProfile.averageVelocity = updateRunningAverage(
            current: updatedProfile.averageVelocity,
            newValue: stroke.avgVelocity,
            count: updatedProfile.totalStrokes
        )

        updatedProfile.averagePressure = updateRunningAverage(
            current: updatedProfile.averagePressure,
            newValue: stroke.avgPressure,
            count: updatedProfile.totalStrokes
        )

        updatedProfile.averageStrokeLength = updateRunningAverage(
            current: updatedProfile.averageStrokeLength,
            newValue: stroke.length,
            count: updatedProfile.totalStrokes
        )

        // Update preferred density
        let currentDensity = session.calculateDensity()
        updatedProfile.preferredDensity = updateRunningAverage(
            current: updatedProfile.preferredDensity,
            newValue: currentDensity,
            count: updatedProfile.totalStrokes
        )

        try? persistenceService.saveUserProfile(updatedProfile)
    }

    // MARK: - Reinforcement Tracking

    /// Record positive reinforcement (AI move was kept)
    func recordPositiveReinforcement(for moveType: AIMoveType) {
        guard var profile = try? persistenceService.loadUserProfile() else { return }

        profile.positiveReinforcementCount += 1

        // Track which move types are accepted
        profile.moveTypeHistory[moveType, default: 0] += 1

        try? persistenceService.saveUserProfile(profile)
    }

    /// Record negative reinforcement (AI move was undone)
    func recordNegativeReinforcement(for moveType: AIMoveType) {
        guard var profile = try? persistenceService.loadUserProfile() else { return }

        profile.negativeReinforcementCount += 1

        // Track which move types are rejected
        profile.moveTypeRejections[moveType, default: 0] += 1

        try? persistenceService.saveUserProfile(profile)
    }

    // MARK: - Lens Preference Tracking

    /// Analyze which lens suggestions lead to accepted AI moves
    func recordLensInfluence(
        dominantLens: String, // "musician", "painter", "physicist"
        moveType: AIMoveType,
        wasAccepted: Bool
    ) {
        guard var profile = try? persistenceService.loadUserProfile() else { return }

        if wasAccepted {
            // Increase weight for lens that produced good results
            switch dominantLens {
            case "musician":
                profile.lensWeightAdjustments[.musician] =
                    (profile.lensWeightAdjustments[.musician] ?? 1.0) + 0.05
            case "painter":
                profile.lensWeightAdjustments[.painter] =
                    (profile.lensWeightAdjustments[.painter] ?? 1.0) + 0.05
            case "physicist":
                profile.lensWeightAdjustments[.physicist] =
                    (profile.lensWeightAdjustments[.physicist] ?? 1.0) + 0.05
            default:
                break
            }

            // Cap at 2.0x weight
            for lens in LensType.allCases {
                if let weight = profile.lensWeightAdjustments[lens], weight > 2.0 {
                    profile.lensWeightAdjustments[lens] = 2.0
                }
            }
        } else {
            // Slightly decrease weight for lens that produced rejected results
            switch dominantLens {
            case "musician":
                profile.lensWeightAdjustments[.musician] =
                    max(0.5, (profile.lensWeightAdjustments[.musician] ?? 1.0) - 0.02)
            case "painter":
                profile.lensWeightAdjustments[.painter] =
                    max(0.5, (profile.lensWeightAdjustments[.painter] ?? 1.0) - 0.02)
            case "physicist":
                profile.lensWeightAdjustments[.physicist] =
                    max(0.5, (profile.lensWeightAdjustments[.physicist] ?? 1.0) - 0.02)
            default:
                break
            }
        }

        try? persistenceService.saveUserProfile(profile)
    }

    // MARK: - Session Statistics

    /// Record session-level statistics
    func recordSessionStats(session: DrawingSession) {
        guard var profile = try? persistenceService.loadUserProfile() else { return }

        profile.totalSessions += 1

        let userStrokes = session.strokes.filter { $0.source == .user }
        let aiStrokes = session.strokes.filter { $0.source == .ai }

        let sessionDuration = session.strokes.last?.timestamp.timeIntervalSince(
            session.strokes.first?.timestamp ?? Date()
        ) ?? 0

        profile.totalDrawingTime += sessionDuration
        profile.averageSessionDuration = profile.totalDrawingTime / Double(profile.totalSessions)

        // Track AI interaction ratio
        let interactionRatio = Double(aiStrokes.count) / max(1.0, Double(userStrokes.count))
        profile.averageAIInteractionRatio = updateRunningAverage(
            current: profile.averageAIInteractionRatio,
            newValue: interactionRatio,
            count: profile.totalSessions
        )

        try? persistenceService.saveUserProfile(profile)
    }

    // MARK: - Helper Methods

    private func updateRunningAverage(
        current: Double,
        newValue: Double,
        count: Int
    ) -> Double {
        guard count > 0 else { return newValue }
        return (current * Double(count - 1) + newValue) / Double(count)
    }
}
