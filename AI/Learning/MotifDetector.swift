//
//  MotifDetector.swift
//  AIDrawing
//
//  Detects recurring drawing patterns and motifs for AI learning
//

import Foundation
import CoreGraphics

class MotifDetector {
    private let persistenceService: PersistenceService
    private let minMotifOccurrences = 3  // Minimum frequency to be considered a motif
    private let maxMotifAge: TimeInterval = 7 * 24 * 60 * 60  // 1 week

    init(persistenceService: PersistenceService = .shared) {
        self.persistenceService = persistenceService
    }

    // MARK: - Motif Detection

    /// Analyze session for recurring patterns
    func detectMotifs(in session: DrawingSession) -> [Motif] {
        let userStrokes = session.strokes.filter { $0.source == .user }

        guard userStrokes.count >= 3 else { return [] }

        var detectedMotifs: [Motif] = []

        // Detect velocity pattern motifs
        if let velocityMotif = detectVelocityPattern(userStrokes) {
            detectedMotifs.append(velocityMotif)
        }

        // Detect directional pattern motifs
        if let directionalMotif = detectDirectionalPattern(userStrokes) {
            detectedMotifs.append(directionalMotif)
        }

        // Detect gesture sequence motifs
        if let gestureMotif = detectGestureSequence(userStrokes) {
            detectedMotifs.append(gestureMotif)
        }

        return detectedMotifs
    }

    /// Update user profile with detected motifs
    func updateProfileWithMotifs(_ newMotifs: [Motif]) {
        guard var profile = try? persistenceService.loadUserProfile() else { return }

        for newMotif in newMotifs {
            // Check if motif already exists
            if let index = profile.motifs.firstIndex(where: {
                $0.gestureSequence == newMotif.gestureSequence
            }) {
                // Update existing motif
                var existing = profile.motifs[index]
                existing = Motif(
                    id: existing.id,
                    gestureSequence: existing.gestureSequence,
                    frequency: existing.frequency + 1,
                    lastSeen: Date()
                )
                profile.motifs[index] = existing
            } else {
                // Add new motif
                profile.motifs.append(newMotif)
            }
        }

        // Clean up old motifs
        profile.motifs = profile.motifs.filter { motif in
            let age = Date().timeIntervalSince(motif.lastSeen)
            return age < maxMotifAge && motif.frequency >= minMotifOccurrences
        }

        // Sort by frequency
        profile.motifs.sort { $0.frequency > $1.frequency }

        // Keep only top 20 motifs
        if profile.motifs.count > 20 {
            profile.motifs = Array(profile.motifs.prefix(20))
        }

        try? persistenceService.saveUserProfile(profile)
    }

    // MARK: - Pattern Detection Methods

    /// Detect velocity pattern (fast, medium, slow sequences)
    private func detectVelocityPattern(_ strokes: [Stroke]) -> Motif? {
        guard strokes.count >= 3 else { return nil }

        var pattern: [String] = []

        for stroke in strokes.suffix(5) {  // Check last 5 strokes
            if stroke.avgVelocity > 200 {
                pattern.append("fast")
            } else if stroke.avgVelocity > 100 {
                pattern.append("medium")
            } else {
                pattern.append("slow")
            }
        }

        // Check if pattern has variation (not all same speed)
        let uniqueElements = Set(pattern).count
        guard uniqueElements > 1 else { return nil }

        return Motif(
            gestureSequence: pattern,
            frequency: 1,
            lastSeen: Date()
        )
    }

    /// Detect directional pattern (up, down, left, right sequences)
    private func detectDirectionalPattern(_ strokes: [Stroke]) -> Motif? {
        guard strokes.count >= 3 else { return nil }

        var pattern: [String] = []

        for stroke in strokes.suffix(5) {
            let dx = stroke.endPoint.x - stroke.startPoint.x
            let dy = stroke.endPoint.y - stroke.startPoint.y

            // Determine primary direction
            if abs(dx) > abs(dy) {
                pattern.append(dx > 0 ? "right" : "left")
            } else {
                pattern.append(dy > 0 ? "down" : "up")
            }
        }

        return Motif(
            gestureSequence: pattern,
            frequency: 1,
            lastSeen: Date()
        )
    }

    /// Detect gesture sequence (line, curve, circle, etc.)
    private func detectGestureSequence(_ strokes: [Stroke]) -> Motif? {
        guard strokes.count >= 3 else { return nil }

        var pattern: [String] = []

        for stroke in strokes.suffix(5) {
            let gesture = classifyGesture(stroke)
            pattern.append(gesture)
        }

        return Motif(
            gestureSequence: pattern,
            frequency: 1,
            lastSeen: Date()
        )
    }

    // MARK: - Gesture Classification

    /// Simple heuristic gesture classification
    private func classifyGesture(_ stroke: Stroke) -> String {
        let length = stroke.length
        let curvature = stroke.curvature
        let directionChanges = stroke.directionChanges

        // Check for very short strokes (dots)
        if length < 10 {
            return "dot"
        }

        // Check for relatively straight lines
        if curvature < 0.1 && directionChanges < 2 {
            return "line"
        }

        // Check for curves
        if curvature > 0.1 && curvature < 0.5 && directionChanges < 3 {
            return "curve"
        }

        // Check for zigzags
        if directionChanges > 4 {
            return "zigzag"
        }

        // Check for potential circles/loops (high curvature, closed)
        if curvature > 0.5 {
            let startToEnd = sqrt(
                pow(stroke.endPoint.x - stroke.startPoint.x, 2) +
                pow(stroke.endPoint.y - stroke.startPoint.y, 2)
            )

            if startToEnd < length * 0.3 {
                return "loop"
            }

            return "circle"
        }

        // Default to generic gesture
        return "gesture"
    }

    // MARK: - Motif Query

    /// Check if a pattern matches known motifs
    func matchesKnownMotif(_ pattern: [String]) -> Motif? {
        guard let profile = try? persistenceService.loadUserProfile() else { return nil }

        return profile.motifs.first { motif in
            motif.gestureSequence == pattern
        }
    }

    /// Get user's most common motifs
    func getMostCommonMotifs(limit: Int = 5) -> [Motif] {
        guard let profile = try? persistenceService.loadUserProfile() else { return [] }

        return Array(profile.motifs.prefix(limit))
    }
}
