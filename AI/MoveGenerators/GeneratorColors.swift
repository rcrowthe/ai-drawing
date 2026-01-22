//
//  GeneratorColors.swift
//  AIDrawing
//
//  Central color configuration for all generators
//  Change these to customize AI stroke colors
//

import Foundation
import UIKit

struct GeneratorColors {
    /// Echo Generator color (dark blue variant - medium width, high opacity)
    static var echoColor: UIColor = UIColor(red: 0.2, green: 0.4, blue: 0.7, alpha: 1.0)  // Increased from 0.95

    /// Texture Generator color (dark blue variant - lighter, thinner width)
    static var textureColor: UIColor = UIColor(red: 0.3, green: 0.5, blue: 0.8, alpha: 0.95)  // Increased from 0.85

    /// Structural Generator color (dark blue variant - deep, thick width)
    static var structuralColor: UIColor = UIColor(red: 0.1, green: 0.3, blue: 0.6, alpha: 1.0)

    /// Contrast Generator color (dark blue variant - vibrant, varied width)
    static var contrastColor: UIColor = UIColor(red: 0.25, green: 0.45, blue: 0.75, alpha: 1.0)  // Increased from 0.9

    /// Predictive Generator color (dark blue variant - bright, medium opacity)
    static var predictiveColor: UIColor = UIColor(red: 0.35, green: 0.55, blue: 0.85, alpha: 0.95)  // Increased from 0.85

    /// Surprise Generator color (dark blue variant - rich, high opacity)
    static var surpriseColor: UIColor = UIColor(red: 0.15, green: 0.35, blue: 0.65, alpha: 1.0)  // Increased from 0.9

    /// Ivy Generator color (dark blue variant - subtle but visible)
    static var ivyColor: UIColor = UIColor(red: 0.2, green: 0.4, blue: 0.65, alpha: 0.95)  // Increased from 0.85 - was too faint

    /// User pen color (default: dark blue to match generator family)
    static var userPenColor: UIColor = UIColor(red: 0.15, green: 0.35, blue: 0.65, alpha: 1.0)
}
