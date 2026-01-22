//
//  AIStatusIndicator.swift
//  AIDrawing
//
//  Shows current AI state with attention mode, speeds, alignment, and activity
//

import SwiftUI

struct AIStatusIndicator: View {
    let aiState: AIState
    let userSpeed: String
    let aiSpeed: String
    let lastMoveType: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Attention Mode
            HStack(spacing: 6) {
                Circle()
                    .fill(attentionModeColor)
                    .frame(width: 8, height: 8)
                Text(aiState.attentionMode.rawValue.uppercased())
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.primary)
            }

            // Alignment Mode
            HStack(spacing: 6) {
                Image(systemName: aiState.alignmentMode == .pro ? "arrow.up.right" : "arrow.down.left")
                    .font(.system(size: 9))
                    .foregroundColor(aiState.alignmentMode == .pro ? .green : .orange)
                Text(aiState.alignmentMode.rawValue.uppercased())
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            // User Speed
            HStack(spacing: 6) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 9))
                    .foregroundColor(.blue)
                Text("USER: \(userSpeed)")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            // AI Speed
            HStack(spacing: 6) {
                Image(systemName: "brain")
                    .font(.system(size: 9))
                    .foregroundColor(.purple)
                Text("AI: \(aiSpeed)")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            // Last Move Type (if available)
            if let moveType = lastMoveType {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 9))
                        .foregroundColor(.yellow)
                    Text(moveType.uppercased())
                        .font(.system(size: 9, weight: .light, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }

            // Activity State
            HStack(spacing: 6) {
                Circle()
                    .fill(activityStateColor)
                    .frame(width: 6, height: 6)
                Text(activityStateText)
                    .font(.system(size: 9, weight: .light, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .systemBackground).opacity(0.85))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
    }

    private var attentionModeColor: Color {
        switch aiState.attentionMode {
        case .wander:
            return Color.cyan
        case .focus:
            return Color.orange
        }
    }

    private var activityStateColor: Color {
        switch aiState.activityState {
        case .activeWithUser:
            return Color.green
        case .responding:
            return Color.yellow
        case .idle:
            return Color.gray
        }
    }

    private var activityStateText: String {
        switch aiState.activityState {
        case .activeWithUser:
            return "DRAWING"
        case .responding:
            return "RESPONDING"
        case .idle:
            return "IDLE"
        }
    }
}
