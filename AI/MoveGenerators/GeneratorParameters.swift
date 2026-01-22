//
//  GeneratorParameters.swift
//  AIDrawing
//
//  ⚙️ CENTRAL TUNING FILE - Adjust all AI stroke visual parameters here
//  Change any value and rebuild to see the effect
//

import Foundation
import CoreGraphics
import PencilKit

// Note: UIColor not available in non-UI files, using explicit color values
// Colors: .cyan, .systemGreen, .systemOrange, .magenta, .systemPurple

struct GeneratorParameters {

    // MARK: - 🔊 ECHO GENERATOR (Cyan)
    // Follows user's stroke with parallel wavy line

    struct Echo {
        /// Base distance from user stroke (perpendicular offset)
        static var baseOffsetWander: CGFloat = 30.0  // When AI is in "wander" attention mode
        static var baseOffsetFocus: CGFloat = 15.0   // When AI is in "focus" attention mode

        /// Wave amplitude - how much the echo wiggles (0 = straight parallel)
        static var waveAmplitude: CGFloat = 8.0

        /// Number of curve segments (more = smoother, slower to compute)
        static var segments: Int = 2  // MINIMUM for performance (was 4)

        /// Visual appearance - medium weight for echo
        static var pointSize: CGFloat = 3.0      // Thickness of stroke points
        static var strokeWidth: CGFloat = 3.5    // Medium weight (increased from 3.0)
        static var opacity: CGFloat = 1.0        // 0.0 = invisible, 1.0 = fully visible
        static var force: CGFloat = 0.7          // Apple Pencil pressure simulation
    }

    // MARK: - 🏗️ STRUCTURAL GENERATOR (Cyan)
    // Reinforces shapes, edges, curves

    struct Structural {

        /// EDGE REINFORCEMENT - Parallel lines with slight wobble
        struct Edge {
            static var offsetWander: CGFloat = 40.0   // Distance in wander mode
            static var offsetFocus: CGFloat = 20.0    // Distance in focus mode
            static var wobbleAmplitude: CGFloat = 4.0 // Slight organic wobble (0 = perfectly straight)
            static var segments: Int = 8
            static var pointSize: CGFloat = 5.0
            static var strokeWidth: CGFloat = 5.0  // Thick for structural (increased from 4.0)
        }

        /// CURVE REINFORCEMENT - Parallel curves with arc emphasis
        struct Curve {
            static var baseOffset: CGFloat = 15.0
            static var arcAmplitude: CGFloat = 12.0
            static var segments: Int = 2  // MINIMUM (was 4)
            static var pointSize: CGFloat = 3.0
            static var strokeWidth: CGFloat = 4.0  // Thicker (increased from 3.0)
        }

        /// ANGLE REINFORCEMENT - Emphasizes corners
        struct Angle {
            static var pointSize: CGFloat = 4.0
            static var strokeWidth: CGFloat = 5.0  // Thick (increased from 4.0)
        }

        /// CLOSURE SUGGESTION - Closes open shapes
        struct Closure {
            static var segments: Int = 2  // MINIMUM (was 3)
            static var pointSize: CGFloat = 3.0
            static var strokeWidth: CGFloat = 4.0  // Thicker (increased from 3.0)
        }

        static var opacity: CGFloat = 1.0
        static var force: CGFloat = 0.7
    }

    // MARK: - 💚 CONTRAST GENERATOR (Green)
    // Creates tension by drawing in opposite/contrasting direction

    struct Contrast {
        /// Length as fraction of user's stroke (0.6 = 60% of user stroke length)
        static var lengthMultiplier: CGFloat = 0.6

        /// Wave amplitude - makes contrast curved instead of straight (0 = straight line)
        static var waveAmplitude: CGFloat = 10.0

        /// Number of curve segments
        static var segments: Int = 2  // MINIMUM (was 4)

        /// Angle deviation range (how "opposite" the contrast is)
        static var angleOffsetMin: CGFloat = .pi / 2
        static var angleOffsetMax: CGFloat = .pi

        /// Visual appearance
        static var pointSize: CGFloat = 3.0
        static var strokeWidth: CGFloat = 3.5  // Increased from 3.0
        static var opacity: CGFloat = 1.0
        static var force: CGFloat = 0.8
    }

    // MARK: - 🧡 TEXTURE GENERATOR (Orange)
    // Adds detail through hatching, stippling, dots

    struct Texture {

        /// HATCHING - Parallel cross-hatch lines
        struct Hatching {
            static var lineCountWander: Int = 1        // REDUCED (was 2)
            static var lineCountFocus: Int = 2         // REDUCED (was 3)
            static var spacingWander: CGFloat = 15.0   // INCREASED (was 12)
            static var spacingFocus: CGFloat = 10.0    // INCREASED (was 8)
            static var lengthMultiplier: CGFloat = 0.15 // REDUCED (was 0.2)
            static var segments: Int = 2               // REDUCED (was 4)
            static var pointSize: CGFloat = 2.0
            static var strokeWidth: CGFloat = 2.5  // Increased from 2.0
        }

        /// STIPPLING - Random dots scattered around stroke
        struct Stippling {
            static var dotCountWander: Int = 4         // REDUCED (was 8)
            static var dotCountFocus: Int = 3          // REDUCED (was 5)
            static var radiusMultiplier: CGFloat = 0.3
            static var pointSize: CGFloat = 3.0
            static var strokeWidth: CGFloat = 3.0  // Increased from 2.5
        }

        /// DOTS - Dots along the stroke path
        struct Dots {
            static var dotCount: Int = 3  // REDUCED (was 5)
            static var randomOffsetRange: ClosedRange<CGFloat> = -3.0...3.0
            static var pointSize: CGFloat = 3.0
            static var strokeWidth: CGFloat = 3.0  // Increased from 2.5
        }

        static var opacity: CGFloat = 1.0
        static var force: CGFloat = 0.6
    }

    // MARK: - 💗 PREDICTIVE GENERATOR (Magenta)
    // Anticipates where user will draw next

    struct Predictive {
        static var projectionDistance: CGFloat = 30.0  // REDUCED (was 40)
        static var segments: Int = 2  // MINIMUM (was 4)
        static var pointSize: CGFloat = 3.0
        static var strokeWidth: CGFloat = 3.5  // Increased from 3.0
        static var opacity: CGFloat = 1.0
        static var force: CGFloat = 0.7
    }

    // MARK: - 💜 SURPRISE GENERATOR (Purple)
    // Creates unexpected flourishes and gestures

    struct Surprise {

        struct Spiral {
            static var turns: CGFloat = 0.75  // REDUCED (was 1.0)
            static var maxRadius: CGFloat = 20.0  // REDUCED (was 25)
            static var segments: Int = 6  // MINIMUM (was 10)
        }

        struct Zigzag {
            static var zigCount: Int = 2  // MINIMUM (was 3)
            static var zigWidth: CGFloat = 10.0  // REDUCED (was 12)
            static var zigLength: CGFloat = 6.0  // REDUCED (was 8)
        }

        struct Loop {
            static var radius: CGFloat = 12.0  // REDUCED (was 15)
            static var segments: Int = 6  // MINIMUM (was 8)
        }

        /// Visual appearance
        static var pointSize: CGFloat = 3.0
        static var strokeWidth: CGFloat = 3.5  // Increased from 3.0
        static var opacity: CGFloat = 1.0
        static var force: CGFloat = 0.7
    }

    // MARK: - 🌿 IVY GENERATOR (Earthy Green)
    // Organic vine that follows and jumps between strokes

    struct Ivy {
        /// Proximity threshold - distance to detect nearby strokes to jump to (pixels)
        static var proximityThreshold: CGFloat = 30.0

        /// Crisscross probability - chance to flip to other side of stroke (0.0 - 1.0)
        static var crisscrossProbability: Double = 0.18

        /// Base wave amplitude - how far ivy waves from stroke (pixels)
        static var baseWaveAmplitude: CGFloat = 10.0

        /// Smoothness - curve smoothness at vertices (0.0 = sharp/square, 1.0 = smooth/round)
        static var smoothness: Double = 0.8

        /// Total segments - number of points generated along path
        static var totalSegments: Int = 30

        /// Visual appearance
        static var pointSize: CGFloat = 2.0
        static var strokeWidth: CGFloat = 2.5  // Increased from 2.0
        static var opacity: CGFloat = 0.95  // Increased from 0.85 - was too transparent
        static var force: CGFloat = 0.6
    }
}

