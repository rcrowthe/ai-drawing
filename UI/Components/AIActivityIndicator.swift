//
//  AIActivityIndicator.swift
//  AIDrawing
//
//  Visual indicator showing AI state and activity
//

import SwiftUI

struct AIActivityIndicator: View {
    let aiState: AIState

    var body: some View {
        HStack(spacing: 8) {
            // Activity dot
            Circle()
                .fill(activityColor)
                .frame(width: 8, height: 8)
                .animation(.easeInOut(duration: 0.5), value: aiState.activityState)

            // State labels
            VStack(alignment: .leading, spacing: 2) {
                Text(activityText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text(modeText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .systemBackground).opacity(0.9))
                .shadow(color: .black.opacity(0.1), radius: 4)
        )
    }

    // MARK: - Computed Properties

    private var activityColor: Color {
        switch aiState.activityState {
        case .activeWithUser:
            return .green
        case .responding:
            return .blue
        case .idle:
            return .gray
        }
    }

    private var activityText: String {
        switch aiState.activityState {
        case .activeWithUser:
            return "AI Active"
        case .responding:
            return "AI Responding"
        case .idle:
            return "AI Idle"
        }
    }

    private var modeText: String {
        let attention = aiState.attentionMode == .wander ? "Wander" : "Focus"
        let alignment = aiState.alignmentMode == .pro ? "Pro" : "Anti"
        return "\(attention) • \(alignment)"
    }
}

#Preview {
    VStack(spacing: 20) {
        AIActivityIndicator(aiState: AIState(
            attentionMode: .wander,
            alignmentMode: .pro,
            activityState: .activeWithUser
        ))

        AIActivityIndicator(aiState: AIState(
            attentionMode: .focus,
            alignmentMode: .anti,
            activityState: .idle
        ))
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}
