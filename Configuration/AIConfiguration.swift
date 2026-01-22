//
//  AIConfiguration.swift
//  AIDrawing
//
//  User-adjustable AI parameters
//

import Foundation
import UIKit

struct AIConfiguration: Codable {
    // Assertiveness: how often AI proposes gestures (0.0 - 1.0)
    var assertiveness: Double = 1.0  // SET TO 1.0 - AI ALWAYS responds (unless idle)

    // Surprise probability: frequency of deviation (0.0 - 0.3 recommended)
    var surpriseProbability: Double = 0.15  // INCREASED from 0.1

    // Lens weights: balance between perspectives (0.0 - 2.0)
    var musicianWeight: Double = 1.5  // INCREASED - prioritize rhythm
    var painterWeight: Double = 1.2   // INCREASED - prioritize composition
    var physicistWeight: Double = 1.3 // INCREASED - prioritize energy

    // Alignment bias: pro vs anti (0.0 = always anti, 1.0 = always pro)
    var alignmentBias: Double = 0.6  // Slightly more variety

    // Idle timeout: seconds before AI goes silent (1.0 - 10.0)
    var idleTimeout: TimeInterval = 3.0  // RESTORED TO 3.0 - goes silent after 3s of user inactivity

    // Animation speed multiplier: controls how fast AI strokes animate (0.5 - 3.0)
    // 1.0 = normal speed, 2.0 = twice as fast, 0.5 = half speed
    // This multiplier is applied ON TOP of per-stroke speed variations
    var animationSpeedMultiplier: Double = 1.0  // 1.0 = normal speed

    // Continuous drawing controls
    var continuousDrawDuration: Double = 5.0    // How long AI continues drawing after user stops (seconds) - reduced from 10
    var continuousDrawInterval: Double = 1.2    // Time between continuous AI strokes (seconds) - increased from 0.8
    var continuousDrawMaxStrokes: Int = 20      // Maximum number of strokes in continuous mode (safety limit) - reduced from 50

    // Color variation controls (applied to all AI generators)
    var colorHueVariation: Double = 0.0         // Hue shift variation in degrees (0-360, 0 = no variation)
    var colorSaturationVariation: Double = 0.0  // Saturation variation (0.0-1.0, 0 = no variation)
    var colorBrightnessVariation: Double = 0.0  // Brightness variation (0.0-1.0, 0 = no variation)
    var colorOpacityVariation: Double = 0.0     // Opacity/alpha variation (0.0-1.0, 0 = no variation)

    // Autonomous mode: AI draws even when user is idle
    var autonomousModeEnabled: Bool = false

    // MARK: - Generator Toggles
    // Enable/disable specific generator types
    var echoEnabled: Bool = true
    var textureEnabled: Bool = true
    var structuralEnabled: Bool = true
    var contrastEnabled: Bool = true
    var predictiveEnabled: Bool = true
    var surpriseEnabled: Bool = true
    var ivyEnabled: Bool = true

    // MARK: - Generator Parameters with Randomness
    // Each parameter has a base value and randomness (-10 to +10, where 0 = no randomness)
    // Randomness is applied as: value * (1.0 + random(-abs(randomness)/100, +abs(randomness)/100))

    // PREDICTIVE GENERATOR PARAMETERS
    var predictiveLineLength: Double = 50.0      // Base projection distance in pixels
    var predictiveLineLengthRandomness: Double = 0.0  // -10 to +10
    var predictiveCurvature: Double = 1.0        // Curve intensity multiplier
    var predictiveCurvatureRandomness: Double = 0.0

    // ECHO GENERATOR PARAMETERS
    var echoOffset: Double = 30.0               // Perpendicular distance from user stroke
    var echoOffsetRandomness: Double = 0.0
    var echoWaveAmplitude: Double = 8.0         // Wave wiggle amount
    var echoWaveAmplitudeRandomness: Double = 0.0

    // STRUCTURAL GENERATOR PARAMETERS
    var structuralOffset: Double = 30.0         // Distance for edge reinforcement
    var structuralOffsetRandomness: Double = 0.0
    var structuralWobble: Double = 4.0          // Organic wobble amount
    var structuralWobbleRandomness: Double = 0.0

    // CONTRAST GENERATOR PARAMETERS
    var contrastLength: Double = 0.6            // Length multiplier (0.0-1.0)
    var contrastLengthRandomness: Double = 0.0
    var contrastWaveAmplitude: Double = 10.0    // Wave amount
    var contrastWaveAmplitudeRandomness: Double = 0.0

    // TEXTURE GENERATOR PARAMETERS
    var textureSpacing: Double = 12.0           // Hatching line spacing
    var textureSpacingRandomness: Double = 0.0
    var textureDensity: Double = 1.0            // Density multiplier for dots/hatches
    var textureDensityRandomness: Double = 0.0

    // SURPRISE GENERATOR PARAMETERS
    var surpriseSize: Double = 15.0             // Size of surprise elements (spirals, loops, etc)
    var surpriseSizeRandomness: Double = 0.0
    var surpriseComplexity: Double = 1.0        // Complexity multiplier
    var surpriseComplexityRandomness: Double = 0.0

    // IVY GENERATOR PARAMETERS
    var ivyWaveAmplitude: Double = 10.0         // How far ivy waves from stroke
    var ivyWaveAmplitudeRandomness: Double = 0.0
    var ivyProximity: Double = 30.0             // Distance threshold to jump to nearby strokes
    var ivyProximityRandomness: Double = 0.0
    var ivyShapeConformance: Double = 0.5       // 0=contrast/perpendicular, 1=conform/parallel to shapes
    var ivyShapeDetectionMinRadius: Double = 50.0  // Minimum distance for shape detection (don't react to very close strokes)
    var ivyShapeDetectionMaxRadius: Double = 150.0 // Maximum distance for shape detection (don't react to distant strokes)

    // MARK: - Colors (stored as RGB components for Codable)
    // User drawing colors - default to dark blue to match generator family
    var userPenColorRed: Double = 0.15
    var userPenColorGreen: Double = 0.35
    var userPenColorBlue: Double = 0.65
    var userPenColorAlpha: Double = 1.0

    // AI generator colors
    var echoColorRed: Double = 0.0
    var echoColorGreen: Double = 1.0
    var echoColorBlue: Double = 1.0
    var echoColorAlpha: Double = 1.0

    var textureColorRed: Double = 1.0
    var textureColorGreen: Double = 0.647
    var textureColorBlue: Double = 0.0
    var textureColorAlpha: Double = 1.0

    var structuralColorRed: Double = 0.0
    var structuralColorGreen: Double = 1.0
    var structuralColorBlue: Double = 1.0
    var structuralColorAlpha: Double = 1.0

    var contrastColorRed: Double = 0.0
    var contrastColorGreen: Double = 1.0
    var contrastColorBlue: Double = 0.0
    var contrastColorAlpha: Double = 1.0

    var predictiveColorRed: Double = 1.0
    var predictiveColorGreen: Double = 0.0
    var predictiveColorBlue: Double = 1.0
    var predictiveColorAlpha: Double = 1.0

    var surpriseColorRed: Double = 0.5
    var surpriseColorGreen: Double = 0.0
    var surpriseColorBlue: Double = 0.5
    var surpriseColorAlpha: Double = 1.0

    // MARK: - Color Helpers
    var userPenColor: UIColor {
        get {
            UIColor(red: userPenColorRed, green: userPenColorGreen, blue: userPenColorBlue, alpha: userPenColorAlpha)
        }
        set {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            newValue.getRed(&r, green: &g, blue: &b, alpha: &a)
            userPenColorRed = Double(r)
            userPenColorGreen = Double(g)
            userPenColorBlue = Double(b)
            userPenColorAlpha = Double(a)
        }
    }

    var echoColor: UIColor {
        get { UIColor(red: echoColorRed, green: echoColorGreen, blue: echoColorBlue, alpha: echoColorAlpha) }
        set {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            newValue.getRed(&r, green: &g, blue: &b, alpha: &a)
            echoColorRed = Double(r)
            echoColorGreen = Double(g)
            echoColorBlue = Double(b)
            echoColorAlpha = Double(a)
        }
    }

    var textureColor: UIColor {
        get { UIColor(red: textureColorRed, green: textureColorGreen, blue: textureColorBlue, alpha: textureColorAlpha) }
        set {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            newValue.getRed(&r, green: &g, blue: &b, alpha: &a)
            textureColorRed = Double(r)
            textureColorGreen = Double(g)
            textureColorBlue = Double(b)
            textureColorAlpha = Double(a)
        }
    }

    var structuralColor: UIColor {
        get { UIColor(red: structuralColorRed, green: structuralColorGreen, blue: structuralColorBlue, alpha: structuralColorAlpha) }
        set {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            newValue.getRed(&r, green: &g, blue: &b, alpha: &a)
            structuralColorRed = Double(r)
            structuralColorGreen = Double(g)
            structuralColorBlue = Double(b)
            structuralColorAlpha = Double(a)
        }
    }

    var contrastColor: UIColor {
        get { UIColor(red: contrastColorRed, green: contrastColorGreen, blue: contrastColorBlue, alpha: contrastColorAlpha) }
        set {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            newValue.getRed(&r, green: &g, blue: &b, alpha: &a)
            contrastColorRed = Double(r)
            contrastColorGreen = Double(g)
            contrastColorBlue = Double(b)
            contrastColorAlpha = Double(a)
        }
    }

    var predictiveColor: UIColor {
        get { UIColor(red: predictiveColorRed, green: predictiveColorGreen, blue: predictiveColorBlue, alpha: predictiveColorAlpha) }
        set {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            newValue.getRed(&r, green: &g, blue: &b, alpha: &a)
            predictiveColorRed = Double(r)
            predictiveColorGreen = Double(g)
            predictiveColorBlue = Double(b)
            predictiveColorAlpha = Double(a)
        }
    }

    var surpriseColor: UIColor {
        get { UIColor(red: surpriseColorRed, green: surpriseColorGreen, blue: surpriseColorBlue, alpha: surpriseColorAlpha) }
        set {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            newValue.getRed(&r, green: &g, blue: &b, alpha: &a)
            surpriseColorRed = Double(r)
            surpriseColorGreen = Double(g)
            surpriseColorBlue = Double(b)
            surpriseColorAlpha = Double(a)
        }
    }

    /// Create configuration with default values
    init() {}

    // MARK: - Randomness Application Helper

    /// Apply randomness to a parameter value
    /// - Parameters:
    ///   - baseValue: The base parameter value
    ///   - randomness: Randomness amount (-10 to +10, where 0 = no randomness)
    /// - Returns: Value with randomness applied
    func applyRandomness(to baseValue: Double, randomness: Double) -> Double {
        guard randomness != 0 else { return baseValue }

        // Convert randomness to percentage (10 = 10% = 0.1)
        let magnitude = abs(randomness) / 100.0

        // Generate random variation between -magnitude and +magnitude
        let variation = Double.random(in: -magnitude...magnitude)

        // Apply variation: value * (1.0 + variation)
        return baseValue * (1.0 + variation)
    }

    /// Apply color variation to a UIColor
    /// - Parameter baseColor: The base color
    /// - Returns: Color with hue/saturation/brightness/opacity variation applied
    func applyColorVariation(to baseColor: UIColor) -> UIColor {
        // If no variation, return original color
        guard colorHueVariation != 0 || colorSaturationVariation != 0 ||
              colorBrightnessVariation != 0 || colorOpacityVariation != 0 else {
            return baseColor
        }

        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        baseColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        // Apply hue variation (wraps around 0-1)
        if colorHueVariation != 0 {
            let hueShift = CGFloat(Double.random(in: -colorHueVariation...colorHueVariation) / 360.0)
            hue = (hue + hueShift).truncatingRemainder(dividingBy: 1.0)
            if hue < 0 { hue += 1.0 }
        }

        // Apply saturation variation (clamp to 0-1)
        if colorSaturationVariation != 0 {
            let satShift = CGFloat(Double.random(in: -colorSaturationVariation...colorSaturationVariation))
            saturation = max(0.0, min(1.0, saturation + satShift))
        }

        // Apply brightness variation (clamp to 0-1)
        if colorBrightnessVariation != 0 {
            let brightShift = CGFloat(Double.random(in: -colorBrightnessVariation...colorBrightnessVariation))
            brightness = max(0.0, min(1.0, brightness + brightShift))
        }

        // Apply opacity variation (clamp to 0-1)
        if colorOpacityVariation != 0 {
            let alphaShift = CGFloat(Double.random(in: -colorOpacityVariation...colorOpacityVariation))
            alpha = max(0.0, min(1.0, alpha + alphaShift))
        }

        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
    }

    /// Create configuration with custom values
    init(
        assertiveness: Double,
        surpriseProbability: Double,
        musicianWeight: Double,
        painterWeight: Double,
        physicistWeight: Double,
        alignmentBias: Double,
        idleTimeout: TimeInterval,
        autonomousModeEnabled: Bool = false,
        echoEnabled: Bool = true,
        textureEnabled: Bool = true,
        structuralEnabled: Bool = true,
        contrastEnabled: Bool = true,
        predictiveEnabled: Bool = true,
        surpriseEnabled: Bool = true
    ) {
        self.assertiveness = assertiveness
        self.surpriseProbability = surpriseProbability
        self.musicianWeight = musicianWeight
        self.painterWeight = painterWeight
        self.physicistWeight = physicistWeight
        self.alignmentBias = alignmentBias
        self.idleTimeout = idleTimeout
        self.autonomousModeEnabled = autonomousModeEnabled
        self.echoEnabled = echoEnabled
        self.textureEnabled = textureEnabled
        self.structuralEnabled = structuralEnabled
        self.contrastEnabled = contrastEnabled
        self.predictiveEnabled = predictiveEnabled
        self.surpriseEnabled = surpriseEnabled
    }
}

// MARK: - Presets

extension AIConfiguration {
    enum Preset {
        case subtleCompanion
        case boldCollaborator
        case contrarian
    }

    /// Subtle AI that rarely intervenes
    static var subtleCompanion: AIConfiguration {
        return AIConfiguration(
            assertiveness: 0.3,
            surpriseProbability: 0.05,
            musicianWeight: 1.5,
            painterWeight: 1.0,
            physicistWeight: 0.5,
            alignmentBias: 0.9,
            idleTimeout: 2.0
        )
    }

    /// Bold AI that frequently contributes
    static var boldCollaborator: AIConfiguration {
        return AIConfiguration(
            assertiveness: 0.8,
            surpriseProbability: 0.2,
            musicianWeight: 1.0,
            painterWeight: 1.2,
            physicistWeight: 1.2,
            alignmentBias: 0.5,
            idleTimeout: 5.0
        )
    }

    /// Contrarian AI that challenges user
    static var contrarian: AIConfiguration {
        return AIConfiguration(
            assertiveness: 0.6,
            surpriseProbability: 0.25,
            musicianWeight: 0.5,
            painterWeight: 1.0,
            physicistWeight: 1.5,
            alignmentBias: 0.2,
            idleTimeout: 4.0
        )
    }
}
