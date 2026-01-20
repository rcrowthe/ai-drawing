//
//  AIMove.swift
//  AIDrawing
//
//  Represents a proposed AI drawing move
//

import Foundation
import PencilKit
import CoreGraphics

struct AIMove {
    let moveType: AIMoveType
    let path: PKStrokePath
    let tool: PKInkingTool
    let timestamp: Date
    let metadata: [String: Any]

    /// Estimated bounding box (for safety validation)
    var estimatedBoundingBox: CGRect {
        var minX: CGFloat = .infinity
        var minY: CGFloat = .infinity
        var maxX: CGFloat = -.infinity
        var maxY: CGFloat = -.infinity

        for i in 0..<path.count {
            let point = path[i].location
            minX = min(minX, point.x)
            minY = min(minY, point.y)
            maxX = max(maxX, point.x)
            maxY = max(maxY, point.y)
        }

        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    /// Convert to PKStroke for rendering
    func toPKStroke() -> PKStroke {
        return PKStroke(ink: PKInk(tool.inkType, color: tool.color), path: path)
    }

    init(
        moveType: AIMoveType,
        path: PKStrokePath,
        tool: PKInkingTool = PKInkingTool(.marker, color: .cyan, width: 15),
        metadata: [String: Any] = [:]
    ) {
        self.moveType = moveType
        self.path = path
        self.tool = tool
        self.timestamp = Date()
        self.metadata = metadata
    }
}
