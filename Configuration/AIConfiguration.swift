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
    var assertiveness: Double = 0.3  // LOW to prevent freezing

    // Surprise probability: frequency of deviation (0.0 - 0.3 recommended)
    var surpriseProbability: Double = 0.1

    // Lens weights: balance between perspectives (0.0 - 2.0)
    var musicianWeight: Double = 1.0
    var painterWeight: Double = 1.0
    var physicistWeight: Double = 1.0

    // Alignment bias: pro vs anti (0.0 = always anti, 1.0 = always pro)
    var alignmentBias: Double = 0.7

    // Idle timeout: seconds before AI goes silent (1.0 - 10.0)
    var idleTimeout: TimeInterval = 3.0

    // Autonomous mode: AI draws even when user is idle
    var autonomousModeEnabled: Bool = false

    // Continuous co-drawing mode
    var continuousModeEnabled: Bool = true  // Default to ON for immediate co-drawing
    var continuousDrawRate: Double = 1.5  // strokes per second (0.5-5.0) - moderate rate for instant drawing
    var maxLocalDensity: Double = 0.95  // 0.0-1.0, max density before AI stops drawing
    var startDelay: Double = 0.3  // seconds to wait after user starts drawing before AI joins
    var stopDelay: Double = 1.5  // seconds after user stops before AI stops

    // MARK: - Generator Toggles
    // Enable/disable specific generator types
    var echoEnabled: Bool = true
    var textureEnabled: Bool = true
    var structuralEnabled: Bool = true
    var contrastEnabled: Bool = true
    var predictiveEnabled: Bool = true
    var surpriseEnabled: Bool = true

    // MARK: - Colors (stored as RGB components for Codable)
    // User drawing colors
    var userPenColorRed: Double = 0.0
    var userPenColorGreen: Double = 0.0
    var userPenColorBlue: Double = 0.0
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
