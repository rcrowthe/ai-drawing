//
//  MoveSelector.swift
//  AIDrawing
//
//  Selects appropriate move type based on lens suggestions and AI state
//

import Foundation

class MoveSelector {
    /// Select move type from lens suggestions
    func select(
        from suggestions: [(moveType: AIMoveType, confidence: Double)],
        state: AIState,
        configuration: AIConfiguration
    ) -> AIMoveType {
        print("🎲 MoveSelector: Received \(suggestions.count) suggestions:")
        for (moveType, confidence) in suggestions {
            print("🎲   - \(moveType): \(String(format: "%.2f", confidence))")
        }

        guard !suggestions.isEmpty else {
            print("🎲 No suggestions - defaulting to ECHO")
            return .echo  // Default fallback
        }

        // Check for surprise probability first
        let surpriseRoll = Double.random(in: 0...1)
        print("🎲 Surprise roll: \(String(format: "%.2f", surpriseRoll)) vs \(String(format: "%.2f", configuration.surpriseProbability))")
        if surpriseRoll < configuration.surpriseProbability {
            print("🎲 SURPRISE selected!")
            return .surprise
        }

        // Apply alignment mode bias
        let biasedSuggestions = applyAlignmentBias(suggestions, mode: state.alignmentMode)
        print("🎲 After alignment bias (\(state.alignmentMode)):")
        for (moveType, confidence) in biasedSuggestions {
            print("🎲   - \(moveType): \(String(format: "%.2f", confidence))")
        }

        // Weighted random selection from top suggestions
        let selected = weightedRandomSelect(biasedSuggestions)
        print("🎲 SELECTED: \(selected)")
        return selected
    }

    // MARK: - Alignment Bias

    private func applyAlignmentBias(
        _ suggestions: [(moveType: AIMoveType, confidence: Double)],
        mode: AlignmentMode
    ) -> [(AIMoveType, Double)] {
        return suggestions.map { moveType, confidence in
            let boost: Double

            switch mode {
            case .pro:
                // Boost echo, structural, texture (reinforcing moves)
                if [.echo, .structural, .texture].contains(moveType) {
                    boost = 1.3
                } else {
                    boost = 1.0
                }

            case .anti:
                // Boost contrast, surprise, predictive (deviating moves)
                if [.contrast, .surprise].contains(moveType) {
                    boost = 1.5
                } else if moveType == .predictive {
                    boost = 1.2
                } else {
                    boost = 1.0
                }
            }

            return (moveType, confidence * boost)
        }
    }

    // MARK: - Weighted Random Selection

    private func weightedRandomSelect(_ suggestions: [(AIMoveType, Double)]) -> AIMoveType {
        guard !suggestions.isEmpty else { return .echo }

        // MUCH MORE RANDOM - almost ignore the weights
        // Give every move type a HUGE random boost to flatten distribution
        let randomizedSuggestions = suggestions.map { moveType, weight in
            let randomBoost = Double.random(in: 0.3...3.0)  // Was 0.5-1.5, now 0.3-3.0 for WAY more chaos
            return (moveType, weight * randomBoost)
        }

        // Just pick randomly from randomized suggestions
        let totalWeight = randomizedSuggestions.map { $0.1 }.reduce(0, +)

        guard totalWeight > 0 else {
            return randomizedSuggestions.randomElement()!.0
        }

        let roll = Double.random(in: 0...totalWeight)
        var cumulative: Double = 0.0

        print("🎲 Weighted random roll: \(String(format: "%.2f", roll)) / \(String(format: "%.2f", totalWeight))")
        for (moveType, weight) in randomizedSuggestions {
            cumulative += weight
            print("🎲   - \(moveType): cumulative \(String(format: "%.2f", cumulative))")
            if roll <= cumulative {
                print("🎲   → Selected \(moveType)!")
                return moveType
            }
        }

        // Fallback to random
        return randomizedSuggestions.randomElement()!.0
    }
}
