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
    /// Echo Generator color (default: cyan)
    static var echoColor: UIColor = .cyan

    /// Texture Generator color (default: orange)
    static var textureColor: UIColor = .systemOrange

    /// Structural Generator color (default: cyan)
    static var structuralColor: UIColor = .cyan

    /// Contrast Generator color (default: green)
    static var contrastColor: UIColor = .systemGreen

    /// Predictive Generator color (default: magenta)
    static var predictiveColor: UIColor = .magenta

    /// Surprise Generator color (default: purple)
    static var surpriseColor: UIColor = .systemPurple

    /// User pen color (default: black)
    static var userPenColor: UIColor = .black
}
