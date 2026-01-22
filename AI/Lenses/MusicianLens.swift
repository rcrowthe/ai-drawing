//
//  MusicianLens.swift
//  AIDrawing
//
//  Analyzes rhythm, tempo, timing, and flourishes
//

import Foundation
import CoreGraphics

class MusicianLens: Lens {
    var weight: Double = 1.0

    // Thresholds
    private let rhythmicRepetitionThreshold = 0.7
    private let accelerationThreshold = 50.0  // Points per second squared
    private let phraseGapThreshold: TimeInterval = 0.5  // Seconds

    func analyze(
        userStroke: Stroke,
        recentStrokes: [Stroke],
        canvasState: CanvasState
    ) -> LensAnalysis {
        // ANALYZE ALL STROKES but weight the latest (userStroke) more heavily
        // Combine recent strokes with the current one
        let allStrokes = recentStrokes + [userStroke]

        // Extract rhythmic features from ALL strokes
        let tempo = calculateTempo(allStrokes)
        let acceleration = calculateAcceleration(allStrokes)
        let pausePattern = detectPausePattern(allStrokes)
        let rhythmicRepetition = detectRhythmicRepetition(allStrokes)

        // Also analyze JUST the latest stroke for immediate characteristics
        let latestVelocity = userStroke.avgVelocity
        let latestPressure = userStroke.avgPressure

        var suggestions: [(AIMoveType, Double)] = []

        // Rhythmic repetition detected - echo the rhythm
        if rhythmicRepetition > rhythmicRepetitionThreshold {
            suggestions.append((.echo, 0.8))
        }

        // Latest stroke is FAST - immediate texture response (weighted heavily)
        if latestVelocity > 400.0 {
            suggestions.append((.texture, 0.9))  // High confidence for latest stroke
        }

        // User is accelerating (trend across strokes) - add excitement
        if acceleration > accelerationThreshold {
            suggestions.append((.texture, 0.6))
        }

        // Pause at phrase boundary - complete the phrase
        if pausePattern.isPhrasal {
            suggestions.append((.predictive, 0.7))
        }

        // Hesitation detected - offer support
        if pausePattern.isHesitation {
            suggestions.append((.structural, 0.5))
        }

        let parameters: [String: Double] = [
            "tempo": tempo,
            "acceleration": acceleration,
            "rhythmicRepetition": rhythmicRepetition,
            "phraseComplete": pausePattern.isPhrasal ? 1.0 : 0.0,
            "latestVelocity": latestVelocity,  // Track latest stroke separately
            "latestPressure": latestPressure
        ]

        let urgency = LensAnalysis.calculateUrgency(from: suggestions)

        return LensAnalysis(
            lensType: .musician,
            suggestedMoveTypes: suggestions,
            parameters: parameters,
            urgency: urgency * weight
        )
    }

    // MARK: - Analysis Methods

    private func calculateTempo(_ strokes: [Stroke]) -> Double {
        guard strokes.count >= 2 else { return 0.0 }

        // Strokes per second in recent window
        let first = strokes.first!
        let last = strokes.last!
        let timeSpan = last.timestamp.timeIntervalSince(first.timestamp)

        guard timeSpan > 0 else { return 0.0 }
        return Double(strokes.count) / timeSpan
    }

    private func calculateAcceleration(_ strokes: [Stroke]) -> Double {
        guard strokes.count >= 3 else { return 0.0 }

        // Calculate velocity changes
        var velocityChanges: [Double] = []

        for i in 1..<strokes.count {
            let prevVel = strokes[i - 1].avgVelocity
            let currVel = strokes[i].avgVelocity
            let timeDelta = strokes[i].timestamp.timeIntervalSince(strokes[i - 1].timestamp)

            if timeDelta > 0 {
                let velChange = (currVel - prevVel) / timeDelta
                velocityChanges.append(velChange)
            }
        }

        guard !velocityChanges.isEmpty else { return 0.0 }

        // Average acceleration
        let avgAccel = velocityChanges.reduce(0, +) / Double(velocityChanges.count)
        return abs(avgAccel)
    }

    private func detectPausePattern(_ strokes: [Stroke]) -> (isPhrasal: Bool, isHesitation: Bool) {
        guard strokes.count >= 2 else {
            return (false, false)
        }

        // Check gap between last two strokes
        let lastGap = strokes.last!.timestamp.timeIntervalSince(
            strokes[strokes.count - 2].timestamp
        )

        // Calculate average gap
        var totalGaps: TimeInterval = 0
        for i in 1..<strokes.count {
            totalGaps += strokes[i].timestamp.timeIntervalSince(strokes[i - 1].timestamp)
        }
        let avgGap = totalGaps / Double(strokes.count - 1)

        // Phrasal pause: longer than average
        let isPhrasal = lastGap > avgGap * 2.0 && lastGap > phraseGapThreshold

        // Hesitation: series of very short strokes
        let recentLengths = strokes.suffix(3).map { $0.length }
        let avgRecentLength = recentLengths.reduce(0, +) / Double(recentLengths.count)
        let isHesitation = avgRecentLength < 50.0  // Short strokes

        return (isPhrasal, isHesitation)
    }

    private func detectRhythmicRepetition(_ strokes: [Stroke]) -> Double {
        guard strokes.count >= 4 else { return 0.0 }

        // Analyze velocity patterns for repetition
        let velocities = strokes.map { $0.avgVelocity }

        // Look for repeating patterns in velocity
        var matchCount = 0
        let windowSize = 2

        for i in 0..<(velocities.count - windowSize * 2) {
            let pattern1 = Array(velocities[i..<(i + windowSize)])
            let pattern2 = Array(velocities[(i + windowSize)..<(i + windowSize * 2)])

            // Check if patterns are similar
            let similarity = calculatePatternSimilarity(pattern1, pattern2)
            if similarity > 0.8 {
                matchCount += 1
            }
        }

        let totalComparisons = max(velocities.count - windowSize * 2, 1)
        return Double(matchCount) / Double(totalComparisons)
    }

    private func calculatePatternSimilarity(_ p1: [Double], _ p2: [Double]) -> Double {
        guard p1.count == p2.count && !p1.isEmpty else { return 0.0 }

        var totalDiff: Double = 0.0
        for i in 0..<p1.count {
            totalDiff += abs(p1[i] - p2[i])
        }

        let avgDiff = totalDiff / Double(p1.count)
        let avgMagnitude = (p1.reduce(0, +) + p2.reduce(0, +)) / Double(p1.count + p2.count)

        guard avgMagnitude > 0 else { return 0.0 }

        // Similarity = 1 - (normalized difference)
        return max(0.0, 1.0 - (avgDiff / avgMagnitude))
    }
}
