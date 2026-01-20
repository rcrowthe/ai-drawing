//
//  UserProfile.swift
//  AIDrawing
//
//  Long-term behavioral data and learning
//

import Foundation
import CoreGraphics

/// Recurring pattern motif
struct Motif: Codable, Identifiable {
    let id: UUID
    let gestureSequence: [String]  // Sequence of gesture types
    let frequency: Int
    let lastSeen: Date

    init(id: UUID = UUID(), gestureSequence: [String], frequency: Int, lastSeen: Date) {
        self.id = id
        self.gestureSequence = gestureSequence
        self.frequency = frequency
        self.lastSeen = lastSeen
    }
}

/// User's drawing profile for AI adaptation
struct UserProfile: Codable {
    var userId: UUID
    var createdAt: Date
    var lastUpdated: Date

    // Stroke statistics
    var totalStrokes: Int = 0
    var totalSessions: Int = 0
    var totalDrawingTime: TimeInterval = 0.0
    var averageSessionDuration: TimeInterval = 0.0

    // Aggregated behavioral patterns
    var averageVelocity: Double = 0.0
    var averagePressure: Double = 0.0
    var averageStrokeLength: Double = 0.0
    var preferredDensity: Double = 0.5
    var motifs: [Motif] = []

    // AI interaction metrics
    var averageAIInteractionRatio: Double = 0.0  // AI strokes per user stroke

    // AI adaptation data
    var lensWeightAdjustments: [LensType: Double] = [:]  // Learned lens preferences
    var moveTypePreferences: [String: Double] = [:]       // AIMoveType.rawValue: preference
    var moveTypeHistory: [AIMoveType: Int] = [:]          // Accepted move counts
    var moveTypeRejections: [AIMoveType: Int] = [:]       // Rejected move counts

    // Reinforcement history
    var positiveReinforcementCount: Int = 0
    var negativeReinforcementCount: Int = 0

    /// Create a new profile
    init() {
        self.userId = UUID()
        self.createdAt = Date()
        self.lastUpdated = Date()
    }

    /// Update profile with new stroke data
    mutating func updateWithStroke(_ stroke: Stroke) {
        // Update running averages
        let currentCount = Double(positiveReinforcementCount + negativeReinforcementCount + 1)

        averageVelocity = (averageVelocity * (currentCount - 1) + stroke.avgVelocity) / currentCount
        averagePressure = (averagePressure * (currentCount - 1) + stroke.avgPressure) / currentCount

        lastUpdated = Date()
    }

    /// Record reinforcement feedback
    mutating func recordReinforcement(_ reinforcement: Reinforcement) {
        switch reinforcement {
        case .good:
            positiveReinforcementCount += 1
        case .bad:
            negativeReinforcementCount += 1
        }
        lastUpdated = Date()
    }
}

