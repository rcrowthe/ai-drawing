//
//  AIState.swift
//  AIDrawing
//
//  Current state of the AI system
//

import Foundation

/// Attention mode - how the AI perceives user's drawing style
enum AttentionMode: String, Codable {
    case wander  // User draws loosely, shifts zones rapidly
    case focus   // User concentrates on one area, strokes slow/refine
}

/// Alignment mode - how the AI responds to user
enum AlignmentMode: String, Codable {
    case pro   // Reinforces user direction, rhythm, intention
    case anti  // Introduces tension, contrast, deviation
}

/// Activity state - what the AI is currently doing
enum ActivityState: String, Codable {
    case activeWithUser  // Drawing simultaneously with user
    case responding      // User paused, AI completing gesture
    case idle            // Silent, no action
}

/// Current snapshot of AI state
struct AIState: Codable {
    var attentionMode: AttentionMode
    var alignmentMode: AlignmentMode
    var activityState: ActivityState
    var lastUserStrokeTime: Date?
    var autonomousModeEnabled: Bool

    init(
        attentionMode: AttentionMode = .wander,
        alignmentMode: AlignmentMode = .pro,
        activityState: ActivityState = .idle,
        lastUserStrokeTime: Date? = nil,
        autonomousModeEnabled: Bool = false
    ) {
        self.attentionMode = attentionMode
        self.alignmentMode = alignmentMode
        self.activityState = activityState
        self.lastUserStrokeTime = lastUserStrokeTime
        self.autonomousModeEnabled = autonomousModeEnabled
    }
}
