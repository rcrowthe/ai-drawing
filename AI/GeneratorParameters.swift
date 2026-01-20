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
        static var segments: Int = 12

        /// Visual appearance
        static var pointSize: CGFloat = 3.0      // Thickness of stroke points
        static var strokeWidth: CGFloat = 3.0    // Overall stroke width
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
            static var strokeWidth: CGFloat = 4.0
        }

        /// CURVE REINFORCEMENT - Parallel curves with arc emphasis
        struct Curve {
            static var baseOffset: CGFloat = 15.0      // Base distance from stroke
            static var arcAmplitude: CGFloat = 12.0    // Arc that peaks in middle (0 = parallel)
            static var segments: Int = 10
            static var pointSize: CGFloat = 3.0
            static var strokeWidth: CGFloat = 3.0
        }

        /// ANGLE REINFORCEMENT - Emphasizes corners
        struct Angle {
            static var pointSize: CGFloat = 4.0
            static var strokeWidth: CGFloat = 4.0
        }

        /// CLOSURE SUGGESTION - Closes open shapes
        struct Closure {
            static var segments: Int = 5
            static var pointSize: CGFloat = 3.0
            static var strokeWidth: CGFloat = 3.0
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
        static var segments: Int = 10

        /// Angle deviation range (how "opposite" the contrast is)
        static var angleOffsetMin: CGFloat = .pi / 2  // Minimum 90 degrees different
        static var angleOffsetMax: CGFloat = .pi      // Maximum 180 degrees (completely opposite)

        /// Visual appearance
        static var pointSize: CGFloat = 3.0
        static var strokeWidth: CGFloat = 3.0
        static var opacity: CGFloat = 1.0
        static var force: CGFloat = 0.8
    }

    // MARK: - 🧡 TEXTURE GENERATOR (Orange)
    // Adds detail through hatching, stippling, dots

    struct Texture {

        /// HATCHING - Parallel cross-hatch lines
        struct Hatching {
            static var lineCountWander: Int = 2        // Number of lines in wander mode
            static var lineCountFocus: Int = 3         // Number of lines in focus mode
            static var spacingWander: CGFloat = 12.0   // Space between lines (wander)
            static var spacingFocus: CGFloat = 8.0     // Space between lines (focus)
            static var lengthMultiplier: CGFloat = 0.2 // Line length as fraction of stroke width
            static var segments: Int = 4               // Segments per line
            static var pointSize: CGFloat = 2.0
            static var strokeWidth: CGFloat = 2.0
        }

        /// STIPPLING - Random dots scattered around stroke
        struct Stippling {
            static var dotCountWander: Int = 8         // Number of dots (wander mode)
            static var dotCountFocus: Int = 5          // Number of dots (focus mode)
            static var radiusMultiplier: CGFloat = 0.3 // Scatter radius as fraction of stroke width
            static var pointSize: CGFloat = 3.0
            static var strokeWidth: CGFloat = 2.5
        }

        /// DOTS - Dots along the stroke path
        struct Dots {
            static var dotCount: Int = 5
            static var randomOffsetRange: ClosedRange<CGFloat> = -3.0...3.0  // Random jitter
            static var pointSize: CGFloat = 3.0
            static var strokeWidth: CGFloat = 2.5
        }

        static var opacity: CGFloat = 1.0
        static var force: CGFloat = 0.6
    }

    // MARK: - 💗 PREDICTIVE GENERATOR (Magenta)
    // Anticipates where user will draw next

    struct Predictive {
        /// How far ahead to project (in points)
        static var projectionDistance: CGFloat = 50.0

        /// Number of segments in projected stroke
        static var segments: Int = 6

        /// Visual appearance
        static var pointSize: CGFloat = 3.0
        static var strokeWidth: CGFloat = 3.0
        static var opacity: CGFloat = 1.0
        static var force: CGFloat = 0.7
    }

    // MARK: - 💜 SURPRISE GENERATOR (Purple)
    // Creates unexpected flourishes and gestures

    struct Surprise {

        /// SPIRAL - Expanding spiral
        struct Spiral {
            static var turns: CGFloat = 1.5           // Number of rotations
            static var maxRadius: CGFloat = 30.0       // Maximum spiral radius
            static var segments: Int = 20              // Points in spiral (more = smoother)
        }

        /// ZIGZAG - Angular zigzag pattern
        struct Zigzag {
            static var zigCount: Int = 4               // Number of zigs
            static var zigWidth: CGFloat = 15.0        // Height of each zig
            static var zigLength: CGFloat = 10.0       // Horizontal spacing
        }

        /// LOOP - Circular loop
        struct Loop {
            static var radius: CGFloat = 20.0          // Loop radius
            static var segments: Int = 12              // Points in circle
        }

        /// Visual appearance
        static var pointSize: CGFloat = 3.0
        static var strokeWidth: CGFloat = 3.0
        static var opacity: CGFloat = 1.0
        static var force: CGFloat = 0.7
    }
}

